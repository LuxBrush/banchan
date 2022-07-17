defmodule Banchan.Workers.Thumbnailer do
  @moduledoc """
  Worker responsible for generating thumbnails and  for uploaded media.
  """
  use Oban.Worker,
    queue: :media,
    unique: [period: 60],
    tags: ["thumbnailer", "media"]

  require Logger

  alias Banchan.Accounts.User
  alias Banchan.Repo
  alias Banchan.Uploads
  alias Banchan.Uploads.Upload

  @impl Oban.Worker
  def perform(%_{
        args: %{
          "src" => src,
          "dest" => dest,
          "opts" => opts
        }
      }) do
    src = %Upload{id: src["id"], name: src["name"], key: src["key"], bucket: src["bucket"]}
    dest = %Upload{id: dest["id"], name: dest["name"], key: dest["key"], bucket: dest["bucket"]}

    process(src, dest, opts)
  end

  def thumbnail(upload)

  def thumbnail(%Upload{pending: true}) do
    # Only processed uploads can be thumbnailed.
    {:error, :pending}
  end

  def thumbnail(%Upload{} = upload, opts \\ []) do
    if Uploads.image?(upload) do
      {:ok, ret} =
        Repo.transaction(fn ->
          pending =
            Uploads.gen_pending(
              %User{id: upload.uploader_id},
              "image/jpeg",
              Keyword.get(opts, :name, "thumbnail.jpg")
            )

          with {:ok, pending} <- Repo.insert(pending),
               {:ok, _} <-
                 Oban.insert(
                   __MODULE__.new(%{
                     src: %{
                       id: upload.id,
                       bucket: upload.bucket,
                       key: upload.key,
                       name: upload.name
                     },
                     dest: %{
                       id: pending.id,
                       bucket: pending.bucket,
                       key: pending.key,
                       name: pending.name
                     },
                     opts: %{
                       target_size: Keyword.get(opts, :target_size),
                       format: Keyword.get(opts, :format, "jpeg"),
                       dimensions: Keyword.get(opts, :dimensions),
                       callback: Keyword.get(opts, :callback)
                     }
                   })
                 ) do
            {:ok, pending}
          end
        end)

      ret
    else
      # Only images can be thumbnailed right now.
      {:error, :unsupported_input}
    end
  end

  defp process(src, dest, opts) do
    tmp_src = Path.join([System.tmp_dir!(), src.key <> Path.extname(src.name)])
    File.mkdir_p!(Path.dirname(tmp_src))
    Uploads.write_data!(src, tmp_src)

    tmp_dest = Path.join([System.tmp_dir!(), dest.key <> Path.extname(dest.name)])
    File.mkdir_p!(Path.dirname(tmp_dest))

    # https://www.smashingmagazine.com/2015/06/efficient-image-resizing-with-imagemagick/
    Mogrify.open(tmp_src)
    |> Mogrify.format(opts["format"])
    |> Mogrify.custom("filter", "Triangle")
    |> Mogrify.custom("define", "filter:support=2")
    |> Mogrify.custom("unsharp", "0.25x0.25+8+0.065")
    |> Mogrify.custom("dither", "None")
    |> Mogrify.custom("posterize", "136")
    |> Mogrify.custom("quality", "82")
    |> Mogrify.custom("define", "jpeg:fancy-upsampling=off")
    |> Mogrify.custom("define", "png:compression-filter=5")
    |> Mogrify.custom("define", "png:compression-level=9")
    |> Mogrify.custom("define", "png:compression-strategy=1")
    |> Mogrify.custom("define", "png:exclude-chunk=all")
    |> Mogrify.custom("interlace", "none")
    |> Mogrify.custom("colorspace", "sRGB")
    |> Mogrify.custom("strip")
    |> then(fn mog ->
      if opts["target_size"] do
        mog
        |> Mogrify.custom("define", "#{opts["format"]}:extent=#{opts["target_size"]}")
      else
        mog
      end
    end)
    |> then(fn mog ->
      if opts["dimensions"] do
        mog
        |> Mogrify.gravity("Center")
        |> Mogrify.custom("thumbnail", opts["dimensions"])
        |> Mogrify.custom("extent", opts["dimensions"])
      else
        mog
      end
    end)
    |> Mogrify.save(path: tmp_dest)

    Uploads.upload_file!(dest, tmp_dest)

    Uploads.update_upload!(dest, %{
      size: File.stat!(tmp_dest).size,
      pending: false
    })

    File.rm!(tmp_src)
    File.rm!(tmp_dest)

    case opts["callback"] do
      [module, name, args] ->
        apply(
          String.to_existing_atom(module),
          String.to_existing_atom(name),
          args
        )

      [module, name] ->
        apply(
          String.to_existing_atom(module),
          String.to_existing_atom(name),
          [dest]
        )

      _ ->
        nil
    end

    :ok
  end
end
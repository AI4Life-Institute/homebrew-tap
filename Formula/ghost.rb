# Formula for: brew install ai4life/tap/ghost
#
# Deploy to: https://github.com/AI4Life-Institute/homebrew-tap
#   homebrew-tap/
#   └── Formula/
#       └── ghost.rb   ← this file
#
# Update sha256 on each release:
#   curl -sL https://github.com/AI4Life-Institute/ghost-in-the-shell/archive/refs/tags/vX.Y.Z.tar.gz | shasum -a 256

class Ghost < Formula
  desc "Control AI coding agents on your machine via Discord"
  homepage "https://github.com/AI4Life-Institute/ghost-in-the-shell"
  url "https://github.com/AI4Life-Institute/ghost-in-the-shell/archive/refs/tags/v0.2.23.tar.gz"
  sha256 "8d72caadb9080df76d1c557338bbbc8321c03b6cc3b60c5034683226859783db"
  license "Nonstandard"

  head "https://github.com/AI4Life-Institute/ghost-in-the-shell.git", branch: "master"

  depends_on "python@3.12"
  depends_on "tmux"
  depends_on "uv" => :build

  def install
    # Install ghost via uv tool into ~/.local/share/uv/tools (user space),
    # which avoids Homebrew's dylib relinking that breaks Rust-compiled .so files.
    uv = Formula["uv"].opt_bin/"uv"
    repo_url = "https://github.com/AI4Life-Institute/ghost-in-the-shell.git"
    tag = "v#{version}"

    # Write shim scripts that delegate to the uv-managed install
    ghost_shim = <<~SH
      #!/bin/bash
      set -euo pipefail
      UV="#{uv}"
      if ! "$UV" tool list 2>/dev/null | grep -q '^ghost-in-the-shell'; then
        echo "Installing ghost (first run)..."
        "$UV" tool install "git+#{repo_url}@#{tag}"
      fi
      exec "$("$UV" tool dir)/ghost-in-the-shell/bin/ghost" "$@"
    SH

    (bin/"ghost").write ghost_shim
    (bin/"ghost").chmod 0755
    (bin/"gits").write ghost_shim.sub("/ghost\" \"$@\"", "/gits\" \"$@\"")
    (bin/"gits").chmod 0755
  end


  def caveats
    <<~EOS
      Run the setup wizard to configure Ghost:

        ghost

      To restart the background service:

        ghost restart
    EOS
  end

  test do
    assert_match "ghost", shell_output("#{bin}/ghost --help 2>&1")
  end
end

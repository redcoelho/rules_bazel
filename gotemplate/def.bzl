load("@rules_go//go:def.bzl", "go_context")

def _get_gofmt(go_ctx):
  for tool in go_ctx.sdk.tools:
      if tool.basename == "gofmt":
          return tool
  return None

def _go_template_impl(ctx):
    orig = ctx.actions.declare_file(ctx.attr.name + "_orig.go")
    out = ctx.actions.declare_file(ctx.attr.name + ".go")

    args = ctx.actions.args()
    args.add_all([
        "--template",
        ctx.file.template,
        "--params",
        dict(ctx.attr.params), # JSON
        "--out",
        orig,
    ])
    ctx.actions.run(
        outputs = [orig],
        inputs = [ctx.file.template],
        executable = ctx.executable._gotemplate,
        arguments = [args],
        mnemonic = "GoTemplate",
        progress_message = "Rendering %s" % orig.short_path,
    )

    go = go_context(ctx)
    gofmt = _get_gofmt(go)
    ctx.actions.run_shell(
        inputs = [orig],
        tools = [gofmt],
        command = "{gofmt} -s {orig} > {dst}".format(
            gofmt = gofmt.path,
            orig = orig.path,
            dst = out.path,
        ),
        outputs = [out],
        progress_message = "Formatting %s" % out.short_path,
    )

    return [
        DefaultInfo(files = depset([out])),
    ]

go_template = rule(
    doc = "Render a Go template file",
    implementation = _go_template_impl,
    attrs = {
        "template": attr.label(
            mandatory = True,
            allow_single_file = True,
        ),
        "params": attr.string_dict(
            mandatory = True,
        ),
        "_gotemplate": attr.label(
            default = ":gotemplate",
            cfg = "exec",
            executable = True,
        ),
    },
    toolchains = ["@rules_go//go:toolchain"],
)
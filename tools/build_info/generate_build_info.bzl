"""Generate C++ build info from workspace status files."""

def _generate_build_info_impl(ctx):
    """Implementation of generate_build_info rule."""
    
    # Input: workspace status files
    # NOTE: ctx.version_file is volatile-status.txt, ctx.info_file is stable-status.txt!
    volatile_status = ctx.version_file
    stable_status = ctx.info_file
    
    # Output: generated C++ source
    output = ctx.outputs.out
    
    # Run generator script
    ctx.actions.run(
        outputs = [output],
        inputs = [stable_status, volatile_status],
        executable = ctx.executable._generator,
        arguments = [
            stable_status.path,
            volatile_status.path,
            output.path,
        ],
        mnemonic = "GenerateBuildInfo",
        progress_message = "Generating build info for %s" % ctx.label.name,
    )
    
    return [DefaultInfo(files = depset([output]))]

generate_build_info = rule(
    implementation = _generate_build_info_impl,
    attrs = {
        "_generator": attr.label(
            default = "//uni/tools/build_info:generate_build_info",
            executable = True,
            cfg = "exec",
        ),
        "out": attr.output(mandatory = True),
    },
    doc = "Generate C++ build info source file from workspace status.",
)

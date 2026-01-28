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

def _var_providing_rule_impl(ctx):
    return [
        platform_common.TemplateVariableInfo({
            "FOO": ctx.attr.var_value,
            "WORKSPACE_NAME": ctx.workspace_name,
            "LABEL_NAME": ctx.label.name,
            "LABEL_PACKAGE_NAME": ctx.label.package,
            "LABEL_WORKSPACE_NAME": ctx.label.workspace_name,
            "LABEL_REPO_NAME": ctx.label.repo_name,
            "LABEL_WORKSPACE_ROOT": ctx.label.workspace_root,
        }),
    ]

var_providing_rule = rule(
    implementation = _var_providing_rule_impl,
    attrs = {"var_value": attr.string()},
)

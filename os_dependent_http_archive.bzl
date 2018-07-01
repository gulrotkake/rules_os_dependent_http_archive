# Copyright 2016 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Modified by https://github.com/jemdiggity

def _cpu_value(repository_ctx):
  """Returns the name of the host operating system.
  Args:
    repository_ctx: The repository context.
  Returns:
    A string containing the name of the host operating system.
  """
  os_name = repository_ctx.os.name.lower()
  if os_name.startswith("mac os"):
    return "darwin"
  if any([x in os_name for x in ["linux", "freebsd"]]):
    return "linux"
  if os_name.find("windows") != -1:
    return "windows"
  result = repository_ctx.execute(["uname", "-s"])
  return result.stdout.strip()

def _os_dependent_http_archive(repository_ctx):
  """Implementation of the os_dependent_http_archive rule."""
  if repository_ctx.attr.build_file and repository_ctx.attr.build_file_content:
    repository_ctx.fail("Only one of build_file and build_file_content can be provided.")

  cpu_value = _cpu_value(repository_ctx)

  repository_ctx.file('WORKSPACE', "workspace(name = \"{name}\")\n".format(name=repository_ctx.name))
  if repository_ctx.attr.build_file:
    repository_ctx.symlink(repository_ctx.attr.build_file, 'BUILD')
  else:
    repository_ctx.file('BUILD', repository_ctx.attr.build_file_content)

  repository_ctx.download_and_extract(
    repository_ctx.attr.urls[cpu_value],
    "",
    repository_ctx.attr.sha256[cpu_value],
    repository_ctx.attr.type,
    repository_ctx.attr.strip_prefix[cpu_value])

_os_dependent_http_archive_attrs = {
  "strip_prefix": attr.string_dict(),
  "type": attr.string(),
  "build_file": attr.label(),
  "build_file_content": attr.string(),
  "urls": attr.string_list_dict(),
  "sha256": attr.string_dict(),
}

os_dependent_http_archive = repository_rule(
  implementation = _os_dependent_http_archive,
  attrs = _os_dependent_http_archive_attrs,
)



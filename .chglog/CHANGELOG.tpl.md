{{ if .Versions -}}

{{ if .Unreleased.CommitGroups -}}

## [Unreleased]

{{ range .Unreleased.CommitGroups -}}

### {{ .Title }}

{{ range .Commits -}}

- {{ if .Scope }}**{{ .Scope }}:** {{ end }}{{ .Subject }} [ [{{ .Hash.Short }}]({{ $.Info.RepositoryURL }}/commit/{{ .Hash.Long }}) ]
{{ end }}
{{ end -}}
{{ else -}}

# {{ upper (index (split "/" (index ( urlParse $.Info.RepositoryURL ) "path")) "_2")  }}

# What's changed

{{ end -}}
{{ end -}}

{{ range .Versions }}
<a name="{{ .Tag.Name }}"></a>

## {{ if .Tag.Previous }}[{{ .Tag.Name }}]{{ else }}{{ .Tag.Name }}{{ end }} - {{ datetime "2006-01-02" .Tag.Date }}

{{ range .CommitGroups -}}

### {{ .Title }}

{{ range .Commits -}}

- {{ if .Scope }}**{{ .Scope }}:** {{ end }}{{ .Subject }} [ [{{ .Hash.Short }}]({{ $.Info.RepositoryURL }}/commit/{{ .Hash.Long }}) ]
{{ end }}
{{ end -}}

{{- if .RevertCommits -}}

### Reverts

{{ range .RevertCommits -}}

- {{ .Revert.Header }}
{{ end }}
{{ end -}}

{{- if .MergeCommits -}}

### Pull Requests

{{ range .MergeCommits -}}

- {{ .Header }} ({{ .Body }})
{{ end }}
{{ end -}}

{{- if .NoteGroups -}}
{{ range .NoteGroups -}}

### {{ .Title }}

{{ range .Notes }}
{{ .Body }}
{{ end }}
{{ end -}}
{{ end -}}
{{ if .Tag.Previous -}}
**Full Changelog:** [{{ .Tag.Previous.Name }}...{{ .Tag.Name }}]
{{ end -}}
{{ end -}}

{{- if .Versions }}
[Unreleased]: {{ .Info.RepositoryURL }}/compare/{{ $latest := index .Versions 0 }}{{ $latest.Tag.Name }}...HEAD
{{ range .Versions -}}
{{ if .Tag.Previous -}}
[{{ .Tag.Name }}]: {{ $.Info.RepositoryURL }}/compare/{{ .Tag.Previous.Name }}...{{ .Tag.Name }}

[{{ .Tag.Previous.Name }}...{{ .Tag.Name }}]: {{ $.Info.RepositoryURL }}/compare/{{ .Tag.Previous.Name }}...{{ .Tag.Name }}

{{ end -}}
{{ end -}}
{{ end -}}

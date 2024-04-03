{{/* Generate the full name for resources */}}
{{- define "python-app.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name }}
{{- end }}

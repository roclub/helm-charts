{{- define "booking-tool.fullname" -}}
{{- .Release.Name }}
{{- end }}

{{- define "booking-tool.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "booking-tool.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
{{- required "serviceAccount.name is required when serviceAccount.create is false" .Values.serviceAccount.name }}
{{- end -}}
{{- end }}

{{- define "booking-tool.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "booking-tool.selectorLabels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

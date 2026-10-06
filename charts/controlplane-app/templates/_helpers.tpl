{{- define "controlplane-app.fullname" -}}
{{- .Release.Name }}
{{- end }}

{{- define "controlplane-app.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "controlplane-app.selectorLabels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

# prevent unsafe configuration of PostgreSQL migration and recovery settings
{{- define "controlplane-app.validatePostgres" -}}
{{- if not .Values.postgres.backup.objectStore.destinationPath -}}
{{- fail "postgres.backup.objectStore.destinationPath must be set to a confirmed backup write destination" -}}
{{- end -}}
{{- if .Values.postgres.recovery.enabled -}}
{{- if not .Values.postgres.recovery.destinationPath -}}
{{- fail "postgres.recovery.destinationPath is required when recovery is enabled" -}}
{{- end -}}
{{- if not .Values.postgres.recovery.serverName -}}
{{- fail "postgres.recovery.serverName is required when recovery is enabled" -}}
{{- end -}}
{{- if not .Values.postgres.recovery.credentials.existingSecret -}}
{{- fail "postgres.recovery.credentials.existingSecret is required when recovery is enabled" -}}
{{- end -}}
{{- end -}}
{{- end -}}

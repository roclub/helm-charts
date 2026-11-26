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

{{- define "booking-tool.postgresURL" -}}
{{- if eq .root.Values.postgres.users.runtime.name .root.Values.postgres.users.migration.name -}}
{{- fail "postgres.users.runtime.name and postgres.users.migration.name must differ" -}}
{{- end -}}
{{- $user := .user.name | urlquery | replace "+" "%20" -}}
{{- /* URL userinfo/path use percent-encoded spaces, not form-encoded '+'. */ -}}
{{- $password := .user.password | urlquery | replace "+" "%20" -}}
{{- $host := printf "%s-postgres-cluster-rw" (include "booking-tool.fullname" .root) -}}
{{- $database := .root.Values.postgres.connection.database | urlquery | replace "+" "%20" -}}
{{- printf "postgres://%s:%s@%s:%v/%s?sslmode=%s" $user $password $host .root.Values.postgres.connection.port $database .root.Values.postgres.connection.sslMode -}}
{{- end }}

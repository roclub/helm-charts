{{/*
Expand the name of the chart.
*/}}
{{- define "postgres.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "postgres.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "postgres.clusterName" -}}
{{- default (printf "%s-cluster" (include "postgres.fullname" .)) .Values.cluster.name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "postgres.superuserSecretName" -}}
{{- default (printf "%s-pg-superuser" (include "postgres.fullname" .)) .Values.cluster.superuserSecretName | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "postgres.objectStoreName" -}}
{{- default (printf "%s-backup" (include "postgres.fullname" .)) .Values.objectStore.name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "postgres.backupCredentialsSecretName" -}}
{{- default (printf "%s-backup-creds" (include "postgres.fullname" .)) .Values.objectStore.credentialsSecretName | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "postgres.scheduledBackupName" -}}
{{- default (printf "%s-daily-backup" (include "postgres.fullname" .)) .Values.scheduledBackup.name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "postgres.certificateSecretName" -}}
{{- default (printf "%s-postgres-cert" (include "postgres.fullname" .)) .Values.certificates.secretName | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "postgres.issuerName" -}}
{{- default (printf "%s-selfsigned-issuer" (include "postgres.fullname" .)) .Values.certificates.issuerName | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "postgres.namespace" -}}
{{- if .Values.namespaceOverride }}
namespace: {{ .Values.namespaceOverride | quote }}
{{- end }}
{{- end }}

{{- define "postgres.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "postgres.labels" -}}
helm.sh/chart: {{ include "postgres.chart" . }}
app.kubernetes.io/name: {{ include "postgres.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

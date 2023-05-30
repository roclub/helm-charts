{{/*
Expand the name of the chart.
*/}}
{{- define "roclub-app-org-registration.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "roclub-app-org-registration.fullname" -}}
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

{{/*
Define the name for all api related resources
*/}}
{{- define "roclub-app-org-registration.apiName" -}}
{{- if .Values.fullnameOverride }}
{{- printf "%s-api" .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $prefix := default .Chart.Name .Values.nameOverride }}
{{- printf "%s-api-%s" $prefix .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Define the name for all authority related resources
*/}}
{{- define "roclub-app-org-registration.authorityName" -}}
{{- if .Values.fullnameOverride }}
{{- printf "%s-authority" .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $prefix := default .Chart.Name .Values.nameOverride }}
{{- printf "%s-authority-%s" $prefix .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}


{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "roclub-app-org-registration.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "roclub-app-org-registration.labels" -}}
helm.sh/chart: {{ include "roclub-app-org-registration.chart" . }}
{{ include "roclub-app-org-registration.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "roclub-app-org-registration.selectorLabels" -}}
app.kubernetes.io/name: {{ include "roclub-app-org-registration.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "roclub-app-org-registration.serviceAccountName" -}}
{{- if .Values.api.serviceAccount.create }}
{{- default (include "roclub-app-org-registration.fullname" .) .Values.api.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.api.serviceAccount.name }}
{{- end }}
{{- end }}
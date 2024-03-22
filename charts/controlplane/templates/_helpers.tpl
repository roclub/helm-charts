{/*
Expand the name of the chart.
*/}}
{{- define "controlplane.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "controlplane.fullname" -}}
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
Create chart name and version as used by the chart label.
*/}}
{{- define "controlplane.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "controlplane.labels" -}}
helm.sh/chart: {{ include "controlplane.chart" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "controlplane.selectorLabels" -}}
app.kubernetes.io/name: {{ include "controlplane.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "controlplane.remoteControlGatewayName" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s-remote-control-gateway" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "controlplane.serviceAccountRemoteControlGatewayName" -}}
{{- if .Values.remoteControlGateway.serviceAccount.create }}
{{- default (include "controlplane.fullname" .) .Values.remoteControlGateway.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.remoteControlGateway.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "controlplane.selectorLabelsRemoteControlGateway" -}}
app.kubernetes.io/name: {{ include "controlplane.remoteControlGatewayName" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "controlplane.selectorLabelsRemoteControl" -}}
app.kubernetes.io/name: {{ include "controlplane.remoteControlName" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}



{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "controlplane.remoteControlName" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- printf "%s-remote-control" .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s-remote-control" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "controlplane.serviceAccountRemoteControlName" -}}
{{- if .Values.remoteControl.serviceAccount.create }}
{{- default (include "controlplane.fullname" .) .Values.remoteControl.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.remoteControl.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "controlplane.connectorStatusName" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- printf "%s-connector-status" .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s-connector-status" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "controlplane.selectorLabelsConnectorStatus" -}}
app.kubernetes.io/name: {{ include "controlplane.connectorStatusName" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "controlplane.serviceAccountConnectorStatusName" -}}
{{- if .Values.connectorStatus.serviceAccount.create }}
{{- default (include "controlplane.fullname" .) .Values.connectorStatus.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.connectorStatus.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "controlplane.connectorControlName" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- printf "%s-connector-control" .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s-connector-control" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "controlplane.selectorLabelsConnectorControl" -}}
app.kubernetes.io/name: {{ include "controlplane.connectorControlName" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "controlplane.serviceAccountConnectorControlName" -}}
{{- if .Values.connectorControl.serviceAccount.create }}
{{- default (include "controlplane.fullname" .) .Values.connectorControl.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.connectorControl.serviceAccount.name }}
{{- end }}
{{- end }}


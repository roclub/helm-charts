{{/*
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
app.kubernetes.io/managed-by: {{ .Release.Service }}
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

{{- define "controlplane.serviceAccountAuthZName" -}}
{{- if .Values.authZ.serviceAccount.create }}
{{- default (include "controlplane.fullname" .) .Values.authZ.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.authZ.serviceAccount.name }}
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

{{- define "controlplane.authZName" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- printf "%s-authz" .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s-authz" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "controlplane.selectorLabelsConnectorControl" -}}
app.kubernetes.io/name: {{ include "controlplane.connectorControlName" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "controlplane.selectorLabelsAuthZ" -}}
app.kubernetes.io/name: {{ include "controlplane.authZName" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "controlplane.serviceAccountConnectorControlName" -}}
{{- if .Values.connectorControl.serviceAccount.create }}
{{- default (include "controlplane.fullname" .) .Values.connectorControl.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.connectorControl.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "controlplane.influxdb2.secrets.token" -}}
{{- randAlphaNum 32 | b64enc }}
{{- end }}

{{- define "controlplane.influxdb2.secrets.password" -}}
{{- randAlphaNum 32 | b64enc }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "controlplane.conferenceWebsocketGatewayName" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s-conference-websocket-gateway" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "controlplane.selectorLabelsConferenceWebsocketGateway" -}}
app.kubernetes.io/name: {{ include "controlplane.conferenceWebsocketGatewayName" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "controlplane.selectorLabelsConferenceWebsocket" -}}
app.kubernetes.io/name: {{ include "controlplane.conferenceWebsocketName" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "controlplane.conferenceWebsocketName" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- printf "%s-conference-websocket" .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s-conference-websocket" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "controlplane.serviceAccountConferenceWebsocketName" -}}
{{- if .Values.conferenceWebsocket.serviceAccount.create }}
{{- default (include "controlplane.fullname" .) .Values.conferenceWebsocket.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.conferenceWebsocket.serviceAccount.name }}
{{- end }}
{{- end }}


{{- define "controlplane.notificationsName" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- printf "%s-notifications" .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s-notifications" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "controlplane.selectorLabelsNotifications" -}}
app.kubernetes.io/name: {{ include "controlplane.notificationsName" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "controlplane.serviceAccountNotificationsName" -}}
{{- if .Values.notifications.serviceAccount.create }}
{{- default (include "controlplane.fullname" .) .Values.notifications.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.notifications.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "controlplane.selectorLabelsOrganization" -}}
app.kubernetes.io/name: {{ include "controlplane.organizationName" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "controlplane.organizationName" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- printf "%s-organization" .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s-organization" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "controlplane.serviceAccountOrganizationName" -}}
{{- if .Values.organization.serviceAccount.create }}
{{- default (include "controlplane.fullname" .) .Values.organization.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.organization.serviceAccount.name }}
{{- end }}
{{- end }}
{{- define "delivery-lab.selectorLabels" -}}
app.kubernetes.io/name: {{ .component }}
app.kubernetes.io/instance: {{ .root.Release.Name }}
{{- end }}

{{- define "delivery-lab.labels" -}}
{{ include "delivery-lab.selectorLabels" . }}
app.kubernetes.io/part-of: delivery-lab
app.kubernetes.io/managed-by: {{ .root.Release.Service }}
{{- end }}

{{- define "delivery-lab.podSecurity" -}}
runAsNonRoot: true
seccompProfile:
  type: RuntimeDefault
{{- end }}

{{- define "delivery-lab.containerSecurity" -}}
allowPrivilegeEscalation: false
capabilities:
  drop:
    - ALL
{{- end }}

{{- define "delivery-lab.appImage" -}}
{{ .Values.image.repository }}:{{ .Values.image.tag }}
{{- end }}

{{- define "delivery-lab.wait" -}}
- name: wait-deps
  image: {{ .image }}
  imagePullPolicy: {{ .pullPolicy }}
  command:
    - node
    - -e
    - |
      const net = require("net");
      const targets = (process.env.WAIT_FOR || "").split(",").filter(Boolean);
      function open(host, port) {
        return new Promise((resolve) => {
          const once = () => {
            const socket = net.connect({ host, port: Number(port) }, () => {
              socket.end();
              resolve();
            });
            socket.on("error", () => {
              socket.destroy();
              setTimeout(once, 2000);
            });
          };
          once();
        });
      }
      Promise.all(targets.map((item) => {
        const parts = item.split(":");
        return open(parts[0], parts[1]);
      })).then(() => process.exit(0));
  env:
    - name: WAIT_FOR
      value: {{ .targets | quote }}
  resources:
    requests:
      cpu: 20m
      memory: 64Mi
    limits:
      cpu: 200m
      memory: 256Mi
  securityContext:
    {{- include "delivery-lab.containerSecurity" . | nindent 4 }}
{{- end }}

#!/bin/bash

# Solicitar ID da VM ao usuário
read -p "Digite o ID da VM no Proxmox: " VM_ID
VM_CONFIG_FILE="/etc/pve/qemu-server/$VM_ID.conf"

# Solicitar UUID ao usuário ou usar padrão
DEFAULT_UUID="954eb8ef-a3f9-4d3f-b968-b6f2e8ab2e36"
read -p "Deseja usar o UUID padrão ($DEFAULT_UUID)? (s/n): " USE_DEFAULT_UUID
if [ "$USE_DEFAULT_UUID" == "s" ]; then
  UUID="$DEFAULT_UUID"
else
  read -p "Digite o UUID desejado: " UUID
fi

# Parâmetros para que a VM não seja detectada como VM
HYPERV_ARGS="-cpu host,-hypervisor,kvm=off,hv_vendor_id=123456789123"

# Verificar se o arquivo de configuração da VM existe
if [ ! -f "$VM_CONFIG_FILE" ]; then
  echo "Arquivo de configuração da VM não encontrado em: $VM_CONFIG_FILE"
  exit 1
fi

# Adicionar parâmetros de Hypervisor
if ! grep -q "args:" "$VM_CONFIG_FILE"; then
  echo "args: $HYPERV_ARGS" >> "$VM_CONFIG_FILE"
else
  sed -i "/args: / s/$/ $HYPERV_ARGS/" "$VM_CONFIG_FILE"
fi

# Adicionar SMBIOS
if grep -q "smbios1:" "$VM_CONFIG_FILE"; then
  sed -i "/smbios1:/ s/.*/smbios1: uuid=$UUID,manufacturer=TEVOT1ZP,product=MjBCRTAwNjFNQw==,version=MEI5ODQwMSBQcm8=,serial=VzFLUzQyNzExMUU=,base64=1/" "$VM_CONFIG_FILE"
else
  echo "smbios1: uuid=$UUID,manufacturer=TEVOT1ZP,product=MjBCRTAwNjFNQw==,version=MEI5ODQwMSBQcm8=,serial=VzFLUzQyNzExMUU=,base64=1" >> "$VM_CONFIG_FILE"
fi

# Adicionar informações específicas para mascarar a VM
if ! grep -q "features:" "$VM_CONFIG_FILE"; then
  echo "features: acpi=1,apic=1,hv_relaxed=1,hv_vapic=1,hv_spinlocks=8191,hv_vpindex=1,hv_runtime=1,hv_synic=1,hv_stimer=1,hv_reset=1,hv_vendor_id=123456789123,hv_frequencies=1,kvm_hidden=1,vmport=off,smm=1,ioapic=on" >> "$VM_CONFIG_FILE"
else
  sed -i "/features:/ s/.*/features: acpi=1,apic=1,hv_relaxed=1,hv_vapic=1,hv_spinlocks=8191,hv_vpindex=1,hv_runtime=1,hv_synic=1,hv_stimer=1,hv_reset=1,hv_vendor_id=123456789123,hv_frequencies=1,kvm_hidden=1,vmport=off,smm=1,ioapic=on/" "$VM_CONFIG_FILE"
fi

# Mensagem de conclusão
echo "Parâmetros de ocultação da VM foram aplicados à VM ID $VM_ID. Por favor, reinicie a VM para aplicar as mudanças."
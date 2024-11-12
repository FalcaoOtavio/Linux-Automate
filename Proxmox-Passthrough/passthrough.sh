#!/bin/bash

# Perguntar se o usuário usa Intel ou AMD
read -p "Você está usando um processador Intel ou AMD? (intel/amd): " CPU_TYPE

# Editar GRUB
GRUB_FILE="/etc/default/grub"
if [ -f "$GRUB_FILE" ]; then
  sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="quiet"/#&/' $GRUB_FILE
  if [ "$CPU_TYPE" == "intel" ]; then
    sed -i '/^#GRUB_CMDLINE_LINUX_DEFAULT="quiet"/a GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on iommu=pt pcie_acs_override=downstream,multifunction nofb nomodeset video=vesafb:off,efifb:off"' $GRUB_FILE
  elif [ "$CPU_TYPE" == "amd" ]; then
    sed -i '/^#GRUB_CMDLINE_LINUX_DEFAULT="quiet"/a GRUB_CMDLINE_LINUX_DEFAULT="quiet amd_iommu=on iommu=pt pcie_acs_override=downstream,multifunction nofb nomodeset video=vesafb:off,efifb:off"' $GRUB_FILE
  else
    echo "Tipo de processador não reconhecido. Saindo..."
    exit 1
  fi
else
  echo "Arquivo GRUB não encontrado. Saindo..."
  exit 1
fi

# Atualizar GRUB
update-grub

# Editar arquivo de módulos
MODULES_FILE="/etc/modules"
if [ -f "$MODULES_FILE" ]; then
  echo -e "\nvfio\nvfio_iommu_type1\nvfio_pci\nvfio_virqfd" >> $MODULES_FILE
else
  echo "Arquivo de módulos não encontrado. Saindo..."
  exit 1
fi

# Configurar IOMMU Remapping
echo "options vfio_iommu_type1 allow_unsafe_interrupts=1" > /etc/modprobe.d/iommu_unsafe_interrupts.conf
echo "options kvm ignore_msrs=1" > /etc/modprobe.d/kvm.conf

# Blacklist dos drivers da GPU
BLACKLIST_FILE="/etc/modprobe.d/blacklist.conf"
echo -e "\nblacklist radeon\nblacklist nouveau\nblacklist nvidia\nblacklist nvidiafb" > $BLACKLIST_FILE

# Buscar GPUs NVIDIA ou AMD
echo "Buscando GPUs NVIDIA e AMD no sistema..."
NVIDIA_GPUS=$(lspci -nn | grep -i nvidia)
AMD_GPUS=$(lspci -nn | grep -i amd)

GPU_IDS_ADDITIONAL=""

if [ -n "$NVIDIA_GPUS" ]; then
  echo "GPUs NVIDIA encontradas:"
  echo "$NVIDIA_GPUS"
  NVIDIA_IDS=$(echo "$NVIDIA_GPUS" | grep -oP '\[([0-9a-f]{4}:[0-9a-f]{4})\]' | tr -d '[]' | paste -sd ',')
  GPU_IDS_ADDITIONAL+="$NVIDIA_IDS"
fi

if [ -n "$AMD_GPUS" ]; then
  echo "GPUs AMD encontradas:"
  echo "$AMD_GPUS"
  AMD_IDS=$(echo "$AMD_GPUS" | grep -oP '\[([0-9a-f]{4}:[0-9a-f]{4})\]' | tr -d '[]' | paste -sd ',')
  if [ -n "$GPU_IDS_ADDITIONAL" ]; then
    GPU_IDS_ADDITIONAL+=",$AMD_IDS"
  else
    GPU_IDS_ADDITIONAL+="$AMD_IDS"
  fi
fi

# Adicionar GPU ao VFIO
if [ -n "$GPU_IDS_ADDITIONAL" ]; then
  VFIO_FILE="/etc/modprobe.d/vfio.conf"
  echo "options vfio-pci ids=$GPU_IDS_ADDITIONAL disable_vga=1" > $VFIO_FILE
fi

# Atualizar initramfs
update-initramfs -u

# Mensagem de conclusão
echo "Configuração concluída. Por favor, reinicie o servidor manualmente para aplicar as mudanças."
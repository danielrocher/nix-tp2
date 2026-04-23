{ pkgs, ... }:
{
  # Bootloader UEFI
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Modules noyau pour la virtualisation
  boot.initrd.availableKernelModules =
    [ "ahci" "xhci_pci" "virtio_pci" "virtio_blk" "virtio_scsi" "sd_mod" ];
  boot.kernelModules = [ "kvm-intel" "virtio_net" ];

  # Agent QEMU : permet les snapshots propres et le shutdown via virsh
  services.qemuGuest.enable = true;

}
include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-onlineupdate
PKG_VERSION:=1.0.0
PKG_RELEASE:=1

LUCI_TITLE:=LuCI Online Update
LUCI_DEPENDS:=+curl +wget +rpcd-mod-ucode +ucode-mod-ubus +ucode-mod-fs +ucode-mod-http
LUCI_PKGARCH:=all

include $(TOPDIR)/feeds/luci/luci.mk

define Package/$(PKG_NAME)/description
 Online firmware upgrade plugin for OpenWrt 25.12
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-onlineupdate
PKG_VERSION:=1.0
PKG_RELEASE:=1

LUCI_TITLE:=LuCI Online Update (GitHub)
LUCI_DEPENDS:=+curl +wget +rpcd-mod-ucode +ucode-mod-fs +ucode-mod-http +ucode-mod-ubus

LUCI_PKGARCH:=all

include $(TOPDIR)/feeds/luci/luci.mk

define Package/$(PKG_NAME)/description
 Online firmware upgrade via GitHub Releases (OpenWrt 25.12)
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract NYBProxyAdmin is ProxyAdmin, AccessControl {
    TransparentUpgradeableProxy private _picklePointClaimable;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function deployPicklePointClaimableProxy(
        address implementation
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _picklePointClaimable = new TransparentUpgradeableProxy(
            implementation,
            address(this),
            abi.encodeWithSignature("initialize(address)", _msgSender())
        );
    }

    function upgradePicklePointClaimableProxy(
        address implementation
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            address(_picklePointClaimable) != address(0),
            "Proxy not deployed"
        );
        _picklePointClaimable.upgradeTo(implementation);
    }

    function picklePointClaimableProxy() public view returns (address) {
        return address(_picklePointClaimable);
    }
}
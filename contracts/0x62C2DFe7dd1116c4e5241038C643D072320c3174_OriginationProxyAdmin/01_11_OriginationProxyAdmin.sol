// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev This is an auxiliary contract meant to be assigned as the admin of a {TransparentUpgradeableProxy}. For an
 * explanation of why you would want to use this see the documentation for {TransparentUpgradeableProxy}.
 * @notice modified version which handles multiple proxies
 */
contract OriginationProxyAdmin is Ownable {
    // Mapping of proxy to admin of proxy
    // Proxy admins can upgrade the proxy or change the admin
    mapping(address => address) proxyAdmins;

    event ProxyOwnershipTransferred(
        address indexed proxy,
        address indexed oldOwner,
        address indexed newOwner
    );

    /**
     * @dev Returns the current implementation of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyImplementation(TransparentUpgradeableProxy proxy)
        public
        view
        virtual
        returns (address)
    {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("implementation()")) == 0x5c60da1b
        (bool success, bytes memory returndata) = address(proxy).staticcall(
            hex"5c60da1b"
        );
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Returns the current admin of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyAdmin(TransparentUpgradeableProxy proxy)
        public
        view
        virtual
        returns (address)
    {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("admin()")) == 0xf851a440
        (bool success, bytes memory returndata) = address(proxy).staticcall(
            hex"f851a440"
        );
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Transfer ownership of proxy to another address
     *
     * Requirements:
     * - The caller must be admin of the *proxy*
     *
     * @param proxy proxy address to transfer admin
     * @param newAdmin new proxy admin address
     */
    function transferProxyOwnership(address proxy, address newAdmin)
        public
        virtual
        isProxyAdmin(proxy, msg.sender)
    {
        require(newAdmin != address(0x0), "Admin cannot be the zero address");
        proxyAdmins[proxy] = newAdmin;
        emit ProxyOwnershipTransferred(proxy, msg.sender, newAdmin);
    }

    /**
     * @dev Upgrades `proxy` to `implementation`. See {TransparentUpgradeableProxy-upgradeTo}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgrade(address payable proxy, address implementation)
        public
        virtual
        isProxyAdmin(proxy, msg.sender)
    {
        TransparentUpgradeableProxy(proxy).upgradeTo(implementation);
    }

    /**
     * @dev Upgrades `proxy` to `implementation`. See {TransparentUpgradeableProxy-upgradeTo}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgradeAndCall(
        address payable proxy,
        address implementation,
        bytes calldata data
    ) public virtual isProxyAdmin(proxy, msg.sender) {
        TransparentUpgradeableProxy(proxy).upgradeToAndCall(
            implementation,
            data
        );
    }

    /**
     * Add proxy admin to a given proxy
     * Called only by the owner once on pool deployment
     */
    function setProxyAdmin(address proxy, address admin) external onlyOwner {
        proxyAdmins[proxy] = admin;
    }

    modifier isProxyAdmin(address proxy, address user) {
        require(proxyAdmins[proxy] == user, "User is not admin of proxy");
        _;
    }
}
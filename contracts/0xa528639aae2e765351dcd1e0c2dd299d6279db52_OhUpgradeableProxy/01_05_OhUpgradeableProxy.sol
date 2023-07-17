// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol";

/// @title Oh! Finance Upgradeable Proxy
/// @notice Versioned, EIP-1967 Compliant Proxy
/// @dev Upgrades managed by the proxy admin contract
contract OhUpgradeableProxy is TransparentUpgradeableProxy {
    bytes32 private constant _VERSION_SLOT = 0x460994c355dbc8229336897ed9def5884fb6b26b0a995b156780d056c758577d;

    constructor(
        address _logic,
        address admin_,
        bytes memory _data
    ) TransparentUpgradeableProxy(_logic, admin_, _data) {
        assert(_VERSION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.version")) - 1));
        _setVersion(1);
    }

    function getAdmin() external view returns (address admin_) {
        admin_ = _admin();
    }

    function getImplementation() external view returns (address implementation_) {
        implementation_ = _implementation();
    }

    function getVersion() external view returns (uint256 version_) {
        version_ = _version();
    }

    /// @notice Override to support versioning
    function _upgradeTo(address newImplementation) internal virtual override {
        super._upgradeTo(newImplementation);
        _setVersion(_version() + 1);
    }

    /// @notice Get the current version number
    function _version() internal view returns (uint256 version_) {
        bytes32 slot = _VERSION_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            version_ := sload(slot)
        }
    }

    /// @notice Set the version on deployment/upgrades
    function _setVersion(uint256 version_) private {
        bytes32 slot = _VERSION_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, version_)
        }
    }
}
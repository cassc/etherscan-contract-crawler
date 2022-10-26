// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./Proxy.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 *
 * Upgradeability is only provided internally through {_upgradeTo}. For an externally upgradeable proxy see
 * {TransparentUpgradeableProxy}.
 */
contract UpgradeableProxy is Proxy {

    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializating the storage of the proxy like a Solidity constructor.
     */
    constructor(uint256 _initVersion) public payable {
        _setVersion(_initVersion);
    }

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(uint256 version, address indexed implementation);

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    bytes32 private constant _VERSION_SLOT = 0x460994c355dbc8229336897ed9def5884fb6b26b0a995b156780d056c758577e;

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view override returns (address impl) {
        bytes32 slot = _IMPLEMENTATION_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            impl := sload(slot)
        }
    }

    /**
   * @dev Tells the version name of the current implementation
    * return uint256 representing the name of the current version
    */
    function _version() internal view returns (uint256 version) {
        bytes32 slot = _VERSION_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            version := sload(slot)
        }
    }


    /**
     * @dev Upgrades the proxy to a new implementation.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(uint256 version, address newImplementation) internal {
        _setImplementation(newImplementation);

        _setVersion(version);

        emit Upgraded(version, newImplementation);
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(isContract(newImplementation), "UpgradeableProxy: new implementation is not a contract");

        bytes32 slot = _IMPLEMENTATION_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newImplementation)
        }
    }

    function _setVersion(uint256 _newVersion) private {
        // This additional check guarantees that new version will be at least greater than the privios one,
        // so it is impossible to reuse old versions, or use the last version twice
        require(_newVersion > _version(), "Version can not be less then last");

        bytes32 slot = _VERSION_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, _newVersion)
        }
    }

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}
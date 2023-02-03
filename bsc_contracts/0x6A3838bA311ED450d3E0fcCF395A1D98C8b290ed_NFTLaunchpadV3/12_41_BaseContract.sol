// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./access/AccessControllable.sol";

// solhint-disable func-name-mixedcase
abstract contract BaseContract is AccessControllable, UUPSUpgradeable {
    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    // slither-disable-next-line unused-state
    uint256[50] private __gap;

    function __BaseContract_init(address acl) internal onlyInitializing {
        __BaseContract_init_unchained(acl);
    }

    function __BaseContract_init_unchained(address acl) internal onlyInitializing {
        __UUPSUpgradeable_init();
        __AccessControllable_init(acl);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyAdmin {}
}
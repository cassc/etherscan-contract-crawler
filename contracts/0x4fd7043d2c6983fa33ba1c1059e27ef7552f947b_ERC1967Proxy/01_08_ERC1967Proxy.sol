// SPDX-License-Identifier: CC0-1.0

/// @title ERC1967 Proxy Contract

/**
 *        ><<    ><<<<< ><<    ><<      ><<
 *      > ><<          ><<      ><<      ><<
 *     >< ><<         ><<       ><<      ><<
 *   ><<  ><<        ><<        ><<      ><<
 *  ><<<< >< ><<     ><<        ><<      ><<
 *        ><<        ><<       ><<<<    ><<<<
 */

pragma solidity ^0.8.17;

import "openzeppelin/proxy/Proxy.sol";
import "openzeppelin-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol";

contract ERC1967Proxy is Proxy, ERC1967UpgradeUpgradeable {
    constructor(address _logic, bytes memory _data) {
        _upgradeToAndCall(_logic, _data, false);
    }

    function _implementation() internal view virtual override returns (address implementation) {
        return ERC1967UpgradeUpgradeable._getImplementation();
    }
}
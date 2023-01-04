// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.6.12;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Proxy} from "./Proxy.sol";

contract UpgradeabilityProxy is Proxy {
    bytes32 internal constant IMPLEMENTATION_SLOT = 0xb48ff3cc8de8878868881880f0848a636898d5306468c6789081cc8a04636f38;

    constructor(address implementationContract) public {
        _upgradeTo(implementationContract);
    }

    function _implementation() internal view override returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            impl := sload(slot)
        }
    }

    function _upgradeTo(address newImplementation) internal {
        require(Address.isContract(newImplementation), "Non-contract address");

        _setImplementation(newImplementation);
    }

    function _setImplementation(address newImplementation) internal {
        require(Address.isContract(newImplementation), "Non-contract address");

        bytes32 slot = IMPLEMENTATION_SLOT;

        assembly {
            sstore(slot, newImplementation)
        }
    }
}
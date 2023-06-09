// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import { INonTransparentProxied } from "./interfaces/INonTransparentProxied.sol";

contract NonTransparentProxied is INonTransparentProxied {

    bytes32 internal constant ADMIN_SLOT          = bytes32(uint256(keccak256("eip1967.proxy.admin"))          - 1);
    bytes32 internal constant IMPLEMENTATION_SLOT = bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);

    function admin() public view override returns (address admin_) {
        admin_ = _getAddress(ADMIN_SLOT);
    }

    function implementation() public view override returns (address implementation_) {
        implementation_ = _getAddress(IMPLEMENTATION_SLOT);
    }

    function _getAddress(bytes32 slot_) private view returns (address value_) {
        assembly {
            value_ := sload(slot_)
        }
    }

}
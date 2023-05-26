// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.13;

import {ERC4626} from "solmate/mixins/ERC4626.sol";

abstract contract IxPYT is ERC4626 {
    function sweep(address receiver) external virtual returns (uint256 shares);
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/structs/BitMaps.sol";

import "../../base/ERC20BaseInternal.sol";
import "./IERC20SupplyInternal.sol";
import "./ERC20SupplyStorage.sol";

abstract contract ERC20SupplyInternal is IERC20SupplyInternal {
    using ERC20SupplyStorage for ERC20SupplyStorage.Layout;

    function _maxSupply() internal view returns (uint256) {
        return ERC20SupplyStorage.layout().maxSupply;
    }
}
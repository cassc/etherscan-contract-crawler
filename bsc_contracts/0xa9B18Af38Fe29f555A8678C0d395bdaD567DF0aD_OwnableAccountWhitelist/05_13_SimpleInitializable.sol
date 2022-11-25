// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {ISimpleInitializable} from "./ISimpleInitializable.sol";
import {Initializable} from "./Initializable.sol";

abstract contract SimpleInitializable is ISimpleInitializable, Initializable {
    // bytes32 private constant _INITIALIZER_SLOT = bytes32(uint256(keccak256("xSwap.v2.SimpleInitializable._initializer")) - 1);
    bytes32 private constant _INITIALIZER_SLOT = 0x4c943a984a6327bfee4b36cd148236ae13d07c9a3fe7f9857f4809df3e826db1;

    // prettier-ignore
    constructor()
        Initializable(_INITIALIZER_SLOT)
    {} // solhint-disable-line no-empty-blocks

    function initialize() public init {
        _initialize();
    }

    function _initialize() internal virtual;
}
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "./SubCollectionHelper.sol";

contract SquigglesHelper is SubCollectionHelper {

    uint256 public constant SQUIGGLES_START_INDEX = 0;
    uint256 public constant SQUIGGLES_END_INDEX = 9733;

    function isValid(uint256 _idx) internal pure override returns (bool) {
        return _idx >= SQUIGGLES_START_INDEX && _idx <= SQUIGGLES_END_INDEX;
    }

}
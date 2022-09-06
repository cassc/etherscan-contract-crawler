// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import { MondayAPE } from './MondayAPE.sol';

abstract contract Controller {
    MondayAPE public mondayAPE;
    function _mint(address to, uint256 apeId, uint256 amount) internal {
        mondayAPE.mint(to, apeId, amount);
    }
}
// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import {IYieldVestment} from "./IYieldVestment.sol";

contract YieldVestment is IYieldVestment {

    function isVested(uint256 tokenId) external view override returns (bool vested) {
        vested = false;
    }

}
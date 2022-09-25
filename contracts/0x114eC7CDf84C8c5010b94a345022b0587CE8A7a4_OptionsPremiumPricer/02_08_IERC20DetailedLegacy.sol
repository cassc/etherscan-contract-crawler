// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;

import { IERC20Legacy } from "./IERC20Legacy.sol";

interface IERC20DetailedLegacy is IERC20Legacy {
    function decimals() external view returns (uint8);

    function symbol() external view returns (string calldata);
}
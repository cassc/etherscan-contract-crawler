// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import { IERC165 } from "./IERC165.sol";

interface IERC2981 is IERC165 {
    function royaltyInfo(uint tokenId, uint salePrice) external view returns (address receiver, uint royaltyAmount);
}
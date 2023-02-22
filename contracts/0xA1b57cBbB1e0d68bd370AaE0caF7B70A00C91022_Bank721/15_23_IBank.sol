// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {TokenType} from "../constant/TokenEnums.sol";
import {NFT} from "../constant/BaseStructs.sol";

interface IBank is IERC165 {
    function bindMarket(address market_) external;
}
// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.16;

import {ICToken} from "./ICToken.sol";

interface IComptroller {
    function claimComp(address holder, ICToken[] memory cTokens) external;

    function compAccrued(address) external view returns (uint256);

    function markets(address) external returns (bool, uint256);

    function enterMarkets(address[] calldata) external returns (uint256[] memory);

    function getAccountLiquidity(address) external view returns (uint256, uint256, uint256);
}
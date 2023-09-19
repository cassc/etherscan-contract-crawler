/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.8.16;

import "../lib/Types.sol";

interface ID3Maker {
    function init(address, address, uint256) external;
    function getTokenMMInfoForPool(address token)
        external
        view
        returns (Types.TokenMMInfo memory tokenMMInfo, uint256 tokenIndex);
    function checkHeartbeat() external view returns (bool);
    function getOneTokenOriginIndex(address token) external view returns (int256);
    function getPoolTokenListFromMaker() external view returns(address[] memory tokenlist);
}
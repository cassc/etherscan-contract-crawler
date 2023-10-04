// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

import "../libraries/Types.sol";

interface IHouse {
    function getBet(uint256 _id) external view returns (Types.Bet memory);
    function getPlayerStats(address _account) external view returns (uint256, uint256, uint256, uint256, uint256);
}
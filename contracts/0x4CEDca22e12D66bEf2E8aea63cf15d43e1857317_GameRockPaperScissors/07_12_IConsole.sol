// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

import "../libraries/Types.sol";

interface IConsole {
    function getGasPerRoll() external view returns (uint256);
    function getMinBetSize() external view returns (uint256);
    function getGame(uint256 _id) external view returns (Types.Game memory);
    function getGameByImpl(address _impl) external view returns (Types.Game memory);
}
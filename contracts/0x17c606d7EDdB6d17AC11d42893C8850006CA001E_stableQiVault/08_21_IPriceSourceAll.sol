// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
interface IPriceSource {
    function latestRoundData() external view returns (uint256);
    function latestAnswer() external view returns (uint256);
    function decimals() external view returns (uint8);
}
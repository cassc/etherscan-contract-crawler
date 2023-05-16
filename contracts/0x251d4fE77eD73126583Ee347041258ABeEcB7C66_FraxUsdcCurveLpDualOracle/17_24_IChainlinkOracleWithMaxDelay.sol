// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IChainlinkOracleWithMaxDelay is IERC165 {
    event SetMaximumOracleDelay(address oracle, uint256 oldMaxOracleDelay, uint256 newMaxOracleDelay);

    function CHAINLINK_FEED_ADDRESS() external view returns (address);

    function CHAINLINK_FEED_DECIMALS() external view returns (uint8);

    function CHAINLINK_FEED_PRECISION() external view returns (uint256);

    function getChainlinkPrice() external view returns (bool _isBadData, uint256 _updatedAt, uint256 _usdPerEth);

    function maximumOracleDelay() external view returns (uint256);

    function setMaximumOracleDelay(uint256 _newMaxOracleDelay) external;
}
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IFraxUsdChainlinkOracleWithMaxDelay is IERC165 {
    event SetMaximumFraxUsdOracleDelay(uint256 oldMaxOracleDelay, uint256 newMaxOracleDelay);

    function FRAX_USD_CHAINLINK_FEED_ADDRESS() external view returns (address);

    function FRAX_USD_CHAINLINK_FEED_DECIMALS() external view returns (uint8);

    function FRAX_USD_CHAINLINK_FEED_PRECISION() external view returns (uint256);

    function maximumFraxUsdOracleDelay() external view returns (uint256);

    function getFraxUsdChainlinkPrice()
        external
        view
        returns (bool _isBadData, uint256 _updatedAt, uint256 _usdPerFrax);

    function setMaximumFraxUsdOracleDelay(uint256 _newMaxOracleDelay) external;
}
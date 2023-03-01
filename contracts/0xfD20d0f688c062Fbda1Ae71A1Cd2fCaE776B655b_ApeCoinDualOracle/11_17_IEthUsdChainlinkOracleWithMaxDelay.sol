// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IEthUsdChainlinkOracleWithMaxDelay is IERC165 {
    event SetMaximumEthUsdOracleDelay(uint256 oldMaxOracleDelay, uint256 newMaxOracleDelay);

    function ETH_USD_CHAINLINK_FEED_ADDRESS() external view returns (address);

    function ETH_USD_CHAINLINK_FEED_DECIMALS() external view returns (uint8);

    function ETH_USD_CHAINLINK_FEED_PRECISION() external view returns (uint256);

    function maximumEthUsdOracleDelay() external view returns (uint256);

    function getEthUsdChainlinkPrice() external view returns (bool _isBadData, uint256 _updatedAt, uint256 _usdPerEth);
}
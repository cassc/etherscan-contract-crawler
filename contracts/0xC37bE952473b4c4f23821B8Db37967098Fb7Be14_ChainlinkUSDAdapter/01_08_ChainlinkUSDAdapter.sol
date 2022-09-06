// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "./NormalizingOracleAdapter.sol";
import "../../interfaces/IChainlinkV3Aggregator.sol";

contract ChainlinkUSDAdapter is NormalizingOracleAdapter {
    /// @notice chainlink aggregator with price in USD
    IChainlinkV3Aggregator public immutable aggregator;

    constructor(
        string memory _assetName,
        string memory _assetSymbol,
        address _asset,
        IChainlinkV3Aggregator _aggregator
    ) NormalizingOracleAdapter(_assetName, _assetSymbol, _asset, 8, 8) {
        require(address(_aggregator) != address(0), "invalid aggregator");

        aggregator = _aggregator;
    }

    /// @dev returns price of asset in 1e8
    function latestAnswer() external view override returns (int256) {
        (, int256 price, , , ) = aggregator.latestRoundData();
        return int256(_normalize(uint256(price)));
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contracts
import {CrossChainRateProvider} from "./core/CrossChainRateProvider.sol";

// Interfaces
import {IRocketTokenRETH} from "./interfaces/IRocketTokenRETH.sol";

/// @title rETH cross chain rate provider
/// @author witherblock
/// @notice Provides the current exchange rate of rETH to a receiver contract on a different chain than the one this contract is deployed on
contract REthRateProvider is CrossChainRateProvider {
    constructor(uint16 _dstChainId, address _layerZeroEndpoint) {
        rateInfo = RateInfo({
            tokenSymbol: "rETH",
            tokenAddress: 0xae78736Cd615f374D3085123A210448E74Fc6393,
            baseTokenSymbol: "ETH",
            baseTokenAddress: address(0) // Address 0 for native tokens
        });
        dstChainId = _dstChainId;
        layerZeroEndpoint = _layerZeroEndpoint;
    }

    /// @notice Returns the latest rate from the rETH contract
    function getLatestRate() public view override returns (uint256) {
        return
            IRocketTokenRETH(0xae78736Cd615f374D3085123A210448E74Fc6393)
                .getExchangeRate();
    }
}
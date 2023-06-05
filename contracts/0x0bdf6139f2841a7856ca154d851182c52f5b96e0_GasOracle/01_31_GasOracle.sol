// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IGasOracle} from "./interfaces/IGasOracle.sol";

/**
 * @title GasOracle
 * @dev A contract that provides gas price and native token USD price data on other blockchains.
 */
contract GasOracle is Ownable, IGasOracle {
    struct ChainData {
        // price of the chain's native token in USD
        uint128 price;
        // price of a gas unit in the chain's native token with precision according to the const ORACLE_PRECISION
        uint128 gasPrice;
    }
    uint private constant ORACLE_PRECISION = 18;
    uint private constant ORACLE_SCALING_FACTOR = 10 ** ORACLE_PRECISION;
    // number to divide by to change precision from gas oracle price precision to chain precision
    uint private immutable fromOracleToChainScalingFactor;

    mapping(uint chainId => ChainData) public override chainData;
    // current chain ID
    uint public immutable override chainId;

    constructor(uint chainId_, uint chainPrecision) {
        chainId = chainId_;
        fromOracleToChainScalingFactor = 10 ** (ORACLE_PRECISION - chainPrecision);
    }

    /**
     * @notice Sets the chain data for a given chain ID.
     * @param chainId_ The ID of the given chain to set data for.
     * @param price_ The price of the given chain's native token in USD.
     * @param gasPrice The price of a gas unit in the given chain's native token (with precision according to the const
     * `ORACLE_PRECISION`).
     */
    function setChainData(uint chainId_, uint128 price_, uint128 gasPrice) external override onlyOwner {
        chainData[chainId_].price = price_;
        chainData[chainId_].gasPrice = gasPrice;
    }

    /**
     * @notice Sets only the price for a given chain ID.
     * @param chainId_ The ID of the given chain to set the price for.
     * @param price_ The price of the given chain's native token in USD.
     */
    function setPrice(uint chainId_, uint128 price_) external override onlyOwner {
        chainData[chainId_].price = price_;
    }

    /**
     * @notice Sets only the gas price for a given chain ID.
     * @param chainId_ The ID of the given chain to set the gas price for.
     * @param gasPrice The price of a gas unit in the given chain's native token (with precision according to the const
     * `ORACLE_PRECISION`).
     */
    function setGasPrice(uint chainId_, uint128 gasPrice) external override onlyOwner {
        chainData[chainId_].gasPrice = gasPrice;
    }

    /**
     * @notice Calculates the gas cost of a transaction on another chain in the current chain's native token.
     * @param otherChainId The ID of the chain for which to get the gas cost.
     * @param gasAmount The amount of gas used in a transaction.
     * @return The gas cost of a transaction in the current chain's native token
     */
    function getTransactionGasCostInNativeToken(
        uint otherChainId,
        uint gasAmount
    ) external view override returns (uint) {
        return
            (chainData[otherChainId].gasPrice * gasAmount * chainData[otherChainId].price) /
            chainData[chainId].price /
            fromOracleToChainScalingFactor;
    }

    /**
     * @notice Calculates the gas cost of a transaction on another chain in USD.
     * @param otherChainId The ID of the chain for which to get the gas cost.
     * @param gasAmount The amount of gas used in a transaction.
     * @return The gas cost of a transaction in USD with precision of `ORACLE_PRECISION`
     */
    function getTransactionGasCostInUSD(uint otherChainId, uint gasAmount) external view override returns (uint) {
        return (chainData[otherChainId].gasPrice * gasAmount * chainData[otherChainId].price) / ORACLE_SCALING_FACTOR;
    }

    /**
     * @notice Get the cross-rate between the two chains' native tokens.
     * @param otherChainId The ID of the other chain to get the cross-rate for.
     */
    function crossRate(uint otherChainId) external view override returns (uint) {
        return (chainData[otherChainId].price * ORACLE_SCALING_FACTOR) / chainData[chainId].price;
    }

    /**
     * @notice Get the price of a given chain's native token in USD.
     * @param chainId_ The ID of the given chain to get the price.
     * @return the price of the given chain's native token in USD with precision of const ORACLE_PRECISION
     */
    function price(uint chainId_) external view override returns (uint) {
        return chainData[chainId_].price;
    }

    fallback() external payable {
        revert("Unsupported");
    }

    receive() external payable {
        revert("Unsupported");
    }
}
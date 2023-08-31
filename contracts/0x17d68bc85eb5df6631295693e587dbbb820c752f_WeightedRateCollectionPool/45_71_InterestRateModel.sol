// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/ILiquidity.sol";

/**
 * @title Interest Rate Model API
 * @author MetaStreet Labs
 */
abstract contract InterestRateModel {
    /**
     * @notice Get interest rate model name
     * @return Interest rate model name
     */
    function INTEREST_RATE_MODEL_NAME() external view virtual returns (string memory);

    /**
     * @notice Get interest rate model version
     * @return Interest rate model version
     */
    function INTEREST_RATE_MODEL_VERSION() external view virtual returns (string memory);

    /**
     * Get interest rate for liquidity
     * @param amount Liquidity amount
     * @param rates Rates
     * @param nodes Liquidity nodes
     * @param count Liquidity node count
     * @return Interest per second
     */
    function _rate(
        uint256 amount,
        uint64[] memory rates,
        ILiquidity.NodeSource[] memory nodes,
        uint16 count
    ) internal view virtual returns (uint256);

    /**
     * Distribute interest to liquidity
     * @param amount Liquidity amount
     * @param interest Interest to distribute
     * @param nodes Liquidity nodes
     * @param count Liquidity node count
     * @return Interest distribution
     */
    function _distribute(
        uint256 amount,
        uint256 interest,
        ILiquidity.NodeSource[] memory nodes,
        uint16 count
    ) internal view virtual returns (uint128[] memory);
}
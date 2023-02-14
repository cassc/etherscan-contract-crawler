// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import "./CloberMarketDeployer.sol";

interface CloberStableMarketDeployer is CloberMarketDeployer {
    /**
     * @notice Deploys a new stable market.
     * @dev Only the market factory can call this function.
     * @param orderToken The address of the new market's order token.
     * @param quoteToken The quote token address.
     * @param baseToken The base token address.
     * @param salt The salt used to compute the address of the contract.
     * @param quoteUnit The amount that one raw amount represents in quote tokens.
     * @param makerFee The maker fee.
     * Paid to the maker when negative, paid by the maker when positive.
     * Every 10000 represents a 1% fee on trade volume.
     * @param takerFee The taker fee.
     * Paid by the taker.
     * Every 10000 represents a 1% fee on trade volume.
     * @param a The starting price point.
     * @param d The common difference between price points.
     * @return The address of the deployed stable market.
     */
    function deploy(
        address orderToken,
        address quoteToken,
        address baseToken,
        bytes32 salt,
        uint96 quoteUnit,
        int24 makerFee,
        uint24 takerFee,
        uint128 a,
        uint128 d
    ) external returns (address);
}
// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../interfaces/IDepositHandler.sol";

interface IPricingModule is IDepositHandler {
    struct PriceInfo {
        address[] v2LpTokens;
        uint256[] v2LpAmounts;
        V3LPData[] v3LpTokens;
        uint256 usdtAmount;
    }

    /**
     * @notice Get price of vault creation.
     * @param user Address of vault creator.
     * @param fungibleTokenDeposits Array of fungible token deposits
     * consisting of addresses and amounts.
     * @param nonFungibleTokenDeposits Array of non-fungible token deposits
     * consisting of addresses and IDs.
     * @param multiTokenDeposits Array of multi token deposits consisting of
     * addresses, IDs and their corresponding amounts.
     * @return A four-item tuple consisting of an array of LP token addresses,
     * an array of the corresponding required payment amounts, an array of V3LPData, and the amount
     * of USDT required.
     */
    function getPrice(
        address user,
        FungibleTokenDeposit[] memory fungibleTokenDeposits,
        NonFungibleTokenDeposit[] memory nonFungibleTokenDeposits,
        MultiTokenDeposit[] memory multiTokenDeposits,
        bool isVested
    ) external view returns (PriceInfo memory);
}
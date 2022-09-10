// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../interfaces/IDepositHandler.sol";

interface IPricingModule is IDepositHandler {
    /**
     * @notice Get price of vault creation.
     * @param vault Address of vault
     * @param user Address of vault creator.
     * @param referrer Address of person that referred vault creator. Can be
     * zero address.
     * @param fungibleTokenDeposits Array of fungible token deposits
     * consisting of addresses and amounts.
     * @param nonFungibleTokenDeposits Array of non-fungible token deposits
     * consisting of addresses and IDs.
     * @param multiTokenDeposits Array of multi token deposits consisting of
     * addresses, IDs and their corresponding amounts.
     * @return A three-item tuple consisting of an array of LP token addresses,
     * an array of the corresponding required payment amounts, and the amount
     * of USDT required.
     */
    function getPrice(
        address vault,
        address user,
        address referrer,
        FungibleTokenDeposit[] memory fungibleTokenDeposits,
        NonFungibleTokenDeposit[] memory nonFungibleTokenDeposits,
        MultiTokenDeposit[] memory multiTokenDeposits,
        bool isVested
    )
        external
        view
        returns (
            address[] memory,
            uint256[] memory,
            uint256
        );
}
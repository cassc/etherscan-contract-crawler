// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/**
 * @title Vitreus Affiliate Payout Registry
 *
 * @notice Registry which allows to register deposits under certain affiliate
 * and claim the rewards after each presale round ends
 */
interface IAffiliatePayoutRegistry {
    /**
     * @notice Register deposit
     *
     * @param affiliate the address of affiliate person
     * @param roundId the presale round number
     * @param amount the amount of deposit
     */
    function registerDeposit(address affiliate, uint256 roundId, uint256 amount) external;

    /**
     * @dev Claims rewards for an affiliate in a specific round.
     * @param signature The EIP712 signature.
     */
    function claimRewards(bytes calldata signature) external;
}
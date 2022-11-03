// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

interface IClaimRewards {
    /**
     * `claimRewardsToEthereum` triggers a withdrawal of a darknode operator's
     * rewards. `claimRewardsToEthereum` must be called by the operator
     * performing the withdrawals. When RenVM sees the claim, it will produce a
     * signature which needs to be submitted to the asset's Ren Gateway contract
     * on Ethereum.
     *
     * @param assetSymbol The token symbol being claimed (e.g. "BTC", "DOGE" or
     *        "FIL").
     * @param recipientAddress The Ethereum address to which the assets are
     *        being withdrawn to.
     * @param fractionInBps A value between 0 and 10000 (inclusive) that
     *        indicates the percent to withdraw from each of the operator's
     *        darknodes. The value should be in BPS (e.g. 10000 represents 100%,
     *        and 5000 represents 50%).
     */
    function claimRewardsToEthereum(
        string memory assetSymbol,
        address recipientAddress,
        uint256 fractionInBps
    ) external returns (uint256);
}
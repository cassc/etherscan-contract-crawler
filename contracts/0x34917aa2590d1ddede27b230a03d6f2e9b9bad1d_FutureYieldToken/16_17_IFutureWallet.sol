// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

interface IFutureWallet {
    /* Events */

    event YieldRedeemed(address _user, uint256 _periodIndex);
    event WithdrawalsPaused();
    event WithdrawalsResumed();

    /**
     * @notice register the yield of an expired period
     * @param _amount the amount of yield to be registered
     */
    function registerExpiredFuture(uint256 _amount) external;

    /**
     * @notice redeem the yield of the underlying yield of the FYT held by the sender
     * @param _periodIndex the index of the period to redeem the yield from
     */
    function redeemYield(uint256 _periodIndex) external;

    /**
     * @notice return the yield that could be redeemed by an address for a particular period
     * @param _periodIndex the index of the corresponding period
     * @param _user the FYT holder
     * @return the yield that could be redeemed by the token holder for this period
     */
    function getRedeemableYield(uint256 _periodIndex, address _user) external view returns (uint256);

    /**
     * @notice getter for the address of the future corresponding to this future wallet
     * @return the address of the future
     */
    function getFutureVaultAddress() external view returns (address);

    /**
     * @notice getter for the address of the IBT corresponding to this future wallet
     * @return the address of the IBT
     */
    function getIBTAddress() external view returns (address);

    /* Rewards mecanisms*/

    /**
     * @notice Harvest all rewards from the future wallet
     */
    function harvestRewards() external;

    /**
     * @notice Transfer all the redeemable rewards to set defined recipient
     */
    function redeemAllWalletRewards() external;

    /**
     * @notice Transfer the specified token reward balance tot the defined recipient
     * @param _rewardToken the reward token to redeem the balance of
     */
    function redeemWalletRewards(address _rewardToken) external;

    /**
     * @notice Getter for the address of the rewards recipient
     * @return the address of the rewards recipient
     */
    function getRewardsRecipient() external view returns (address);

    /**
     * @notice Setter for the address of the rewards recipient
     */
    function setRewardRecipient(address _recipient) external;
}
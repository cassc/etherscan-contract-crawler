// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "contracts/interfaces/apwine/tokens/IPT.sol";
import "contracts/interfaces/apwine/IRegistry.sol";
import "contracts/interfaces/apwine/IFutureWallet.sol";

interface IFutureVault {
    /* Events */
    event NewPeriodStarted(uint256 _newPeriodIndex);
    event FutureWalletSet(address _futureWallet);
    event RegistrySet(IRegistry _registry);
    event FundsDeposited(address _user, uint256 _amount);
    event FundsWithdrawn(address _user, uint256 _amount);
    event PTSet(IPT _pt);
    event LiquidityTransfersPaused();
    event LiquidityTransfersResumed();
    event DelegationCreated(address _delegator, address _receiver, uint256 _amount);
    event DelegationRemoved(address _delegator, address _receiver, uint256 _amount);

    /* Params */
    /**
     * @notice Getter for the PERIOD future parameter
     * @return returns the period duration of the future
     */
    function PERIOD_DURATION() external view returns (uint256);

    /**
     * @notice Getter for the PLATFORM_NAME future parameter
     * @return returns the platform of the future
     */
    function PLATFORM_NAME() external view returns (string memory);

    /**
     * @notice Start a new period
     * @dev needs corresponding permissions for sender
     */
    function startNewPeriod() external;

    /**
     * @notice Exit a terminated pool
     * @param _user the user to exit from the pool
     * @dev only pt are required as there  aren't any new FYTs
     */
    function exitTerminatedFuture(address _user) external;

    /**
     * @notice Update the state of the user and mint claimable pt
     * @param _user user adress
     */
    function updateUserState(address _user) external;

    /**
     * @notice Send the user their owed FYT (and pt if there are some claimable)
     * @param _user address of the user to send the FYT to
     */
    function claimFYT(address _user, uint256 _amount) external;

    /**
     * @notice Deposit funds into ongoing period
     * @param _user user adress
     * @param _amount amount of funds to unlock
     * @dev part of the amount deposited will be used to buy back the yield already generated proportionally to the amount deposited
     */
    function deposit(address _user, uint256 _amount) external;

    /**
     * @notice Sender unlocks the locked funds corresponding to their pt holding
     * @param _user user adress
     * @param _amount amount of funds to unlock
     * @dev will require a transfer of FYT of the ongoing period corresponding to the funds unlocked
     */
    function withdraw(address _user, uint256 _amount) external;

    /**
     * @notice Create a delegation from one address to another
     * @param _delegator the address delegating its future FYTs
     * @param _receiver the address receiving the future FYTs
     * @param _amount the of future FYTs to delegate
     */
    function createFYTDelegationTo(
        address _delegator,
        address _receiver,
        uint256 _amount
    ) external;

    /**
     * @notice Remove a delegation from one address to another
     * @param _delegator the address delegating its future FYTs
     * @param _receiver the address receiving the future FYTs
     * @param _amount the of future FYTs to remove from the delegation
     */
    function withdrawFYTDelegationFrom(
        address _delegator,
        address _receiver,
        uint256 _amount
    ) external;

    /* Getters */

    /**
     * @notice Getter the total number of FYTs on address is delegating
     * @param _delegator the delegating address
     * @return totalDelegated the number of FYTs delegated
     */
    function getTotalDelegated(address _delegator) external view returns (uint256 totalDelegated);

    /**
     * @notice Getter for next period index
     * @return next period index
     * @dev index starts at 1
     */
    function getNextPeriodIndex() external view returns (uint256);

    /**
     * @notice Getter for current period index
     * @return current period index
     * @dev index starts at 1
     */
    function getCurrentPeriodIndex() external view returns (uint256);

    /**
     * @notice Getter for the amount of pt that the user can claim
     * @param _user user to check the check the claimable pt of
     * @return the amount of pt claimable by the user
     */
    function getClaimablePT(address _user) external view returns (uint256);

    /**
     * @notice Getter for the amount (in underlying) of premium redeemable with the corresponding amount of fyt/pt to be burned
     * @param _user user adress
     * @return premiumLocked the premium amount unlockage at this period (in underlying), amountRequired the amount of pt/fyt required for that operation
     */
    function getUserEarlyUnlockablePremium(address _user)
        external
        view
        returns (uint256 premiumLocked, uint256 amountRequired);

    /**
     * @notice Getter for user IBT amount that is unlockable
     * @param _user the user to unlock the IBT from
     * @return the amount of IBT the user can unlock
     */
    function getUnlockableFunds(address _user) external view returns (uint256);

    /**
     * @notice Getter for the amount of FYT that the user can claim for a certain period
     * @param _user the user to check the claimable FYT of
     * @param _periodIndex period ID to check the claimable FYT of
     * @return the amount of FYT claimable by the user for this period ID
     */
    function getClaimableFYTForPeriod(address _user, uint256 _periodIndex) external view returns (uint256);

    /**
     * @notice Getter for the yield currently generated by one pt for the current period
     * @return the amount of yield (in IBT) generated during the current period
     */
    function getUnrealisedYieldPerPT() external view returns (uint256);

    /**
     * @notice Getter for the number of pt that can be minted for an amoumt deposited now
     * @param _amount the amount to of IBT to deposit
     * @return the number of pt that can be minted for that amount
     */
    function getPTPerAmountDeposited(uint256 _amount) external view returns (uint256);

    /**
     * @notice Getter for premium in underlying tokens that can be redeemed at the end of the period of the deposit
     * @param _amount the amount of underlying deposited
     * @return the number of underlying of the ibt deposited that will be redeemable
     */
    function getPremiumPerUnderlyingDeposited(uint256 _amount) external view returns (uint256);

    /**
     * @notice Getter for total underlying deposited in the vault
     * @return the total amount of funds deposited in the vault (in underlying)
     */
    function getTotalUnderlyingDeposited() external view returns (uint256);

    /**
     * @notice Getter for the total yield generated during one period
     * @param _periodID the period id
     * @return the total yield in underlying value
     */
    function getYieldOfPeriod(uint256 _periodID) external view returns (uint256);

    /**
     * @notice Getter for controller address
     * @return the controller address
     */
    function getControllerAddress() external view returns (address);

    /**
     * @notice Getter for futureWallet address
     * @return futureWallet address
     */
    function getFutureWalletAddress() external view returns (address);

    /**
     * @notice Getter for the IBT address
     * @return IBT address
     */
    function getIBTAddress() external view returns (address);

    /**
     * @notice Getter for future pt address
     * @return pt address
     */
    function getPTAddress() external view returns (address);

    /**
     * @notice Getter for FYT address of a particular period
     * @param _periodIndex period index
     * @return FYT address
     */
    function getFYTofPeriod(uint256 _periodIndex) external view returns (address);

    /**
     * @notice Getter for the terminated state of the future
     * @return true if this vault is terminated
     */
    function isTerminated() external view returns (bool);

    /**
     * @notice Getter for the performance fee factor of the current period
     * @return the performance fee factor of the futureVault
     */
    function getPerformanceFeeFactor() external view returns (uint256);

    /* Rewards mecanisms*/

    /**
     * @notice Harvest all rewards from the vault
     */
    function harvestRewards() external;

    /**
     * @notice Transfer all the redeemable rewards to set defined recipient
     */
    function redeemAllVaultRewards() external;

    /**
     * @notice Transfer the specified token reward balance tot the defined recipient
     * @param _rewardToken the reward token to redeem the balance of
     */
    function redeemVaultRewards(address _rewardToken) external;

    /**
     * @notice Add a token to the list of reward tokens
     * @param _token the reward token to add to the list
     * @dev the token must be different than the ibt
     */
    function addRewardsToken(address _token) external;

    /**
     * @notice Getter to check if a token is in the reward tokens list
     * @param _token the token to check if it is in the list
     * @return true if the token is a reward token
     */
    function isRewardToken(address _token) external view returns (bool);

    /**
     * @notice Getter for the reward token at an index
     * @param _index the index of the reward token in the list
     * @return the address of the token at this index
     */
    function getRewardTokenAt(uint256 _index) external view returns (address);

    /**
     * @notice Getter for the size of the list of reward tokens
     * @return the number of token in the list
     */
    function getRewardTokensCount() external view returns (uint256);

    /**
     * @notice Getter for the address of the rewards recipient
     * @return the address of the rewards recipient
     */
    function getRewardsRecipient() external view returns (address);

    /**
     * @notice Setter for the address of the rewards recipient
     */
    function setRewardRecipient(address _recipient) external;

    /* Admin functions */

    /**
     * @notice Set futureWallet address
     */
    function setFutureWallet(IFutureWallet _futureWallet) external;

    /**
     * @notice Set Registry
     */
    function setRegistry(IRegistry _registry) external;

    /**
     * @notice Pause liquidity transfers
     */
    function pauseLiquidityTransfers() external;

    /**
     * @notice Resume liquidity transfers
     */
    function resumeLiquidityTransfers() external;

    /**
     * @notice Convert an amount of IBTs in its equivalent in underlying tokens
     * @param _amount the amount of IBTs
     * @return the corresponding amount of underlying
     */
    function convertIBTToUnderlying(uint256 _amount) external view returns (uint256);

    /**
     * @notice Convert an amount of underlying tokens in its equivalent in IBTs
     * @param _amount the amount of underlying tokens
     * @return the corresponding amount of IBTs
     */
    function convertUnderlyingtoIBT(uint256 _amount) external view returns (uint256);
}
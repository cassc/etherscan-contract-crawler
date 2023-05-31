//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝

pragma solidity 0.8.16;
//SPDX-License-Identifier: BUSL-1.1

import "./IncentivizedLocker.sol";
import {IDelegateRegistry} from "interfaces/external/IDelegateRegistry.sol";
import {AuraLocker} from "interfaces/external/aura/vlAura.sol";
import {Math} from "openzeppelin/utils/math/Math.sol";

/**
 * @title Warlord AURA Locker contract
 * @author Paladin
 * @notice Contract locking AURA into vlAURA, claiming rewards and delegating voting power
 */
contract WarAuraLocker is IncentivizedLocker {
  using SafeERC20 for IERC20;

  /**
   * @notice Address of the vlAURA contract
   */
  AuraLocker private constant vlAura = AuraLocker(0x3Fa73f1E5d8A792C80F426fc8F84FBF7Ce9bBCAC);
  /**
   * @notice Address of the AURA contract
   */
  IERC20 private constant aura = IERC20(0xC0c293ce456fF0ED870ADd98a0828Dd4d2903DBF);
  /**
   * @notice Address of the DelegateRegistry contract
   */
  IDelegateRegistry private constant registry = IDelegateRegistry(0x469788fE6E9E9681C6ebF3bF78e7Fd26Fc015446);

  /**
   * @notice Address of the delegate for gauge votes
   */
  address public gaugeDelegate;

  /**
   * @notice Event emitted when the gauge delegate is updated
   */
  event SetGaugeDelegate(address oldDelegate, address newDelegate);

  // Constructor

  constructor(address _controller, address _redeemModule, address _warMinter, address _delegatee)
    WarBaseLocker(_controller, _redeemModule, _warMinter, _delegatee)
  {
    // constructor delegating only on snapshot because on chain delegation requires locking first
    registry.setDelegate("aurafinance.eth", _delegatee);
  }

  /**
   * @notice Returns the address of the token being locked
   * @return address : token
   */
  function token() external pure returns (address) {
    return address(aura);
  }

  /**
   * @notice Returns the current total amount of locked tokens for this Locker
   */
  function getCurrentLockedTokens() external view override returns (uint256) {
    (uint256 totalBalance,,,) = vlAura.lockedBalances(address(this));
    return totalBalance;
  }

  /**
   * @dev Locks the tokens in the vlToken contract
   * @param amount Amount to lock
   */
  function _lock(uint256 amount) internal override {
    aura.safeTransferFrom(msg.sender, address(this), amount);

    if (aura.allowance(address(this), address(vlAura)) != 0) aura.safeApprove(address(vlAura), 0);
    aura.safeIncreaseAllowance(address(vlAura), amount);

    vlAura.lock(address(this), amount);
  }

  /**
   * @dev Harvest rewards & send them to the Controller
   */
  function _harvest() internal override {
    AuraLocker.EarnedData[] memory rewards = vlAura.claimableRewards(address(this));
    uint256 rewardsLength = rewards.length;

    vlAura.getReward(address(this), false);

    for (uint256 i; i < rewardsLength;) {
      IERC20 rewardToken = IERC20(rewards[i].token);
      uint256 rewardBalance = rewardToken.balanceOf(address(this));
      rewardToken.safeTransfer(controller, rewardBalance);

      unchecked {
        ++i;
      }
    }
  }

  /**
   * @dev Updates the Delegatee & delegates the voting power
   * @param _delegatee Address of the delegatee
   */
  function _setDelegate(address _delegatee) internal override {
    registry.setDelegate("aurafinance.eth", _delegatee);
  }

  /**
   * @notice Updates the Gauge Delegatee & delegates the voting power
   * @param _delegatee Address of the delegatee
   */
  function setGaugeDelegate(address _delegatee) external onlyOwner {
    (,, uint256 lockedBalance,) = vlAura.lockedBalances(address(this));
    if (lockedBalance == 0) revert Errors.DelegationRequiresLock();

    emit SetGaugeDelegate(gaugeDelegate, _delegatee);
    gaugeDelegate = _delegatee;

    vlAura.delegate(_delegatee);
  }

  /**
   * @dev Processes the unlock of tokens
   */
  function _processUnlock() internal override {
    // Harvest the rewards before processing unlocks
    _harvest();

    // Get the amount being unlocked
    (, uint256 unlockableBalance,,) = vlAura.lockedBalances(address(this));
    if (unlockableBalance == 0) return;

    // Get the amount needed in the Redeem Module
    uint256 withdrawalAmount = IWarRedeemModule(redeemModule).queuedForWithdrawal(address(aura));

    // If unlock == 0 relock everything
    if (withdrawalAmount == 0) {
      vlAura.processExpiredLocks(true);
    } else {
      // otherwise withdraw everything and lock only what's left
      vlAura.processExpiredLocks(false);
      withdrawalAmount = Math.min(unlockableBalance, withdrawalAmount);
      aura.safeTransfer(address(redeemModule), withdrawalAmount);
      IWarRedeemModule(redeemModule).notifyUnlock(address(aura), withdrawalAmount);

      uint256 relock = unlockableBalance - withdrawalAmount;
      if (relock > 0) {
        if (aura.allowance(address(this), address(vlAura)) != 0) aura.safeApprove(address(vlAura), 0);
        aura.safeIncreaseAllowance(address(vlAura), relock);
        vlAura.lock(address(this), relock);
      }
    }
  }

  /**
   * @dev Migrates the tokens hold by this contract to another address (& unlocks everything that can be unlocked)
   * @param receiver Address to receive the migrated tokens
   */
  function _migrate(address receiver) internal override {
    // withdraws unlockable balance to receiver
    vlAura.processExpiredLocks(false);
    uint256 unlockedBalance = aura.balanceOf(address(this));
    aura.safeTransfer(receiver, unlockedBalance);

    // withdraws rewards to controller
    _harvest();
  }

  /**
   * @notice Recover ERC2O tokens in the contract
   * @dev Recover ERC2O tokens in the contract
   * @param _token Address of the ERC2O token
   * @return bool: success
   */
  function recoverERC20(address _token) external onlyOwner returns (bool) {
    if (_token == address(aura)) revert Errors.RecoverForbidden();

    if (_token == address(0)) revert Errors.ZeroAddress();
    uint256 amount = IERC20(_token).balanceOf(address(this));
    if (amount == 0) revert Errors.ZeroValue();

    IERC20(_token).safeTransfer(owner(), amount);

    return true;
  }
}
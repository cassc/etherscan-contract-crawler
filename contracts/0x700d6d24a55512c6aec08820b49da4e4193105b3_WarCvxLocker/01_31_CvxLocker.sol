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
import {CvxLockerV2} from "interfaces/external/convex/vlCvx.sol";
import {Math} from "openzeppelin/utils/math/Math.sol";

/**
 * @title Warlord CVX Locker contract
 * @author Paladin
 * @notice Contract locking CVX into vlCVX, claiming rewards and delegating voting power
 */
contract WarCvxLocker is IncentivizedLocker {
  using SafeERC20 for IERC20;

  /**
   * @notice Address of the vlCVX contract
   */
  CvxLockerV2 private constant vlCvx = CvxLockerV2(0x72a19342e8F1838460eBFCCEf09F6585e32db86E);
  /**
   * @notice Address of the CVX token
   */
  IERC20 private constant cvx = IERC20(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
  /**
   * @notice Address of the DelegateRegistry contract
   */
  IDelegateRegistry private constant registry = IDelegateRegistry(0x469788fE6E9E9681C6ebF3bF78e7Fd26Fc015446);

  // Constructor

  constructor(address _controller, address _redeemModule, address _warMinter, address _delegatee)
    WarBaseLocker(_controller, _redeemModule, _warMinter, _delegatee)
  {
    registry.setDelegate("cvx.eth", _delegatee);
  }

  /**
   * @notice Returns the address of the token being locked
   * @return address : token
   */
  function token() external pure returns (address) {
    return address(cvx);
  }

  /**
   * @notice Returns the current total amount of locked tokens for this Locker
   */
  function getCurrentLockedTokens() external view override returns (uint256) {
    (uint256 totalBalance,,,) = vlCvx.lockedBalances(address(this));
    return totalBalance;
  }

  /**
   * @dev Locks the tokens in the vlToken contract
   * @param amount Amount to lock
   */
  function _lock(uint256 amount) internal override {
    cvx.safeTransferFrom(msg.sender, address(this), amount);

    if (cvx.allowance(address(this), address(vlCvx)) != 0) cvx.safeApprove(address(vlCvx), 0);
    cvx.safeIncreaseAllowance(address(vlCvx), amount);

    vlCvx.lock(address(this), amount, 0);
  }

  /**
   * @dev Harvest rewards & send them to the Controller
   */
  function _harvest() internal override {
    CvxLockerV2.EarnedData[] memory rewards = vlCvx.claimableRewards(address(this));
    uint256 rewardsLength = rewards.length;

    vlCvx.getReward(address(this), false);

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
    registry.setDelegate("cvx.eth", _delegatee);
  }

  /**
   * @dev Processes the unlock of tokens
   */
  function _processUnlock() internal override {
    // Harvest the rewards before processing unlocks
    _harvest();

    // Get the amount being unlocked
    (, uint256 unlockableBalance,,) = vlCvx.lockedBalances(address(this));
    if (unlockableBalance == 0) return;

    // Get the amount needed in the Redeem Module
    uint256 withdrawalAmount = IWarRedeemModule(redeemModule).queuedForWithdrawal(address(cvx));

    // If unlock == 0 relock everything
    if (withdrawalAmount == 0) {
      vlCvx.processExpiredLocks(true);
    } else {
      // otherwise withdraw everything and lock only what's left
      vlCvx.processExpiredLocks(false);
      withdrawalAmount = Math.min(unlockableBalance, withdrawalAmount);
      cvx.safeTransfer(address(redeemModule), withdrawalAmount);
      IWarRedeemModule(redeemModule).notifyUnlock(address(cvx), withdrawalAmount);

      uint256 relock = unlockableBalance - withdrawalAmount;
      if (relock > 0) {
        if (cvx.allowance(address(this), address(vlCvx)) != 0) cvx.safeApprove(address(vlCvx), 0);
        cvx.safeIncreaseAllowance(address(vlCvx), relock);
        vlCvx.lock(address(this), relock, 0);
      }
    }
  }

  /**
   * @dev Migrates the tokens hold by this contract to another address (& unlocks everything that can be unlocked)
   * @param receiver Address to receive the migrated tokens
   */
  function _migrate(address receiver) internal override {
    // withdraws unlockable balance to receiver
    vlCvx.withdrawExpiredLocksTo(receiver);

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
    if (_token == address(cvx)) revert Errors.RecoverForbidden();

    if (_token == address(0)) revert Errors.ZeroAddress();
    uint256 amount = IERC20(_token).balanceOf(address(this));
    if (amount == 0) revert Errors.ZeroValue();

    IERC20(_token).safeTransfer(owner(), amount);

    return true;
  }
}
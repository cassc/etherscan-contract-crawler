// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import './interfaces/ITokenStakingPool.sol';
import './interfaces/IPoolExtension.sol';

/// @author www.github.com/jscrui
/// @title Staking Platform with fixed APY and lockup
contract TokenStakingPool is IPoolExtension, ITokenStakingPool, Ownable {
  using SafeERC20 for IERC20;

  address public immutable mainPool;
  IERC20 public immutable token;
  uint public fixedAPR;

  uint private _totalStaked;

  mapping(address => uint) public staked;
  mapping(address => uint) private _rewardsToClaim;
  mapping(address => uint) public _userStartTime;

  modifier onlyPool() {
    require(_msgSender() == mainPool, 'Unauthorized');
    _;
  }

  /**
   * @notice constructor contains all the parameters of the staking platform
   * @dev all parameters are immutable
   * @param _token, address of the token to be staked
   * @param _fixedAPR, the fixed APY (in %) 10 = 10%, 50 = 50%
   */
  constructor(address _mainPool, IERC20 _token, uint _fixedAPR) {
    mainPool = _mainPool;
    token = _token;
    fixedAPR = _fixedAPR;
  }

  function setShare(
    address wallet,
    uint256 balanceChange,
    bool isRemoving
  ) external override onlyPool {
    if (isRemoving) {
      _withdraw(wallet, balanceChange);
    } else {
      _deposit(wallet, balanceChange);
    }
  }

  /**
   * @notice function that allows a user to deposit tokens
   * @dev user must first approve the amount to deposit before calling this function,
   * cannot exceed the `maxAmountStaked`
   * @param amount, the amount to be deposited
   * @dev that the amount deposited should greater than 0
   */
  function _deposit(address wallet, uint amount) internal {
    require(amount > 0, 'Amount must be greater than 0');

    if (_userStartTime[wallet] == 0) {
      _userStartTime[wallet] = block.timestamp;
    }

    _updateRewards(wallet);

    staked[wallet] += amount;
    _totalStaked += amount;
    emit Deposit(wallet, amount);
  }

  /**
   * @notice function that allows a user to withdraw its initial deposit
   * @param amount, amount to withdraw
   * @dev `amount` must be higher than `0`
   * @dev `amount` must be lower or equal to the amount staked
   * withdraw reset all states variable for the `msg.sender` to 0, and claim rewards
   * if rewards to claim
   */
  function _withdraw(address wallet, uint amount) internal {
    require(amount > 0, 'Amount must be greater than 0');
    require(amount <= staked[wallet], 'Amount higher than stakedAmount');

    _updateRewards(wallet);
    if (_rewardsToClaim[wallet] > 0) {
      _claimRewards(wallet);
    }
    _totalStaked -= amount;
    staked[wallet] -= amount;

    emit Withdraw(wallet, amount);
  }

  /**
   * @notice claim all remaining balance on the contract
   * Residual balance is all the remaining tokens that have not been distributed
   * (e.g, in case the number of stakeholders is not sufficient)
   * @dev Can only be called after the end of the staking period
   * Cannot claim initial stakeholders deposit
   */
  function withdrawResidualBalance() external onlyOwner {
    uint residualBalance = token.balanceOf(address(this)) - _totalStaked;
    require(residualBalance > 0, 'No residual Balance to withdraw');
    token.safeTransfer(_msgSender(), residualBalance);
  }

  /**
   * @notice function that allows the owner to set the APY
   * @param _newAPR, the new APY to be set (in %) 10 = 10%, 50 = 50
   */
  function setAPR(uint8 _newAPR) external onlyOwner {
    fixedAPR = _newAPR;
  }

  /**
   * @notice function that returns the amount of total Staked tokens
   * for a specific user
   * @param stakeHolder, address of the user to check
   * @return uint amount of the total deposited Tokens by the caller
   */
  function amountStaked(
    address stakeHolder
  ) external view override returns (uint) {
    return staked[stakeHolder];
  }

  /**
   * @notice function that returns the amount of total Staked tokens
   * on the smart contract
   * @return uint amount of the total deposited Tokens
   */
  function totalDeposited() external view override returns (uint) {
    return _totalStaked;
  }

  /**
   * @notice function that returns the amount of pending rewards
   * that can be claimed by the user
   * @param stakeHolder, address of the user to be checked
   * @return uint amount of claimable rewards
   */
  function rewardOf(address stakeHolder) external view override returns (uint) {
    return _calculateRewards(stakeHolder);
  }

  /**
   * @notice function that claims pending rewards
   * @dev transfer the pending rewards to the `msg.sender`
   */
  function claimRewards() external override {
    _claimRewards(_msgSender());
  }

  /**
   * @notice calculate rewards based on the `fixedAPR`
   * @param stakeHolder, address of the user to be checked
   * @return uint amount of claimable tokens of the specified address
   */
  function _calculateRewards(address stakeHolder) internal view returns (uint) {
    uint _timeStaked = block.timestamp - _userStartTime[stakeHolder];
    return
      ((staked[stakeHolder] * fixedAPR * _timeStaked) / 365 days / 100) +
      _rewardsToClaim[stakeHolder];
  }

  /**
   * @notice internal function that claims pending rewards
   * @dev transfer the pending rewards to the user address
   */
  function _claimRewards(address stakeHolder) private {
    _updateRewards(stakeHolder);

    uint rewardsToClaim = _rewardsToClaim[stakeHolder];
    require(rewardsToClaim > 0, 'Nothing to claim');

    _rewardsToClaim[stakeHolder] = 0;
    token.safeTransfer(stakeHolder, rewardsToClaim);
    emit Claim(stakeHolder, rewardsToClaim);
  }

  /**
   * @notice function that update pending rewards
   * and shift them to rewardsToClaim
   * @dev update rewards claimable
   * and check the time spent since deposit for the `msg.sender`
   */
  function _updateRewards(address stakeHolder) private {
    _rewardsToClaim[stakeHolder] = _calculateRewards(stakeHolder);
    _userStartTime[stakeHolder] = block.timestamp;
  }
}
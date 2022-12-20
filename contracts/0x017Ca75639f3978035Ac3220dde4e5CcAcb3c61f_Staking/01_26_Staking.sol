// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import './Ownable.sol';
import './XSD.sol';

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/math/SafeCast.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/security/Pausable.sol';

import './Timelock.sol';

// This contract handles stake and unstake of xStaderToken tokens.
contract Staking is Ownable, ReentrancyGuard, Pausable, Timelock {
  XSD public xStaderToken;
  bool public isStakePaused = false;
  bool public isUnstakePaused = false;
  uint256 public minDeposit = 0;

  /// @notice maximum deposit amount per staking transaction
  uint256 public maxDeposit = 1000000 * 10**18;

  /// @notice address of rewards contract
  address public rewardsContractAddress;

  /// @notice address of undelegation contract
  address payable public undelegationContractAddress;

  /// @notice event emitted after call function receive
  event Received(address indexed from, uint256 amount);
  /// @notice event emitted after call function fallback
  event Fallback(address indexed from, uint256 amount);
  /// @notice event emitted after call function stake
  event Staked(address indexed to, uint256 SDReceived, uint256 xSDMinted);
  /// @notice event emitted after call function unstake
  event UnStaked(address indexed from, uint256 SDSent, uint256 xSDBurnt);
  /// @notice additional provisional event for the event received via call undelgation function while unstake
  event Undelegated(address indexed to, uint256 amount,uint256 index);
  ///@notice event emitted after min deposit value  is updated
  event minDepositChanged(uint256 newMinDeposit, uint256 oldMinDeposit);
  ///@notice event emitted after max deposit value  is updated
  event maxDepositChanged(uint256 newMaxDeposit, uint256 oldMaxDeposit);
  ///@notice event emitted after staking contract address is updated
  event rewardsContractSet(address newRewardsContractAddress, address oldRewardsContractAddress);
  ///@notice event emitted after undelegation contract address is updated
  event undelegationContractSet(
    address newUndelegationContractAddress,
    address oldUndelegationContractAddress
  );

  constructor(
    IERC20 _staderToken,
    XSD _xStaderToken,
    address payable _undelegationContractAddress,
    address _multiSigTokenMover
  ) checkZeroAddress(_undelegationContractAddress) Timelock(_staderToken, _multiSigTokenMover) {
    staderToken = _staderToken;
    xStaderToken = _xStaderToken;
    undelegationContractAddress = _undelegationContractAddress;
  }

  /**********************
   * User functions      *
   **********************/
  // Locks staderToken and mints xStaderToken
  function stake(uint256 _amount) external whenNotPaused nonReentrant {
    require(!isStakePaused, 'Staking is paused');
    require(
      _amount > minDeposit && _amount <= maxDeposit,
      'Deposit amount must be within valid range'
    );
    require(
      staderToken.balanceOf(address(rewardsContractAddress)) > 0,
      'Rewards contract cannot have zero balance'
    );

    // Gets the amount of staderToken locked in the contract
    uint256 totalStaderToken = staderToken.balanceOf(address(this));
    // Gets the amount of XSD in existence
    uint256 totalShares = xStaderToken.totalSupply();
    // If no xStaderToken exists, mint it 1:1 to the amount put in

    uint256 amountToSend = _amount;
    if (totalShares == 0 || amountToSend == 0) {
      xStaderToken.mint(msg.sender, amountToSend);
    }
    // Calculate and mint the amount of XSD the SD is worth. The ratio will change overtime, as XSD is burned/minted and staderToken deposited + gained from fees / withdrawn.
    else {
      amountToSend = (_amount * (totalShares)) / (totalStaderToken);
      xStaderToken.mint(msg.sender, amountToSend);
    }
    // Lock the staderToken in the contract
    emit Staked(msg.sender, _amount, amountToSend);
    require(
      staderToken.transferFrom(msg.sender, address(this), _amount),
      'Failed to deposit staderToken'
    );
  }

  // Unlocks the staked + rewards staderToken and burns xStaderToken
  function unstake(uint256 _share) external whenNotPaused nonReentrant {
    require(!isUnstakePaused, 'Unstaking is paused');
    // Gets the amount of XSD in existence
    uint256 totalShares = xStaderToken.totalSupply();
    // Calculates the amount of staderToken the xStaderToken is worth
    uint256 sdToSend = (_share * (staderToken.balanceOf(address(this)))) / (totalShares);
    require(xStaderToken.transferFrom(msg.sender, address(this), _share), 'Failed to transfer xSD');
    xStaderToken.burn(_share);
    ///@dev move tokens to undelegation contract
    emit UnStaked(msg.sender, sdToSend, _share);
    (bool success, ) = payable(undelegationContractAddress).call(
      abi.encodeWithSignature('undelegate(address,uint256)', msg.sender, sdToSend)
    );
    if (!success) {
      revert('Transfer failed to undelegation contract');
    }
    require(staderToken.transfer(undelegationContractAddress, sdToSend));
  }

  /**********************
   * Getter functions  *
   **********************/

  function getExchangeRate() external view returns (uint256) {
    uint256 exchangeRate = 1 * 1e18;
    uint256 balance = staderToken.balanceOf(address(this));
    if (balance > 0 && xStaderToken.totalSupply() > 0) {
      exchangeRate = (balance * 1e18) / xStaderToken.totalSupply();
    }
    return exchangeRate;
  }

  /**********************
   * Setter functions   *
   **********************/
  /// @notice Toggle pause state of Stake function
  function updateStakeIsPaused() external onlyOwner {
    isStakePaused = !isStakePaused;
  }

  /// @notice Toggle pause state of Unstake function
  function updateUnStakeIsPaused() external onlyOwner {
    isUnstakePaused = !isUnstakePaused;
  }

  /// @notice Set minimum deposit amount (onlyOwner)
  /// @param _newMinDeposit the minimum deposit amount in multiples of 10**8
  function updateMinDeposit(uint256 _newMinDeposit) external onlyOwner {
    require(minDeposit != _newMinDeposit, 'Min Deposit is unchanged');
    require(_newMinDeposit< maxDeposit, 'Min must be less than Max Deposit');
    emit minDepositChanged(_newMinDeposit, minDeposit);
    minDeposit = _newMinDeposit;
  }

  /// @notice Set maximum deposit amount (onlyOwner)
  /// @param _newMaxDeposit the maximum deposit amount in multiples of 10**8
  function updateMaxDeposit(uint256 _newMaxDeposit) external onlyOwner {
    require(maxDeposit != _newMaxDeposit, 'Max Deposit is unchanged');
    require(_newMaxDeposit>0, 'Max Deposit 0');
    require(_newMaxDeposit>=minDeposit, 'Max must be greater Min Deposit');
    emit maxDepositChanged(_newMaxDeposit, maxDeposit);
    maxDeposit = _newMaxDeposit;
  }

  /// @notice Set rewards contract address (onlyOwner)
  /// @param _rewardsContractAddress the rewards contract address value
  function setRewardsContractAddress(address _rewardsContractAddress)
    external
    checkZeroAddress(_rewardsContractAddress)
    onlyOwner
  {
    require(rewardsContractAddress != _rewardsContractAddress, 'Rewards address is unchanged');
    emit rewardsContractSet(_rewardsContractAddress, rewardsContractAddress);
    rewardsContractAddress = _rewardsContractAddress;
  }

  /// @notice Set undelegation contract address (onlyOwner)
  /// @param _undelegationContractAddress the undelegation contract address value
  function setUndelegationContractAddress(address payable _undelegationContractAddress)
    external
    checkZeroAddress(_undelegationContractAddress)
    onlyOwner
  {
    require(
      undelegationContractAddress != _undelegationContractAddress,
      'Undelegation address is unchanged'
    );
    emit undelegationContractSet(_undelegationContractAddress, undelegationContractAddress);
    undelegationContractAddress = _undelegationContractAddress;
  }

  /// @notice Pauses the contract
  /// @dev The contract must be in the unpaused ot normal state
  function pause() external onlyOwner {
    _pause();
  }

  /// @notice Unpauses the contract and returns it to the normal state
  /// @dev The contract must be in the paused state
  function unpause() external onlyOwner {
    _unpause();
  }

  /**********************
   * Fallback functions *
   **********************/
  /// @notice when no other function matches (not even the receive function)
  fallback() external payable {
    emit Fallback(msg.sender, msg.value);
  }

  /// @notice for empty calldata (and any value)
  receive() external payable {
    emit Received(msg.sender, msg.value);
  }
}
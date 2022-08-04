/******************************************************************************************************
Yieldification Vesting Contract

Website: https://yieldification.com
Twitter: https://twitter.com/yieldification
Telegram: https://t.me/yieldification
******************************************************************************************************/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';
import './interfaces/IYDF.sol';

contract YDFVester is Ownable {
  IYDF private _ydf;

  uint256 public fullyVestedPeriod = 90 days;
  uint256 public withdrawsPerPeriod = 10;

  struct TokenVest {
    uint256 start;
    uint256 end;
    uint256 totalWithdraws;
    uint256 withdrawsCompleted;
    uint256 amount;
  }
  mapping(address => TokenVest[]) public vests;
  address[] public stakeContracts;

  event CreateVest(address indexed user, uint256 amount);
  event Withdraw(address indexed user, uint256 index, uint256 amountWithdrawn);

  modifier onlyStake() {
    bool isStake;
    for (uint256 i = 0; i < stakeContracts.length; i++) {
      if (msg.sender == stakeContracts[i]) {
        isStake = true;
        break;
      }
    }
    require(isStake, 'not a staking contract');
    _;
  }

  constructor(address _token) {
    _ydf = IYDF(_token);
  }

  // we expect the staking contract (re: the owner) to transfer tokens to
  // this contract, so no need to transferFrom anywhere
  function createVest(address _user, uint256 _amount) external onlyStake {
    vests[_user].push(
      TokenVest({
        start: block.timestamp,
        end: block.timestamp + fullyVestedPeriod,
        totalWithdraws: withdrawsPerPeriod,
        withdrawsCompleted: 0,
        amount: _amount
      })
    );
    emit CreateVest(_user, _amount);
  }

  function withdraw(uint256 _index) external {
    address _user = msg.sender;
    TokenVest storage _vest = vests[_user][_index];
    require(_vest.amount > 0, 'vest does not exist');
    require(
      _vest.withdrawsCompleted < _vest.totalWithdraws,
      'already withdrew all tokens'
    );

    uint256 _tokensPerWithdrawPeriod = _vest.amount / _vest.totalWithdraws;
    uint256 _withdrawsAllowed = getWithdrawsAllowed(_user, _index);

    // make sure the calculated allowed amount doesn't exceed total amount for vest
    _withdrawsAllowed = _withdrawsAllowed > _vest.totalWithdraws
      ? _vest.totalWithdraws
      : _withdrawsAllowed;

    require(
      _vest.withdrawsCompleted < _withdrawsAllowed,
      'currently vesting, please wait for next withdrawable time period'
    );

    uint256 _withdrawsToComplete = _withdrawsAllowed - _vest.withdrawsCompleted;

    _vest.withdrawsCompleted = _withdrawsAllowed;
    _ydf.transfer(_user, _tokensPerWithdrawPeriod * _withdrawsToComplete);
    _ydf.addToBuyTracker(
      _user,
      _tokensPerWithdrawPeriod * _withdrawsToComplete
    );

    // clean up/remove vest entry if it's completed
    if (_vest.withdrawsCompleted == _vest.totalWithdraws) {
      vests[_user][_index] = vests[_user][vests[_user].length - 1];
      vests[_user].pop();
    }

    emit Withdraw(
      _user,
      _index,
      _tokensPerWithdrawPeriod * _withdrawsToComplete
    );
  }

  function getWithdrawsAllowed(address _user, uint256 _index)
    public
    view
    returns (uint256)
  {
    TokenVest memory _vest = vests[_user][_index];
    uint256 _secondsPerWithdrawPeriod = (_vest.end - _vest.start) /
      _vest.totalWithdraws;
    return (block.timestamp - _vest.start) / _secondsPerWithdrawPeriod;
  }

  function getUserVests(address _user)
    external
    view
    returns (TokenVest[] memory)
  {
    return vests[_user];
  }

  function getYDF() external view returns (address) {
    return address(_ydf);
  }

  function addStakingContract(address _contract) external onlyOwner {
    stakeContracts.push(_contract);
  }
}
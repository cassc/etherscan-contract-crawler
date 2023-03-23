// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./Pool.sol";
import "./interfaces/IPoolFactory.sol";

contract PoolGenerator is Ownable {
  using SafeMath for uint256;
    using SafeERC20 for IERC20;

  IPoolFactory public factory;
  address public devAddr;
  uint256 public fee = 50;

  constructor (IPoolFactory _factory, address _devAddr) {
    factory = _factory;
    devAddr = _devAddr;
  }

  function createPool (
    address _rewardToken,
    address _lpToken,
    uint256 _aprPercent,
    uint256 _amount
  ) public returns (address){
    Pool newPool = new Pool(_lpToken, _rewardToken, msg.sender, _aprPercent);
    IERC20(_rewardToken).safeTransferFrom(msg.sender, devAddr, _amount.mul(fee).div(1000));
    IERC20(_rewardToken).safeTransferFrom(msg.sender, address(newPool), _amount.mul(1000 - fee).div(1000));
    factory.registerPool(address(newPool));
    return address(newPool);
  }
}
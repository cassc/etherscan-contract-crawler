// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "openzeppelin-contracts/interfaces/IERC20.sol";
import "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts/proxy/utils/UUPSUpgradeable.sol";
import "./interfaces/IPool.sol";
import "./interfaces/IPoolRibbon.sol";
import "./interfaces/IPoolFactory.sol";
// import "forge-std/console.sol";

/// @title Clearpool Wrapper
contract ClearpoolWrapper is UUPSUpgradeable {
  enum PoolType {
    CLEARPOOL,
    RIBBON
  }

  struct Pool {
    PoolType poolType;
    IPool pool;
    IPoolFactory factory;
    uint256 withdrawAboveUtilizationRate;
  }

  uint256 numPools;
  mapping(uint256 => Pool) public pools;

  using SafeERC20 for IERC20;

  function _authorizeUpgrade(address) internal override onlyOwner {}

  address immutable owner;
  address constant gelatoOpsAddress = 0xB3f5503f93d5Ef84b06993a1975B9D21B962892F;

  // Storage variables: do not change order or remove, as this contract must be upgradeable

  // Modifiers

  modifier onlyOwner() {
    require(owner == msg.sender, "not owner");
    _;
  }

  modifier onlyOwnerOrGelato() {
    require(owner == msg.sender || gelatoOpsAddress == msg.sender, "not owner or gelato");
    _;
  }

  modifier poolExists(uint256 _poolId) {
    require(address(pools[_poolId].pool) != address(0), "pool does not exist");
    _;
  }

  // Initialization

  // sets immutable variables only, as this will be deployed behind a proxy
  constructor() {
    owner = msg.sender;
  }

  function rescueToken(address _token, uint256 _amount) external onlyOwner {
    if (_token == address(0)) {
      payable(owner).transfer(_amount);
    } else {
      IERC20(_token).safeTransfer(owner, _amount);
    }
  }

  function addPool(
    PoolType _poolType,
    address _pool,
    address _factory,
    uint256 _withdrawAboveUtilizationRate
  ) external onlyOwner {
    require(_pool != address(0), "_pool cannot be address(0)");
    require(_withdrawAboveUtilizationRate != 0, "_withdrawAboveUtilizationRate cannot be zero");
    require(
      IPool(_pool).getUtilizationRate() < _withdrawAboveUtilizationRate,
      "_withdrawAboveUtilizationRate cannot be lower than current utilization rate"
    );
    pools[numPools] =
      Pool(_poolType, IPool(_pool), IPoolFactory(_factory), _withdrawAboveUtilizationRate);
    IERC20(IPool(_pool).currency()).approve(address(_pool), type(uint256).max);
    numPools++;
  }

  function callPool(uint256 _poolId, bytes calldata _data)
    external
    payable
    onlyOwner
    poolExists(_poolId)
  {
    _callPool(_poolId, _data, msg.value);
  }

  function callAllPools(bytes calldata _data) external onlyOwner {
    for (uint256 i = 0; i < numPools; i++) {
      _callPool(i, _data, 0);
    }
  }

  function getRewards(uint256 _poolId) external onlyOwner poolExists(_poolId) {
    _getRewards(_poolId);
  }

  function getAllRewards() external onlyOwner {
    for (uint256 i = 0; i < numPools; i++) {
      _getRewards(i);
    }
  }

  function provide(uint256 _poolId, uint256 _amount) external onlyOwner poolExists(_poolId) {
    if (pools[_poolId].poolType == PoolType.RIBBON) {
      // ribbon needs referral code... give the owner address, i guess?
      IPoolRibbon(address(pools[_poolId].pool)).provide(_amount, owner);
    } else {
      pools[_poolId].pool.provide(_amount);
    }
  }

  function redeem(uint256 _poolId, uint256 _amount) external onlyOwner poolExists(_poolId) {
    pools[_poolId].pool.redeem(_amount);
  }

  function gelatoExec() external onlyOwnerOrGelato {
    bool balanceChanged = false;
    for (uint256 i = 0; i < numPools; i++) {
      if (mustWithdrawPool(pools[i])) {
        uint256 balanceBefore = IERC20(pools[i].pool.currency()).balanceOf(address(this));
        pools[i].pool.redeem(type(uint256).max);
        uint256 balanceAfter = IERC20(pools[i].pool.currency()).balanceOf(address(this));
        if (balanceAfter > balanceBefore) balanceChanged = true;
      }
    }

    require(balanceChanged, "no balances changed");
  }

  function checkGelato() external view returns (bool canExec, bytes memory execPayload) {
    for (uint256 i = 0; i < numPools; i++) {
      if (mustWithdrawPool(pools[i])) {
        canExec = true;
        execPayload = abi.encodeWithSelector(this.gelatoExec.selector);
        break;
      }
    }
  }

  // Internal

  function mustWithdrawPool(Pool memory _pool) internal view returns (bool) {
    return _pool.pool.getUtilizationRate() > _pool.withdrawAboveUtilizationRate
      && _pool.pool.balanceOf(address(this)) > 0;
  }

  function _callPool(uint256 _poolId, bytes calldata _data, uint256 _value) internal {
    (bool success,) = address(pools[_poolId].pool).call{value: _value}(_data);
    require(success, "call reverted");
  }

  function _getRewards(uint256 _poolId) internal {
    address[] memory poolsList = new address[](1);
    poolsList[0] = address(pools[_poolId].pool);
    pools[_poolId].factory.withdrawReward(poolsList);
  }
}
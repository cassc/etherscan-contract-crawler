// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {TermPool, ITermPool} from './TermPool.sol';
import {ITermPoolFactory} from './interfaces/ITermPoolFactory.sol';
import {IOwnable} from './interfaces/IOwnable.sol';
import {IClassicPool} from './interfaces/IClassicPool.sol';
import {IPermissionlessPoolFactory} from './interfaces/IPermissionlessPoolFactory.sol';
import {IPermissionlessPoolMaster} from './interfaces/IPermissionlessPoolMaster.sol';
import {BeaconProxy} from '@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol';
import {Initializable} from '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import './utils/TermUtils.sol';

// TODO open pool for everyone
contract TermPoolFactory is ITermPoolFactory, Initializable, TermUtils {
  /// @notice Amount of pools that are listed in the factory
  uint256 public listedPoolsCount;

  /// @notice Permissionless factory address
  address public permissionlessFactory;

  /// @notice Implementation address for TermPool
  address public termPoolBeacon;

  /// @notice Implementation address for TpToken
  address public tpTokenBeacon;

  /// @notice Array of used cpTokens to iterate over them
  address[] private _usedCpTokens;

  /// @notice Mapping of cpToken to Term Pool info struct
  mapping(address => PoolInfo) public poolsByCpToken;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  /// @notice Initializes the upgradeable contract
  /// @param _permissionlessFactory Permissionless Factory contract address
  function __TermPoolFactory_init(
    address _permissionlessFactory
  ) external initializer notZeroAddr(_permissionlessFactory) {
    permissionlessFactory = _permissionlessFactory;
  }

  /// @notice Function is called by contract owner to set new pool beacon
  /// @param _termPoolBeacon New pool beacon contract address
  function setTermPoolBeacon(
    address _termPoolBeacon
  ) external onlyOwner notZeroAddr(_termPoolBeacon) notSameAddr(termPoolBeacon, _termPoolBeacon) {
    termPoolBeacon = _termPoolBeacon;
    emit TermPoolBeaconSet(_termPoolBeacon);
  }

  /// @notice Function is called by contract owner to set new tpToken beacon
  /// @param _tpTokenBeacon New tpToken beacon contract address
  function setTpTokenBeacon(
    address _tpTokenBeacon
  ) external onlyOwner notZeroAddr(_tpTokenBeacon) notSameAddr(tpTokenBeacon, _tpTokenBeacon) {
    tpTokenBeacon = _tpTokenBeacon;
    emit TpTokenBeaconSet(_tpTokenBeacon);
  }

  /// @notice Function is called by contract owner to set new permissionless factory
  /// @param _permissionlessFactory New permissionless factory contract address
  function setPermissionlessFactory(
    address _permissionlessFactory
  )
    external
    onlyOwner
    notZeroAddr(_permissionlessFactory)
    notSameAddr(permissionlessFactory, _permissionlessFactory)
  {
    permissionlessFactory = _permissionlessFactory;
    emit PermissionlessFactoryChanged(_permissionlessFactory);
  }

  /// @notice Function is called by contract owner or cpPool manager to set new pool beacon
  /// @param _cpToken Address of cpToken
  function createTermPool(
    address _cpToken
  ) external override notZeroAddr(_cpToken) returns (address pool) {
    bool isPool = IPermissionlessPoolFactory(permissionlessFactory).isPool(_cpToken);

    if (!isPool) {
      revert WrongCpToken(_cpToken);
    }

    bool isListed = false;
    if (owner() == msg.sender) isListed = true;

    address currency = IPermissionlessPoolMaster(_cpToken).currency();
    address manager = IPermissionlessPoolMaster(_cpToken).manager();

    if (owner() != msg.sender && manager != msg.sender) {
      revert NotOwnerOrManager(msg.sender);
    }

    PoolInfo storage poolInfo = poolsByCpToken[_cpToken];
    if (poolInfo.pool != address(0)) revert PoolAlreadyExist(poolInfo.pool);

    // create new pool
    ITermPool termPool = ITermPool(address(new BeaconProxy(termPoolBeacon, '')));
    pool = address(termPool);
    termPool.__TermPool_init(_cpToken, manager, isListed);

    // save pool info
    poolInfo.pool = pool;
    poolInfo.currency = currency;
    poolInfo.isListed = isListed;
    _usedCpTokens.push(_cpToken);

    if (isListed) {
      listedPoolsCount++;
    }
    emit TermPoolCreated(pool, _cpToken);
  }

  /// @notice Lists an existing pool
  /// @dev Callable only by owner
  /// @param _cpToken Address of cpToken
  function setPoolListing(address _cpToken, bool _isListed) external onlyOwner {
    PoolInfo storage poolInfo = poolsByCpToken[_cpToken];

    if (poolInfo.pool == address(0)) revert PoolNotExist(_cpToken);
    if (poolInfo.isListed == _isListed) revert SameListingStatus(_cpToken);

    poolInfo.isListed = _isListed;

    if (_isListed) listedPoolsCount++;
    else listedPoolsCount--;

    ITermPool(poolInfo.pool).setListed(_isListed);
  }

  /// @notice Returns listed Term Pools info
  /// @return pools Array of pools info
  function getPools() external view returns (PoolInfo[] memory pools) {
    pools = new PoolInfo[](listedPoolsCount);
    uint256 counter;
    for (uint256 i = 0; i < _usedCpTokens.length; ++i) {
      if (poolsByCpToken[_usedCpTokens[i]].isListed && counter < listedPoolsCount) {
        pools[counter] = poolsByCpToken[_usedCpTokens[i]];
        ++counter;
      }
    }
    return pools;
  }

  /// @notice Returns address of the contract owner
  /// @dev Owner is the same as in permissionless factory
  function owner() public view returns (address) {
    return IOwnable(permissionlessFactory).owner();
  }

  modifier onlyOwner() {
    if (owner() == msg.sender) _;
    else revert NotOwner(msg.sender);
  }
}
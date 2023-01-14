// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {ISynthereumFinder} from '../core/interfaces/IFinder.sol';
import {
  ISynthereumFactoryVersioning
} from '../core/interfaces/IFactoryVersioning.sol';
import {ILendingStorageManager} from './interfaces/ILendingStorageManager.sol';
import {ILendingModule} from './interfaces/ILendingModule.sol';
import {SynthereumInterfaces, FactoryInterfaces} from '../core/Constants.sol';
import {PreciseUnitMath} from '../base/utils/PreciseUnitMath.sol';
import {SynthereumFactoryAccess} from '../common/libs/FactoryAccess.sol';
import {
  EnumerableSet
} from '../../@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import {
  ReentrancyGuard
} from '../../@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract LendingStorageManager is ILendingStorageManager, ReentrancyGuard {
  using EnumerableSet for EnumerableSet.AddressSet;

  mapping(bytes32 => LendingInfo) internal idToLendingInfo;
  EnumerableSet.AddressSet internal swapModules;
  mapping(address => address) internal collateralToSwapModule; // ie USDC -> JRTSwapUniswap address
  mapping(address => PoolStorage) internal poolStorage; // ie jEUR/USDC pooldata

  ISynthereumFinder immutable synthereumFinder;

  modifier onlyLendingManager() {
    require(
      msg.sender ==
        synthereumFinder.getImplementationAddress(
          SynthereumInterfaces.LendingManager
        ),
      'Not allowed'
    );
    _;
  }

  modifier onlyPoolFactory() {
    SynthereumFactoryAccess._onlyPoolFactory(synthereumFinder);
    _;
  }

  constructor(ISynthereumFinder _finder) {
    synthereumFinder = _finder;
  }

  function setLendingModule(
    string calldata _id,
    LendingInfo calldata _lendingInfo
  ) external override nonReentrant onlyLendingManager {
    bytes32 lendingId = keccak256(abi.encode(_id));
    require(lendingId != 0x00, 'Wrong module identifier');
    idToLendingInfo[lendingId] = _lendingInfo;
  }

  function addSwapProtocol(address _swapModule)
    external
    override
    nonReentrant
    onlyLendingManager
  {
    require(_swapModule != address(0), 'Swap module can not be 0x');
    require(swapModules.add(_swapModule), 'Swap module already supported');
  }

  function removeSwapProtocol(address _swapModule)
    external
    override
    nonReentrant
    onlyLendingManager
  {
    require(_swapModule != address(0), 'Swap module can not be 0x');
    require(swapModules.remove(_swapModule), 'Swap module not supported');
  }

  function setSwapModule(address _collateral, address _swapModule)
    external
    override
    nonReentrant
    onlyLendingManager
  {
    require(
      swapModules.contains(_swapModule) || _swapModule == address(0),
      'Swap module not supported'
    );
    collateralToSwapModule[_collateral] = _swapModule;
  }

  function setShares(
    address _pool,
    uint64 _daoInterestShare,
    uint64 _jrtBuybackShare
  ) external override nonReentrant onlyLendingManager {
    PoolStorage storage poolData = poolStorage[_pool];
    require(poolData.lendingModuleId != 0x00, 'Bad pool');
    require(
      _jrtBuybackShare <= PreciseUnitMath.PRECISE_UNIT &&
        _daoInterestShare <= PreciseUnitMath.PRECISE_UNIT,
      'Invalid share'
    );

    poolData.jrtBuybackShare = _jrtBuybackShare;
    poolData.daoInterestShare = _daoInterestShare;
  }

  function setPoolStorage(
    string calldata _lendingID,
    address _pool,
    address _collateral,
    address _interestBearingToken,
    uint64 _daoInterestShare,
    uint64 _jrtBuybackShare
  ) external override nonReentrant onlyPoolFactory {
    bytes32 id = keccak256(abi.encode(_lendingID));
    LendingInfo memory lendingInfo = idToLendingInfo[id];
    address lendingModule = lendingInfo.lendingModule;
    require(lendingModule != address(0), 'Module not supported');
    require(
      _jrtBuybackShare <= PreciseUnitMath.PRECISE_UNIT &&
        _daoInterestShare <= PreciseUnitMath.PRECISE_UNIT,
      'Invalid share'
    );

    // set pool storage
    PoolStorage storage poolData = poolStorage[_pool];
    require(poolData.lendingModuleId == 0x00, 'Pool already exists');
    poolData.lendingModuleId = id;
    poolData.collateral = _collateral;
    poolData.jrtBuybackShare = _jrtBuybackShare;
    poolData.daoInterestShare = _daoInterestShare;

    // set interest bearing token
    _setBearingToken(
      poolData,
      _collateral,
      lendingModule,
      lendingInfo,
      _interestBearingToken
    );
  }

  function migratePoolStorage(
    address _oldPool,
    address _newPool,
    uint256 _newCollateralDeposited
  ) external override nonReentrant onlyLendingManager {
    PoolStorage memory oldPoolData = poolStorage[_oldPool];
    bytes32 oldLendingId = oldPoolData.lendingModuleId;
    require(oldLendingId != 0x00, 'Bad migration pool');

    PoolStorage storage newPoolData = poolStorage[_newPool];
    require(newPoolData.lendingModuleId == 0x00, 'Bad new pool');

    // copy storage to new pool
    newPoolData.lendingModuleId = oldLendingId;
    newPoolData.collateral = oldPoolData.collateral;
    newPoolData.interestBearingToken = oldPoolData.interestBearingToken;
    newPoolData.jrtBuybackShare = oldPoolData.jrtBuybackShare;
    newPoolData.daoInterestShare = oldPoolData.daoInterestShare;
    newPoolData.collateralDeposited = _newCollateralDeposited;
    newPoolData.unclaimedDaoJRT = oldPoolData.unclaimedDaoJRT;
    newPoolData.unclaimedDaoCommission = oldPoolData.unclaimedDaoCommission;

    // delete old pool slot
    delete poolStorage[_oldPool];
  }

  function migrateLendingModule(
    string calldata _newLendingID,
    address _pool,
    address _newInterestBearingToken
  )
    external
    override
    nonReentrant
    onlyLendingManager
    returns (PoolStorage memory, LendingInfo memory)
  {
    bytes32 id = keccak256(abi.encode(_newLendingID));
    LendingInfo memory newLendingInfo = idToLendingInfo[id];
    address newLendingModule = newLendingInfo.lendingModule;
    require(newLendingModule != address(0), 'Id not existent');

    // set lending module
    PoolStorage storage poolData = poolStorage[_pool];
    poolData.lendingModuleId = id;

    // set interest bearing token
    _setBearingToken(
      poolData,
      poolData.collateral,
      newLendingModule,
      newLendingInfo,
      _newInterestBearingToken
    );

    return (poolData, newLendingInfo);
  }

  function updateValues(
    address _pool,
    uint256 _collateralDeposited,
    uint256 _daoJRT,
    uint256 _daoInterest
  ) external override nonReentrant onlyLendingManager {
    PoolStorage storage poolData = poolStorage[_pool];
    require(poolData.lendingModuleId != 0x00, 'Bad pool');

    // update collateral deposit amount of the pool
    poolData.collateralDeposited = _collateralDeposited;

    // update dao unclaimed interest of the pool
    poolData.unclaimedDaoJRT = _daoJRT;
    poolData.unclaimedDaoCommission = _daoInterest;
  }

  function getLendingModule(string calldata _id)
    external
    view
    override
    returns (LendingInfo memory lendingInfo)
  {
    bytes32 lendingId = keccak256(abi.encode(_id));
    require(lendingId != 0x00, 'Wrong module identifier');
    lendingInfo = idToLendingInfo[lendingId];
    require(
      lendingInfo.lendingModule != address(0),
      'Lending module not supported'
    );
  }

  function getPoolData(address _pool)
    external
    view
    override
    returns (PoolStorage memory poolData, LendingInfo memory lendingInfo)
  {
    poolData = poolStorage[_pool];
    require(poolData.lendingModuleId != 0x00, 'Not existing pool');
    lendingInfo = idToLendingInfo[poolData.lendingModuleId];
  }

  function getPoolStorage(address _pool)
    external
    view
    override
    returns (PoolStorage memory poolData)
  {
    poolData = poolStorage[_pool];
    require(poolData.lendingModuleId != 0x00, 'Not existing pool');
  }

  function getLendingData(address _pool)
    external
    view
    override
    returns (
      PoolLendingStorage memory lendingStorage,
      LendingInfo memory lendingInfo
    )
  {
    PoolStorage storage poolData = poolStorage[_pool];
    require(poolData.lendingModuleId != 0x00, 'Not existing pool');
    lendingStorage.collateralToken = poolData.collateral;
    lendingStorage.interestToken = poolData.interestBearingToken;
    lendingInfo = idToLendingInfo[poolData.lendingModuleId];
  }

  function getSwapModules() external view override returns (address[] memory) {
    uint256 numberOfModules = swapModules.length();
    address[] memory modulesList = new address[](numberOfModules);
    for (uint256 j = 0; j < numberOfModules; j++) {
      modulesList[j] = swapModules.at(j);
    }
    return modulesList;
  }

  function getCollateralSwapModule(address _collateral)
    external
    view
    override
    returns (address swapModule)
  {
    swapModule = collateralToSwapModule[_collateral];
    require(
      swapModule != address(0),
      'Swap module not added for this collateral'
    );
    require(swapModules.contains(swapModule), 'Swap module not supported');
  }

  function getInterestBearingToken(address _pool)
    external
    view
    override
    returns (address interestTokenAddr)
  {
    require(poolStorage[_pool].lendingModuleId != 0x00, 'Not existing pool');
    interestTokenAddr = poolStorage[_pool].interestBearingToken;
  }

  function getShares(address _pool)
    external
    view
    override
    returns (uint256 jrtBuybackShare, uint256 daoInterestShare)
  {
    require(poolStorage[_pool].lendingModuleId != 0x00, 'Not existing pool');
    jrtBuybackShare = poolStorage[_pool].jrtBuybackShare;
    daoInterestShare = poolStorage[_pool].daoInterestShare;
  }

  function getCollateralDeposited(address _pool)
    external
    view
    override
    returns (uint256 collateralAmount)
  {
    require(poolStorage[_pool].lendingModuleId != 0x00, 'Not existing pool');
    collateralAmount = poolStorage[_pool].collateralDeposited;
  }

  function _setBearingToken(
    PoolStorage storage _actualPoolData,
    address _collateral,
    address _lendingModule,
    LendingInfo memory _lendingInfo,
    address _interestToken
  ) internal {
    try
      ILendingModule(_lendingModule).getInterestBearingToken(
        _collateral,
        _lendingInfo.args
      )
    returns (address interestTokenAddr) {
      _actualPoolData.interestBearingToken = interestTokenAddr;
    } catch {
      require(_interestToken != address(0), 'No bearing token passed');
      _actualPoolData.interestBearingToken = _interestToken;
    }
  }
}
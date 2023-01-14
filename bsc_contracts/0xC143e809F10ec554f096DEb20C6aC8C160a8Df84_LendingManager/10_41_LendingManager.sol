// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {ILendingManager} from './interfaces/ILendingManager.sol';
import {ILendingModule} from './interfaces/ILendingModule.sol';
import {ILendingStorageManager} from './interfaces/ILendingStorageManager.sol';
import {ISynthereumFinder} from '../core/interfaces/IFinder.sol';
import {SynthereumInterfaces} from '../core/Constants.sol';
import {
  ISynthereumLendingTransfer
} from '../synthereum-pool/common/interfaces/ILendingTransfer.sol';
import {
  ISynthereumLendingRewards
} from '../synthereum-pool/common/interfaces/ILendingRewards.sol';
import {PreciseUnitMath} from '../base/utils/PreciseUnitMath.sol';
import {Address} from '../../@openzeppelin/contracts/utils/Address.sol';
import {IERC20} from '../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {
  SafeERC20
} from '../../@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {SynthereumFactoryAccess} from '../common/libs/FactoryAccess.sol';
import {
  AccessControlEnumerable
} from '../../@openzeppelin/contracts/access/AccessControlEnumerable.sol';
import {
  ReentrancyGuard
} from '../../@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract LendingManager is
  ILendingManager,
  ReentrancyGuard,
  AccessControlEnumerable
{
  using Address for address;
  using SafeERC20 for IERC20;
  using PreciseUnitMath for uint256;

  ISynthereumFinder immutable synthereumFinder;

  bytes32 public constant MAINTAINER_ROLE = keccak256('Maintainer');

  string private constant DEPOSIT_SIG =
    'deposit((bytes32,uint256,uint256,uint256,address,uint64,address,uint64),bytes,uint256)';

  string private constant WITHDRAW_SIG =
    'withdraw((bytes32,uint256,uint256,uint256,address,uint64,address,uint64),address,bytes,uint256,address)';

  string private JRTSWAP_SIG =
    'swapToJRT(address,address,address,uint256,bytes)';

  string private TOTAL_TRANSFER_SIG =
    'totalTransfer(address,address,address,address,bytes)';

  modifier onlyMaintainer() {
    require(
      hasRole(MAINTAINER_ROLE, msg.sender),
      'Sender must be the maintainer'
    );
    _;
  }

  modifier onlyPoolFactory() {
    SynthereumFactoryAccess._onlyPoolFactory(synthereumFinder);
    _;
  }

  constructor(ISynthereumFinder _finder, Roles memory _roles) nonReentrant {
    synthereumFinder = _finder;

    _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(MAINTAINER_ROLE, DEFAULT_ADMIN_ROLE);
    _setupRole(DEFAULT_ADMIN_ROLE, _roles.admin);
    _setupRole(MAINTAINER_ROLE, _roles.maintainer);
  }

  function deposit(uint256 _amount)
    external
    override
    nonReentrant
    returns (ReturnValues memory returnValues)
  {
    (
      ILendingStorageManager.PoolStorage memory poolData,
      ILendingStorageManager.LendingInfo memory lendingInfo,
      ILendingStorageManager poolStorageManager
    ) = _getPoolInfo();

    // delegate call implementation
    bytes memory result =
      address(lendingInfo.lendingModule).functionDelegateCall(
        abi.encodeWithSignature(
          DEPOSIT_SIG,
          poolData,
          lendingInfo.args,
          _amount
        )
      );

    ILendingModule.ReturnValues memory res =
      abi.decode(result, (ILendingModule.ReturnValues));

    // split interest
    InterestSplit memory interestSplit =
      splitGeneratedInterest(
        res.totalInterest,
        poolData.daoInterestShare,
        poolData.jrtBuybackShare
      );

    // update pool storage values
    poolStorageManager.updateValues(
      msg.sender,
      poolData.collateralDeposited + res.tokensOut + interestSplit.poolInterest,
      poolData.unclaimedDaoJRT + interestSplit.jrtInterest,
      poolData.unclaimedDaoCommission + interestSplit.commissionInterest
    );

    // set return values
    returnValues.tokensOut = res.tokensOut;
    returnValues.tokensTransferred = res.tokensTransferred;
    returnValues.poolInterest = interestSplit.poolInterest;
    returnValues.daoInterest =
      interestSplit.commissionInterest +
      interestSplit.jrtInterest;
    returnValues.prevTotalCollateral = poolData.collateralDeposited;
  }

  function withdraw(uint256 _interestTokenAmount, address _recipient)
    external
    override
    nonReentrant
    returns (ReturnValues memory returnValues)
  {
    (
      ILendingStorageManager.PoolStorage memory poolData,
      ILendingStorageManager.LendingInfo memory lendingInfo,
      ILendingStorageManager poolStorageManager
    ) = _getPoolInfo();

    // delegate call implementation
    bytes memory result =
      address(lendingInfo.lendingModule).functionDelegateCall(
        abi.encodeWithSignature(
          WITHDRAW_SIG,
          poolData,
          msg.sender,
          lendingInfo.args,
          _interestTokenAmount,
          _recipient
        )
      );

    ILendingModule.ReturnValues memory res =
      abi.decode(result, (ILendingModule.ReturnValues));

    // split interest
    InterestSplit memory interestSplit =
      splitGeneratedInterest(
        res.totalInterest,
        poolData.daoInterestShare,
        poolData.jrtBuybackShare
      );

    // update storage value
    poolStorageManager.updateValues(
      msg.sender,
      poolData.collateralDeposited + interestSplit.poolInterest - res.tokensOut,
      poolData.unclaimedDaoJRT + interestSplit.jrtInterest,
      poolData.unclaimedDaoCommission + interestSplit.commissionInterest
    );

    // set return values
    returnValues.tokensOut = res.tokensOut;
    returnValues.tokensTransferred = res.tokensTransferred;
    returnValues.poolInterest = interestSplit.poolInterest;
    returnValues.daoInterest =
      interestSplit.commissionInterest +
      interestSplit.jrtInterest;
    returnValues.prevTotalCollateral = poolData.collateralDeposited;
  }

  function updateAccumulatedInterest()
    external
    override
    nonReentrant
    returns (ReturnValues memory returnValues)
  {
    (
      ILendingStorageManager.PoolStorage memory poolData,
      ILendingStorageManager.LendingInfo memory lendingInfo,
      ILendingStorageManager poolStorageManager
    ) = _getPoolInfo();

    // retrieve accumulated interest
    uint256 totalInterest =
      ILendingModule(lendingInfo.lendingModule).getUpdatedInterest(
        msg.sender,
        poolData,
        lendingInfo.args
      );

    // split according to shares
    InterestSplit memory interestSplit =
      splitGeneratedInterest(
        totalInterest,
        poolData.daoInterestShare,
        poolData.jrtBuybackShare
      );

    //update pool storage
    poolStorageManager.updateValues(
      msg.sender,
      poolData.collateralDeposited + interestSplit.poolInterest,
      poolData.unclaimedDaoJRT + interestSplit.jrtInterest,
      poolData.unclaimedDaoCommission + interestSplit.commissionInterest
    );

    // return values
    returnValues.poolInterest = interestSplit.poolInterest;
    returnValues.daoInterest =
      interestSplit.jrtInterest +
      interestSplit.commissionInterest;
    returnValues.prevTotalCollateral = poolData.collateralDeposited;
  }

  function batchClaimCommission(
    address[] calldata _pools,
    uint256[] calldata _amounts
  ) external override onlyMaintainer nonReentrant {
    require(_pools.length == _amounts.length, 'Invalid call');
    address recipient =
      synthereumFinder.getImplementationAddress(
        SynthereumInterfaces.CommissionReceiver
      );
    uint256 totalAmount;
    for (uint8 i = 0; i < _pools.length; i++) {
      if (_amounts[i] > 0) {
        claimCommission(_pools[i], _amounts[i], recipient);
        totalAmount += _amounts[i];
      }
    }

    emit BatchCommissionClaim(totalAmount, recipient);
  }

  function batchBuyback(
    address[] calldata _pools,
    uint256[] calldata _amounts,
    address _collateralAddress,
    bytes calldata _swapParams
  ) external override onlyMaintainer nonReentrant {
    require(_pools.length == _amounts.length, 'Invalid call');
    ILendingStorageManager poolStorageManager = getStorageManager();

    // withdraw collateral and update all pools
    uint256 aggregatedCollateral;
    address recipient =
      synthereumFinder.getImplementationAddress(
        SynthereumInterfaces.BuybackProgramReceiver
      );
    for (uint8 i = 0; i < _pools.length; i++) {
      address pool = _pools[i];
      uint256 _collateralAmount = _amounts[i];

      (
        ILendingStorageManager.PoolStorage memory poolData,
        ILendingStorageManager.LendingInfo memory lendingInfo
      ) = poolStorageManager.getPoolData(pool);

      // all pools need to have the same collateral
      require(poolData.collateral == _collateralAddress, 'Collateral mismatch');

      (uint256 interestTokenAmount, ) =
        collateralToInterestToken(pool, _collateralAmount);

      // trigger transfer of interest token from the pool
      interestTokenAmount = ISynthereumLendingTransfer(pool)
        .transferToLendingManager(interestTokenAmount);

      bytes memory withdrawRes =
        address(lendingInfo.lendingModule).functionDelegateCall(
          abi.encodeWithSignature(
            WITHDRAW_SIG,
            poolData,
            pool,
            lendingInfo.args,
            interestTokenAmount,
            address(this)
          )
        );

      ILendingModule.ReturnValues memory res =
        abi.decode(withdrawRes, (ILendingModule.ReturnValues));

      // update aggregated collateral to use for buyback
      aggregatedCollateral += res.tokensTransferred;

      // split interest
      InterestSplit memory interestSplit =
        splitGeneratedInterest(
          res.totalInterest,
          poolData.daoInterestShare,
          poolData.jrtBuybackShare
        );

      //update pool storage
      poolStorageManager.updateValues(
        pool,
        poolData.collateralDeposited + interestSplit.poolInterest,
        poolData.unclaimedDaoJRT + interestSplit.jrtInterest - res.tokensOut,
        poolData.unclaimedDaoCommission + interestSplit.commissionInterest
      );
    }

    // execute the buyback call with all the withdrawn collateral
    address JARVIS =
      synthereumFinder.getImplementationAddress(
        SynthereumInterfaces.JarvisToken
      );
    bytes memory result =
      address(poolStorageManager.getCollateralSwapModule(_collateralAddress))
        .functionDelegateCall(
        abi.encodeWithSignature(
          JRTSWAP_SIG,
          recipient,
          _collateralAddress,
          JARVIS,
          aggregatedCollateral,
          _swapParams
        )
      );

    emit BatchBuyback(
      aggregatedCollateral,
      abi.decode(result, (uint256)),
      recipient
    );
  }

  function setLendingModule(
    string calldata _id,
    ILendingStorageManager.LendingInfo calldata _lendingInfo
  ) external override onlyMaintainer nonReentrant {
    ILendingStorageManager poolStorageManager = getStorageManager();
    poolStorageManager.setLendingModule(_id, _lendingInfo);
  }

  function addSwapProtocol(address _swapModule)
    external
    override
    onlyMaintainer
    nonReentrant
  {
    ILendingStorageManager poolStorageManager = getStorageManager();
    poolStorageManager.addSwapProtocol(_swapModule);
  }

  function removeSwapProtocol(address _swapModule)
    external
    override
    onlyMaintainer
    nonReentrant
  {
    ILendingStorageManager poolStorageManager = getStorageManager();
    poolStorageManager.removeSwapProtocol(_swapModule);
  }

  function setSwapModule(address _collateral, address _swapModule)
    external
    override
    onlyMaintainer
    nonReentrant
  {
    ILendingStorageManager poolStorageManager = getStorageManager();
    poolStorageManager.setSwapModule(_collateral, _swapModule);
  }

  function setShares(
    address _pool,
    uint64 _daoInterestShare,
    uint64 _jrtBuybackShare
  ) external override onlyMaintainer nonReentrant {
    ILendingStorageManager poolStorageManager = getStorageManager();
    poolStorageManager.setShares(_pool, _daoInterestShare, _jrtBuybackShare);
  }

  // to migrate liquidity to another lending module
  function migrateLendingModule(
    string memory _newLendingID,
    address _newInterestBearingToken,
    uint256 _interestTokenAmount
  ) external override nonReentrant returns (MigrateReturnValues memory) {
    (
      ILendingStorageManager.PoolStorage memory poolData,
      ILendingStorageManager.LendingInfo memory lendingInfo,
      ILendingStorageManager poolStorageManager
    ) = _getPoolInfo();

    uint256 prevDepositedCollateral = poolData.collateralDeposited;

    // delegate call withdraw collateral from old module
    ILendingModule.ReturnValues memory res;
    {
      bytes memory withdrawRes =
        address(lendingInfo.lendingModule).functionDelegateCall(
          abi.encodeWithSignature(
            WITHDRAW_SIG,
            poolData,
            msg.sender,
            lendingInfo.args,
            _interestTokenAmount,
            address(this)
          )
        );

      res = abi.decode(withdrawRes, (ILendingModule.ReturnValues));
    }
    // split interest
    InterestSplit memory interestSplit =
      splitGeneratedInterest(
        res.totalInterest,
        poolData.daoInterestShare,
        poolData.jrtBuybackShare
      );

    // add interest to pool data
    uint256 newDaoJRT = poolData.unclaimedDaoJRT + interestSplit.jrtInterest;
    uint256 newDaoCommission =
      poolData.unclaimedDaoCommission + interestSplit.commissionInterest;

    // temporary set pool data collateral and interest to 0 to freshly deposit
    poolStorageManager.updateValues(msg.sender, 0, 0, 0);

    // set new lending module and obtain new pool data
    ILendingStorageManager.LendingInfo memory newLendingInfo;
    (poolData, newLendingInfo) = poolStorageManager.migrateLendingModule(
      _newLendingID,
      msg.sender,
      _newInterestBearingToken
    );

    // delegate call deposit into new module
    bytes memory result =
      address(newLendingInfo.lendingModule).functionDelegateCall(
        abi.encodeWithSignature(
          DEPOSIT_SIG,
          poolData,
          newLendingInfo.args,
          res.tokensTransferred,
          msg.sender
        )
      );

    ILendingModule.ReturnValues memory depositRes =
      abi.decode(result, (ILendingModule.ReturnValues));

    // update storage with accumulated interest
    uint256 actualCollateralDeposited =
      depositRes.tokensOut - newDaoJRT - newDaoCommission;

    poolStorageManager.updateValues(
      msg.sender,
      actualCollateralDeposited,
      newDaoJRT,
      newDaoCommission
    );

    return (
      MigrateReturnValues(
        prevDepositedCollateral,
        interestSplit.poolInterest,
        actualCollateralDeposited
      )
    );
  }

  function migratePool(address _migrationPool, address _newPool)
    external
    override
    onlyPoolFactory
    nonReentrant
    returns (uint256 sourceCollateralAmount, uint256 actualCollateralAmount)
  {
    ILendingStorageManager poolStorageManager = getStorageManager();
    (
      ILendingStorageManager.PoolLendingStorage memory lendingStorage,
      ILendingStorageManager.LendingInfo memory lendingInfo
    ) = poolStorageManager.getLendingData(_migrationPool);

    // delegate call deposit into new module
    bytes memory result =
      address(lendingInfo.lendingModule).functionDelegateCall(
        abi.encodeWithSignature(
          TOTAL_TRANSFER_SIG,
          _migrationPool,
          _newPool,
          lendingStorage.collateralToken,
          lendingStorage.interestToken,
          lendingInfo.args
        )
      );

    (uint256 prevTotalAmount, uint256 newTotalAmount) =
      abi.decode(result, (uint256, uint256));

    sourceCollateralAmount = poolStorageManager.getCollateralDeposited(
      _migrationPool
    );

    actualCollateralAmount =
      sourceCollateralAmount +
      newTotalAmount -
      prevTotalAmount;

    poolStorageManager.migratePoolStorage(
      _migrationPool,
      _newPool,
      actualCollateralAmount
    );
  }

  function claimLendingRewards(address[] calldata _pools)
    external
    override
    onlyMaintainer
    nonReentrant
  {
    ILendingStorageManager poolStorageManager = getStorageManager();
    ILendingStorageManager.PoolLendingStorage memory poolLendingStorage;
    ILendingStorageManager.LendingInfo memory lendingInfo;
    address recipient =
      synthereumFinder.getImplementationAddress(
        SynthereumInterfaces.LendingRewardsReceiver
      );
    for (uint8 i = 0; i < _pools.length; i++) {
      (poolLendingStorage, lendingInfo) = poolStorageManager.getLendingData(
        _pools[i]
      );
      ISynthereumLendingRewards(_pools[i]).claimLendingRewards(
        lendingInfo,
        poolLendingStorage,
        recipient
      );
    }
  }

  function interestTokenToCollateral(
    address _pool,
    uint256 _interestTokenAmount
  )
    external
    view
    override
    returns (uint256 collateralAmount, address interestTokenAddr)
  {
    ILendingStorageManager poolStorageManager = getStorageManager();
    (
      ILendingStorageManager.PoolLendingStorage memory lendingStorage,
      ILendingStorageManager.LendingInfo memory lendingInfo
    ) = poolStorageManager.getLendingData(_pool);

    collateralAmount = ILendingModule(lendingInfo.lendingModule)
      .interestTokenToCollateral(
      _interestTokenAmount,
      lendingStorage.collateralToken,
      lendingStorage.interestToken,
      lendingInfo.args
    );
    interestTokenAddr = lendingStorage.interestToken;
  }

  function getAccumulatedInterest(address _pool)
    external
    view
    override
    returns (
      uint256 poolInterest,
      uint256 commissionInterest,
      uint256 buybackInterest,
      uint256 collateralDeposited
    )
  {
    ILendingStorageManager poolStorageManager = getStorageManager();
    (
      ILendingStorageManager.PoolStorage memory poolData,
      ILendingStorageManager.LendingInfo memory lendingInfo
    ) = poolStorageManager.getPoolData(_pool);

    uint256 totalInterest =
      ILendingModule(lendingInfo.lendingModule).getAccumulatedInterest(
        _pool,
        poolData,
        lendingInfo.args
      );

    InterestSplit memory interestSplit =
      splitGeneratedInterest(
        totalInterest,
        poolData.daoInterestShare,
        poolData.jrtBuybackShare
      );
    poolInterest = interestSplit.poolInterest;
    commissionInterest = interestSplit.commissionInterest;
    buybackInterest = interestSplit.jrtInterest;
    collateralDeposited = poolData.collateralDeposited;
  }

  function collateralToInterestToken(address _pool, uint256 _collateralAmount)
    public
    view
    override
    returns (uint256 interestTokenAmount, address interestTokenAddr)
  {
    ILendingStorageManager poolStorageManager = getStorageManager();
    (
      ILendingStorageManager.PoolLendingStorage memory lendingStorage,
      ILendingStorageManager.LendingInfo memory lendingInfo
    ) = poolStorageManager.getLendingData(_pool);

    interestTokenAmount = ILendingModule(lendingInfo.lendingModule)
      .collateralToInterestToken(
      _collateralAmount,
      lendingStorage.collateralToken,
      lendingStorage.interestToken,
      lendingInfo.args
    );
    interestTokenAddr = lendingStorage.interestToken;
  }

  function claimCommission(
    address _pool,
    uint256 _collateralAmount,
    address _recipient
  ) internal {
    ILendingStorageManager poolStorageManager = getStorageManager();
    (
      ILendingStorageManager.PoolStorage memory poolData,
      ILendingStorageManager.LendingInfo memory lendingInfo
    ) = poolStorageManager.getPoolData(_pool);

    // trigger transfer of funds from _pool
    (uint256 interestTokenAmount, ) =
      collateralToInterestToken(_pool, _collateralAmount);
    interestTokenAmount = ISynthereumLendingTransfer(_pool)
      .transferToLendingManager(interestTokenAmount);

    // delegate call withdraw
    bytes memory result =
      address(lendingInfo.lendingModule).functionDelegateCall(
        abi.encodeWithSignature(
          WITHDRAW_SIG,
          poolData,
          _pool,
          lendingInfo.args,
          interestTokenAmount,
          _recipient
        )
      );
    ILendingModule.ReturnValues memory res =
      abi.decode(result, (ILendingModule.ReturnValues));

    // split interest
    InterestSplit memory interestSplit =
      splitGeneratedInterest(
        res.totalInterest,
        poolData.daoInterestShare,
        poolData.jrtBuybackShare
      );

    //update pool storage
    poolStorageManager.updateValues(
      _pool,
      poolData.collateralDeposited + interestSplit.poolInterest,
      poolData.unclaimedDaoJRT + interestSplit.jrtInterest,
      poolData.unclaimedDaoCommission +
        interestSplit.commissionInterest -
        res.tokensOut
    );
  }

  function _getPoolInfo()
    internal
    view
    returns (
      ILendingStorageManager.PoolStorage memory poolData,
      ILendingStorageManager.LendingInfo memory lendingInfo,
      ILendingStorageManager poolStorageManager
    )
  {
    poolStorageManager = getStorageManager();
    (poolData, lendingInfo) = poolStorageManager.getPoolData(msg.sender);
  }

  function getStorageManager() internal view returns (ILendingStorageManager) {
    return
      ILendingStorageManager(
        synthereumFinder.getImplementationAddress(
          SynthereumInterfaces.LendingStorageManager
        )
      );
  }

  function splitGeneratedInterest(
    uint256 _totalInterestGenerated,
    uint64 _daoRatio,
    uint64 _jrtRatio
  ) internal pure returns (InterestSplit memory interestSplit) {
    if (_totalInterestGenerated == 0) return interestSplit;

    uint256 daoInterest = _totalInterestGenerated.mul(_daoRatio);
    interestSplit.jrtInterest = daoInterest.mul(_jrtRatio);
    interestSplit.commissionInterest = daoInterest - interestSplit.jrtInterest;
    interestSplit.poolInterest = _totalInterestGenerated - daoInterest;
  }
}
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import { OracleLibrary } from '@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol';
import { IERC20, SafeERC20 } from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import { Math } from '@openzeppelin/contracts/utils/math/Math.sol';
import { ERC20 } from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import { INPM } from './interfaces/INonfungiblePositionManager.sol';
import { IUniswapV3Pool } from './interfaces/IUniswapV3Pool.sol';
import { INFT } from './interfaces/INFT.sol';
import { BaseToken } from './BaseToken.sol';
import { FeeSplitter } from './FeeSplitter.sol';
import { IWETH9, UniswapBase } from './UniswapBase.sol';
import { MasterchefExit } from './MasterchefExit.sol';
import { STOToken } from './STOToken.sol';
import { APermit } from './APermit.sol';
import { ILido } from './interfaces/ILido.sol';

contract Exit10 is UniswapBase, APermit {
  using SafeERC20 for IERC20;
  using Math for uint256;

  struct DeployParams {
    address NFT;
    address STO;
    address BOOT;
    address BLP;
    address EXIT;
    address masterchef; // EXIT/USDC Stakers
    address feeSplitter; // Distribution to STO + BOOT and BLP stakers
    address beneficiary; // Address to receive fees if pool goes back into range after Exit10
    address lido;
    uint256 bootstrapStart;
    uint256 bootstrapDuration;
    uint256 bootstrapCap;
    uint256 accrualParameter; // The number of seconds it takes to accrue 50% of the cap, represented as an 18 digit fixed-point number.
  }

  struct BondData {
    uint256 bondAmount;
    uint256 claimedBLP;
    uint64 startTime;
    uint64 endTime;
    BondStatus status;
  }

  enum BondStatus {
    nonExistent,
    active,
    cancelled,
    converted
  }

  uint256 private pendingBucket;
  uint256 private reserveBucket;
  uint256 private bootstrapBucket;
  uint256 public bootstrapBucketFinal;
  uint256 public exitBucketBootstrapBucketFinal;

  // EXIT TOKEN
  uint256 public exitTokenSupplyFinal;
  uint256 public exitTokenRewardsFinal;

  // BOOT TOKEN
  uint256 public bootstrapRewardsPlusRefund;

  // STO TOKEN
  uint256 public teamPlusBackersRewards;

  bool public isBootstrapCapReached;
  bool public inExitMode;
  bool private hasUpdatedRewards;

  mapping(uint256 => BondData) private idToBondData;

  uint256 public constant TOKEN_MULTIPLIER = 1e8;
  uint256 public constant MAX_EXIT_SUPPLY = 100_000_000 ether;
  uint128 private constant MAX_UINT_128 = type(uint128).max;
  uint256 private constant MAX_UINT_256 = type(uint256).max;
  uint256 private constant DEADLINE = 1e10;

  BaseToken public immutable STO;
  BaseToken public immutable BOOT;
  BaseToken public immutable BLP;
  BaseToken public immutable EXIT;
  INFT public immutable NFT;

  address public immutable LIDO;
  address public immutable BENEFICIARY;
  address public immutable MASTERCHEF;
  address public immutable FEE_SPLITTER;

  uint256 public immutable BOOTSTRAP_START;
  uint256 public immutable BOOTSTRAP_FINISH;
  uint256 public immutable BOOTSTRAP_LIQUIDITY_CAP;
  uint256 public immutable ACCRUAL_PARAMETER;

  event BootstrapLock(
    address indexed recipient,
    uint256 lockAmount,
    uint256 amountAdded0,
    uint256 amountAdded1,
    uint256 bootTokensMinted
  );
  event CreateBond(
    address indexed recipient,
    uint256 bondID,
    uint256 bondAmount,
    uint256 amountAdded0,
    uint256 amountAdded1
  );
  event CancelBond(address indexed caller, uint256 bondID, uint256 amountReturned0, uint256 amountReturned1);
  event ConvertBond(address indexed caller, uint256 bondID, uint256 bondAmount, uint256 accrued, uint256 blpClaimed);
  event Redeem(address indexed caller, uint256 burnedBLP, uint256 amountReturned0, uint256 amountReturned1);
  event Exit(
    address indexed caller,
    uint256 time,
    uint256 bootstrapRefund,
    uint256 bootstrapRewards,
    uint256 teamPlusBackersRewards,
    uint256 exitTokenRewards
  );
  event BootClaim(address indexed caller, address indexed token, uint256 amountBurned, uint256 amountClaimed);
  event StoClaim(address indexed caller, address indexed token, uint256 amountBurned, uint256 amountClaimed);
  event ExitClaim(
    address indexed caller,
    address indexed token,
    uint256 amountBurned,
    uint256 liquidityClaimed,
    uint256 feesClaimed,
    uint256 stakedEthClaimed
  );
  event ClaimAndDistributeFees(address indexed caller, uint256 amountClaimed0, uint256 amountClaimed1);
  event StakeEth(address indexed caller, uint256 amountStaked, uint256 sharesReceived);

  constructor(BaseDeployParams memory baseParams_, DeployParams memory params_) UniswapBase(baseParams_) {
    STO = STOToken(params_.STO);
    BOOT = BaseToken(params_.BOOT);
    BLP = BaseToken(params_.BLP);
    EXIT = BaseToken(params_.EXIT);
    NFT = INFT(params_.NFT);

    MASTERCHEF = params_.masterchef;
    FEE_SPLITTER = params_.feeSplitter;
    BENEFICIARY = params_.beneficiary;
    LIDO = params_.lido;

    BOOTSTRAP_START = params_.bootstrapStart;
    BOOTSTRAP_FINISH = params_.bootstrapDuration + params_.bootstrapStart;
    BOOTSTRAP_LIQUIDITY_CAP = params_.bootstrapCap;
    ACCRUAL_PARAMETER = params_.accrualParameter;

    IERC20(IUniswapV3Pool(POOL).token0()).approve(NPM, MAX_UINT_256);
    IERC20(IUniswapV3Pool(POOL).token1()).approve(NPM, MAX_UINT_256);
    IERC20(IUniswapV3Pool(POOL).token0()).approve(FEE_SPLITTER, MAX_UINT_256);
    IERC20(IUniswapV3Pool(POOL).token1()).approve(FEE_SPLITTER, MAX_UINT_256);
  }

  receive() external payable {}

  function bootstrapLock(
    AddLiquidity memory params
  ) public payable returns (uint256 tokenId, uint128 liquidityAdded, uint256 amountAdded0, uint256 amountAdded1) {
    _requireNoExitMode();
    require(block.timestamp >= BOOTSTRAP_START, 'EXIT10: Bootstrap not started');
    require(_isBootstrapOngoing(), 'EXIT10: Bootstrap ended');
    require(!isBootstrapCapReached, 'EXIT10: Bootstrap cap reached');

    _depositTokens(params.amount0Desired, params.amount1Desired);

    (tokenId, liquidityAdded, amountAdded0, amountAdded1) = _addLiquidity(params);

    bootstrapBucket += liquidityAdded;

    if (BOOTSTRAP_LIQUIDITY_CAP != 0) {
      if (bootstrapBucket > BOOTSTRAP_LIQUIDITY_CAP) {
        uint256 diff;
        unchecked {
          diff = bootstrapBucket - BOOTSTRAP_LIQUIDITY_CAP;
        }
        (uint256 amountRemoved0, uint256 amountRemoved1) = _decreaseLiquidity(
          UniswapBase.RemoveLiquidity({ liquidity: uint128(diff), amount0Min: 0, amount1Min: 0, deadline: DEADLINE })
        );
        (uint256 amountCollected0, uint256 amountCollected1) = _collect(
          address(this),
          uint128(amountRemoved0),
          uint128(amountRemoved1)
        );

        liquidityAdded -= uint128(diff);
        amountAdded0 -= amountCollected0;
        amountAdded1 -= amountCollected1;
        bootstrapBucket = BOOTSTRAP_LIQUIDITY_CAP;
        isBootstrapCapReached = true;
      }
    }

    uint256 mintAmount = liquidityAdded * TOKEN_MULTIPLIER;
    BOOT.mint(params.depositor, mintAmount);

    _safeTransferTokens(params.depositor, params.amount0Desired - amountAdded0, params.amount1Desired - amountAdded1);

    emit BootstrapLock(params.depositor, liquidityAdded, amountAdded0, amountAdded1, mintAmount);
  }

  function createBond(
    AddLiquidity memory params
  ) public payable returns (uint256 bondID, uint128 liquidityAdded, uint256 amountAdded0, uint256 amountAdded1) {
    _requireNoExitMode();
    require(!_isBootstrapOngoing(), 'EXIT10: Bootstrap ongoing');

    claimAndDistributeFees();

    _depositTokens(params.amount0Desired, params.amount1Desired);

    (, liquidityAdded, amountAdded0, amountAdded1) = _addLiquidity(params);

    bondID = NFT.mint(params.depositor);

    BondData memory bondData;
    bondData.bondAmount = liquidityAdded;
    bondData.startTime = uint64(block.timestamp);
    bondData.status = BondStatus.active;
    idToBondData[bondID] = bondData;

    pendingBucket += liquidityAdded;

    _safeTransferTokens(params.depositor, params.amount0Desired - amountAdded0, params.amount1Desired - amountAdded1);

    emit CreateBond(params.depositor, bondID, liquidityAdded, amountAdded0, amountAdded1);
  }

  function stakeEth(uint256 amount) external returns (uint256 share) {
    _requireNoExitMode();
    IWETH9(WETH).withdraw(amount);
    uint256 amountEth = address(this).balance;
    share = ILido(LIDO).submit{ value: amountEth }(BENEFICIARY);
    require(share > 0, 'Exit10: Deposited zero amount');
    emit StakeEth(msg.sender, amountEth, share);
  }

  function bootstrapLockWithPermit(
    AddLiquidity memory params,
    PermitParameters memory permitParams0,
    PermitParameters memory permitParams1
  ) external payable returns (uint256 tokenId, uint128 liquidityAdded, uint256 amountAdded0, uint256 amountAdded1) {
    _permitTokens(permitParams0, permitParams1);
    return bootstrapLock(params);
  }

  function createBondWithPermit(
    AddLiquidity memory params,
    PermitParameters memory permitParams0,
    PermitParameters memory permitParams1
  ) external payable returns (uint256 bondID, uint128 liquidityAdded, uint256 amountAdded0, uint256 amountAdded1) {
    _permitTokens(permitParams0, permitParams1);
    return createBond(params);
  }

  function cancelBond(
    uint256 bondID,
    RemoveLiquidity memory params
  ) external returns (uint256 amountRemoved0, uint256 amountRemoved1) {
    _requireCallerOwnsBond(bondID);
    BondData memory bond = idToBondData[bondID];
    _requireActiveStatus(bond.status);

    claimAndDistributeFees();

    params.liquidity = uint128(bond.bondAmount);
    idToBondData[bondID].status = BondStatus.cancelled;
    idToBondData[bondID].endTime = uint64(block.timestamp);

    (amountRemoved0, amountRemoved1) = _decreaseLiquidity(params);
    (uint256 amountCollected0, uint256 amountCollected1) = _collect(
      msg.sender,
      uint128(amountRemoved0),
      uint128(amountRemoved1)
    );

    pendingBucket -= params.liquidity;

    emit CancelBond(msg.sender, bondID, amountCollected0, amountCollected1);
  }

  function convertBond(uint256 bondID, RemoveLiquidity memory params) external returns (uint256 blpTokenAmount) {
    _requireNoExitMode();
    _requireCallerOwnsBond(bondID);
    BondData memory bond = idToBondData[bondID];
    _requireActiveStatus(bond.status);

    claimAndDistributeFees();

    params.liquidity = uint128(bond.bondAmount);
    uint256 accruedLiquidity = _getAccruedLiquidity(bond);
    blpTokenAmount = accruedLiquidity * TOKEN_MULTIPLIER;

    idToBondData[bondID].status = BondStatus.converted;
    idToBondData[bondID].endTime = uint64(block.timestamp);
    idToBondData[bondID].claimedBLP = blpTokenAmount;

    pendingBucket -= params.liquidity;
    reserveBucket += accruedLiquidity;

    BLP.mint(msg.sender, blpTokenAmount);

    emit ConvertBond(msg.sender, bondID, bond.bondAmount, accruedLiquidity, blpTokenAmount);
  }

  function redeem(RemoveLiquidity memory params) external returns (uint256 amountRemoved0, uint256 amountRemoved1) {
    claimAndDistributeFees();

    reserveBucket -= params.liquidity;

    uint256 amountToBurn = params.liquidity * TOKEN_MULTIPLIER;
    BLP.burn(msg.sender, amountToBurn);

    (amountRemoved0, amountRemoved1) = _decreaseLiquidity(params);
    (uint256 amountCollected0, uint256 amountCollected1) = _collect(
      msg.sender,
      uint128(amountRemoved0),
      uint128(amountRemoved1)
    );

    emit Redeem(msg.sender, amountToBurn, amountCollected0, amountCollected1);
  }

  function exit10() external {
    _requireNoExitMode();
    _requireOutOfTickRange();

    claimAndDistributeFees();

    inExitMode = true;

    exitTokenSupplyFinal = EXIT.totalSupply();
    exitBucketBootstrapBucketFinal = _liquidityAmount() - (pendingBucket + reserveBucket);
    bootstrapBucketFinal = bootstrapBucket;
    bootstrapBucket = 0;

    RemoveLiquidity memory rmParams = RemoveLiquidity({
      liquidity: uint128(exitBucketBootstrapBucketFinal),
      amount0Min: 0,
      amount1Min: 0,
      deadline: DEADLINE
    });

    uint256 exitBucketBootstrapBucketRewards;

    if (TOKEN_OUT < TOKEN_IN) {
      (exitBucketBootstrapBucketRewards, ) = _decreaseLiquidity(rmParams);
      (exitBucketBootstrapBucketRewards, ) = _collect(address(this), uint128(exitBucketBootstrapBucketRewards), 0);
    } else {
      (, exitBucketBootstrapBucketRewards) = _decreaseLiquidity(rmParams);
      (, exitBucketBootstrapBucketRewards) = _collect(address(this), 0, uint128(exitBucketBootstrapBucketRewards));
    }

    // Total initial deposits that needs to be returned to bootstrappers
    uint256 bootstrapRefund = exitBucketBootstrapBucketFinal != 0
      ? (bootstrapBucketFinal * exitBucketBootstrapBucketRewards) / exitBucketBootstrapBucketFinal
      : 0;

    (bootstrapRewardsPlusRefund, teamPlusBackersRewards, exitTokenRewardsFinal) = _calculateFinalShares(
      bootstrapRefund,
      exitBucketBootstrapBucketRewards,
      bootstrapBucketFinal,
      exitTokenSupplyFinal
    );

    emit Exit(
      msg.sender,
      block.timestamp,
      bootstrapRefund,
      bootstrapRewardsPlusRefund - bootstrapRefund,
      teamPlusBackersRewards,
      exitTokenRewardsFinal
    );
  }

  function bootstrapClaim() external returns (uint256 claim) {
    _requireExitMode();
    BaseToken boot = BOOT;
    uint256 bootBalance = boot.balanceOf(msg.sender);

    claim = _getClaimableAmount(bootBalance / TOKEN_MULTIPLIER, bootstrapBucketFinal, bootstrapRewardsPlusRefund);

    boot.burn(msg.sender, bootBalance);
    _safeTransferToken(TOKEN_OUT, msg.sender, claim);

    emit BootClaim(msg.sender, address(BOOT), bootBalance, claim);
  }

  function stoClaim() external returns (uint256 claim) {
    _requireExitMode();
    BaseToken sto = STO;
    uint256 stoBalance = sto.balanceOf(msg.sender);

    claim = _getClaimableAmount(stoBalance, STOToken(address(sto)).MAX_SUPPLY(), teamPlusBackersRewards);

    sto.burn(msg.sender, stoBalance);
    _safeTransferToken(TOKEN_OUT, msg.sender, claim);

    emit StoClaim(msg.sender, address(STO), stoBalance, claim);
  }

  function exitClaim() external returns (uint256 claimedLiquidity, uint256 claimedFees, uint256 claimedStakedEth) {
    _requireExitMode();
    BaseToken exit = EXIT;
    uint256 exitBalance = exit.balanceOf(msg.sender);
    uint256 exitTotalSupply = exit.totalSupply();

    claimedLiquidity = _getClaimableAmount(exitBalance, exitTokenSupplyFinal, exitTokenRewardsFinal);
    claimedFees = _getClaimableAmount(exitBalance, exitTotalSupply, IERC20(TOKEN_IN).balanceOf(address(this)));

    uint256 shares;
    if (LIDO != address(0))
      shares = _getClaimableAmount(exitBalance, exitTotalSupply, ILido(LIDO).sharesOf(address(this)));

    exit.burn(msg.sender, exitBalance);

    _safeTransferToken(TOKEN_OUT, msg.sender, claimedLiquidity);
    _safeTransferToken(TOKEN_IN, msg.sender, claimedFees);
    if (shares != 0) claimedStakedEth = ILido(LIDO).transferShares(msg.sender, shares);

    emit ExitClaim(msg.sender, address(exit), exitBalance, claimedLiquidity, claimedFees, claimedStakedEth);
  }

  function getBondData(
    uint256 bondID
  ) external view returns (uint256 bondAmount, uint256 claimedBLP, uint64 startTime, uint64 endTime, uint8 status) {
    BondData memory bond = idToBondData[bondID];
    return (bond.bondAmount, bond.claimedBLP, bond.startTime, bond.endTime, uint8(bond.status));
  }

  function getBuckets() external view returns (uint256 pending, uint256 reserve, uint256 exit, uint256 bootstrap) {
    pending = pendingBucket;
    reserve = reserveBucket;
    bootstrap = bootstrapBucket;
    exit = _exitBucket();
  }

  function getAccruedAmount(uint256 bondID) external view returns (uint256) {
    BondData memory bond = idToBondData[bondID];

    if (bond.status != BondStatus.active) {
      return 0;
    }

    return _getAccruedLiquidity(bond);
  }

  function claimAndDistributeFees() public {
    (uint256 amountCollected0, uint256 amountCollected1) = _collect(address(this), MAX_UINT_128, MAX_UINT_128);

    if (amountCollected0 + amountCollected1 == 0) return;

    if (!inExitMode) {
      uint256 amountTokenOut;
      uint256 amountTokenIn;

      if (TOKEN_OUT < TOKEN_IN) {
        (amountTokenOut, amountTokenIn) = (amountCollected0, amountCollected1);
      } else {
        (amountTokenOut, amountTokenIn) = (amountCollected1, amountCollected0);
      }

      FeeSplitter(FEE_SPLITTER).collectFees(amountTokenOut, amountTokenIn);
    } else {
      // In case liquidity from Pending + Reserve buckets goes back in range after Exit10
      _safeTransferTokens(BENEFICIARY, amountCollected0, amountCollected1);
    }

    emit ClaimAndDistributeFees(msg.sender, amountCollected0, amountCollected1);
  }

  function updateRewards(uint256 amountTokenIn) external {
    require(msg.sender == FEE_SPLITTER, 'Exit10: Caller not authorized.');
    if (inExitMode) return;
    // For every 1 ETH acquired in fees we mint 1000 EXIT tokens
    uint256 mintAmount = amountTokenIn * 1000;
    mintAmount = _mintExitCapped(MASTERCHEF, mintAmount);
    MasterchefExit(MASTERCHEF).updateRewards(mintAmount);
  }

  function _getClaimableAmount(
    uint256 _shares,
    uint256 _totalSupply,
    uint256 _totalAssets
  ) internal pure returns (uint256 _claimable) {
    require(_shares != 0, 'EXIT10: Amount must be != 0');
    _claimable = _shares.mulDiv(_totalAssets, _totalSupply, Math.Rounding.Down);
  }

  function _depositTokens(uint256 _amount0, uint256 _amount1) internal {
    IERC20(POOL.token0()).safeTransferFrom(msg.sender, address(this), _amount0);
    IERC20(POOL.token1()).safeTransferFrom(msg.sender, address(this), _amount1);
  }

  function _safeTransferTokens(address _recipient, uint256 _amount0, uint256 _amount1) internal {
    _safeTransferToken(POOL.token0(), _recipient, _amount0);
    _safeTransferToken(POOL.token1(), _recipient, _amount1);
  }

  function _safeTransferToken(address _token, address _recipient, uint256 _amount) internal {
    if (_amount != 0) IERC20(_token).safeTransfer(_recipient, _amount);
  }

  function _mintExitCapped(address recipient, uint256 amount) internal returns (uint256 mintAmount) {
    uint256 newSupply = EXIT.totalSupply() + amount;
    mintAmount = newSupply > MAX_EXIT_SUPPLY ? MAX_EXIT_SUPPLY - EXIT.totalSupply() : amount;
    if (mintAmount != 0) EXIT.mint(recipient, mintAmount);
  }

  function _exitBucket() internal view returns (uint256 _exitAmount) {
    if (positionId == 0) return 0;
    _exitAmount = inExitMode ? 0 : _liquidityAmount() - (pendingBucket + reserveBucket + bootstrapBucket);
  }

  function _liquidityAmount() internal view returns (uint128 _liquidity) {
    if (positionId != 0) (, , , , , , , _liquidity, , , , ) = INPM(NPM).positions(positionId);
  }

  function _currentTick() internal view returns (int24 _tick) {
    (, _tick, , , , , ) = POOL.slot0();
  }

  function _getAccruedLiquidity(BondData memory _params) internal view returns (uint256 accruedAmount) {
    uint256 bondDuration = block.timestamp - _params.startTime;
    accruedAmount = (_params.bondAmount * bondDuration) / (bondDuration + ACCRUAL_PARAMETER);
  }

  function _isBootstrapOngoing() internal view returns (bool) {
    return (block.timestamp < BOOTSTRAP_FINISH);
  }

  function _requireExitMode() internal view {
    require(inExitMode, 'EXIT10: Not in Exit mode');
  }

  function _requireNoExitMode() internal view {
    require(!inExitMode, 'EXIT10: In Exit mode');
  }

  function _requireOutOfTickRange() internal view {
    (int24 blockStartTick, ) = OracleLibrary.getBlockStartingTickAndLiquidity(address(POOL));
    int24 currentTick = _currentTick();
    int24 tickDiff = blockStartTick > currentTick ? blockStartTick - currentTick : currentTick - blockStartTick;
    bool limit = (tickDiff < 100); // 100 ticks is about 1% in price difference
    if (TOKEN_IN > TOKEN_OUT) {
      require(currentTick <= TICK_LOWER && limit, 'EXIT10: Not out of tick range');
    } else {
      require(currentTick >= TICK_UPPER && limit, 'EXIT10: Not out of tick range');
    }
  }

  function _requireCallerOwnsBond(uint256 _bondID) internal view {
    require(msg.sender == NFT.ownerOf(_bondID), 'EXIT10: Caller must own the bond');
  }

  function _requireActiveStatus(BondStatus _status) internal pure {
    require(_status == BondStatus.active, 'EXIT10: Bond must be active');
  }

  function _calculateFinalShares(
    uint256 _refund,
    uint256 _totalRewards,
    uint256 _bootstrapBucket,
    uint256 _exitSupply
  ) internal pure returns (uint256 _bootRewards, uint256 _stoRewards, uint256 _exitRewards) {
    uint256 exitBucketMinusRefund = _totalRewards - _refund;
    uint256 tenPercent = exitBucketMinusRefund / 10;

    if (_bootstrapBucket != 0) {
      // Initial deposit plus 10% of the Exit Bucket
      _bootRewards = _refund + tenPercent;
    }
    // 20% of the ExitLiquidity
    _stoRewards = tenPercent << 1;

    if (_exitSupply != 0) {
      // 70% Exit Token holders
      _exitRewards = _totalRewards - (_bootRewards + _stoRewards);
    } else {
      _stoRewards = _totalRewards - _bootRewards;
    }
  }
}
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {ICreditLineStorage} from './interfaces/ICreditLineStorage.sol';
import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IStandardERC20} from '../../base/interfaces/IStandardERC20.sol';
import {
  IMintableBurnableERC20
} from '../../tokens/interfaces/IMintableBurnableERC20.sol';
import {ISynthereumFinder} from '../../core/interfaces/IFinder.sol';
import {ICreditLine} from './interfaces/ICreditLine.sol';
import {SynthereumInterfaces} from '../../core/Constants.sol';
import {
  FixedPoint
} from '../../../@uma/core/contracts/common/implementation/FixedPoint.sol';
import {
  SafeERC20
} from '../../../@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {CreditLineLib} from './CreditLineLib.sol';
import {
  ERC2771Context
} from '../../../@jarvis-network/synthereum-contracts/contracts/common/ERC2771Context.sol';
import {Initializable} from '../../base/utils/Initializable.sol';
import {
  ReentrancyGuard
} from '../../../@openzeppelin/contracts/security/ReentrancyGuard.sol';

/**
 * @title
 * @notice
 */
contract CreditLine is
  ICreditLine,
  ICreditLineStorage,
  ERC2771Context,
  Initializable,
  ReentrancyGuard
{
  using FixedPoint for FixedPoint.Unsigned;
  using SafeERC20 for IERC20;
  using SafeERC20 for IMintableBurnableERC20;
  using CreditLineLib for PositionData;
  using CreditLineLib for PositionManagerData;

  //----------------------------------------
  // Constants
  //----------------------------------------

  string public constant override typology = 'SELF-MINTING';

  bytes32 public constant MAINTAINER_ROLE = keccak256('Maintainer');

  //----------------------------------------
  // Storage
  //----------------------------------------

  // Maps sponsor addresses to their positions. Each sponsor can have only one position.
  mapping(address => PositionData) internal positions;
  // uint256 tokenSponsorsCount; // each new token sponsor will be identified with an incremental uint

  GlobalPositionData internal globalPositionData;

  PositionManagerData internal positionManagerData;

  FeeStatus internal feeStatus;

  //----------------------------------------
  // Events
  //----------------------------------------

  event Deposit(address indexed sponsor, uint256 indexed collateralAmount);
  event Withdrawal(address indexed sponsor, uint256 indexed collateralAmount);
  event PositionCreated(
    address indexed sponsor,
    uint256 indexed collateralAmount,
    uint256 indexed tokenAmount,
    uint256 feeAmount
  );
  event NewSponsor(address indexed sponsor);
  event EndedSponsorPosition(address indexed sponsor);
  event Redeem(
    address indexed sponsor,
    uint256 indexed collateralAmount,
    uint256 indexed tokenAmount
  );
  event Repay(
    address indexed sponsor,
    uint256 indexed numTokensRepaid,
    uint256 indexed newTokenCount
  );
  event EmergencyShutdown(
    address indexed caller,
    uint256 settlementPrice,
    uint256 shutdowntimestamp
  );
  event SettleEmergencyShutdown(
    address indexed caller,
    uint256 indexed collateralReturned,
    uint256 indexed tokensBurned
  );
  event Liquidation(
    address indexed sponsor,
    address indexed liquidator,
    uint256 liquidatedTokens,
    uint256 liquidatedCollateral,
    uint256 collateralReward,
    uint256 liquidationTime
  );

  //----------------------------------------
  // Modifiers
  //----------------------------------------

  modifier notEmergencyShutdown() {
    require(
      positionManagerData.emergencyShutdownTimestamp == 0,
      'Contract emergency shutdown'
    );
    _;
  }

  modifier isEmergencyShutdown() {
    require(
      positionManagerData.emergencyShutdownTimestamp != 0,
      'Contract not emergency shutdown'
    );
    _;
  }

  modifier onlyCollateralisedPosition(address sponsor) {
    require(
      positions[sponsor].rawCollateral.isGreaterThan(0),
      'Position has no collateral'
    );
    _;
  }

  constructor() {
    _disableInitializers();
  }

  //----------------------------------------
  // Initialization
  //----------------------------------------

  function initialize(PositionManagerParams memory _positionManagerData)
    external
    override
    initializer
    nonReentrant
  {
    positionManagerData.initialize(
      _positionManagerData.synthereumFinder,
      _positionManagerData.collateralToken,
      _positionManagerData.syntheticToken,
      _positionManagerData.priceFeedIdentifier,
      _positionManagerData.minSponsorTokens,
      _positionManagerData.excessTokenBeneficiary,
      _positionManagerData.version
    );
  }

  //----------------------------------------
  // External functions
  //----------------------------------------

  function deposit(uint256 collateralAmount)
    external
    override
    notEmergencyShutdown
    nonReentrant
  {
    PositionData storage positionData = _getPositionData(_msgSender());

    positionData.depositTo(
      globalPositionData,
      positionManagerData,
      FixedPoint.Unsigned(collateralAmount),
      _msgSender(),
      _msgSender()
    );
  }

  function depositTo(address sponsor, uint256 collateralAmount)
    external
    override
    notEmergencyShutdown
    nonReentrant
  {
    PositionData storage positionData = _getPositionData(sponsor);

    positionData.depositTo(
      globalPositionData,
      positionManagerData,
      FixedPoint.Unsigned(collateralAmount),
      sponsor,
      _msgSender()
    );
  }

  function withdraw(uint256 collateralAmount)
    external
    override
    notEmergencyShutdown
    nonReentrant
    returns (uint256 amountWithdrawn)
  {
    PositionData storage positionData = _getPositionData(_msgSender());

    amountWithdrawn = positionData
      .withdraw(
      globalPositionData,
      positionManagerData,
      FixedPoint.Unsigned(collateralAmount),
      _msgSender()
    )
      .rawValue;
  }

  function create(uint256 collateralAmount, uint256 numTokens)
    external
    override
    notEmergencyShutdown
    nonReentrant
    returns (uint256 feeAmount)
  {
    PositionData storage positionData = positions[_msgSender()];
    feeAmount = positionData
      .create(
      globalPositionData,
      positionManagerData,
      FixedPoint.Unsigned(collateralAmount),
      FixedPoint.Unsigned(numTokens),
      feeStatus,
      _msgSender()
    )
      .rawValue;
  }

  function redeem(uint256 numTokens)
    external
    override
    notEmergencyShutdown
    nonReentrant
    returns (uint256 amountWithdrawn)
  {
    PositionData storage positionData = _getPositionData(_msgSender());

    amountWithdrawn = positionData
      .redeem(
      globalPositionData,
      positionManagerData,
      FixedPoint.Unsigned(numTokens),
      _msgSender()
    )
      .rawValue;
  }

  function repay(uint256 numTokens)
    external
    override
    notEmergencyShutdown
    nonReentrant
  {
    PositionData storage positionData = _getPositionData(_msgSender());
    positionData.repay(
      globalPositionData,
      positionManagerData,
      FixedPoint.Unsigned(numTokens),
      _msgSender()
    );
  }

  function liquidate(address sponsor, uint256 maxTokensToLiquidate)
    external
    override
    notEmergencyShutdown
    nonReentrant
    returns (
      uint256 tokensLiquidated,
      uint256 collateralLiquidated,
      uint256 collateralReward
    )
  {
    // Retrieve Position data for sponsor
    PositionData storage positionToLiquidate = _getPositionData(sponsor);

    // try to liquidate it - reverts if is properly collateralised
    (
      collateralLiquidated,
      tokensLiquidated,
      collateralReward
    ) = positionToLiquidate.liquidate(
      positionManagerData,
      globalPositionData,
      FixedPoint.Unsigned(maxTokensToLiquidate),
      _msgSender()
    );

    emit Liquidation(
      sponsor,
      _msgSender(),
      tokensLiquidated,
      collateralLiquidated,
      collateralReward,
      block.timestamp
    );
  }

  function settleEmergencyShutdown()
    external
    override
    isEmergencyShutdown()
    nonReentrant
    returns (uint256 amountWithdrawn)
  {
    PositionData storage positionData = positions[_msgSender()];
    amountWithdrawn = positionData
      .settleEmergencyShutdown(
      globalPositionData,
      positionManagerData,
      _msgSender()
    )
      .rawValue;
  }

  function emergencyShutdown()
    external
    override
    notEmergencyShutdown
    nonReentrant
    returns (uint256 timestamp, uint256 price)
  {
    return positionManagerData.emergencyShutdown();
  }

  function claimFee()
    external
    override
    nonReentrant
    returns (uint256 feeClaimed)
  {
    feeClaimed = positionManagerData.claimFee(feeStatus, _msgSender());
  }

  function trimExcess(IERC20 token)
    external
    override
    nonReentrant
    returns (uint256 amount)
  {
    amount = positionManagerData
      .trimExcess(globalPositionData, feeStatus, token)
      .rawValue;
  }

  function deleteSponsorPosition(address sponsor) external override {
    require(
      _msgSender() == address(this),
      'Only the contract can invoke this function'
    );
    delete positions[sponsor];
  }

  function minSponsorTokens() external view override returns (uint256 amount) {
    amount = positionManagerData.minSponsorTokens.rawValue;
  }

  function excessTokensBeneficiary()
    external
    view
    override
    returns (address beneficiary)
  {
    beneficiary = positionManagerData.excessTokenBeneficiary;
  }

  function capMintAmount() external view override returns (uint256 capMint) {
    capMint = positionManagerData.capMintAmount().rawValue;
  }

  function feeInfo() external view override returns (Fee memory fee) {
    fee = positionManagerData.feeInfo();
  }

  function totalFeeAmount() external view override returns (uint256 totalFee) {
    totalFee = feeStatus.totalFeeAmount.rawValue;
  }

  function userFeeGained(address feeGainer)
    external
    view
    override
    returns (uint256 feeGained)
  {
    feeGained = feeStatus.feeGained[feeGainer].rawValue;
  }

  function liquidationReward()
    external
    view
    override
    returns (uint256 rewardPct)
  {
    rewardPct = positionManagerData.liquidationRewardPercentage().rawValue;
  }

  function collateralRequirement()
    external
    view
    override
    returns (uint256 collReq)
  {
    collReq = positionManagerData.collateralRequirement().rawValue;
  }

  function getPositionData(address sponsor)
    external
    view
    override
    returns (uint256 collateralAmount, uint256 tokensAmount)
  {
    return (
      positions[sponsor].rawCollateral.rawValue,
      positions[sponsor].tokensOutstanding.rawValue
    );
  }

  function getGlobalPositionData()
    external
    view
    override
    returns (uint256 totCollateral, uint256 totTokensOutstanding)
  {
    totCollateral = globalPositionData.rawTotalPositionCollateral.rawValue;
    totTokensOutstanding = globalPositionData.totalTokensOutstanding.rawValue;
  }

  function collateralCoverage(address sponsor)
    external
    view
    override
    returns (bool, uint256)
  {
    return positionManagerData.collateralCoverage(positions[sponsor]);
  }

  function liquidationPrice(address sponsor)
    external
    view
    override
    returns (uint256)
  {
    return positionManagerData.liquidationPrice(positions[sponsor]);
  }

  function synthereumFinder()
    external
    view
    override
    returns (ISynthereumFinder finder)
  {
    finder = positionManagerData.synthereumFinder;
  }

  function syntheticToken() external view override returns (IERC20 synthToken) {
    synthToken = positionManagerData.tokenCurrency;
  }

  function collateralToken() public view override returns (IERC20 collateral) {
    collateral = positionManagerData.collateralToken;
  }

  function syntheticTokenSymbol()
    external
    view
    override
    returns (string memory symbol)
  {
    symbol = IStandardERC20(address(positionManagerData.tokenCurrency))
      .symbol();
  }

  function version() external view override returns (uint8 contractVersion) {
    contractVersion = positionManagerData.version;
  }

  function priceIdentifier()
    external
    view
    override
    returns (bytes32 identifier)
  {
    identifier = positionManagerData.priceIdentifier;
  }

  function emergencyShutdownPrice()
    external
    view
    override
    isEmergencyShutdown()
    returns (uint256 price)
  {
    price = positionManagerData.emergencyShutdownPrice.rawValue;
  }

  function emergencyShutdownTime()
    external
    view
    override
    isEmergencyShutdown()
    returns (uint256 time)
  {
    time = positionManagerData.emergencyShutdownTimestamp;
  }

  /**
   * @notice Check if an address is the trusted forwarder
   * @param  forwarder Address to check
   * @return True is the input address is the trusted forwarder, otherwise false
   */
  function isTrustedForwarder(address forwarder)
    public
    view
    override
    returns (bool)
  {
    try
      positionManagerData.synthereumFinder.getImplementationAddress(
        SynthereumInterfaces.TrustedForwarder
      )
    returns (address trustedForwarder) {
      if (forwarder == trustedForwarder) {
        return true;
      } else {
        return false;
      }
    } catch {
      return false;
    }
  }

  //----------------------------------------
  // Internal functions
  //----------------------------------------
  function _getPositionData(address sponsor)
    internal
    view
    onlyCollateralisedPosition(sponsor)
    returns (PositionData storage)
  {
    return positions[sponsor];
  }

  function _msgSender()
    internal
    view
    override(ERC2771Context)
    returns (address sender)
  {
    return ERC2771Context._msgSender();
  }

  function _msgData()
    internal
    view
    override(ERC2771Context)
    returns (bytes calldata)
  {
    return ERC2771Context._msgData();
  }
}
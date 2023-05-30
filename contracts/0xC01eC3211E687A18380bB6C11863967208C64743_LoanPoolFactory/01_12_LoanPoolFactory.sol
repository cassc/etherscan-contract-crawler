// SPDX-License-Identifier: BUSL-1.1
// See bluejay.finance/license
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

import "../interfaces/ILoanPool.sol";
import "../interfaces/ICreditLineBase.sol";
import "../interfaces/ILoanPoolFactory.sol";

contract LoanPoolFactory is ILoanPoolFactory, AccessControl {
  bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

  /// @notice Address of the fee recipient
  address public override feeRecipient;

  /// @notice Address of the loan pool template
  address public override loanPoolTemplate;

  /// @notice Credit line template that can be used with the factory
  mapping(address => bool) public override isCreditLineTemplate;

  /// @notice Fees for a particular fee tier, in WAD
  mapping(uint256 => uint256) public override feesForTier;

  /// @notice Fee tier for a particular asset
  mapping(address => uint256) public override feesTierForAsset;

  /// @notice Is a loan pool deployed by this factory contract
  mapping(address => bool) public override loanPoolDeployed;

  /// @notice Checks that the credit line template is registered
  /// @param template Address of the credit line template
  modifier onlyCreditLineTemplate(address template) {
    if (!isCreditLineTemplate[template])
      revert CreditLineTemplateNotRegistered();
    _;
  }

  /// @notice Constructor of the factory
  /// @param _feeRecipient Address of the fee recipient
  /// @param _loanPoolTemplate Address of the loan pool template
  /// @param _defaultFees Fees for the default fee tier
  constructor(
    address _feeRecipient,
    address _loanPoolTemplate,
    uint256 _defaultFees
  ) {
    feeRecipient = _feeRecipient;
    loanPoolTemplate = _loanPoolTemplate;
    feesForTier[0] = _defaultFees;
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(MANAGER_ROLE, msg.sender);
  }

  // =============================== PUBLIC FUNCTIONS =================================

  /// @notice Creates a new loan pool
  /// @param creditLineTemplate Address of the credit line template
  /// @param fundingAsset Address of the asset used for the loan
  /// @param borrower Address of the borrower
  /// @param _uints Array of values to initialize the loan, see params for _createPool
  /// @return loanPool Address of the loan pool
  /// @return creditLine Address of the credit line
  function createPool(
    address creditLineTemplate,
    address fundingAsset,
    address borrower,
    uint256[11] calldata _uints
  ) public override returns (ILoanPool loanPool, ICreditLineBase creditLine) {
    uint256 fee = feesOnAsset(fundingAsset);
    (loanPool, creditLine) = _createPool(
      creditLineTemplate,
      fundingAsset,
      borrower,
      [
        _uints[0],
        _uints[1],
        _uints[2],
        _uints[3],
        _uints[4],
        _uints[5],
        _uints[6],
        _uints[7],
        _uints[8],
        _uints[9],
        _uints[10],
        fee
      ]
    );
  }

  // =============================== MANAGERS FUNCTIONS =================================

  /// @notice Creates a new loan pool, with a custom fee, in WAD
  /// @param creditLineTemplate Address of the credit line template
  /// @param fundingAsset Address of the asset used for the loan
  /// @param borrower Address of the borrower
  /// @param _uints Array of values to initialize the loan, see params for _createPool
  /// @return loanPool Address of the loan pool
  /// @return creditLine Address of the credit line
  function createCustomPool(
    address creditLineTemplate,
    address fundingAsset,
    address borrower,
    uint256[12] calldata _uints
  )
    public
    override
    onlyRole(MANAGER_ROLE)
    returns (ILoanPool loanPool, ICreditLineBase creditLine)
  {
    (loanPool, creditLine) = _createPool(
      creditLineTemplate,
      fundingAsset,
      borrower,
      _uints
    );
  }

  // =============================== INTERNAL FUNCTIONS =================================

  /// @notice Internal function to create a new loan pool
  /// @param creditLineTemplate Address of the credit line template
  /// @param fundingAsset Address of the asset used for the loan
  /// @param borrower Address of the borrower
  /// @param _uints Array of values to initialize the loan
  // _uints[0] _maxLimit Maximum amount of assets that can be borrowed, in asset's decimals
  // _uints[1] _interestApr Annual interest rate, in WAD
  // _uints[2] _paymentPeriod Length of each payment period, in seconds
  // _uints[3] _gracePeriod Length of the grace period (late fees is not applied), in seconds
  // _uints[4] _lateFeeApr Additional annual interest rate applied on late payments, in WAD
  // _uints[5] _loanTenureInPeriods Number of periods before the loan is due, in wei
  // _uints[6] _earlyRepaymentFee Early repayment fee, in WAD
  // _uints[7] _fundingStart Timestamp of the start of the funding period, in unix epoch time
  // _uints[8] _fundingPeriod Length of the funding period, in seconds
  // _uints[9] _minFundingRequired Minimum amount of funding required, in asset's decimals
  // _uints[10] _drawdownPeriod Length of the drawdown period before refund occurs, in seconds
  // _uints[11] _fee Fee for the loan, in WAD
  /// @return loanPool Address of the loan pool
  /// @return creditLine Address of the credit line
  function _createPool(
    address creditLineTemplate,
    address fundingAsset,
    address borrower,
    uint256[12] memory _uints
  )
    internal
    onlyCreditLineTemplate(creditLineTemplate)
    returns (ILoanPool loanPool, ICreditLineBase creditLine)
  {
    creditLine = ICreditLineBase(Clones.clone(creditLineTemplate));
    loanPool = ILoanPool(Clones.clone(loanPoolTemplate));
    loanPool.initialize(
      creditLine,
      IERC20(fundingAsset),
      borrower,
      feeRecipient,
      _uints
    );
    loanPoolDeployed[address(loanPool)] = true;
    emit LoanPoolCreated(
      address(loanPool),
      borrower,
      fundingAsset,
      creditLineTemplate,
      address(creditLine),
      _uints[0],
      _uints[11]
    );
  }

  // =============================== ADMIN FUNCTIONS =================================

  /// @notice Add a new credit line template that determines the loan term
  /// @param _creditLine Address of the credit line template
  function addCreditLine(
    address _creditLine
  ) public override onlyRole(DEFAULT_ADMIN_ROLE) {
    isCreditLineTemplate[_creditLine] = true;
    emit UpdateCreditLineTemplate(_creditLine, true);
  }

  /// @notice Remove a credit line template
  /// @param _creditLine Address of the credit line template
  function removeCreditLine(
    address _creditLine
  ) public override onlyRole(DEFAULT_ADMIN_ROLE) {
    isCreditLineTemplate[_creditLine] = false;
    emit UpdateCreditLineTemplate(_creditLine, false);
  }

  /// @notice Set the fees for a given tier of assets
  /// @dev Tier 0 is the default for assets that did not get tagged explicitly
  /// @param tier Tier of the asset
  /// @param fee Fees, in WAD
  function setFeeTier(
    uint256 tier,
    uint256 fee
  ) public override onlyRole(DEFAULT_ADMIN_ROLE) {
    feesForTier[tier] = fee;
    emit UpdateFeeTier(tier, fee);
  }

  /// @notice Set the fee tier for a given asset
  /// @param asset Address of the asset
  /// @param tier Tier of the asset
  function setAssetFeeTier(
    address asset,
    uint256 tier
  ) public override onlyRole(DEFAULT_ADMIN_ROLE) {
    feesTierForAsset[asset] = tier;
    emit UpdateAssetFeeTier(asset, tier);
  }

  /// @notice Set the fee recipient
  /// @param _feeRecipient Address of the fee recipient
  function setFeeRecipient(
    address _feeRecipient
  ) public override onlyRole(DEFAULT_ADMIN_ROLE) {
    feeRecipient = _feeRecipient;
    emit UpdateFeeRecipient(_feeRecipient);
  }

  // =============================== VIEW FUNCTIONS =================================

  /// @notice Get the fees applied on the loan for a given asset
  /// @param asset Address of the asset
  /// @return fee Fees, in WAD
  function feesOnAsset(
    address asset
  ) public view override returns (uint256 fee) {
    fee = feesForTier[feesTierForAsset[asset]];
  }
}
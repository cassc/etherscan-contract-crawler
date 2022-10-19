// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

// import "hardhat/console.sol";

import "./access/BackendAgent.sol";
import "./lib/token/BEP20/IBEP20.sol";
import "./token/MFCToken.sol";
import "./exchange/ExchangeCheck.sol";
import "./exchange/MFCExchange.sol";
import "./exchange/MFCExchangeFloor.sol";
import "./treasury/BUSDT.sol";
import "./RegistrarClient.sol";
import "./access/AdminGovernanceAgent.sol";

contract MFCCollateralLoan is BackendAgent, ExchangeCheck, RegistrarClient, AdminGovernanceAgent {

  // We use this to get around stack too deep errors.
  struct TradeOfferVars {
    uint256 maxInput;
    uint256 busdFee;
    uint256 mfcFee;
    uint256 mfcOut;
  }

  struct CalcOfferRepayment {
    uint256 effectiveBusdPaidOff;
    uint256 excessBUSD;
    uint256 excessCollateral;
    uint256 accruedInterest;
    bool isPaidOff;
  }

  uint256 public constant MULTIPLIER = 10**18;
  uint256 public constant DAY_IN_SECONDS = 86400;
  uint256 public constant OFFER_PRICE_LTV_RATIO = 1020409000000000000; // 1.020409;
  uint256 public constant OFFER_NET_COLLATERAL_RATIO = 980000000000000000; // 0.98;
  uint256 public constant BUSD_FEE = 20000000000000000;
  uint256 public constant MFC_FEE = 20000000000000000;
  uint256 public constant EXPIRES_IN = 30 days;
  uint256 public constant MINIMUM_OFFER_AUTOCLOSE_IN_BUSD = 1000000000000000000; // 1 Ether
  uint256 public constant MINIMUM_LOAN_AUTOCLOSE = 100000000; // 0.1 gwei

  enum DataTypes {
    BUSD,
    PERCENTAGE
  }

  MFCExchange private _mfcExchange;
  MFCExchangeFloor private _mfcExchangeFloor;
  MFCToken private _mfc;
  IBEP20 private _busd;
  BUSDT private _busdt;
  address private _mfcExchangeCapAddress;
  address private _busdComptrollerAddress;
  address private _deployer;
  uint256 private _loanTermsNonce = 0;
  uint256 private _loansNonce = 0;
  uint256 private _totalLoanValue = 0;
  uint256 private _maxOpenLoans = 4;
  bool private _allowLoanRenewals = true;

  // This contains the mutable loan terms
  struct LoanTerm {
    uint256 dailyInterestRate;
    uint256 loanDurationInDays;
    uint256 minimumLoanBUSD;
    uint256 originationFeePercentage;
    uint256 extensionFeePercentage;
    uint256 extensionMinimumRepayment;
    DataTypes extensionMinimumRepaymentType;
    uint256 extensionMinimumRemainingPrincipal;
    DataTypes extensionMinimumRemainingPrincipalType;
  }

  // This contains loan info per user
  struct Loan {
    uint256 loanTermId;
    uint256 collateralMFC;
    uint256 originalPrincipalBUSD;
    uint256 remainingPrincipalBUSD;
    uint256 principalRepaidSinceExtensionBUSD;
    uint256 ltv;
    uint256 startAt;
    uint256 endAt;
    uint256 lastPaidAt;
  }

  struct Offer {
    uint256 unfilledQuantity;
    uint256 price;
    uint256 maxPrincipal;     // Principal at the time offer is created
    uint256 maxQuantity;      // Max quantity at the time offer is created
    uint256 expiresAt;
    bool isOpen;
  }

  mapping(uint256 => LoanTerm) private _loanTerms;
  mapping(address => mapping(uint256 => Loan)) private _loans;
  mapping(address => uint8) private _openLoans;
  mapping(address => mapping(uint256 => Offer)) private _offers;

  event CreateLoanTerm(
    uint256 loanTermId,
    uint256 dailyInterestRate,
    uint256 loanDurationInDays,
    uint256 minimumLoanBUSD,
    uint256 originationFeePercentage,
    uint256 extensionFeePercentage,
    uint256 extensionMinimumRepayment,
    DataTypes extensionMinimumRepaymentType,
    uint256 extensionMinimumRemainingPrincipal,
    DataTypes extensionMinimumRemainingPrincipalType);
  event CreateLoan(
    address borrower,
    uint256 loanId,
    uint256 loanTermId,
    uint256 collateralMFC,
    uint256 originalPrincipalBUSD,
    uint256 remainingPrincipalBUSD,
    uint256 principalRepaidSinceExtensionBUSD,
    uint256 ltv,
    uint256 startAt,
    uint256 endAt);

  event PayLoan(
    address borrower,
    uint256 loanId,
    uint256 busdAmount,
    uint256 remainingPrincipalBUSD,
    uint256 principalRepaidSinceExtensionBUSD,
    uint256 collateralMFC,
    uint256 collateralReturned,
    uint256 interestPaid,
    uint256 paidAt
  );
  event ExtendLoan(address borrower, uint256 loanId, uint256 endAt);
  event CloseLoan(address borrower, uint256 loanId, uint256 collateralMFCTransferred);
  event CreateOffer(address borrower, uint256 loanId, uint256 quantity, uint256 price, uint256 expiresAt, uint256 timestamp);
  event TradeOffer(
    address borrower,
    uint256 loanId,
    address buyer,
    uint256 sellerQuantity,
    uint256 buyerQuantity,
    uint256 unfilledQuantity,
    uint256 excessBUSD,
    uint256 timestamp
  );
  event CloseOffer(uint256 loanId, uint256 timestamp);

  constructor(
    address registrarAddress_,
    address busdAddress_,
    address busdComptrollerAddress_,
    address[] memory adminGovAgents,
    address[] memory backendAdminAgents,
    address[] memory backendAgents
  ) RegistrarClient(registrarAddress_)
    AdminGovernanceAgent(adminGovAgents) {
    _busd = IBEP20(busdAddress_);
    _busdComptrollerAddress = busdComptrollerAddress_;
    _deployer = _msgSender();
    _setBackendAdminAgents(backendAdminAgents);
    _setBackendAgents(backendAgents);
  }

  modifier onlyDeployer() {
    require(_deployer == _msgSender(), "Caller is not the deployer");
    _;
  }

  modifier onlyActiveLoan(address borrower, uint256 loanId) {
    require(_loans[borrower][loanId].startAt > 0, "Invalid loan");
    require(isLoanActive(borrower, loanId), "Loan is not active");
    _;
  }

  modifier onlyActiveOffer(address borrower, uint256 loanId) {
    require(_offers[borrower][loanId].isOpen && _offers[borrower][loanId].expiresAt > block.timestamp, "Invalid offer");
    _;
  }

  modifier onlyOpenOffer(uint256 id, address borrower) {
    require(_offers[borrower][id].isOpen, "Offer must be open in order to close");
    _;
  }

  function setupInitialLoanTerm(
    uint256 dailyInterestRate,
    uint256 loanDurationInDays,
    uint256 minimumLoanBUSD,
    uint256 originationFeePercentage,
    uint256 extensionFeePercentage,
    uint256 extensionMinimumRepayment,
    DataTypes extensionMinimumRepaymentType,
    uint256 extensionMinimumRemainingPrincipal,
    DataTypes extensionMinimumRemainingPrincipalType
  ) external onlyDeployer {
    require(_loanTermsNonce == 0, "Loan terms already set up");
    _createNewLoanTerm(
      dailyInterestRate,
      loanDurationInDays,
      minimumLoanBUSD,
      originationFeePercentage,
      extensionFeePercentage,
      extensionMinimumRepayment,
      extensionMinimumRepaymentType,
      extensionMinimumRemainingPrincipal,
      extensionMinimumRemainingPrincipalType
    );
  }

  function createNewLoanTerm(
    uint256 dailyInterestRate,
    uint256 loanDurationInDays,
    uint256 minimumLoanBUSD,
    uint256 originationFeePercentage,
    uint256 extensionFeePercentage,
    uint256 extensionMinimumRepayment,
    DataTypes extensionMinimumRepaymentType,
    uint256 extensionMinimumRemainingPrincipal,
    DataTypes extensionMinimumRemainingPrincipalType
  ) external onlyBackendAdminAgents {
    _createNewLoanTerm(
      dailyInterestRate,
      loanDurationInDays,
      minimumLoanBUSD,
      originationFeePercentage,
      extensionFeePercentage,
      extensionMinimumRepayment,
      extensionMinimumRepaymentType,
      extensionMinimumRemainingPrincipal,
      extensionMinimumRemainingPrincipalType
    );
  }

  function getTotalLoanValue() external view returns (uint256) {
    return _totalLoanValue;
  }

  function getLoan(address borrower, uint256 loanId) external view returns (Loan memory) {
    return _loans[borrower][loanId];
  }

  function isLoanActive(address borrower, uint256 loanId) public view returns (bool) {
    return !_isLoanExpired(borrower, loanId) && _loans[borrower][loanId].remainingPrincipalBUSD > 0;
  }

  function getLoanTerm(uint256 loanTermId) external view returns (LoanTerm memory) {
    return _loanTerms[loanTermId];
  }

  function getCurrentLoanTerm() external view returns (LoanTerm memory) {
    return _loanTerms[_loanTermsNonce];
  }

  function getCurrentLoanTermId() external view returns (uint256) {
    return _loanTermsNonce;
  }

  function accruedInterestBUSD(address borrower, uint256 loanId) external view returns (uint256) {
    return _accruedInterestBUSD(borrower, loanId);
  }

  function accruedInterestMFC(address borrower, uint256 loanId) external view returns (uint256) {
    return _accruedInterestMFC(borrower, loanId);
  }

  function getCollateralMFCForLoanBUSD(uint256 busdAmount) external view returns (uint256) {
    return _getCollateralMFCForLoanBUSD(busdAmount);
  }

  function getMaxOpenLoans() external view returns (uint256) {
    return _maxOpenLoans;
  }

  function setMaxOpenLoans(uint256 maxOpenLoans_) external onlyBackendAdminAgents {
    _maxOpenLoans = maxOpenLoans_;
  }

  function getAllowLoanRenewals() external view returns (bool) {
    return _allowLoanRenewals;
  }

  function setAllowLoanRenewals(bool enabled) external onlyAdminGovAgents {
    _allowLoanRenewals = enabled;
  }

  function createLoan(uint256 loanTermId, uint256 busdAmount, uint256 mfcAmount, uint8 v, bytes32 r, bytes32 s) external {
    require(loanTermId == _loanTermsNonce, "Invalid loan term specified");
    require(_openLoans[_msgSender()] < _maxOpenLoans, "Maximum open loans reached");
    uint256 minCollateralMFC = _getCollateralMFCForLoanBUSD(busdAmount);
    require(mfcAmount >= minCollateralMFC, "mfcAmount too low based on floor price");

    // Call approval
    _mfc.permit(_msgSender(), address(this), mfcAmount, v, r, s);
    _createLoan(busdAmount);
  }

  function _createLoan(uint256 busdAmount) private {
    LoanTerm memory loanTerm = _loanTerms[_loanTermsNonce];
    require(busdAmount >= loanTerm.minimumLoanBUSD, "Minimum loan not met");
    uint256 collateralMFC = _getCollateralMFCForLoanBUSD(busdAmount);

    uint256 loanId = ++_loansNonce;
    uint256 busdComptrollerReceives = busdAmount * loanTerm.originationFeePercentage / MULTIPLIER;
    uint256 borrowerReceives = busdAmount - busdComptrollerReceives;
    uint256 startAt = block.timestamp;
    uint256 endAt = startAt + loanTerm.loanDurationInDays * DAY_IN_SECONDS;
    uint256 mfcPrice = _mfcExchangeFloor.getPrice();

    _loans[_msgSender()][loanId] = Loan(_loanTermsNonce, collateralMFC, busdAmount, busdAmount, 0, mfcPrice, startAt, endAt, 0);
    _openLoans[_msgSender()]++;

    _totalLoanValue += busdAmount;
    _mfc.transferFrom(_msgSender(), address(this), collateralMFC);
    _busdt.collateralTransfer(_msgSender(), borrowerReceives);
    _busdt.collateralTransfer(_busdComptrollerAddress, busdComptrollerReceives);

    emit CreateLoan(_msgSender(), loanId, _loanTermsNonce, collateralMFC, busdAmount, busdAmount, 0, mfcPrice, startAt, endAt);
  }

  function payLoan(uint256 loanId, uint256 busdAmount) external onlyActiveLoan(_msgSender(), loanId) {
    require(_busd.allowance(_msgSender(), address(this)) >= busdAmount, "Insufficient allowance");
    require(_busd.balanceOf(_msgSender()) >= busdAmount, "Insufficient balance");
    require(!_offers[_msgSender()][loanId].isOpen, "Active offer found");

    _payLoanBUSD(_msgSender(), loanId, busdAmount);
  }

  function extendLoan(uint256 loanId) external onlyActiveLoan(_msgSender(), loanId) {
    require(_allowLoanRenewals, "Loan renewals disabled");
    Loan storage loan = _loans[_msgSender()][loanId];
    LoanTerm memory loanTerm = _loanTerms[loan.loanTermId];
    require(loan.principalRepaidSinceExtensionBUSD >= _getMinimumExtensionRepayment(loan.loanTermId, loan.originalPrincipalBUSD), "Minimum repayment not met");
    require(loan.remainingPrincipalBUSD >= _getRemainingPrincipalExtensionLimit(loan.loanTermId, loan.originalPrincipalBUSD), "Principal too low to extend");
    uint256 extensionFeeBUSD = loan.remainingPrincipalBUSD * loanTerm.extensionFeePercentage / MULTIPLIER;
    require(_busd.allowance(_msgSender(), address(this)) >= extensionFeeBUSD, "Insufficient allowance");
    require(_busd.balanceOf(_msgSender()) >= extensionFeeBUSD, "Insufficient balance");

    loan.principalRepaidSinceExtensionBUSD = 0;
    loan.endAt = block.timestamp + loanTerm.loanDurationInDays * DAY_IN_SECONDS;

    _busd.transferFrom(_msgSender(), _busdComptrollerAddress, extensionFeeBUSD);

    emit ExtendLoan(_msgSender(), loanId, loan.endAt);
  }

  // for manually closing out expired loans (defaulted) and taking out the remaining collateral
  function closeLoan(address borrower, uint256 loanId) external onlyBackendAgents {
    require(!isLoanActive(borrower, loanId), "Loan is still active");

    uint256 collateralMFC = _loans[borrower][loanId].collateralMFC;
    uint256 remainingPrincipalBUSD = _loans[borrower][loanId].remainingPrincipalBUSD;

    // Update loan and offer (if any)
    _decrementOpenLoansAndCloseOffer(borrower, loanId);
    _loans[borrower][loanId].collateralMFC = 0;
    _loans[borrower][loanId].remainingPrincipalBUSD = 0;

    // Update total loan value
    _totalLoanValue -= remainingPrincipalBUSD;

    // Transfer an remaining collateral MFC to exchange
    // and update circulation
    _transferToExchangeCap(collateralMFC);

    emit CloseLoan(borrower, loanId, collateralMFC);
  }

  function createOffer(uint256 loanId, uint256 quantity, uint256 price) external onlyValidMember(_msgSender()) onlyActiveLoan(_msgSender(), loanId) {
    require(!_offers[_msgSender()][loanId].isOpen, "Limit one offer per loan");

    Loan memory loan = _loans[_msgSender()][loanId];

    // OFFER_NET_COLLATERAL_RATIO
    uint256 accruedInterest = _accruedInterestMFC(_msgSender(), loanId);
    uint256 maximumQuantity = (loan.collateralMFC - accruedInterest) * OFFER_NET_COLLATERAL_RATIO / MULTIPLIER;
    require(quantity <= maximumQuantity, "Quantity exceeds limit");

    // We're creating a [MFC_BUSD] offer:
    // min price = (remaining principal / (remaining collateral after interest * 0.98)) * 1.020409
    uint256 minPrice = loan.remainingPrincipalBUSD * OFFER_PRICE_LTV_RATIO / maximumQuantity;
    require(price >= minPrice, "Minimum price not met");

    // Cannot open an offer if loan is to expire before end
    // of offer (currently 30 days)
    uint256 expiresAt = block.timestamp + EXPIRES_IN;
    require(loan.endAt > expiresAt, "Loan is about to expire");

    // Create offer
    _offers[_msgSender()][loanId] = Offer(quantity, price, loan.remainingPrincipalBUSD, maximumQuantity, expiresAt, true);

    emit CreateOffer(_msgSender(), loanId, quantity, price, expiresAt, block.timestamp);
  }

  /**
   * @dev This is for other members to trade on the offer the borrower created
   */
  function tradeOffer(address borrower, uint256 loanId, uint256 amountBUSD) external onlyValidMember(_msgSender()) onlyActiveOffer(borrower, loanId) {
    require(amountBUSD > 0, "Invalid quantity");
    require(_busd.allowance(_msgSender(), address(this)) >= amountBUSD, "Insufficient allowance");
    require(_busd.balanceOf(_msgSender()) >= amountBUSD, "Insufficient balance");

    Offer storage offer = _offers[borrower][loanId];
    Loan storage loan = _loans[borrower][loanId];

    TradeOfferVars memory info;
    info.maxInput = offer.unfilledQuantity * offer.price / MULTIPLIER;
    require(amountBUSD <= info.maxInput, "Not enough to sell");

    info.busdFee = amountBUSD * BUSD_FEE / MULTIPLIER;
    info.mfcFee = amountBUSD * MFC_FEE / offer.price;

    info.mfcOut = amountBUSD * MULTIPLIER / offer.price;

    // Calculate and update loan
    CalcOfferRepayment memory calc = _payLoanMFC(
      borrower,
      loanId,
      info.mfcOut,
      offer.maxPrincipal,
      offer.maxQuantity,
      amountBUSD - info.busdFee
    );

    // Update offer
    if (!calc.isPaidOff) {
      if (info.mfcOut > offer.unfilledQuantity) {
        info.mfcOut = offer.unfilledQuantity;
      }
      offer.unfilledQuantity -= info.mfcOut;

      // If remaining quantity is low enough, close it out
      // MFC_BUSD market - converted selling amount in MFC to BUSD < MINIMUM_OFFER_AUTOCLOSE_IN_BUSD
      bool takerCloseout = (offer.unfilledQuantity * offer.price / MULTIPLIER) < MINIMUM_OFFER_AUTOCLOSE_IN_BUSD;

      // console.log("unfilledQuantity: %s, takerCloseout: %s, amount: %s", offer.unfilledQuantity, takerCloseout, offer.unfilledQuantity * offer.price / MULTIPLIER);

      if (takerCloseout) {
        // Auto-close when selling amount in BUSD < MINIMUM_OFFER_AUTOCLOSE_IN_BUSD
        // No need to return MFC from offer, since it was reserving
        // the MFC directly from borrower's collateralMFC pool.
        _closeOffer(borrower, loanId);
      }
    }

    _totalLoanValue -= calc.effectiveBusdPaidOff;

    // Send out MFC fee + accrued interest.
    // Note that we have 2% MFC buffer in the collateral, as
    // the offer can only be created with 98% of collateral max.
    _transferToExchangeCap(info.mfcFee + calc.accruedInterest);

    // Send out MFC to buyer
    _mfc.transfer(_msgSender(), info.mfcOut - info.mfcFee);

    // Send out BUSD fee
    _busd.transferFrom(_msgSender(), _busdComptrollerAddress, info.busdFee);

    // Send out to BUSDT
    _busd.transferFrom(_msgSender(), address(_busdt), amountBUSD - calc.excessBUSD - info.busdFee);
    if (calc.excessBUSD > 0) {
      // Send excess to borrower
      _busd.transferFrom(_msgSender(), borrower, calc.excessBUSD);
    }

    if (calc.excessCollateral > 0) {
      // Return excess MFC to borrower (if any) once loan is repaid in full
      _mfc.transfer(borrower, calc.excessCollateral);
    }

    emit TradeOffer(borrower, loanId, _msgSender(), info.mfcOut, amountBUSD, offer.unfilledQuantity, calc.excessBUSD, loan.lastPaidAt);
    emit PayLoan(
      borrower,
      loanId,
      calc.effectiveBusdPaidOff,
      loan.remainingPrincipalBUSD,
      loan.principalRepaidSinceExtensionBUSD,
      loan.collateralMFC,
      0,
      calc.accruedInterest,
      loan.lastPaidAt
    );
  }

  /**
   * @dev This is for the borrower to sell their collateral to other users
   */
  function tradeCollateral(uint256 loanId, uint256 offerId, address seller, uint256 amountMFC) external onlyValidMember(_msgSender()) onlyActiveLoan(_msgSender(), loanId) {
    _tradeCollateralPrerequisite(loanId, amountMFC);

    Loan storage loan = _loans[_msgSender()][loanId];
    // We are trading on a member's [BUSD_MFC] offer, so their price will be MFC/BUSD.
    MFCExchange.Offer memory offer = _mfcExchange.getOffer(offerId, seller);
    require(offer.isOpen == true && offer.quantity > 0, "Offer is closed or has zero quantity");

    uint256 accruedInterest = _accruedInterestMFC(_msgSender(), loanId);

    // min price formula = (remaining principal / remaining collateral after interest) * 1.020409
    // In this case it's actually max price due to inversion.
    uint256 maxPrice = loan.remainingPrincipalBUSD * OFFER_PRICE_LTV_RATIO / (loan.collateralMFC - accruedInterest);
    maxPrice = MULTIPLIER * MULTIPLIER / maxPrice;
    require(offer.price <= maxPrice, "Minimum price not met");

    _mfc.approve(address(_mfcExchange), amountMFC);

    // Calculate (estimate) and update state first
    MFCExchange.TradeOfferCalcInfo memory calc = _mfcExchange.estimateTradeOffer(offerId, seller, amountMFC);
    CalcOfferRepayment memory loanCalcs = _payLoanMFC(
      _msgSender(),
      loanId,
      amountMFC,
      loan.remainingPrincipalBUSD,
      loan.collateralMFC - accruedInterest,
      calc.amountOut - calc.takerFee
    );

    // Execute actual swap
    MFCExchange.TradeOfferCalcInfo memory realCalc = _mfcExchange.tradeOffer(offerId, seller, amountMFC);
    require(calc.amountOut == realCalc.amountOut, "amountOut does not match");

    // Send out funds post-swap
    _tradeCollateralTransfers(loanId, loanCalcs, realCalc.amountOut, realCalc.takerFee);
  }

  function _tradeCollateralTransfers(uint256 loanId, CalcOfferRepayment memory loanCalcs, uint256 amountOut, uint256 takerFee) private {
    address borrower = _msgSender();
    Loan storage loan = _loans[borrower][loanId];

    // This needs to be updated last (but before transfers)
    // as this affects the floor price.
    _totalLoanValue -= loanCalcs.effectiveBusdPaidOff;

    _transferToExchangeCap(loanCalcs.accruedInterest);

    _busd.transfer(address(_busdt), amountOut - loanCalcs.excessBUSD - takerFee);
    if (loanCalcs.excessBUSD > 0) {
      // Send excess to borrower
      _busd.transfer(borrower, loanCalcs.excessBUSD);
    }

    if (loanCalcs.excessCollateral > 0) {
      // Return excess MFC to borrower (if any) once loan is repaid in full
      _mfc.transfer(borrower, loanCalcs.excessCollateral);
    }

    emit PayLoan(
      borrower,
      loanId,
      loanCalcs.effectiveBusdPaidOff,
      loan.remainingPrincipalBUSD,
      loan.principalRepaidSinceExtensionBUSD,
      loan.collateralMFC,
      0,
      loanCalcs.accruedInterest,
      loan.lastPaidAt
    );
  }

  function closeOffer(uint256 loanId) external onlyOpenOffer(loanId, _msgSender()) {
    _closeOffer(_msgSender(), loanId);
  }

  function closeOffer(address borrower, uint256 loanId) external onlyOpenOffer(loanId, borrower) onlyBackendAgents {
    _closeOffer(borrower, loanId);
  }

  function getOffer(address borrower, uint256 loanId) external view returns (Offer memory) {
    return _offers[borrower][loanId];
  }

  function updateAddresses() public override onlyRegistrar {
    _mfcExchange = MFCExchange(_registrar.getMFCExchange());
    _mfcExchangeFloor = MFCExchangeFloor(_registrar.getMFCExchangeFloor());
    _mfcExchangeCapAddress = _registrar.getMFCExchangeCap();
    _mfc = MFCToken(_registrar.getMFCToken());
    _busdt = BUSDT(_registrar.getBUSDT());
    _updateExchangeCheck(_registrar);
  }

  function _createNewLoanTerm(
    uint256 dailyInterestRate,
    uint256 loanDurationInDays,
    uint256 minimumLoanBUSD,
    uint256 originationFeePercentage,
    uint256 extensionFeePercentage,
    uint256 extensionMinimumRepayment,
    DataTypes extensionMinimumRepaymentType,
    uint256 extensionMinimumRemainingPrincipal,
    DataTypes extensionMinimumRemainingPrincipalType
  ) private {
    require(extensionMinimumRepaymentType == DataTypes.PERCENTAGE || extensionMinimumRepaymentType == DataTypes.BUSD, "Invalid type");
    require(extensionMinimumRemainingPrincipalType == DataTypes.PERCENTAGE || extensionMinimumRemainingPrincipalType == DataTypes.BUSD, "Invalid type");

    _loanTerms[++_loanTermsNonce] = LoanTerm(
      dailyInterestRate,
      loanDurationInDays,
      minimumLoanBUSD,
      originationFeePercentage,
      extensionFeePercentage,
      extensionMinimumRepayment,
      extensionMinimumRepaymentType,
      extensionMinimumRemainingPrincipal,
      extensionMinimumRemainingPrincipalType
    );

    emit CreateLoanTerm(
      _loanTermsNonce,
      dailyInterestRate,
      loanDurationInDays,
      minimumLoanBUSD,
      originationFeePercentage,
      extensionFeePercentage,
      extensionMinimumRepayment,
      extensionMinimumRepaymentType,
      extensionMinimumRemainingPrincipal,
      extensionMinimumRemainingPrincipalType
    );
  }

  function _getCollateralMFCForLoanBUSD(uint256 busdAmount) private view returns (uint256) {
    uint256 mfcPrice = _mfcExchangeFloor.getPrice();
    return mfcPrice * busdAmount / MULTIPLIER;
  }

  function _isLoanExpired(address borrower, uint256 loanId) private view returns (bool) {
    return _loans[borrower][loanId].endAt < block.timestamp;
  }

  // rounding down basis, meaning for 11.6 days borrower will pay interests for 11 days
  // we have to account for the case where borrower might pay at 11.6 days and another payment at 20.4 days
  // because 20.4-11.6 = 8.8 days we cannot calculate directly otherwise 11+8 = 19 days of interest instead of 20
  // therefore we have to look at the number of days in total minus the number of days borrower has paid
  function _daysElapsed(uint256 startAt, uint256 lastPaidAt) private view returns (uint256) {
    uint256 currentTime = block.timestamp;
    if (lastPaidAt > 0) {
      uint256 daysTotal = (currentTime - startAt) / DAY_IN_SECONDS;
      uint256 daysPaid = (lastPaidAt - startAt) / DAY_IN_SECONDS;
      return daysTotal - daysPaid;
    } else {
      return (currentTime - startAt) / DAY_IN_SECONDS;
    }
  }

  function _getMinimumExtensionRepayment(uint256 loanTermId, uint256 originalPrincipalBUSD) private view returns (uint256) {
    LoanTerm memory loanTerm = _loanTerms[loanTermId];
    if (loanTerm.extensionMinimumRepaymentType == DataTypes.BUSD) {
      return loanTerm.extensionMinimumRepayment;
    } else if (loanTerm.extensionMinimumRepaymentType == DataTypes.PERCENTAGE) {
      return originalPrincipalBUSD * loanTerm.extensionMinimumRepayment / MULTIPLIER;
    } else {
      return 0;
    }
  }

  function _getRemainingPrincipalExtensionLimit(uint256 loanTermId, uint256 originalPrincipalBUSD) private view returns (uint256) {
    LoanTerm memory loanTerm = _loanTerms[loanTermId];
    if (loanTerm.extensionMinimumRemainingPrincipalType == DataTypes.BUSD) {
      return loanTerm.extensionMinimumRemainingPrincipal;
    } else if (loanTerm.extensionMinimumRemainingPrincipalType == DataTypes.PERCENTAGE) {
      return originalPrincipalBUSD * loanTerm.extensionMinimumRemainingPrincipal / MULTIPLIER;
    } else {
      return 0;
    }
  }

  function _accruedInterestBUSD(address borrower, uint256 loanId) private view returns (uint256) {
    Loan memory loan = _loans[borrower][loanId];
    LoanTerm memory loanTerm = _loanTerms[loan.loanTermId];
    uint256 daysElapsed = _daysElapsed(loan.startAt, loan.lastPaidAt);

    return loan.remainingPrincipalBUSD * loanTerm.dailyInterestRate * daysElapsed / MULTIPLIER;
  }

  function _accruedInterestMFC(address borrower, uint256 loanId) private view returns (uint256) {
    uint256 interestBUSD = _accruedInterestBUSD(borrower, loanId);
    uint256 mfcPrice = _mfcExchangeFloor.getPrice();

    return interestBUSD * mfcPrice / MULTIPLIER;
  }

  function _payLoanBUSD(address borrower, uint256 loanId, uint256 busdAmount) private {
    Loan storage loan = _loans[borrower][loanId];
    uint256 accruedInterest = _accruedInterestMFC(borrower, loanId);
    loan.collateralMFC -= accruedInterest;

    uint256 excessBUSD = 0;
    uint256 collateralReturned = 0;

    if (busdAmount > loan.remainingPrincipalBUSD) {
      excessBUSD = busdAmount - loan.remainingPrincipalBUSD;
      busdAmount = loan.remainingPrincipalBUSD;
    }

    if (loan.remainingPrincipalBUSD == busdAmount) {
      collateralReturned = loan.collateralMFC;
      _decrementOpenLoansAndCloseOffer(borrower, loanId);
    } else {
      collateralReturned = loan.collateralMFC * busdAmount / loan.remainingPrincipalBUSD;
    }

    loan.remainingPrincipalBUSD -= busdAmount;
    loan.principalRepaidSinceExtensionBUSD += busdAmount;
    loan.collateralMFC -= collateralReturned;
    loan.lastPaidAt = block.timestamp;

    _totalLoanValue -= busdAmount;
    _transferToExchangeCap(accruedInterest);
    _mfc.transfer(borrower, collateralReturned);

    _busd.transferFrom(_msgSender(), address(_busdt), busdAmount);

    if (excessBUSD > 0) {
      _busd.transferFrom(_msgSender(), borrower, excessBUSD);
    }

    emit PayLoan(
      borrower,
      loanId,
      busdAmount,
      loan.remainingPrincipalBUSD,
      loan.principalRepaidSinceExtensionBUSD,
      loan.collateralMFC,
      collateralReturned,
      accruedInterest,
      loan.lastPaidAt
    );
  }

  /**
   * @dev Pay off loan by selling MFC collateral
   */
  function _payLoanMFC(address borrower, uint256 loanId, uint256 mfcToTrade, uint256 maxPrincipal, uint256 maxMFC, uint256 amountBUSD) private returns (CalcOfferRepayment memory) {
    Loan storage loan = _loans[borrower][loanId];

    CalcOfferRepayment memory calc;

    // uint256 percentagePaidOff = mfcToTrade * MULTIPLIER / maxMFC;
    // calc.effectiveBusdPaidOff = percentagePaidOff * maxPrincipal / MULTIPLIER;
    calc.effectiveBusdPaidOff = mfcToTrade * maxPrincipal / maxMFC;
    if (amountBUSD > calc.effectiveBusdPaidOff) {
      calc.excessBUSD = amountBUSD - calc.effectiveBusdPaidOff;
    }
    calc.accruedInterest = _accruedInterestMFC(borrower, loanId);

    // console.log("mfcToTrade: %s\npercentagePaidOff: %s\neffectiveBusdPaidOff: %s", mfcToTrade, percentagePaidOff, calc.effectiveBusdPaidOff);
    // console.log("excessBUSD: %s\naccruedInterest: %s\ncollateralMFC: %s", calc.excessBUSD, calc.accruedInterest, loan.collateralMFC);
    // console.log("amountBUSD: %s", amountBUSD);

    // Update loan
    require(loan.collateralMFC >= mfcToTrade + calc.accruedInterest, "Not enough collateral");
    loan.collateralMFC -= mfcToTrade + calc.accruedInterest;

    // Handle possible precision issues
    if (calc.effectiveBusdPaidOff > loan.remainingPrincipalBUSD) {
      calc.effectiveBusdPaidOff = loan.remainingPrincipalBUSD;
    }
    if (loan.remainingPrincipalBUSD > calc.effectiveBusdPaidOff &&
      (loan.remainingPrincipalBUSD - calc.effectiveBusdPaidOff <= MINIMUM_LOAN_AUTOCLOSE)) {
      calc.effectiveBusdPaidOff = loan.remainingPrincipalBUSD;
    }

    // Loan paid off?
    if (calc.effectiveBusdPaidOff == loan.remainingPrincipalBUSD) {
      calc.isPaidOff = true;
      _decrementOpenLoansAndCloseOffer(borrower, loanId);

      // If there is any remaining collateral, record that
      // so we can later return it to borrower.
      if (loan.collateralMFC > 0) {
        calc.excessCollateral = loan.collateralMFC;
        loan.collateralMFC = 0;
      }
    }

    // Update rest of loan
    loan.remainingPrincipalBUSD -= calc.effectiveBusdPaidOff;
    loan.principalRepaidSinceExtensionBUSD += calc.effectiveBusdPaidOff;
    loan.lastPaidAt = block.timestamp;

    // console.log("remainingPrincipalBUSD: %s, excessCollateral: %s", loan.remainingPrincipalBUSD, calc.excessCollateral);
    // console.log("collateralMFC: %s", loan.collateralMFC);

    return calc;
  }

  function _tradeCollateralPrerequisite(uint256 loanId, uint256 amountMFC) private view {
    require(amountMFC > 0, "Invalid quantity");
    Offer memory offer = _offers[_msgSender()][loanId];
    require(offer.isOpen == false, "Active offer found");
    Loan memory loan = _loans[_msgSender()][loanId];
    uint256 accruedInterest = _accruedInterestMFC(_msgSender(), loanId);
    uint256 remainingCollateralMFC = loan.collateralMFC - accruedInterest;
    require(amountMFC <= remainingCollateralMFC, "Not enough to sell");
  }

  function _transferToExchangeCap(uint256 amount) private {
    _mfc.transfer(_mfcExchangeCapAddress, amount);
  }

  function _decrementOpenLoansAndCloseOffer(address borrower, uint256 loanId) internal {
    if (_openLoans[borrower] > 0) {
      _openLoans[borrower]--;
    }
    if (_offers[borrower][loanId].isOpen) {
      _closeOffer(borrower, loanId);
    }
    emit CloseLoan(borrower, loanId, 0);
  }

  function _closeOffer(address borrower, uint256 loanId) internal {
    delete _offers[borrower][loanId];
    emit CloseOffer(loanId, block.timestamp);
  }
}
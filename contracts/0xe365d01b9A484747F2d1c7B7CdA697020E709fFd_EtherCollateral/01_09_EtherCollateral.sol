// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {SafeDecimalMath} from "./SafeDecimalMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {IERC20} from "./interfaces/IERC20.sol";
import "./interfaces/IConjure.sol";
import "./interfaces/IConjureFactory.sol";
import "./interfaces/IConjureRouter.sol";

/// @author Conjure Finance Team
/// @title EtherCollateral
/// @notice Contract to create a collateral system for conjure
/// @dev Fork of https://github.com/Synthetixio/synthetix/blob/develop/contracts/EtherCollateralsUSD.sol and adopted
contract EtherCollateral is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;

    // ========== CONSTANTS ==========
    uint256 internal constant ONE_THOUSAND = 1e18 * 1000;
    uint256 internal constant ONE_HUNDRED = 1e18 * 100;
    uint256 internal constant ONE_HUNDRED_TEN = 1e18 * 110;

    // ========== SETTER STATE VARIABLES ==========

    // The ratio of Collateral to synths issued
    uint256 public collateralizationRatio;

    // Minting fee for issuing the synths
    uint256 public issueFeeRate;

    // Minimum amount of ETH to create loan preventing griefing and gas consumption. Min 0.05 ETH
    uint256 public constant MIN_LOAN_COLLATERAL_SIZE = 10 ** 18 / 20;

    // Maximum number of loans an account can create
    uint256 public constant ACCOUNT_LOAN_LIMITS = 50;

    // Liquidation ratio when loans can be liquidated
    uint256 public liquidationRatio;

    // Liquidation penalty when loans are liquidated. default 10%
    uint256 public constant LIQUIDATION_PENALTY = 10 ** 18 / 10;

    // ========== STATE VARIABLES ==========

    // The total number of synths issued by the collateral in this contract
    uint256 public totalIssuedSynths;

    // Total number of loans ever created
    uint256 public totalLoansCreated;

    // Total number of open loans
    uint256 public totalOpenLoanCount;

    // Synth loan storage struct
    struct SynthLoanStruct {
        // Account that created the loan
        address payable account;
        // Amount (in collateral token ) that they deposited
        uint256 collateralAmount;
        // Amount (in synths) that they issued to borrow
        uint256 loanAmount;
        // Minting Fee
        uint256 mintingFee;
        // When the loan was created
        uint256 timeCreated;
        // ID for the loan
        uint256 loanID;
        // When the loan was paid back (closed)
        uint256 timeClosed;
    }

    // Users Loans by address
    mapping(address => SynthLoanStruct[]) public accountsSynthLoans;

    // Account Open Loan Counter
    mapping(address => uint256) public accountOpenLoanCounter;

    // address of the conjure contract (which represents the asset)
    address payable public arbasset;

    // the address of the collateral contract factory
    address public _factoryContract;

    // bool indicating if the asset is closed (no more opening loans and deposits)
    // this is set to true if the asset price reaches 0
    bool internal assetClosed;

    // address of the owner
    address public owner;

    // ========== EVENTS ==========

    event IssueFeeRateUpdated(uint256 issueFeeRate);
    event LoanLiquidationOpenUpdated(bool loanLiquidationOpen);
    event LoanCreated(address indexed account, uint256 loanID, uint256 amount);
    event LoanClosed(address indexed account, uint256 loanID);
    event LoanLiquidated(address indexed account, uint256 loanID, address liquidator);
    event LoanPartiallyLiquidated(
        address indexed account,
        uint256 loanID,
        address liquidator,
        uint256 liquidatedAmount,
        uint256 liquidatedCollateral
    );
    event CollateralDeposited(address indexed account, uint256 loanID, uint256 collateralAmount, uint256 collateralAfter);
    event CollateralWithdrawn(address indexed account, uint256 loanID, uint256 amountWithdrawn, uint256 collateralAfter);
    event LoanRepaid(address indexed account, uint256 loanID, uint256 repaidAmount, uint256 newLoanAmount);
    event AssetClosed(bool status);
    event NewOwner(address newOwner);

    constructor() {
        // Don't allow implementation to be initialized.
        _factoryContract = address(1);
    }

    // modifier for only owner
    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    // only owner view for modifier
    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }

    /**
     * @dev initializes the clone implementation and the EtherCollateral contract
     *
     * @param _asset the asset with which the EtherCollateral contract is linked
     * @param _owner the owner of the asset
     * @param _factoryAddress the address of the conjure factory for later fee sending
     * @param _mintingFeeRatio array which holds the minting fee and the c-ratio
    */
    function initialize(
        address payable _asset,
        address _owner,
        address _factoryAddress,
        uint256[2] memory _mintingFeeRatio
    )
    external
    {
        require(_factoryContract == address(0), "already initialized");
        require(_factoryAddress != address(0), "factory can not be null");
        require(_owner != address(0), "_owner can not be null");
        require(_asset != address(0), "_asset can not be null");
        // c-ratio greater 100 and less or equal 1000
        require(_mintingFeeRatio[1] <= ONE_THOUSAND, "C-Ratio Too high");
        require(_mintingFeeRatio[1] > ONE_HUNDRED_TEN, "C-Ratio Too low");

        arbasset = _asset;
        owner = _owner;
        setIssueFeeRateInternal(_mintingFeeRatio[0]);
        _factoryContract = _factoryAddress;
        collateralizationRatio = _mintingFeeRatio[1];
        liquidationRatio = _mintingFeeRatio[1] / 100;
    }

    // ========== SETTERS ==========

    /**
     * @dev lets the owner change the contract owner
     *
     * @param _newOwner the new owner address of the contract
    */
    function changeOwner(address payable _newOwner) external onlyOwner {
        require(_newOwner != address(0), "_newOwner can not be null");
    
        owner = _newOwner;
        emit NewOwner(_newOwner);
    }

    /**
     * @dev Sets minting fee of the asset internal function
     *
     * @param _issueFeeRate the new minting fee
    */
    function setIssueFeeRateInternal(uint256 _issueFeeRate) internal {
        // max 2.5% fee for minting
        require(_issueFeeRate <= 250, "Minting fee too high");

        issueFeeRate = _issueFeeRate;
        emit IssueFeeRateUpdated(issueFeeRate);
    }

    /**
     * @dev Sets minting fee of the asset
     *
     * @param _issueFeeRate the new minting fee
    */
    function setIssueFeeRate(uint256 _issueFeeRate) external onlyOwner {
        // fee can only be lowered
        require(_issueFeeRate <= issueFeeRate, "Fee can only be lowered");

        setIssueFeeRateInternal(_issueFeeRate);
    }

    /**
     * @dev Sets the assetClosed indicator if loan opening is allowed or not
     * Called by the Conjure contract if the asset price reaches 0.
     *
    */
    function setAssetClosed(bool status) external {
        require(msg.sender == arbasset, "Only Conjure contract can call");
        assetClosed = status;
        emit AssetClosed(status);
    }

    /**
     * @dev Gets the assetClosed indicator
    */
    function getAssetClosed() external view returns (bool) {
        return assetClosed;
    }

    /**
     * @dev Gets all the contract information currently in use
     * array indicating which tokens had their prices updated.
     *
     * @return _collateralizationRatio the current C-Ratio
     * @return _issuanceRatio the percentage of 100/ C-ratio e.g. 100/150 = 0.6666666667
     * @return _issueFeeRate the minting fee for a new loan
     * @return _minLoanCollateralSize the minimum loan collateral value
     * @return _totalIssuedSynths the total of all issued synths
     * @return _totalLoansCreated the total of all loans created
     * @return _totalOpenLoanCount the total of open loans
     * @return _ethBalance the current balance of the contract
    */
    function getContractInfo()
    external
    view
    returns (
        uint256 _collateralizationRatio,
        uint256 _issuanceRatio,
        uint256 _issueFeeRate,
        uint256 _minLoanCollateralSize,
        uint256 _totalIssuedSynths,
        uint256 _totalLoansCreated,
        uint256 _totalOpenLoanCount,
        uint256 _ethBalance
    )
    {
        _collateralizationRatio = collateralizationRatio;
        _issuanceRatio = issuanceRatio();
        _issueFeeRate = issueFeeRate;
        _minLoanCollateralSize = MIN_LOAN_COLLATERAL_SIZE;
        _totalIssuedSynths = totalIssuedSynths;
        _totalLoansCreated = totalLoansCreated;
        _totalOpenLoanCount = totalOpenLoanCount;
        _ethBalance = address(this).balance;
    }

    /**
     * @dev Gets the value of of 100 / collateralizationRatio.
     * e.g. 100/150 = 0.6666666667
     *
    */
    function issuanceRatio() public view returns (uint256) {
        // this rounds so you get slightly more rather than slightly less
        return ONE_HUNDRED.divideDecimalRound(collateralizationRatio);
    }

    /**
     * @dev Gets the amount of synths which can be issued given a certain loan amount
     *
     * @param collateralAmount the given ETH amount
     * @return the amount of synths which can be minted with the given collateral amount
    */
    function loanAmountFromCollateral(uint256 collateralAmount) public view returns (uint256) {
        return collateralAmount
        .multiplyDecimal(issuanceRatio())
        .multiplyDecimal(syntharb().getLatestETHUSDPrice())
        .divideDecimal(syntharb().getLatestPrice());
    }

    /**
     * @dev Gets the collateral amount needed (in ETH) to mint a given amount of synths
     *
     * @param loanAmount the given loan amount
     * @return the amount of collateral (in ETH) needed to open a loan for the synth amount
    */
    function collateralAmountForLoan(uint256 loanAmount) public view returns (uint256) {
        return
        loanAmount
        .multiplyDecimal(collateralizationRatio
        .divideDecimalRound(syntharb().getLatestETHUSDPrice())
        .multiplyDecimal(syntharb().getLatestPrice()))
        .divideDecimalRound(ONE_HUNDRED);
    }

    /**
     * @dev Gets the minting fee given the account address and the loanID
     *
     * @param _account the opener of the loan
     * @param _loanID the loan id
     * @return the minting fee of the loan
    */
    function getMintingFee(address _account, uint256 _loanID) external view returns (uint256) {
        // Get the loan from storage
        SynthLoanStruct memory synthLoan = _getLoanFromStorage(_account, _loanID);
        return synthLoan.mintingFee;
    }

    /**
    * @dev Gets the amount to liquidate which can potentially fix the c ratio given this formula:
     * r = target issuance ratio
     * D = debt balance
     * V = Collateral
     * P = liquidation penalty
     * Calculates amount of synths = (D - V * r) / (1 - (1 + P) * r)
     *
     * If the C-Ratio is greater than Liquidation Ratio + Penalty in % then the C-Ratio can be fixed
     * otherwise a greater number is returned and the debtToCover from the calling function is used
     *
     * @param debtBalance the amount of the loan or debt to calculate in USD
     * @param collateral the amount of the collateral in USD
     *
     * @return the amount to liquidate to fix the C-Ratio if possible
     */
    function calculateAmountToLiquidate(uint debtBalance, uint collateral) public view returns (uint) {
        uint unit = SafeDecimalMath.unit();

        uint dividend = debtBalance.sub(collateral.divideDecimal(liquidationRatio));
        uint divisor = unit.sub(unit.add(LIQUIDATION_PENALTY).divideDecimal(liquidationRatio));

        return dividend.divideDecimal(divisor);
    }

    /**
     * @dev Gets all open loans by a given account address
     *
     * @param _account the opener of the loans
     * @return all open loans by ID in form of an array
    */
    function getOpenLoanIDsByAccount(address _account) external view returns (uint256[] memory) {
        SynthLoanStruct[] memory synthLoans = accountsSynthLoans[_account];

        uint256[] memory _openLoanIDs = new uint256[](synthLoans.length);
        uint256 j;

        for (uint i = 0; i < synthLoans.length; i++) {
            if (synthLoans[i].timeClosed == 0) {
                _openLoanIDs[j++] = synthLoans[i].loanID;
            }
        }

        // Change the list size of the array in place
        assembly {
            mstore(_openLoanIDs, j)
        }

        // Return the resized array
        return _openLoanIDs;
    }

    /**
     * @dev Gets all details about a certain loan
     *
     * @param _account the opener of the loans
     * @param _loanID the ID of a given loan
     * @return account the opener of the loan
     * @return collateralAmount the amount of collateral in ETH
     * @return loanAmount the loan amount
     * @return timeCreated the time the loan was initially created
     * @return loanID the ID of the loan
     * @return timeClosed the closure time of the loan (if closed)
     * @return totalFees the minting fee of the loan
    */
    function getLoan(address _account, uint256 _loanID)
    external
    view
    returns (
        address account,
        uint256 collateralAmount,
        uint256 loanAmount,
        uint256 timeCreated,
        uint256 loanID,
        uint256 timeClosed,
        uint256 totalFees
    )
    {
        SynthLoanStruct memory synthLoan = _getLoanFromStorage(_account, _loanID);
        account = synthLoan.account;
        collateralAmount = synthLoan.collateralAmount;
        loanAmount = synthLoan.loanAmount;
        timeCreated = synthLoan.timeCreated;
        loanID = synthLoan.loanID;
        timeClosed = synthLoan.timeClosed;
        totalFees = synthLoan.mintingFee;
    }

    /**
     * @dev Gets the current C-Ratio of a loan
     *
     * @param _account the opener of the loan
     * @param _loanID the loan ID
     * @return loanCollateralRatio the current C-Ratio of the loan
    */
    function getLoanCollateralRatio(address _account, uint256 _loanID) external view returns (uint256 loanCollateralRatio) {
        // Get the loan from storage
        SynthLoanStruct memory synthLoan = _getLoanFromStorage(_account, _loanID);

        (loanCollateralRatio,  ) = _loanCollateralRatio(synthLoan);
    }

    /**
     * @dev Gets the current C-Ratio of a loan by _loan struct
     *
     * @param _loan the loan struct
     * @return loanCollateralRatio the current C-Ratio of the loan
     * @return collateralValue the current value of the collateral in USD
    */
    function _loanCollateralRatio(SynthLoanStruct memory _loan)
    internal
    view
    returns (
        uint256 loanCollateralRatio,
        uint256 collateralValue
    )
    {
        uint256 loanAmountWithAccruedInterest = _loan.loanAmount.multiplyDecimal(syntharb().getLatestPrice());

        collateralValue = _loan.collateralAmount.multiplyDecimal(syntharb().getLatestETHUSDPrice());
        loanCollateralRatio = collateralValue.divideDecimal(loanAmountWithAccruedInterest);
    }


    // ========== PUBLIC FUNCTIONS ==========

    /**
     * @dev Public function to open a new loan in the system
     *
     * @param _loanAmount the amount of synths a user wants to take a loan for
     * @return loanID the ID of the newly created loan
    */
    function openLoan(uint256 _loanAmount)
    external
    payable
    nonReentrant
    returns (uint256 loanID) {
        // asset must be open
        require(!assetClosed, "Asset closed");
        // Require ETH sent to be greater than MIN_LOAN_COLLATERAL_SIZE
        require(
            msg.value >= MIN_LOAN_COLLATERAL_SIZE,
            "Not enough ETH to create this loan. Please see the MIN_LOAN_COLLATERAL_SIZE"
        );

        // Each account is limited to creating 50 (ACCOUNT_LOAN_LIMITS) loans
        require(accountsSynthLoans[msg.sender].length < ACCOUNT_LOAN_LIMITS, "Each account is limited to 50 loans");

        // Calculate issuance amount based on issuance ratio
        syntharb().updatePrice();
        uint256 maxLoanAmount = loanAmountFromCollateral(msg.value);

        // Require requested _loanAmount to be less than maxLoanAmount
        // Issuance ratio caps collateral to loan value at 120%
        require(_loanAmount <= maxLoanAmount, "Loan amount exceeds max borrowing power");

        uint256 ethForLoan = collateralAmountForLoan(_loanAmount);
        uint256 mintingFee = _calculateMintingFee(msg.value);
        require(msg.value >= ethForLoan + mintingFee, "Not enough funds sent to cover fee and collateral");

        // Get a Loan ID
        loanID = _incrementTotalLoansCounter();

        // Create Loan storage object
        SynthLoanStruct memory synthLoan = SynthLoanStruct({
        account: msg.sender,
        collateralAmount: msg.value - mintingFee,
        loanAmount: _loanAmount,
        mintingFee: mintingFee,
        timeCreated: block.timestamp,
        loanID: loanID,
        timeClosed: 0
        });

        // Record loan in mapping to account in an array of the accounts open loans
        accountsSynthLoans[msg.sender].push(synthLoan);

        // Increment totalIssuedSynths
        totalIssuedSynths = totalIssuedSynths.add(_loanAmount);

        // Issue the synth (less fee)
        syntharb().mint(msg.sender, _loanAmount);
        
        // Tell the Dapps a loan was created
        emit LoanCreated(msg.sender, loanID, _loanAmount);

        // Fee distribution. Mint the fees into the FeePool and record fees paid
        if (mintingFee > 0) {
            // conjureRouter gets 25% of the fee
            address payable conjureRouter = IConjureFactory(_factoryContract).getConjureRouter();
            uint256 feeToSend = mintingFee / 4;

            IConjureRouter(conjureRouter).deposit{value:feeToSend}();
            arbasset.transfer(mintingFee.sub(feeToSend));
        }
    }

    /**
     * @dev Function to close a loan
     * calls the internal _closeLoan function with the false parameter for liquidation
     * to mark it as a non liquidation close
     *
     * @param loanID the ID of the loan a user wants to close
    */
    function closeLoan(uint256 loanID) external nonReentrant  {
        _closeLoan(msg.sender, loanID, false);
    }

    /**
     * @dev Add ETH collateral to an open loan
     *
     * @param account the opener of the loan
     * @param loanID the ID of the loan
    */
    function depositCollateral(address account, uint256 loanID) external payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");

        // Get the loan from storage
        SynthLoanStruct memory synthLoan = _getLoanFromStorage(account, loanID);

        // Check loan exists and is open
        _checkLoanIsOpen(synthLoan);

        uint256 totalCollateral = synthLoan.collateralAmount.add(msg.value);

        _updateLoanCollateral(synthLoan, totalCollateral);

        // Tell the Dapps collateral was added to loan
        emit CollateralDeposited(account, loanID, msg.value, totalCollateral);
    }

    /**
     * @dev Withdraw ETH collateral from an open loan
     * the C-Ratio after should not be less than the Liquidation Ratio
     *
     * @param loanID the ID of the loan
     * @param withdrawAmount the amount to withdraw from the current collateral
    */
    function withdrawCollateral(uint256 loanID, uint256 withdrawAmount) external nonReentrant  {
        require(withdrawAmount > 0, "Amount to withdraw must be greater than 0");

        // Get the loan from storage
        SynthLoanStruct memory synthLoan = _getLoanFromStorage(msg.sender, loanID);

        // Check loan exists and is open
        _checkLoanIsOpen(synthLoan);

        uint256 collateralAfter = synthLoan.collateralAmount.sub(withdrawAmount);

        SynthLoanStruct memory loanAfter = _updateLoanCollateral(synthLoan, collateralAfter);

        // require collateral ratio after to be above the liquidation ratio
        (uint256 collateralRatioAfter, ) = _loanCollateralRatio(loanAfter);

        require(collateralRatioAfter > liquidationRatio, "Collateral ratio below liquidation after withdraw");
        
        // Tell the Dapps collateral was added to loan
        emit CollateralWithdrawn(msg.sender, loanID, withdrawAmount, loanAfter.collateralAmount);

        // transfer ETH to msg.sender
        msg.sender.transfer(withdrawAmount);
    }

    /**
     * @dev Repay synths to fix C-Ratio
     *
     * @param _loanCreatorsAddress the address of the loan creator
     * @param _loanID the ID of the loan
     * @param _repayAmount the amount of synths to be repaid
    */
    function repayLoan(
        address _loanCreatorsAddress,
        uint256 _loanID,
        uint256 _repayAmount
    ) external  {
        // check msg.sender has sufficient funds to pay
        require(IERC20(address(syntharb())).balanceOf(msg.sender) >= _repayAmount, "Not enough balance");

        SynthLoanStruct memory synthLoan = _getLoanFromStorage(_loanCreatorsAddress, _loanID);

        // Check loan exists and is open
        _checkLoanIsOpen(synthLoan);

        uint256 loanAmountAfter = synthLoan.loanAmount.sub(_repayAmount);

        // burn funds from msg.sender for repaid amount
        syntharb().burn(msg.sender, _repayAmount);

        // decrease issued synths
        totalIssuedSynths = totalIssuedSynths.sub(_repayAmount);

        // update loan with new total loan amount, record accrued interests
        _updateLoan(synthLoan, loanAmountAfter);

        emit LoanRepaid(_loanCreatorsAddress, _loanID, _repayAmount, loanAmountAfter);
    }

    /**
     * @dev Liquidate loans at or below issuance ratio
     * if the liquidation amount is greater or equal to the owed amount it will also trigger a closure of the loan
     *
     * @param _loanCreatorsAddress the address of the loan creator
     * @param _loanID the ID of the loan
     * @param _debtToCover the amount of synths the liquidator wants to cover
    */
    function liquidateLoan(
        address _loanCreatorsAddress,
        uint256 _loanID,
        uint256 _debtToCover
    ) external nonReentrant  {
        // check msg.sender (liquidator's wallet) has sufficient
        require(IERC20(address(syntharb())).balanceOf(msg.sender) >= _debtToCover, "Not enough balance");

        SynthLoanStruct memory synthLoan = _getLoanFromStorage(_loanCreatorsAddress, _loanID);

        // Check loan exists and is open
        _checkLoanIsOpen(synthLoan);

        (uint256 collateralRatio, uint256 collateralValue) = _loanCollateralRatio(synthLoan);

        // get prices
        syntharb().updatePrice();
        uint currentPrice = syntharb().getLatestPrice();
        uint currentEthUsdPrice = syntharb().getLatestETHUSDPrice();

        require(collateralRatio < liquidationRatio, "Collateral ratio above liquidation ratio");

        // calculate amount to liquidate to fix ratio including accrued interest
        // multiply the loan amount times current price in usd
        // collateralValue is already in usd nomination
        uint256 liquidationAmountUSD = calculateAmountToLiquidate(
            synthLoan.loanAmount.multiplyDecimal(currentPrice),
            collateralValue
        );

        // calculate back the synth amount from the usd nomination
        uint256 liquidationAmount = liquidationAmountUSD.divideDecimal(currentPrice);

        // cap debt to liquidate
        uint256 amountToLiquidate = liquidationAmount < _debtToCover ? liquidationAmount : _debtToCover;

        // burn funds from msg.sender for amount to liquidate
        syntharb().burn(msg.sender, amountToLiquidate);

        // decrease issued totalIssuedSynths
        totalIssuedSynths = totalIssuedSynths.sub(amountToLiquidate);

        // Collateral value to redeem in ETH
        uint256 collateralRedeemed = amountToLiquidate.multiplyDecimal(currentPrice).divideDecimal(currentEthUsdPrice);

        // Add penalty in ETH
        uint256 totalCollateralLiquidated = collateralRedeemed.multiplyDecimal(
            SafeDecimalMath.unit().add(LIQUIDATION_PENALTY)
        );

        // update remaining loanAmount less amount paid and update accrued interests less interest paid
        _updateLoan(synthLoan, synthLoan.loanAmount.sub(amountToLiquidate));

        // indicates if we need a full closure
        bool close;

        if (synthLoan.collateralAmount <= totalCollateralLiquidated) {
            close = true;
            // update remaining collateral on loan
            _updateLoanCollateral(synthLoan, 0);
            totalCollateralLiquidated = synthLoan.collateralAmount;
        }
        else {
            // update remaining collateral on loan
            _updateLoanCollateral(synthLoan, synthLoan.collateralAmount.sub(totalCollateralLiquidated));
        }

        // check if we have a full closure here
        if (close) {
            // emit loan liquidation event
            emit LoanLiquidated(
                _loanCreatorsAddress,
                _loanID,
                msg.sender
            );
            _closeLoan(synthLoan.account, synthLoan.loanID, true);
        } else {
            // emit loan liquidation event
            emit LoanPartiallyLiquidated(
                _loanCreatorsAddress,
                _loanID,
                msg.sender,
                amountToLiquidate,
                totalCollateralLiquidated
            );
        }

        // Send liquidated ETH collateral to msg.sender
        msg.sender.transfer(totalCollateralLiquidated);
    }

    // ========== PRIVATE FUNCTIONS ==========

    /**
     * @dev Internal function to close open loans
     *
     * @param account the account which opened the loan
     * @param loanID the ID of the loan to close
     * @param liquidation bool representing if its a user close or a liquidation close
    */
    function _closeLoan(
        address account,
        uint256 loanID,
        bool liquidation
    ) private {
        // Get the loan from storage
        SynthLoanStruct memory synthLoan = _getLoanFromStorage(account, loanID);

        // Check loan exists and is open
        _checkLoanIsOpen(synthLoan);

        // Record loan as closed
        _recordLoanClosure(synthLoan);

        if (!liquidation) {
            uint256 repayAmount = synthLoan.loanAmount;

            require(
                IERC20(address(syntharb())).balanceOf(msg.sender) >= repayAmount,
                "You do not have the required Synth balance to close this loan."
            );

            // Decrement totalIssuedSynths
            totalIssuedSynths = totalIssuedSynths.sub(synthLoan.loanAmount);

            // Burn all Synths issued for the loan + the fees
            syntharb().burn(msg.sender, repayAmount);
        }

        uint256 remainingCollateral = synthLoan.collateralAmount;

        // Tell the Dapps
        emit LoanClosed(account, loanID);

        // Send remaining collateral to loan creator
        synthLoan.account.transfer(remainingCollateral);
    }

    /**
     * @dev gets a loan struct from the storage
     *
     * @param account the account which opened the loan
     * @param loanID the ID of the loan to close
     * @return synthLoan the loan struct given the input parameters
    */
    function _getLoanFromStorage(address account, uint256 loanID) private view returns (SynthLoanStruct memory synthLoan) {
        SynthLoanStruct[] storage synthLoans = accountsSynthLoans[account];
        for (uint256 i = 0; i < synthLoans.length; i++) {
            if (synthLoans[i].loanID == loanID) {
                synthLoan = synthLoans[i];
                break;
            }
        }
    }

    /**
     * @dev updates the loan amount of a loan
     *
     * @param _synthLoan the synth loan struct representing the loan
     * @param _newLoanAmount the new loan amount to update the loan
    */
    function _updateLoan(
        SynthLoanStruct memory _synthLoan,
        uint256 _newLoanAmount
    ) private {
        // Get storage pointer to the accounts array of loans
        SynthLoanStruct[] storage synthLoans = accountsSynthLoans[_synthLoan.account];
        for (uint256 i = 0; i < synthLoans.length; i++) {
            if (synthLoans[i].loanID == _synthLoan.loanID) {
                synthLoans[i].loanAmount = _newLoanAmount;
            }
        }
    }

    /**
     * @dev updates the collateral amount of a loan
     *
     * @param _synthLoan the synth loan struct representing the loan
     * @param _newCollateralAmount the new collateral amount to update the loan
     * @return synthLoan the loan struct given the input parameters
    */
    function _updateLoanCollateral(SynthLoanStruct memory _synthLoan, uint256 _newCollateralAmount)
    private
    returns (SynthLoanStruct memory synthLoan) {
        // Get storage pointer to the accounts array of loans
        SynthLoanStruct[] storage synthLoans = accountsSynthLoans[_synthLoan.account];
        for (uint256 i = 0; i < synthLoans.length; i++) {
            if (synthLoans[i].loanID == _synthLoan.loanID) {
                synthLoans[i].collateralAmount = _newCollateralAmount;
                synthLoan = synthLoans[i];
            }
        }
    }

    /**
     * @dev records the closure of a loan
     *
     * @param synthLoan the synth loan struct representing the loan
    */
    function _recordLoanClosure(SynthLoanStruct memory synthLoan) private {
        // Get storage pointer to the accounts array of loans
        SynthLoanStruct[] storage synthLoans = accountsSynthLoans[synthLoan.account];
        for (uint256 i = 0; i < synthLoans.length; i++) {
            if (synthLoans[i].loanID == synthLoan.loanID) {
                // Record the time the loan was closed
                synthLoans[i].timeClosed = block.timestamp;
            }
        }

        // Reduce Total Open Loans Count
        totalOpenLoanCount = totalOpenLoanCount.sub(1);
    }

    /**
     * @dev Increments all global counters after a loan creation
     *
     * @return the amount of total loans created
    */
    function _incrementTotalLoansCounter() private returns (uint256) {
        // Increase the total Open loan count
        totalOpenLoanCount = totalOpenLoanCount.add(1);
        // Increase the total Loans Created count
        totalLoansCreated = totalLoansCreated.add(1);
        // Return total count to be used as a unique ID.
        return totalLoansCreated;
    }

    /**
     * @dev calculates the minting fee given the 100+ x% of eth collateral and returns x
     * e.g. input 1.02 ETH fee is set to 2% returns 0.02 ETH as the minting fee
     *
     * @param _ethAmount the amount of eth of the collateral
     * @param mintingFee the fee which is being distributed to the creator and the factory
    */
    function _calculateMintingFee(uint256 _ethAmount) private view returns (uint256 mintingFee) {
        if (issueFeeRate == 0) {
            mintingFee = 0;
        } else {
            mintingFee = _ethAmount.divideDecimalRound(10000 + issueFeeRate).multiplyDecimal(issueFeeRate);
        }

    }

    /**
     * @dev checks if a loan is pen in the system
     *
     * @param _synthLoan the synth loan struct representing the loan
    */
    function _checkLoanIsOpen(SynthLoanStruct memory _synthLoan) internal pure {
        require(_synthLoan.loanID > 0, "Loan does not exist");
        require(_synthLoan.timeClosed == 0, "Loan already closed");
    }

    /* ========== INTERNAL VIEWS ========== */

    /**
     * @dev Gets the interface of the synthetic asset
    */
    function syntharb() internal view returns (IConjure) {
        return IConjure(arbasset);
    }
}
// SPDX-License-Identifier: No License
/**
 * @title Vendor Lending Pool Implementation
 * @author 0xTaiga
 * The legend says that you'r pipi shrinks and boobs get saggy if you fork this contract.
 */
pragma solidity ^0.8.11;

import "./interfaces/IVendorOracle.sol";
import "./interfaces/ILendingPool.sol";
import "./interfaces/IFeesManager.sol";
import "./interfaces/IPoolFactory.sol";
import "./interfaces/IErrors.sol";
import "./utils/VendorUtils.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {SafeERC20Upgradeable as SafeERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract LendingPool is
    IStructs,
    IErrors,
    ILendingPool,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20 for IERC20;
    /* ========== CONSTANT VARIABLES ========== */
    uint256 private constant HUNDRED_PERCENT = 100_0000;

    /* ========== STATE VARIABLES ========== */
    IVendorOracle public priceFeed;
    IPoolFactory public factory;
    IFeesManager public feeManager;
    IERC20 public override colToken;
    IERC20 public override lendToken;
    address public treasury;
    uint256 public mintRatio;
    uint48 public expiry;
    uint48 public protocolFee;                      // 1% = 10000
    uint48 public protocolColFee;                   // 1% = 10000
    mapping(address => uint256) public borrowers;   // List of allowed borrowers. Used only when isPrivate == true
    mapping(address => UserReport) public debt;     // Registry of all borrowers and their debt
    uint256 public totalFees;                       // Sum of all outstanding fees that lenders owes fees to Vendor. Becomes zero when fees are paid.
    address public owner;                           // Creator of the pool a.k.a lender
    uint256 public disabledBorrow;                  // If lender disables borrows, different from emergency pause
    uint256 public isPrivate;                       // If true anyone can borrow, otherwise only ones in `borrowers` mapping
    uint256 public undercollateralized;             // If allows borrowing when collateral bellow mint ratio
    address private _grantedOwner;
    mapping(address => bool) public allowedRollovers;      // Pools to which we can rollover.

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice                 Initialize the pool with all the user provided settings
    /// @param data             See the IStructs for the layout
    function initialize(Data calldata data) external initializer {
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        mintRatio = data.mintRatio;
        owner = data.deployer;
        colToken = IERC20(data.colToken);
        lendToken = IERC20(data.lendToken);
        factory = IPoolFactory(data.factory);
        priceFeed = IVendorOracle(data.oracle);
        feeManager = IFeesManager(data.feesManager);
        treasury = factory.treasury();
        protocolFee = data.protocolFee;
        protocolColFee = data.protocolColFee;
        expiry = data.expiry;
        undercollateralized = data.undercollateralized;
        if (data.borrowers.length > 0) {
            isPrivate = 1;
            for (uint256 j = 0; j != data.borrowers.length; ++j) {
                borrowers[data.borrowers[j]] = 1;
            }
        }
    }

    /* ========== PUBLIC FUNCTIONS ========== */
    ///@notice                  Deposit the funds you would like to lend. Prior approval of lend token is required
    ///@dev                     One could simply just send the tokens directly to the pool
    ///@param _depositAmount    Amount of lend token to deposit into the pool
    function deposit(uint256 _depositAmount) external nonReentrant {
        onlyOwner();
        onlyNotPaused();
        _safeTransferFrom(lendToken, msg.sender, address(this), _depositAmount);
    }

    ///@notice                  Withdraw the lend token from the pool. Only amount minus fees owed to Vendor will be withdrawable
    ///@param _amount           Amount of lend token to withdraw from the pool
    function withdraw(uint256 _amount) external nonReentrant {
        onlyOwner();
        onlyNotPaused();
        if (
            lendToken.balanceOf(address(this)) <
            _amount + ((totalFees * protocolFee) / HUNDRED_PERCENT)
        ) revert InsufficientBalance();
        if (block.timestamp > expiry) revert PoolClosed(); // Collect instead
        _safeTransfer(lendToken, msg.sender, _amount);
    }

    ///@notice                  Borrow on behalf of a wallet
    ///@dev                     We assign the debt to the _borrower and we send the money to the borrower. 
    ///                         Collateral will be taken from the msg.sender.
    ///@param _borrower         User that will need to repay the loan. Collateral of the the msg.sender is used
    ///@param _colDepositAmount Amount of col token user wants to deposit as collateral
    ///@param _rate             The user expected rate should be larger than or equal to the effective rate
    ///@param _estimate         Suggested amount of debt the user should have in this pool. Used on rollovers
    function borrowOnBehalfOf(
        address _borrower,
        uint256 _colDepositAmount,
        uint256 _rate,
        uint256 _estimate
    ) external nonReentrant {
        if (disabledBorrow == 1) revert BorrowingPaused(); // If lender disabled borrowing
        onlyNotPaused();
        if (
            undercollateralized == 0 &&
            !VendorUtils._isValidPrice(address(priceFeed), address(colToken), address(lendToken), mintRatio)
        ) revert NotValidPrice();
        if (block.timestamp > expiry) revert PoolClosed();
        if (isPrivate == 1 && borrowers[msg.sender] == 0) revert PrivatePool();
        uint48 borrowRate = feeManager.getCurrentRate(address(this));
        if (_rate < borrowRate)
            revert FeeTooHigh();

        UserReport storage userReport = debt[_borrower];
        uint256 rawPayoutAmount;

        // If msg.sender is the other pool deployed by the same factory then we can use the passed _estimate as long as it is in the error range
        if (factory.pools(msg.sender)) {
            rawPayoutAmount = VendorUtils._computePayoutAmountWithEstimate(
                _colDepositAmount,
                mintRatio,
                address(colToken),
                address(lendToken),
                _estimate
            );
        } else {
            rawPayoutAmount = VendorUtils._computePayoutAmount(
                _colDepositAmount,
                mintRatio,
                address(colToken),
                address(lendToken)
            );
        }

        userReport.borrowAmount += rawPayoutAmount;
        uint256 fee = feeManager.getFee(address(this), rawPayoutAmount);
        userReport.totalFees += fee;
        _safeTransferFrom(colToken, msg.sender, address(this), _colDepositAmount);
        userReport.colAmount += _colDepositAmount;

        if (!factory.pools(msg.sender)) {
            // If this is not rollover
            if (lendToken.balanceOf(address(this)) < rawPayoutAmount)
                revert NotEnoughLiquidity();

            _safeTransfer(lendToken, _borrower, rawPayoutAmount);
        }
        emit Borrow(_borrower, _colDepositAmount, rawPayoutAmount, borrowRate);
    }

    ///@notice                  Rollover loan into a pool that has been deployed by the same lender as the original one
    ///@dev                     Pools should have same lend/col tokens and lender. New pool should have longer expiry
    ///@param _newPool          Address of the destination pool
    ///
    /// After the rollover the new pool attempts to have the same amount of debt for the user as the old one. For
    /// that reason there are three cases that we need to consider: new and old pools have same mint ratio,
    /// new pool has higher mint ratio or new pool has lower mint ratio.
    /// Same Mint Ratio - In this case we simply move the old collateral to the new pool and pass old debt.
    /// New MR > Old MR - In this case new pool gives more lend token per unit of collateral so we need less collateral to 
    /// maintain same debt. We compute the collateral amount to reimburse using the following formula:
    ///             oldColAmount * (newMR-oldMR)
    ///             ---------------------------- ;
    ///                       newMR
    /// Derivation:
    /// Assuming we have a mint ratio of pool A that is m and we also have a new pool that has a mint ratio 3m, 
    /// that we would like to rollover into, then m/3m=1/3 is the amount of collateral required to borrow the same amount
    /// of lend token in pool B. If we give 3 times more debt for unit of collateral, then we need 3 times less collateral
    /// to maintain same debt level.
    /// Now if we do that with a slightly different notation:
    /// Assuming we have a mint ratio of pool A that is m and we also have a new pool that has a mint ratio M, 
    /// that we would like to rollover into. Then m/M is the amount of collateral required to borrow the same amount of lend token in pool B. 
    /// In that case fraction of the collateral amount to reimburse is: 
    ///            m            M     m           (M-m) 
    ///       1 - ----    OR   --- - ----   OR   ------ ;
    ///            M            M     M            M
    /// If we multiply this fraction by the original collateral amount, we will get the formula above. 
    /// New MR < Old MR - In this case we need more collateral to maintain the same debt. Since we can not expect borrower
    /// to have more collateral token on hand it is easier to ask them to return a fraction of borrowed funds using formula:
    ///             oldColAmount * (oldMR - newMR) ;
    /// This formula basically computes how much over the new mint ratio you were lent given you collateral deposit.
    function rollOver(address _newPool, uint256 _rate) external nonReentrant {
        onlyNotPaused();
        if (!allowedRollovers[_newPool]) revert PoolNotWhitelisted();
        UserReport storage userReport = debt[msg.sender];
        if (block.timestamp > expiry) revert PoolClosed();
        if (userReport.borrowAmount == 0) revert NoDebt();
        ILendingPool newPool = ILendingPool(_newPool);
        VendorUtils._validateNewPool(
            _newPool,
            address(factory),
            address(lendToken),
            owner,
            expiry
        );
        if (address(newPool.colToken()) != address(colToken))
            revert DifferentColToken();
        if (newPool.isPrivate() == 1 && newPool.borrowers(msg.sender) == 0)
            revert PrivatePool();

        if (newPool.disabledBorrow() == 1) revert BorrowingPaused();
        if (
            newPool.undercollateralized() == 0 &&
            !VendorUtils._isValidPrice(
                address(priceFeed),
                address(newPool.colToken()),
                address(newPool.lendToken()),
                newPool.mintRatio()
            )
        ) revert NotValidPrice();

        uint256 borrowRate = feeManager.getCurrentRate(_newPool);
        if (_rate < borrowRate)
            revert FeeTooHigh();

        colToken.approve(_newPool, userReport.colAmount);
        uint256 diffToReimburse;
        if (newPool.mintRatio() <= mintRatio) {
            // Need to repay some loan since you can not borrow as much in a new pool
            uint256 diffToRepay = VendorUtils._computePayoutAmount(
                userReport.colAmount,
                mintRatio - newPool.mintRatio(),
                address(colToken),
                address(lendToken)
            );
            _safeTransferFrom(
                lendToken,
                msg.sender,
                address(this),
                diffToRepay + userReport.totalFees
            );
            newPool.borrowOnBehalfOf(
                msg.sender,
                userReport.colAmount,
                borrowRate,
                userReport.borrowAmount - diffToRepay
            );
        } else {
            // Reimburse the borrower
            diffToReimburse = VendorUtils._computeReimbursement(
                userReport.colAmount,
                mintRatio,
                newPool.mintRatio()
            );
            _safeTransferFrom(
                lendToken,
                msg.sender,
                address(this),
                userReport.totalFees
            );
            _safeTransfer(colToken, msg.sender, diffToReimburse);
            newPool.borrowOnBehalfOf(
                msg.sender,
                userReport.colAmount - diffToReimburse,
                borrowRate,
                userReport.borrowAmount
            );
        }
        totalFees += userReport.totalFees;

        emit RollOver(_newPool, userReport.colAmount - diffToReimburse);
        //Clean users debt in current pool
        userReport.colAmount = 0;
        userReport.borrowAmount = 0;
        userReport.totalFees = 0;
    }

    ///@notice                  Repay the loan on behalf of a different wallet
    ///@dev                     Fees are repaid first thing and then remainder is used to cover the debt
    ///@param _borrower         Wallet who's loan is going to be repaid
    ///@param _repayAmount      Amount of lend token that will be repaid
    function repayOnBehalfOf(address _borrower, uint256 _repayAmount)
        external
        nonReentrant
    {
        onlyNotPaused();
        UserReport memory userReport = debt[_borrower];
        if (block.timestamp > expiry) revert PoolClosed();
        if (_repayAmount > userReport.borrowAmount + userReport.totalFees)
            revert DebtIsLess();
        if (userReport.borrowAmount == 0) revert NoDebt();

        uint256 repayRemainder = _repayAmount;

        //Repay the fee first.
        uint256 initialFeeOwed = userReport.totalFees;
        _safeTransferFrom(lendToken, msg.sender, address(this), _repayAmount);
        if (repayRemainder <= userReport.totalFees) {
            userReport.totalFees -= repayRemainder;
            totalFees += initialFeeOwed - userReport.totalFees;
            debt[_borrower] = userReport;
            return;
        } else if (userReport.totalFees > 0) {
            repayRemainder -= userReport.totalFees;
            userReport.totalFees = 0;
        }

        totalFees += initialFeeOwed - userReport.totalFees; // Increment the lenders debt to Vendor by the fraction of fees repaid by borrower

        // If we are repaying the whole debt, then the borrow amount should be set to 0 and all collateral should be returned
        // without computation to avoid  dust remaining in the pool
        uint256 colReturnAmount = repayRemainder == userReport.borrowAmount
            ? userReport.colAmount
            : VendorUtils._computeCollateralReturn(
                repayRemainder,
                mintRatio,
                address(colToken),
                address(lendToken)
            );

        userReport.borrowAmount -= repayRemainder;
        userReport.colAmount -= colReturnAmount;
        debt[_borrower] = userReport;
        _safeTransfer(colToken, _borrower, colReturnAmount);
        emit Repay(_borrower, colReturnAmount, repayRemainder);
    }

    ///@notice                  Collect the interest, defaulted collateral and pay vendor fee
    function collect() external nonReentrant {
        onlyNotPaused();
        if (block.timestamp <= expiry) revert PoolActive();
        // Send the protocol fee to treasury
        uint256 treasuryLend = (totalFees * protocolFee) / HUNDRED_PERCENT;
        uint256 treasuryCol = (colToken.balanceOf(address(this)) * protocolColFee) / HUNDRED_PERCENT;
        _safeTransfer(
            lendToken,
            treasury,
            treasuryLend
        );
        totalFees = 0;
        _safeTransfer(
            colToken,
            treasury,
            treasuryCol
        );

        // Send the remaining funds to the lender
        uint256 lenderLend = lendToken.balanceOf(address(this));
        uint256 lenderCol = colToken.balanceOf(address(this));
        _safeTransfer(lendToken, owner, lenderLend);
        _safeTransfer(colToken, owner, lenderCol);
        emit Collect(treasuryLend, treasuryCol, lenderLend, lenderCol);
    }

    /* ========== SETTERS ========== */
    ///@notice                  Allow users to extend expiry by three days in case of emergency
    function extendExpiry() external {
        onlyOwner();
        if (!factory.allowUpgrade()) revert UpgradeNotAllowed(); //Only allow extension when we allow upgrade.
        if (block.timestamp + 3 days <= expiry) revert PoolActive();
        expiry = uint48(block.timestamp + 3 days);
        emit UpdateExpiry(expiry);
    }

    ///@notice                  Lender can stop the borrowing from this pool
    function setBorrow(uint256 _disabled) external {
        onlyOwner();
        disabledBorrow = _disabled;
        emit Pause(_disabled);
    }

    ///@notice                  Allow the lender to add a private borrower
    ///@dev                     Will not affect anything if the pool is not private
    function addBorrower(address _newBorrower) external {
        onlyOwner();
        borrowers[_newBorrower] = 1;
        emit AddBorrower(_newBorrower);
    }

    ///@notice                  Allow the lender to select rollover pools
    function setRolloverPool(address _pool, bool _enabled) external {
        onlyOwner();
        allowedRollovers[_pool] = _enabled;
    }

    /* ========== UTILITY ========== */
    ///@notice                  Pre-upgrade checks
    function _authorizeUpgrade(address newImplementation)
        internal
        view
        override
    {
        onlyOwner();
        if (
            newImplementation != factory.poolImplementationAddress() &&
            newImplementation != factory.rollBackImplementation()
        ) revert IllegalImplementation();
        if (!factory.allowUpgrade()) revert UpgradeNotAllowed();
    }

    ///@notice                  Transfer tokens with overflow protection
    ///@param _token            ERC20 token to send
    ///@param _account          Address of an account to send to
    ///@param _amount           Amount of _token to send
    function _safeTransfer(
        IERC20 _token,
        address _account,
        uint256 _amount
    ) private {
        uint256 bal = _token.balanceOf(address(this));
        if (bal < _amount) {
            _token.safeTransfer(_account, bal);
            emit BalanceChange(address(_token), false, bal);
        } else {
            _token.safeTransfer(_account, _amount);
            emit BalanceChange(address(_token), false, _amount);
        }
    }

    function _safeTransferFrom(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _amount
    ) private {
        _token.safeTransferFrom(_from, _to, _amount);
        emit BalanceChange(address(_token), true, _amount);
    }

    ///@notice                  First step in a process of changing the owner
    function grantOwnership(address _newOwner) external {
        onlyOwner();
        _grantedOwner = _newOwner;
    }

    ///@notice                  Second step in a process of changing the owner
    function claimOwnership() external {
        if (_grantedOwner != msg.sender) revert NotGranted();
        owner = _grantedOwner;
        _grantedOwner = address(0);
    }

    /* ========== MODIFIERS ========== */
    ///@notice                  Owner is the deployer of the pool, not Vendor
    function onlyOwner() private view {
        if (msg.sender != owner) revert NotOwner();
    }

    ///@notice                  This pause will be triggered by Vendor 
    function onlyNotPaused() private view {
        if (factory.isPaused(address(this))) revert OperationsPaused();
    }
}
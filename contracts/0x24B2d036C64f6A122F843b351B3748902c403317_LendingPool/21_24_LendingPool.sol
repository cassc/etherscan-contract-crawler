// SPDX-License-Identifier: No License
/**
 * @title Vendor Generic Lending Pool Implementation
 * @author 0xTaiga
 * The legend says that you'r pipi shrinks and boobs get saggy if you fork this contract.
 */

pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../../interfaces/IPositionTracker.sol";
import "../../interfaces/IGenericPool.sol";
import "../../interfaces/IFeesManager.sol";
import "../../interfaces/IPoolFactory.sol";
import "../../interfaces/IStrategy.sol";
import "../../interfaces/IOracle.sol";
import "../../utils/GenericUtils.sol";
import "./LendingPoolUtils.sol";
import "../../utils/Types.sol";
import "./ILendingPool.sol";

contract LendingPool is IGenericPool, ILendingPool, UUPSUpgradeable, ReentrancyGuardUpgradeable {
    
    PoolType private constant poolType = PoolType.LENDING_ONE_TO_MANY;
    uint256 internal constant HUNDRED_PERCENT = 100_0000;
    address private _grantedOwner;

    mapping(address => UserReport) public debts;                        // Registry of all borrowers and their debt
    mapping(address => bool) public allowedBorrowers;                   // Mapping of allowed borrowers. 
    mapping(address => bool) public allowedRollovers;                   // Pools to which we can rollover.
    GeneralPoolSettings public poolSettings;                            // All the main setting of this pool.
    uint256 public lenderTotalFees;

    IPositionTracker public positionTracker;
    IFeesManager public feesManager;
    IPoolFactory public factory;
    IStrategy public strategy;
    IOracle public oracle;
    address public treasury;
    
    /// @notice                              Acts as lending pool contract constructor when pool is deployed. This function validates params,
    ///                                      establishes user defined pool settings and factory settings, whitelists addresses for private pool
    ///                                      if applicatble, and initializes strategy if applicable.
    /// @param _factoryParametersBytes       Contains addresses for external contracts that support this pool. These params should remain constant
    ///                                      for all pools, and are passed by the pool factory, not the user.
    /// @param _poolSettingsBytes            Pool specific settings (set by user). The fields for these settings can be found in: Types.sol  
    /// @dev                                 The third bytes param is used for any kind of additional data needed in a pool. Not used in this pool type.  
    function initialize(
        bytes calldata _factoryParametersBytes,
        bytes calldata _poolSettingsBytes,
        bytes calldata /*_additionalData*/  // Not used in this type of pool.
    ) external initializer {
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        
        FactoryParameters memory _factoryParameters = abi.decode(_factoryParametersBytes, (FactoryParameters));
        GeneralPoolSettings memory _poolSettings = abi.decode(_poolSettingsBytes, (GeneralPoolSettings));
        
        factory = IPoolFactory(msg.sender);
        if (
            address(_poolSettings.colToken) == address(0) ||
            address(_poolSettings.lendToken) == address(0) ||
            _poolSettings.owner == address(0) ||
            _factoryParameters.feesManager == address(0) ||
            _factoryParameters.oracle == address(0) ||
            _factoryParameters.treasury == address(0) ||
            _factoryParameters.posTracker == address(0)
        ) revert ZeroAddress();
        if (
            _poolSettings.lendRatio == 0 ||
            _poolSettings.expiry <= block.timestamp ||
            _poolSettings.poolType != poolType
        ) revert InvalidParameters();
        poolSettings = _poolSettings;
        feesManager = IFeesManager(_factoryParameters.feesManager);
        oracle = IOracle(_factoryParameters.oracle);
        treasury = _factoryParameters.treasury;
        positionTracker = IPositionTracker(_factoryParameters.posTracker);

        if (_poolSettings.allowlist.length > 0) {
            for (uint256 j = 0; j != _poolSettings.allowlist.length;) {
                allowedBorrowers[_poolSettings.allowlist[j]] = true;
                unchecked {++j;}
            }
        }
        if (_factoryParameters.strategy != bytes32(0)){
            strategy = GenericUtils.initiateStrategy(_factoryParameters.strategy, _poolSettings.lendToken, _poolSettings.colToken);
        }
    }

    /// @notice                        Facilitates borrowing on behalf of the _borrower param address. A user shall deposit collateral
    ///                                in exchange for lend tokens. See Vendor documentation for more information on borrowing: 
    ///                                https://docs.vendor.finance/how-to-use/borrow
    /// @param _borrower               The address to which the lend funds will be sent. The entire borrow position will be setup for this borrower address, 
    ///                                the idea here being that a user could borrow on behalf of another address.
    /// @param _colDepositAmount       The amount of collateral a borrower wishes to deposit in exchange for N amount of lend tokens.
    /// @param _rate                   The borrow rate for the pool. This is passed by users to prevent possible front running by lenders.
    /// @return assetsBorrowed         The amount of lend tokens the specified _borrower address will receive._borrower
    /// @return lenderFees             The amount of lend tokens paid to lender. Also known as a lender fee.
    /// @return vendorFees             The amount of lend tokens paid to protocol. Also known as the protocol fee.
    function borrowOnBehalfOf(
        address _borrower,
        uint256 _colDepositAmount,
        uint48 _rate
    ) external nonReentrant returns (uint256 assetsBorrowed, uint256 lenderFees, uint256 vendorFees){
        uint48 effectiveBorrowRate = feesManager.getCurrentRate(address(this)); //Term fee rate that the borrower will actually be charged.
        uint48 maxLTV = poolSettings.ltv;
        IERC20 lendToken = poolSettings.lendToken;
        IERC20 colToken = poolSettings.colToken;
        uint256 lendRatio = poolSettings.lendRatio;
        // Validations
        if (_colDepositAmount == 0) revert NoDebt();
        if (factory.isPoolPaused(address(this), address(lendToken), address(colToken))) revert OperationsPaused();
        if ((poolSettings.allowlist.length > 0) && (!allowedBorrowers[_borrower])) revert PrivatePool();
        if (block.timestamp > poolSettings.expiry) revert PoolExpired();
        // Undercollateralized loans skip price check.
        if(maxLTV != type(uint48).max && !GenericUtils.isValidPrice(oracle, colToken, lendToken, lendRatio, maxLTV, poolType)) revert NotValidPrice();
        // User passed _rate must be larger or equal to the current pool's rate. Otherwise lender might front run borrow transaction and set the fee to a high number. 
        if (_rate < effectiveBorrowRate) revert FeeTooHigh();
        if (poolSettings.pauseTime <= block.timestamp) revert BorrowingPaused(); // If lender disabled borrowing. Repay and rollover out should still work.

        uint256 collateralReceived =  GenericUtils.safeTransferFrom(colToken, msg.sender, address(this), _colDepositAmount);
        // Compute the principal and the owed fees for this borrow based on the collateral passed in
        // Fees are included in the assetsBorrowed as well
        (
            lenderFees,     // Fees borrower will pay to lender
            assetsBorrowed  // Principal borrower will get before lender fee and protocol fee is subtracted
        ) = LendingPoolUtils.computeDebt(
            lendToken, 
            colToken, 
            lendRatio, 
            collateralReceived, 
            effectiveBorrowRate
        );
        UserReport storage report = debts[_borrower];
        // Start a new position tracker if does not yet exist
        if (report.debt == 0) positionTracker.openBorrowPosition(_borrower, address(this));
        // Save the users debt
        report.colAmount += collateralReceived;
        report.debt += assetsBorrowed;

        if (lendBalance() < assetsBorrowed)
            revert NotEnoughLiquidity();
        if (address(strategy) != address(0)) {
            uint256 initLendTokenBalance = lendToken.balanceOf(address(this));
            strategy.beforeLendTokensSent(assetsBorrowed- lenderFees); // We only need to withdraw the parts that need to be sent from the contract, lender fee stays. NOTE: Taxable tokens should not work with strategy. 
            if (lendToken.balanceOf(address(this)) - initLendTokenBalance < assetsBorrowed - lenderFees) revert FailedStrategyWithdraw();
        }
        // Vendor fee is charged from the loaned funds
        vendorFees = assetsBorrowed * poolSettings.protocolFee / HUNDRED_PERCENT;
        GenericUtils.safeTransfer(lendToken, treasury, vendorFees);
        GenericUtils.safeTransfer(lendToken, _borrower, assetsBorrowed - vendorFees - lenderFees);
    
        lenderTotalFees += lenderFees;
        emit Borrow(_borrower, vendorFees, lenderFees, effectiveBorrowRate, collateralReceived, assetsBorrowed);
    }

    /// @notice                         Facilitates the repayment of debt (lend tokens) on behalf of the _borrower param address.
    /// @param _borrower                The borrower address whose debt will be paid off.
    /// @param _repayAmount             The amount of lend tokens that are to be repaid. In cases where the lend token is taxable, 
    ///                                 this is the pre-tax value.
    /// @return lendTokenReceived       The actual amount of lend tokens repaid/received in this pool.
    /// @return colReturnAmount         The amount of collateral tokens returned to _borrower address when lent funds are repaid.
    function repayOnBehalfOf(
        address _borrower,
        uint256 _repayAmount
    ) external nonReentrant returns (uint256 lendTokenReceived, uint256 colReturnAmount){
        IERC20 lendToken = poolSettings.lendToken;
        IERC20 colToken = poolSettings.colToken;
        onlyNotPausedRepayments();
        if (block.timestamp > poolSettings.expiry) revert PoolExpired(); // Collateral was defaulted
        UserReport storage report = debts[_borrower];
        if (report.debt == 0) revert NoDebt();
        if (_repayAmount > report.debt)
            revert DebtIsLess();
        if (factory.pools(msg.sender)) { // If rollover
            if (_repayAmount != report.debt) revert RolloverPartialAmountNotSupported();
            if (!allowedRollovers[msg.sender]) revert PoolNotWhitelisted();
            GenericUtils.safeTransfer(colToken, msg.sender, report.colAmount);
            delete debts[_borrower];
        }else{
            lendTokenReceived = GenericUtils.safeTransferFrom(lendToken, msg.sender, address(this), _repayAmount);
            // If we are repaying the whole debt, then the borrow amount should be set to 0 and all collateral should be returned
            // without computation to avoid  dust remaining in the pool
            colReturnAmount = lendTokenReceived == report.debt
                ? report.colAmount
                : LendingPoolUtils.computeCollateralReturn(
                    lendTokenReceived,
                    poolSettings.lendRatio,
                    colToken,
                    lendToken
                );
            report.debt -= lendTokenReceived;
            report.colAmount -= colReturnAmount;
            GenericUtils.safeTransfer(colToken, _borrower, colReturnAmount);
            if (address(strategy) != address(0)) strategy.afterLendTokensReceived(lendTokenReceived);
        }
        if (report.debt == 0){
            positionTracker.closeBorrowPosition(_borrower);
        }
        emit Repay(_borrower, lendTokenReceived, colReturnAmount);
    }

    /// @notice       After pool expiry, the pool owner (lender) can collect any repaid lend funds and or any defaulted collateral.
    function collect() external nonReentrant {
        IERC20 lendToken = poolSettings.lendToken;
        IERC20 colToken = poolSettings.colToken;
        if (factory.isPoolPaused(address(this), address(lendToken), address(colToken))) revert OperationsPaused();
        if (block.timestamp <= poolSettings.expiry) revert PoolStillActive();     // Withdraw should be used before pool expiry
        if (address(strategy) != address(0)) strategy.beforeLendTokensSent(type(uint256).max);
        address owner = poolSettings.owner;
        // We record the amount that are pre-tax for taxable tokens. As far as we concerned we need to know how much we sent.
        // Receiver can compute how much they got themselves.
        uint256 lendAmount = lendToken.balanceOf(address(this));
        GenericUtils.safeTransfer(lendToken, owner, lendAmount);
        uint256 colAmount = colToken.balanceOf(address(this));
        GenericUtils.safeTransfer(colToken, owner, colAmount);

        positionTracker.closeLendPosition(owner);
        emit Collect(msg.sender, lendAmount, colAmount);
    }

    /// @notice                     The pool owner (lender) can call this function to add funds they wish to lend out into the pool.
    /// @param _depositAmount       The amount of lend tokens that a lender wishes to seed pool with. In cases where the lend token is taxable, 
    ///                             this is the pre-tax value.
    function deposit(
        uint256 _depositAmount
    ) external nonReentrant {
        IERC20 lendToken = poolSettings.lendToken;
        if (factory.isPoolPaused(address(this), address(lendToken), address(poolSettings.colToken))) revert OperationsPaused();
        if (block.timestamp > poolSettings.expiry) revert PoolExpired();
        uint256 lendTokenReceived = GenericUtils.safeTransferFrom(lendToken, msg.sender, address(this), _depositAmount);
        if (address(strategy) != address(0)) strategy.afterLendTokensReceived(lendTokenReceived);
        emit Deposit(msg.sender, lendTokenReceived);
    }

    /// @notice                  Rollover loan into a pool that has been deployed by the same lender as the original one.
    /// @dev                     Pools must have the same lend/col tokens as well as lender. New pool must also have longer expiry.
    /// @param _originPool       Address of the pool we are trying to rollover from.
    /// @param _rate             Max rate that this pool should charge the user.
    /// @param _originDebt       The original debt of the user, passed as param to reduce external calls.
    ///
    /// There are three cases that we need to consider: new and old pools have same mint ratio,
    /// new pool has higher mint ratio or new pool has lower mint ratio.
    /// Same Mint Ratio - In this case we simply move the old collateral to the new pool and pass old debt.
    /// New MR > Old MR - In this case new pool gives more lend token per unit of collateral so we need less collateral to 
    /// maintain same debt. We compute the collateral amount to reimburse using the following formula:
    ///             oldColAmount * (newMR-oldMR)
    ///             ---------------------------- ;
    ///                        newMR
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
    ///            M            M     M             M
    /// If we multiply this fraction by the original collateral amount, we will get the formula above. 
    /// Third and last case New MR < Old MR - In this case we need more collateral to maintain the same debt. Since we can not expect borrower
    /// to have more collateral token on hand it is easier to ask them to return a fraction of borrowed funds using formula:
    ///             oldColAmount * (oldMR - newMR) ;
    /// This formula basically computes how much over the new mint ratio you were lent given you collateral deposit.
    function rollInFrom(
        address _originPool,
        uint256 _originDebt,
        uint48 _rate
    ) external nonReentrant {
        ILendingPool originPool = ILendingPool(_originPool);
        GeneralPoolSettings memory settings = poolSettings; // Need to load struct, otherwise the stack depth becomes an issue
        GeneralPoolSettings memory originSettings = originPool.getPoolSettings();
        if ((settings.allowlist.length > 0) && (!allowedBorrowers[msg.sender])) revert PrivatePool();
        uint48 effectiveBorrowRate = feesManager.getCurrentRate(address(this));
        if (settings.pauseTime <= block.timestamp) revert BorrowingPaused();
        if (effectiveBorrowRate > _rate) revert FeeTooHigh();
        if (factory.isPoolPaused(address(this), address(settings.lendToken), address(settings.colToken))) revert OperationsPaused();
        if (block.timestamp > settings.expiry) revert PoolExpired();    // Can not roll into an expired pool
        LendingPoolUtils.validatePoolForRollover(
            originSettings,
            settings,
            _originPool,
            factory
        );
        uint256 colReturned;
        { // Saving some stack space
            (, uint256 colExpected) = originPool.debts(msg.sender);
            uint256 initColBalance = settings.colToken.balanceOf(address(this));
            originPool.repayOnBehalfOf(msg.sender, _originDebt);
            colReturned = settings.colToken.balanceOf(address(this)) - initColBalance;
            if (colReturned != colExpected) revert InvalidCollateralReceived();
        }
        (uint256 colToReimburse, uint256 lendToRepay) = LendingPoolUtils.computeRolloverDifferences(originSettings, settings, colReturned);
        if (colToReimburse > 0) GenericUtils.safeTransfer(settings.colToken, msg.sender, colToReimburse);

        UserReport storage report = debts[msg.sender];
        // Start a new position tracker if does not yet exist
        if (report.debt == 0) positionTracker.openBorrowPosition(msg.sender, address(this));
        // Save the users debt
        uint256 newDebt = (_originDebt - lendToRepay); // _originDebt was checked in the repayMethod of the origin pool
        report.colAmount += colReturned - colToReimburse;
        report.debt += newDebt;
        uint256 fee = (newDebt * effectiveBorrowRate) / HUNDRED_PERCENT; // Lender Fee
        lendToRepay += fee; // Add the lender fee to the amount the borrower needs to reimburse (if any) to pull all tokens at once
        lenderTotalFees += fee;
        if (GenericUtils.safeTransferFrom(settings.lendToken, msg.sender, address(this), lendToRepay) != lendToRepay) revert TransferFailed();
        uint256 protocolFee = (newDebt * settings.protocolFee) / HUNDRED_PERCENT; // Vendor fee
        if (GenericUtils.safeTransferFrom(settings.lendToken, msg.sender, treasury, protocolFee) != protocolFee) revert TransferFailed();
        if (address(strategy) != address(0)) strategy.afterLendTokensReceived(lendToRepay);

        emit RollIn(msg.sender, _originPool, _originDebt, lendToRepay - fee, fee, protocolFee, colReturned, colToReimburse);
    }

    /// @notice                      Enables the pool owner (lender) to withdraw funds they have deposited into the pool. These funds cannot 
    ///                              have been lent out yet.
    /// @param _withdrawAmount       The amount of lend tokens not currently lent out that the pool owner (lender) wishes to withdraw from the pool.
    function withdraw(
        uint256 _withdrawAmount
    ) external nonReentrant {
        onlyOwner();
        IERC20 lendToken = poolSettings.lendToken;
        if (factory.isPoolPaused(address(this), address(lendToken), address(poolSettings.colToken))) revert OperationsPaused();
        if (block.timestamp > poolSettings.expiry) revert PoolExpired();    // Use collect after expiry of the pool
        uint256 balanceChange;
        uint256 availableLendBalance;
        if (address(strategy) != address(0)) {
            uint256 initLendTokenBalance = lendToken.balanceOf(address(this));
            strategy.beforeLendTokensSent(_withdrawAmount); // Taxable tokens should not work with strategy.
            balanceChange = lendToken.balanceOf(address(this)) - initLendTokenBalance;
            availableLendBalance = balanceChange;
            if (_withdrawAmount != type(uint256).max && balanceChange < _withdrawAmount) revert FailedStrategyWithdraw();
        } else {
            balanceChange = _withdrawAmount;
            availableLendBalance = lendToken.balanceOf(address(this));
        }
        lenderTotalFees = _withdrawAmount < lenderTotalFees ? lenderTotalFees - _withdrawAmount : 0;
        // availableLendBalance < balanceChange when we want to withdraw the whole pool by passing the uint256.max and no strat
        // availableLendBalance > balanceChange when we only withdraw a part of the lend funds
        _withdrawAmount = availableLendBalance > balanceChange ? balanceChange : availableLendBalance;
        GenericUtils.safeTransfer(lendToken, poolSettings.owner, _withdrawAmount);

        emit Withdraw(msg.sender, _withdrawAmount);
    }

    /// @notice       In cases where pool is using a strategy, the pool owner (lender) can withdraw the actual share tokens 
    ///               representing their underlying lend tokens. For more information about strategies, see: https://docs.vendor.finance/overview/what-is-vendor-finance
    /// @dev          Shares represent invested idle funds, thus I should be able to withdraw them without issues.
    function withdrawStrategyTokens() external nonReentrant {
        onlyOwner();
        if (factory.isPoolPaused(address(this), address(poolSettings.lendToken), address(poolSettings.colToken))) 
            revert OperationsPaused();
        if (address(strategy) == address(0)) revert FailedStrategyWithdraw();
        delete lenderTotalFees; // Assuming there is a strat all lender fees are there. If we pool all funds from strat, that means we also pull the fees.
        // Assumption that is made here is that destination is ERC20 compatible, otherwise it will revert. For example a ERC4626 vault.
        uint256 sharesAmount = IERC20(strategy.getDestination()).balanceOf(address(this));
        GenericUtils.safeTransfer(IERC20(strategy.getDestination()), poolSettings.owner, sharesAmount);
        emit WithdrawStrategyTokens(sharesAmount);
    }

    /// @notice                Allows the lender to whitelist or blacklist an address in a private pool
    /// @param _borrower       Address to whitelist or blacklist in private pool.
    /// @param _allowed        Determines whether provided address will be whitelisted or blacklisted.
    /// @dev                   Will not affect anything if the pool is not private
    function updateBorrower(address _borrower, bool _allowed) external {
        onlyOwner();
        if (factory.isPoolPaused(address(this), address(poolSettings.lendToken), address(poolSettings.colToken))) 
            revert OperationsPaused();
        if (poolSettings.allowlist.length == 0) revert NotPrivatePool();
        allowedBorrowers[_borrower] = _allowed;
        emit UpdateBorrower(_borrower, _allowed);
    }

    /// @notice                First step in a process of changing the owner.
    /// @param _newOwner       Address to be made pool owner. 
    function grantOwnership(address _newOwner) external {
        onlyOwner();
        _grantedOwner = _newOwner;
    }

    /// @notice       Second step in the process of changing the owner. The set owner in step1 calls this fc to claim ownership.
    function claimOwnership() external {
        if (_grantedOwner != msg.sender) revert NotGranted();
        emit OwnershipTransferred(poolSettings.owner, _grantedOwner);
        poolSettings.owner = _grantedOwner;
        _grantedOwner = address(0);
    }

    /* ========== SETTERS ========== */
    /// @notice               Allow the lender to select rollover pools.
    /// @param _pool          The pool address the pool owner (lender) would like to whitelist or black list for rollovers.
    /// @param _enabled       Determines whether the _pool param address is whitelisted or blacklisted.
    function setRolloverPool(address _pool, bool _enabled) external {
        onlyOwner();
        allowedRollovers[_pool] = _enabled;
        emit RolloverPoolSet(_pool, _enabled);
    }

    /// @notice                    Sets new rates for lending pool.
    /// @param _ratesAndType       The bytes string used to set rates.
    /// @dev                       Setting fees should be done via the pool and not directly in FeesManager contract for two reasons:
    ///                            - 1) All changes to this contract should be visible by tracking transactions to this contract. 
    ///                            - 2) Different pool types might have different fee changing rules so we can ensure they are followed.
    function setPoolRates(bytes32 _ratesAndType) external {
        onlyOwner();
        if (factory.isPoolPaused(address(this), address(poolSettings.lendToken), address(poolSettings.colToken))) 
            revert OperationsPaused();
        feesManager.setPoolRates(address(this), _ratesAndType, poolSettings.expiry, poolSettings.protocolFee);
    }

    /// @notice                 Pool owner (lender) can pause borrowing for this pool
    /// @param _timestamp       The timestamp that denotes when borrowing for this pool is to be paused.
    function setPauseBorrowing(uint48 _timestamp) external {
        onlyOwner();
        if (factory.isPoolPaused(address(this), address(poolSettings.lendToken), address(poolSettings.colToken))) 
            revert OperationsPaused();
        poolSettings.pauseTime = _timestamp;
        emit Pause(_timestamp);
    }

    /* ========== GETTERS ========== */
    /// @return       Returns the pool settings used in this pool.
    function getPoolSettings() external view returns (GeneralPoolSettings memory){
        return poolSettings;
    }

    /// @return       The amount of lend funds that are available to be lent out.
    function lendBalance() public view returns (uint256) {
        uint256 fullLendTokenBalance = address(strategy) == address(0) ? poolSettings.lendToken.balanceOf(address(this)) : strategy.currentBalance();
        // Due to rounding it is possible that strat returns a few wei less than actual fees earned. To avoid revert send 0.
        // On rollover it is possible that lender fees are present since they are paid up front but there was no deposits for lending. In this case entire strategy balance 
        // consists of rollover fees. They should not be borrowable. 
        return fullLendTokenBalance <= lenderTotalFees ? 0 : fullLendTokenBalance - lenderTotalFees; 
    }

    /// @return       The total balance of collateral tokens in pool.
    function colBalance() public view returns (uint256) {        
        return poolSettings.colToken.balanceOf(address(this));  
    }

    /* ========== MODIFIERS ========== */
    /// @notice       Validates that the caller is the pool owner (lender).
    function onlyOwner() private view {
        if (msg.sender != poolSettings.owner) revert NotOwner();
    }

    /// @notice       Validates that the pool has not been paused by the pool factory. 
    function onlyNotPausedRepayments() private view {
        if (factory.repaymentsPaused()) revert OperationsPaused();
    }

    /* ========== UPGRADES ========== */
    /// @notice                  Contract version for history.
    /// @return                  Contract version.
    function version() external pure returns (uint256) {
        return 1;
    }

    /// @notice      Allows for the upgrade of pool to new implementation.
    function _authorizeUpgrade(address newImplementation)
        internal
        view
        override
    {
        onlyOwner();
        if (!factory.allowUpgrade()) revert UpgradeNotAllowed();
        if (newImplementation != factory.implementations(poolType)) revert ImplementationNotWhitelisted();
    }
  
}
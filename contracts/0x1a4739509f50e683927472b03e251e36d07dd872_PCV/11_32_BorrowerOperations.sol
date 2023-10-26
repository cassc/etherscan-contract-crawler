// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./Interfaces/IBorrowerOperations.sol";
import "./Interfaces/ITroveManager.sol";
import "./Interfaces/ITHUSDToken.sol";
import "./Interfaces/ICollSurplusPool.sol";
import "./Interfaces/ISortedTroves.sol";
import "./Interfaces/IPCV.sol";
import "./Dependencies/LiquityBase.sol";
import "./Dependencies/Ownable.sol";
import "./Dependencies/CheckContract.sol";
import "./Dependencies/SendCollateral.sol";

contract BorrowerOperations is LiquityBase, Ownable, CheckContract, SendCollateral, IBorrowerOperations {

    string constant public NAME = "BorrowerOperations";

    // --- Connected contract declarations ---

    ITroveManager public troveManager;

    address public collateralAddress;
    address public gasPoolAddress;
    address public pcvAddress;
    address public stabilityPoolAddress;

    ICollSurplusPool collSurplusPool;

    ITHUSDToken public thusdToken;

    // A doubly linked list of Troves, sorted by their collateral ratios
    ISortedTroves public sortedTroves;

    /* --- Variable container structs  ---

    Used to hold, return and assign variables inside a function, in order to avoid the error:
    "CompilerError: Stack too deep". */

    struct LocalVariables_adjustTrove {
        uint256 price;
        uint256 collChange;
        uint256 netDebtChange;
        bool isCollIncrease;
        uint256 debt;
        uint256 coll;
        uint256 oldICR;
        uint256 newICR;
        uint256 newTCR;
        uint256 THUSDFee;
        uint256 newDebt;
        uint256 newColl;
        uint256 stake;
    }

    struct LocalVariables_openTrove {
        uint256 price;
        uint256 THUSDFee;
        uint256 netDebt;
        uint256 compositeDebt;
        uint256 ICR;
        uint256 NICR;
        uint256 stake;
        uint256 arrayIndex;
    }

    struct ContractsCache {
        ITroveManager troveManager;
        IActivePool activePool;
        ITHUSDToken thusdToken;
    }

    enum BorrowerOperation {
        openTrove,
        closeTrove,
        adjustTrove
    }

    event TroveUpdated(address indexed _borrower, uint256 _debt, uint256 _coll, uint256 stake, BorrowerOperation operation);
    // --- Dependency setters ---

    function setAddresses(
        address _troveManagerAddress,
        address _activePoolAddress,
        address _defaultPoolAddress,
        address _stabilityPoolAddress,
        address _gasPoolAddress,
        address _collSurplusPoolAddress,
        address _priceFeedAddress,
        address _sortedTrovesAddress,
        address _thusdTokenAddress,
        address _pcvAddress,
        address _collateralAddress
    )
        external
        override
        onlyOwner
    {
        // This makes impossible to open a trove with zero withdrawn THUSD
        assert(MIN_NET_DEBT > 0);

        checkContract(_troveManagerAddress);
        checkContract(_activePoolAddress);
        checkContract(_defaultPoolAddress);
        checkContract(_stabilityPoolAddress);
        checkContract(_gasPoolAddress);
        checkContract(_collSurplusPoolAddress);
        checkContract(_priceFeedAddress);
        checkContract(_sortedTrovesAddress);
        checkContract(_thusdTokenAddress);
        checkContract(_pcvAddress);
        if (_collateralAddress != address(0)) {
            checkContract(_collateralAddress);
        }

        troveManager = ITroveManager(_troveManagerAddress);
        activePool = IActivePool(_activePoolAddress);
        defaultPool = IDefaultPool(_defaultPoolAddress);
        stabilityPoolAddress = _stabilityPoolAddress;
        gasPoolAddress = _gasPoolAddress;
        collSurplusPool = ICollSurplusPool(_collSurplusPoolAddress);
        priceFeed = IPriceFeed(_priceFeedAddress);
        sortedTroves = ISortedTroves(_sortedTrovesAddress);
        thusdToken = ITHUSDToken(_thusdTokenAddress);
        pcvAddress = _pcvAddress;
        collateralAddress = _collateralAddress;
        
        require(
            (Ownable(_defaultPoolAddress).owner() != address(0) || 
            defaultPool.collateralAddress() == _collateralAddress) &&
            (Ownable(_activePoolAddress).owner() != address(0) || 
            activePool.collateralAddress() == _collateralAddress) &&
            (Ownable(_stabilityPoolAddress).owner() != address(0) || 
            IStabilityPool(stabilityPoolAddress).collateralAddress() == _collateralAddress) &&
            (Ownable(_collSurplusPoolAddress).owner() != address(0) || 
            collSurplusPool.collateralAddress() == _collateralAddress) &&
            (address(IPCV(pcvAddress).thusdToken()) == address(0) || 
            address(IPCV(pcvAddress).collateralERC20()) == _collateralAddress),
            "The same collateral address must be used for the entire set of contracts"
        );

        emit TroveManagerAddressChanged(_troveManagerAddress);
        emit ActivePoolAddressChanged(_activePoolAddress);
        emit DefaultPoolAddressChanged(_defaultPoolAddress);
        emit StabilityPoolAddressChanged(_stabilityPoolAddress);
        emit GasPoolAddressChanged(_gasPoolAddress);
        emit CollSurplusPoolAddressChanged(_collSurplusPoolAddress);
        emit PriceFeedAddressChanged(_priceFeedAddress);
        emit SortedTrovesAddressChanged(_sortedTrovesAddress);
        emit THUSDTokenAddressChanged(_thusdTokenAddress);
        emit PCVAddressChanged(_pcvAddress);
        emit CollateralAddressChanged(_collateralAddress);

        _renounceOwnership();
    }

    /// Calls on PCV behalf
    function mintBootstrapLoanFromPCV(uint256 _thusdToMint) external {
        require(msg.sender == pcvAddress, "BorrowerOperations: caller must be PCV");
        thusdToken.mint(pcvAddress, _thusdToMint);
    }

    function burnDebtFromPCV(uint256 _thusdToBurn) external {
        require(msg.sender == pcvAddress, "BorrowerOperations: caller must be PCV");
        thusdToken.burn(pcvAddress, _thusdToBurn);
    }

    // --- Borrower Trove Operations ---

    function openTrove(uint256 _maxFeePercentage, uint256 _THUSDAmount, uint256 _assetAmount, address _upperHint, address _lowerHint) external payable override {
        ContractsCache memory contractsCache = ContractsCache(troveManager, activePool, thusdToken);
        LocalVariables_openTrove memory vars;

        vars.price = priceFeed.fetchPrice();
        bool isRecoveryMode = _checkRecoveryMode(vars.price);

        _requireValidMaxFeePercentage(_maxFeePercentage, isRecoveryMode);
        _requireTroveisNotActive(contractsCache.troveManager, msg.sender);

        vars.THUSDFee;
        vars.netDebt = _THUSDAmount;

        if (!isRecoveryMode) {
            vars.THUSDFee = _triggerBorrowingFee(contractsCache.troveManager, contractsCache.thusdToken, _THUSDAmount, _maxFeePercentage);
            vars.netDebt += vars.THUSDFee;
        }

        _requireAtLeastMinNetDebt(vars.netDebt);

        // ICR is based on the composite debt, i.e. the requested THUSD amount + THUSD borrowing fee + THUSD gas comp.
        vars.compositeDebt = _getCompositeDebt(vars.netDebt);
        assert(vars.compositeDebt > 0);

        // if ETH overwrite the asset value
        _assetAmount = getAssetAmount(_assetAmount);
        vars.ICR = LiquityMath._computeCR(_assetAmount, vars.compositeDebt, vars.price);
        vars.NICR = LiquityMath._computeNominalCR(_assetAmount, vars.compositeDebt);

        if (isRecoveryMode) {
            _requireICRisAboveCCR(vars.ICR);
        } else {
            _requireICRisAboveMCR(vars.ICR);
            uint256 newTCR = _getNewTCRFromTroveChange(_assetAmount, true, vars.compositeDebt, true, vars.price);  // bools: coll increase, debt increase
            _requireNewTCRisAboveCCR(newTCR);
        }

        // Set the trove struct's properties
        contractsCache.troveManager.setTroveStatus(msg.sender, ITroveManager.Status.active);
        contractsCache.troveManager.increaseTroveColl(msg.sender, _assetAmount);
        contractsCache.troveManager.increaseTroveDebt(msg.sender, vars.compositeDebt);

        contractsCache.troveManager.updateTroveRewardSnapshots(msg.sender);
        vars.stake = contractsCache.troveManager.updateStakeAndTotalStakes(msg.sender);

        sortedTroves.insert(msg.sender, vars.NICR, _upperHint, _lowerHint);
        vars.arrayIndex = contractsCache.troveManager.addTroveOwnerToArray(msg.sender);
        emit TroveCreated(msg.sender, vars.arrayIndex);

        /*
         * Move the collateral to the Active Pool, and mint the THUSDAmount to the borrower
         * If the user has insuffient tokens to do the transfer to the Active Pool an error will cause the transaction to revert.
         */
        _activePoolAddColl(contractsCache.activePool, _assetAmount);
        _withdrawTHUSD(contractsCache.activePool, contractsCache.thusdToken, msg.sender, _THUSDAmount, vars.netDebt);
        // Move the THUSD gas compensation to the Gas Pool
        _withdrawTHUSD(contractsCache.activePool, contractsCache.thusdToken, gasPoolAddress, THUSD_GAS_COMPENSATION, THUSD_GAS_COMPENSATION);

        emit TroveUpdated(msg.sender, vars.compositeDebt, _assetAmount, vars.stake, BorrowerOperation.openTrove);
        emit THUSDBorrowingFeePaid(msg.sender, vars.THUSDFee);
    }

    // Send collateral to a trove
    function addColl(uint256 _assetAmount, address _upperHint, address _lowerHint) external payable override {
        _assetAmount = getAssetAmount(_assetAmount);
        _adjustTrove(msg.sender, 0, 0, false, _assetAmount, _upperHint, _lowerHint, 0);
    }

    // Send collateral to a trove. Called by only the Stability Pool.
    function moveCollateralGainToTrove(address _borrower, uint256 _assetAmount, address _upperHint, address _lowerHint) external payable override {
        _requireCallerIsStabilityPool();
        _assetAmount = getAssetAmount(_assetAmount);
        _adjustTrove(_borrower, 0, 0, false, _assetAmount, _upperHint, _lowerHint, 0);
    }

    function getAssetAmount(uint256 _assetAmount) internal view returns (uint256) {
        if (collateralAddress == address(0)) {
            return msg.value;
        }

        require(msg.value == 0, "BorrowerOperations: ERC20 collateral needed, not ETH");
        return _assetAmount;
    }

    // Withdraw collateral from a trove
    function withdrawColl(uint256 _collWithdrawal, address _upperHint, address _lowerHint) external override {
        _adjustTrove(msg.sender, _collWithdrawal, 0, false, 0, _upperHint, _lowerHint, 0);
    }

    // Withdraw THUSD tokens from a trove: mint new THUSD tokens to the owner, and increase the trove's debt accordingly
    function withdrawTHUSD(uint256 _maxFeePercentage, uint256 _THUSDAmount, address _upperHint, address _lowerHint) external override {
        _adjustTrove(msg.sender, 0, _THUSDAmount, true, 0, _upperHint, _lowerHint, _maxFeePercentage);
    }

    // Repay THUSD tokens to a Trove: Burn the repaid THUSD tokens, and reduce the trove's debt accordingly
    function repayTHUSD(uint256 _THUSDAmount, address _upperHint, address _lowerHint) external override {
        _adjustTrove(msg.sender, 0, _THUSDAmount, false, 0, _upperHint, _lowerHint, 0);
    }

    function adjustTrove(uint256 _maxFeePercentage, uint256 _collWithdrawal, uint256 _THUSDChange, bool _isDebtIncrease, uint256 _assetAmount, address _upperHint, address _lowerHint) external payable override {
        _assetAmount = getAssetAmount(_assetAmount);
        _adjustTrove(msg.sender, _collWithdrawal, _THUSDChange, _isDebtIncrease, _assetAmount, _upperHint, _lowerHint, _maxFeePercentage);
    }

    /*
    * _adjustTrove(): Alongside a debt change, this function can perform either a collateral top-up or a collateral withdrawal.
    *
    * It therefore expects either a positive msg.value, or a positive _collWithdrawal argument.
    *
    * If both are positive, it will revert.
    */
    function _adjustTrove(address _borrower, uint256 _collWithdrawal, uint256 _THUSDChange, bool _isDebtIncrease, uint256 _assetAmount, address _upperHint, address _lowerHint, uint256 _maxFeePercentage) internal {
        ContractsCache memory contractsCache = ContractsCache(troveManager, activePool, thusdToken);
        LocalVariables_adjustTrove memory vars;

        vars.price = priceFeed.fetchPrice();
        bool isRecoveryMode = _checkRecoveryMode(vars.price);

        if (_isDebtIncrease) {
            _requireValidMaxFeePercentage(_maxFeePercentage, isRecoveryMode);
            _requireNonZeroDebtChange(_THUSDChange);
        }
        _requireSingularCollChange(_collWithdrawal, _assetAmount);
        _requireNonZeroAdjustment(_collWithdrawal, _THUSDChange, _assetAmount);
        _requireTroveisActive(contractsCache.troveManager, _borrower);

        // Confirm the operation is either a borrower adjusting their own trove, or a pure collateral transfer from the Stability Pool to a trove
        assert(msg.sender == _borrower || (msg.sender == stabilityPoolAddress && _assetAmount > 0 && _THUSDChange == 0));

        contractsCache.troveManager.applyPendingRewards(_borrower);

        // Get the collChange based on whether or not collateral was sent in the transaction
        (vars.collChange, vars.isCollIncrease) = _getCollChange(_assetAmount, _collWithdrawal);

        vars.netDebtChange = _THUSDChange;

        // If the adjustment incorporates a debt increase and system is in Normal Mode, then trigger a borrowing fee
        if (_isDebtIncrease && !isRecoveryMode) {
            vars.THUSDFee = _triggerBorrowingFee(contractsCache.troveManager, contractsCache.thusdToken, _THUSDChange, _maxFeePercentage);
            vars.netDebtChange += vars.THUSDFee; // The raw debt change includes the fee
        }

        vars.debt = contractsCache.troveManager.getTroveDebt(_borrower);
        vars.coll = contractsCache.troveManager.getTroveColl(_borrower);

        // Get the trove's old ICR before the adjustment, and what its new ICR will be after the adjustment
        vars.oldICR = LiquityMath._computeCR(vars.coll, vars.debt, vars.price);
        vars.newICR = _getNewICRFromTroveChange(vars.coll, vars.debt, vars.collChange, vars.isCollIncrease, vars.netDebtChange, _isDebtIncrease, vars.price);
        assert(_collWithdrawal <= vars.coll);

        // Check the adjustment satisfies all conditions for the current system mode
        _requireValidAdjustmentInCurrentMode(isRecoveryMode, _collWithdrawal, _isDebtIncrease, vars);

        // When the adjustment is a debt repayment, check it's a valid amount and that the caller has enough THUSD
        if (!_isDebtIncrease && _THUSDChange > 0) {
            _requireAtLeastMinNetDebt(_getNetDebt(vars.debt) - vars.netDebtChange);
            _requireValidTHUSDRepayment(vars.debt, vars.netDebtChange);
            _requireSufficientTHUSDBalance(contractsCache.thusdToken, _borrower, vars.netDebtChange);
        }

        (vars.newColl, vars.newDebt) = _updateTroveFromAdjustment(contractsCache.troveManager, _borrower, vars.collChange, vars.isCollIncrease, vars.netDebtChange, _isDebtIncrease);
        vars.stake = contractsCache.troveManager.updateStakeAndTotalStakes(_borrower);

        // Re-insert trove in to the sorted list
        uint256 newNICR = _getNewNominalICRFromTroveChange(vars.coll, vars.debt, vars.collChange, vars.isCollIncrease, vars.netDebtChange, _isDebtIncrease);
        sortedTroves.reInsert(_borrower, newNICR, _upperHint, _lowerHint);

        emit TroveUpdated(_borrower, vars.newDebt, vars.newColl, vars.stake, BorrowerOperation.adjustTrove);
        emit THUSDBorrowingFeePaid(msg.sender,  vars.THUSDFee);

        // Use the unmodified _THUSDChange here, as we don't send the fee to the user
        _moveTokensAndCollateralfromAdjustment(
            contractsCache.activePool,
            contractsCache.thusdToken,
            msg.sender,
            vars.collChange,
            vars.isCollIncrease,
            _THUSDChange,
            _isDebtIncrease,
            vars.netDebtChange
        );
    }

    function closeTrove() external override {
        ITroveManager troveManagerCached = troveManager;
        IActivePool activePoolCached = activePool;
        ITHUSDToken thusdTokenCached = thusdToken;
        bool canMint = thusdTokenCached.mintList(address(this));

        _requireTroveisActive(troveManagerCached, msg.sender);
        uint256 price = priceFeed.fetchPrice();
        if (canMint) {
            _requireNotInRecoveryMode(price);
        }

        troveManagerCached.applyPendingRewards(msg.sender);

        uint256 coll = troveManagerCached.getTroveColl(msg.sender);
        uint256 debt = troveManagerCached.getTroveDebt(msg.sender);

        _requireSufficientTHUSDBalance(thusdTokenCached, msg.sender, debt - THUSD_GAS_COMPENSATION);
        if (canMint) {
            uint256 newTCR = _getNewTCRFromTroveChange(coll, false, debt, false, price);
            _requireNewTCRisAboveCCR(newTCR);
        }

        troveManagerCached.removeStake(msg.sender);
        troveManagerCached.closeTrove(msg.sender);

        emit TroveUpdated(msg.sender, 0, 0, 0, BorrowerOperation.closeTrove);

        // Burn the repaid THUSD from the user's balance and the gas compensation from the Gas Pool
        _repayTHUSD(activePoolCached, thusdTokenCached, msg.sender, debt - THUSD_GAS_COMPENSATION);
        _repayTHUSD(activePoolCached, thusdTokenCached, gasPoolAddress, THUSD_GAS_COMPENSATION);

        // Send the collateral back to the user
        activePoolCached.sendCollateral(msg.sender, coll);
    }

    /**
     * Claim remaining collateral from a redemption or from a liquidation with ICR > MCR in Recovery Mode
     */
    function claimCollateral() external override {
        // send collateral from CollSurplus Pool to owner
        collSurplusPool.claimColl(msg.sender);
    }

    // --- Helper functions ---

    function _triggerBorrowingFee(ITroveManager _troveManager, ITHUSDToken _thusdToken, uint256 _THUSDAmount, uint256 _maxFeePercentage) internal returns (uint) {
        _troveManager.decayBaseRateFromBorrowing(); // decay the baseRate state variable
        uint256 THUSDFee = _troveManager.getBorrowingFee(_THUSDAmount);

        _requireUserAcceptsFee(THUSDFee, _THUSDAmount, _maxFeePercentage);

        // Send fee to PCV contract
        _thusdToken.mint(pcvAddress, THUSDFee);
        return THUSDFee;
    }

    function _getUSDValue(uint256 _coll, uint256 _price) internal pure returns (uint) {
        uint256 usdValue = _price * _coll / DECIMAL_PRECISION;

        return usdValue;
    }

    function _getCollChange(
        uint256 _collReceived,
        uint256 _requestedCollWithdrawal
    )
        internal
        pure
        returns(uint256 collChange, bool isCollIncrease)
    {
        if (_collReceived != 0) {
            collChange = _collReceived;
            isCollIncrease = true;
        } else {
            collChange = _requestedCollWithdrawal;
        }
    }

    // Update trove's coll and debt based on whether they increase or decrease
    function _updateTroveFromAdjustment
    (
        ITroveManager _troveManager,
        address _borrower,
        uint256 _collChange,
        bool _isCollIncrease,
        uint256 _debtChange,
        bool _isDebtIncrease
    )
        internal
        returns (uint, uint)
    {
        uint256 newColl = (_isCollIncrease) ? _troveManager.increaseTroveColl(_borrower, _collChange)
                                        : _troveManager.decreaseTroveColl(_borrower, _collChange);
        uint256 newDebt = (_isDebtIncrease) ? _troveManager.increaseTroveDebt(_borrower, _debtChange)
                                        : _troveManager.decreaseTroveDebt(_borrower, _debtChange);

        return (newColl, newDebt);
    }

    function _moveTokensAndCollateralfromAdjustment
    (
        IActivePool _activePool,
        ITHUSDToken _thusdToken,
        address _borrower,
        uint256 _collChange,
        bool _isCollIncrease,
        uint256 _THUSDChange,
        bool _isDebtIncrease,
        uint256 _netDebtChange
    )
        internal
    {
        if (_isDebtIncrease) {
            _withdrawTHUSD(_activePool, _thusdToken, _borrower, _THUSDChange, _netDebtChange);
        } else {
            _repayTHUSD(_activePool, _thusdToken, _borrower, _THUSDChange);
        }

        if (_isCollIncrease) {
            _activePoolAddColl(_activePool, _collChange);
        } else {
            _activePool.sendCollateral(_borrower, _collChange);
        }
    }

    // Send collateral to Active Pool and increase its recorded collateral balance
    function _activePoolAddColl(IActivePool _activePool, uint256 _amount) internal {
        sendCollateralFrom(IERC20(collateralAddress), msg.sender, address(_activePool), _amount);

        if (collateralAddress == address(0)) {
            return;
        }
        _activePool.updateCollateralBalance(_amount);
    }

    // Issue the specified amount of THUSD to _account and increases the total active debt (_netDebtIncrease potentially includes a THUSDFee)
    function _withdrawTHUSD(IActivePool _activePool, ITHUSDToken _thusdToken, address _account, uint256 _THUSDAmount, uint256 _netDebtIncrease) internal {
        _activePool.increaseTHUSDDebt(_netDebtIncrease);
        _thusdToken.mint(_account, _THUSDAmount);
    }

    // Burn the specified amount of THUSD from _account and decreases the total active debt
    function _repayTHUSD(IActivePool _activePool, ITHUSDToken _thusdToken, address _account, uint256 _THUSD) internal {
        _activePool.decreaseTHUSDDebt(_THUSD);
        _thusdToken.burn(_account, _THUSD);
    }

    // --- 'Require' wrapper functions ---

    function _requireSingularCollChange(uint256 _collWithdrawal, uint256 _assetAmount) internal pure {
        require(_assetAmount == 0 || _collWithdrawal == 0, "BorrowerOperations: Cannot withdraw and add coll");
    }

    function _requireCallerIsBorrower(address _borrower) internal view {
        require(msg.sender == _borrower, "BorrowerOps: Caller must be the borrower for a withdrawal");
    }

    function _requireNonZeroAdjustment(uint256 _collWithdrawal, uint256 _THUSDChange, uint256 _assetAmount) internal pure {
        require(_assetAmount != 0 || _collWithdrawal != 0 || _THUSDChange != 0, "BorrowerOps: There must be either a collateral change or a debt change");
    }

    function _requireTroveisActive(ITroveManager _troveManager, address _borrower) internal view {
        ITroveManager.Status status = _troveManager.getTroveStatus(_borrower);
        require(status == ITroveManager.Status.active, "BorrowerOps: Trove does not exist or is closed");
    }

    function _requireTroveisNotActive(ITroveManager _troveManager, address _borrower) internal view {
        ITroveManager.Status status = _troveManager.getTroveStatus(_borrower);
        require(status != ITroveManager.Status.active, "BorrowerOps: Trove is active");
    }

    function _requireNonZeroDebtChange(uint256 _THUSDChange) internal pure {
        require(_THUSDChange > 0, "BorrowerOps: Debt increase requires non-zero debtChange");
    }

    function _requireNotInRecoveryMode(uint256 _price) internal view {
        require(!_checkRecoveryMode(_price), "BorrowerOps: Operation not permitted during Recovery Mode");
    }

    function _requireNoCollWithdrawal(uint256 _collWithdrawal) internal pure {
        require(_collWithdrawal == 0, "BorrowerOps: Collateral withdrawal not permitted Recovery Mode");
    }

    function _requireValidAdjustmentInCurrentMode
    (
        bool _isRecoveryMode,
        uint256 _collWithdrawal,
        bool _isDebtIncrease,
        LocalVariables_adjustTrove memory _vars
    )
        internal
        view
    {
        /*
         *In Recovery Mode, only allow:
         *
         * - Pure collateral top-up
         * - Pure debt repayment
         * - Collateral top-up with debt repayment
         * - A debt increase combined with a collateral top-up which makes the ICR >= 150% and improves the ICR (and by extension improves the TCR).
         *
         * In Normal Mode, ensure:
         *
         * - The new ICR is above MCR
         * - The adjustment won't pull the TCR below CCR
         */
        if (_isRecoveryMode) {
            _requireNoCollWithdrawal(_collWithdrawal);
            if (_isDebtIncrease) {
                _requireICRisAboveCCR(_vars.newICR);
                _requireNewICRisAboveOldICR(_vars.newICR, _vars.oldICR);
            }
        } else { // if Normal Mode
            _requireICRisAboveMCR(_vars.newICR);
            _vars.newTCR = _getNewTCRFromTroveChange(_vars.collChange, _vars.isCollIncrease, _vars.netDebtChange, _isDebtIncrease, _vars.price);
            _requireNewTCRisAboveCCR(_vars.newTCR);
        }
    }

    function _requireICRisAboveMCR(uint256 _newICR) internal pure {
        require(_newICR >= MCR, "BorrowerOps: An operation that would result in ICR < MCR is not permitted");
    }

    function _requireICRisAboveCCR(uint256 _newICR) internal pure {
        require(_newICR >= CCR, "BorrowerOps: Operation must leave trove with ICR >= CCR");
    }

    function _requireNewICRisAboveOldICR(uint256 _newICR, uint256 _oldICR) internal pure {
        require(_newICR >= _oldICR, "BorrowerOps: Cannot decrease your Trove's ICR in Recovery Mode");
    }

    function _requireNewTCRisAboveCCR(uint256 _newTCR) internal pure {
        require(_newTCR >= CCR, "BorrowerOps: An operation that would result in TCR < CCR is not permitted");
    }

    function _requireAtLeastMinNetDebt(uint256 _netDebt) internal pure {
        require (_netDebt >= MIN_NET_DEBT, "BorrowerOps: Trove's net debt must be greater than minimum");
    }

    function _requireValidTHUSDRepayment(uint256 _currentDebt, uint256 _debtRepayment) internal pure {
        require(_debtRepayment <= _currentDebt - THUSD_GAS_COMPENSATION, "BorrowerOps: Amount repaid must not be larger than the Trove's debt");
    }

    function _requireCallerIsStabilityPool() internal view {
        require(msg.sender == stabilityPoolAddress, "BorrowerOps: Caller is not Stability Pool");
    }

     function _requireSufficientTHUSDBalance(ITHUSDToken _thusdToken, address _borrower, uint256 _debtRepayment) internal view {
        require(_thusdToken.balanceOf(_borrower) >= _debtRepayment, "BorrowerOps: Caller doesnt have enough THUSD to make repayment");
    }

    function _requireValidMaxFeePercentage(uint256 _maxFeePercentage, bool _isRecoveryMode) internal pure {
        if (_isRecoveryMode) {
            require(_maxFeePercentage <= DECIMAL_PRECISION,
                "Max fee percentage must less than or equal to 100%");
        } else {
            require(_maxFeePercentage >= BORROWING_FEE_FLOOR && _maxFeePercentage <= DECIMAL_PRECISION,
                "Max fee percentage must be between 0.5% and 100%");
        }
    }

    // --- ICR and TCR getters ---

    // Compute the new collateral ratio, considering the change in coll and debt. Assumes 0 pending rewards.
    function _getNewNominalICRFromTroveChange
    (
        uint256 _coll,
        uint256 _debt,
        uint256 _collChange,
        bool _isCollIncrease,
        uint256 _debtChange,
        bool _isDebtIncrease
    )
        pure
        internal
        returns (uint)
    {
        (uint256 newColl, uint256 newDebt) = _getNewTroveAmounts(_coll, _debt, _collChange, _isCollIncrease, _debtChange, _isDebtIncrease);

        uint256 newNICR = LiquityMath._computeNominalCR(newColl, newDebt);
        return newNICR;
    }

    // Compute the new collateral ratio, considering the change in coll and debt. Assumes 0 pending rewards.
    function _getNewICRFromTroveChange
    (
        uint256 _coll,
        uint256 _debt,
        uint256 _collChange,
        bool _isCollIncrease,
        uint256 _debtChange,
        bool _isDebtIncrease,
        uint256 _price
    )
        pure
        internal
        returns (uint)
    {
        (uint256 newColl, uint256 newDebt) = _getNewTroveAmounts(_coll, _debt, _collChange, _isCollIncrease, _debtChange, _isDebtIncrease);

        uint256 newICR = LiquityMath._computeCR(newColl, newDebt, _price);
        return newICR;
    }

    function _getNewTroveAmounts(
        uint256 _coll,
        uint256 _debt,
        uint256 _collChange,
        bool _isCollIncrease,
        uint256 _debtChange,
        bool _isDebtIncrease
    )
        internal
        pure
        returns (uint, uint)
    {
        uint256 newColl = _coll;
        uint256 newDebt = _debt;

        newColl = _isCollIncrease ? _coll + _collChange :  _coll - _collChange;
        newDebt = _isDebtIncrease ? _debt + _debtChange : _debt - _debtChange;

        return (newColl, newDebt);
    }

    function _getNewTCRFromTroveChange
    (
        uint256 _collChange,
        bool _isCollIncrease,
        uint256 _debtChange,
        bool _isDebtIncrease,
        uint256 _price
    )
        internal
        view
        returns (uint)
    {
        uint256 totalColl = getEntireSystemColl();
        uint256 totalDebt = getEntireSystemDebt();

        totalColl = _isCollIncrease ? totalColl + _collChange : totalColl - _collChange;
        totalDebt = _isDebtIncrease ? totalDebt + _debtChange : totalDebt - _debtChange;

        uint256 newTCR = LiquityMath._computeCR(totalColl, totalDebt, _price);
        return newTCR;
    }

    function getCompositeDebt(uint256 _debt) external pure override returns (uint) {
        return _getCompositeDebt(_debt);
    }
}
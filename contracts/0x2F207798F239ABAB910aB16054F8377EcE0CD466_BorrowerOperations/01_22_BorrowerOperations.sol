// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./Interfaces/IBorrowerOperations.sol";
import "./Interfaces/ITroveManager.sol";
import "./Interfaces/IARTHValuecoin.sol";
import "./Interfaces/ICollSurplusPool.sol";
import "./Interfaces/ISortedTroves.sol";
import "./Dependencies/LiquityBase.sol";
import "./Dependencies/SafeMath.sol";
import "./Dependencies/Ownable.sol";
import "./Dependencies/CheckContract.sol";

contract BorrowerOperations is LiquityBase, Ownable, CheckContract, IBorrowerOperations {
    using SafeMath for uint256;
    string public constant NAME = "BorrowerOperations";

    // --- Connected contract declarations ---

    ITroveManager public troveManager;

    address stabilityPoolAddress;

    address gasPoolAddress;

    ICollSurplusPool collSurplusPool;

    IARTHValuecoin public arthToken;

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
        uint256 ARTHFee;
        uint256 newDebt;
        uint256 newColl;
        uint256 stake;
    }

    struct LocalVariables_openTrove {
        uint256 price;
        uint256 ARTHFee;
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
        IARTHValuecoin arthToken;
    }

    mapping(address => bool) public frontEnds;

    // --- Dependency setters ---

    function setAddresses(
        address _troveManagerAddress,
        address _activePoolAddress,
        address _defaultPoolAddress,
        address _stabilityPoolAddress,
        address _gasPoolAddress,
        address _collSurplusPoolAddress,
        address _governanceAddress,
        address _sortedTrovesAddress,
        address _arthTokenAddress
    ) external override onlyOwner {
        checkContract(_troveManagerAddress);
        checkContract(_activePoolAddress);
        checkContract(_defaultPoolAddress);
        checkContract(_stabilityPoolAddress);
        checkContract(_gasPoolAddress);
        checkContract(_collSurplusPoolAddress);
        checkContract(_governanceAddress);
        checkContract(_sortedTrovesAddress);
        checkContract(_arthTokenAddress);

        troveManager = ITroveManager(_troveManagerAddress);
        activePool = IActivePool(_activePoolAddress);
        defaultPool = IDefaultPool(_defaultPoolAddress);
        stabilityPoolAddress = _stabilityPoolAddress;
        gasPoolAddress = _gasPoolAddress;
        collSurplusPool = ICollSurplusPool(_collSurplusPoolAddress);
        governance = IGovernance(_governanceAddress);
        sortedTroves = ISortedTroves(_sortedTrovesAddress);
        arthToken = IARTHValuecoin(_arthTokenAddress);

        emit TroveManagerAddressChanged(_troveManagerAddress);
        emit ActivePoolAddressChanged(_activePoolAddress);
        emit DefaultPoolAddressChanged(_defaultPoolAddress);
        emit StabilityPoolAddressChanged(_stabilityPoolAddress);
        emit GasPoolAddressChanged(_gasPoolAddress);
        emit CollSurplusPoolAddressChanged(_collSurplusPoolAddress);
        emit GovernanceAddressChanged(_governanceAddress);
        emit SortedTrovesAddressChanged(_sortedTrovesAddress);
        emit ARTHTokenAddressChanged(_arthTokenAddress);

        // This makes impossible to open a trove with zero withdrawn ARTH
        assert(MIN_NET_DEBT() > 0);

        _renounceOwnership(); // renounce ownership after migration is done (openTroveFor)
    }

    // --- Borrower Trove Operations ---

    function registerFrontEnd() external override {
        _requireFrontEndNotRegistered(msg.sender);
        _requireTroveisNotActive(troveManager, msg.sender);
        frontEnds[msg.sender] = true;
        emit FrontEndRegistered(msg.sender, block.timestamp);
    }

    function openTrove(
        uint256 _maxFeePercentage,
        uint256 _ARTHAmount,
        address _upperHint,
        address _lowerHint
    ) external payable override {
        _openTrove(
            msg.sender,
            msg.sender,
            _maxFeePercentage,
            _ARTHAmount,
            _upperHint,
            _lowerHint,
            address(0)
        );
    }

    function openTrove(
        uint256 _maxFeePercentage,
        uint256 _ARTHAmount,
        address _upperHint,
        address _lowerHint,
        address _frontEndTag
    ) external payable override {
        _openTrove(
            msg.sender,
            msg.sender,
            _maxFeePercentage,
            _ARTHAmount,
            _upperHint,
            _lowerHint,
            _frontEndTag
        );
    }

    function openTroveFor(
        address _who,
        uint256 _maxFeePercentage,
        uint256 _ARTHAmount,
        address _upperHint,
        address _lowerHint,
        address _frontEndTag
    ) external payable onlyOwner {
        _openTrove(
            _who,
            msg.sender,
            _maxFeePercentage,
            _ARTHAmount,
            _upperHint,
            _lowerHint,
            _frontEndTag
        );
    }

    function _openTrove(
        address _who,
        address _arthRecipeint,
        uint256 _maxFeePercentage,
        uint256 _ARTHAmount,
        address _upperHint,
        address _lowerHint,
        address _frontEndTag
    ) internal {
        _requireFrontEndIsRegisteredOrZero(_frontEndTag);
        _requireFrontEndNotRegistered(_who);

        ContractsCache memory contractsCache = ContractsCache(troveManager, activePool, arthToken);
        LocalVariables_openTrove memory vars;

        vars.price = getPriceFeed().fetchPrice();
        bool isRecoveryMode = _checkRecoveryMode(vars.price);

        _requireValidMaxFeePercentage(_maxFeePercentage, isRecoveryMode);
        _requireTroveisNotActive(contractsCache.troveManager, _who);

        vars.ARTHFee;
        vars.netDebt = _ARTHAmount;

        if (!isRecoveryMode) {
            vars.ARTHFee = _triggerBorrowingFee(
                contractsCache.troveManager,
                contractsCache.arthToken,
                _ARTHAmount,
                _maxFeePercentage,
                _frontEndTag
            );
            vars.netDebt = vars.netDebt.add(vars.ARTHFee);
        }
        _requireAtLeastMinNetDebt(vars.netDebt);

        // ICR is based on the composite debt, i.e. the requested ARTH amount + ARTH borrowing fee + ARTH gas comp.
        vars.compositeDebt = _getCompositeDebt(vars.netDebt);
        assert(vars.compositeDebt > 0);

        vars.ICR = LiquityMath._computeCR(msg.value, vars.compositeDebt, vars.price);
        vars.NICR = LiquityMath._computeNominalCR(msg.value, vars.compositeDebt);

        if (isRecoveryMode) {
            _requireICRisAboveCCR(vars.ICR);
        } else {
            _requireICRisAboveMCR(vars.ICR);
            uint256 newTCR = _getNewTCRFromTroveChange(
                msg.value,
                true,
                vars.compositeDebt,
                true,
                vars.price
            ); // bools: coll increase, debt increase
            _requireNewTCRisAboveCCR(newTCR);
        }

        // Set the trove struct's properties
        contractsCache.troveManager.setTroveFrontEndTag(_who, _frontEndTag);
        contractsCache.troveManager.setTroveStatus(_who, 1);
        contractsCache.troveManager.increaseTroveColl(_who, msg.value);
        contractsCache.troveManager.increaseTroveDebt(_who, vars.compositeDebt);

        contractsCache.troveManager.updateTroveRewardSnapshots(_who);
        vars.stake = contractsCache.troveManager.updateStakeAndTotalStakes(_who);

        sortedTroves.insert(_who, vars.NICR, _upperHint, _lowerHint);
        vars.arrayIndex = contractsCache.troveManager.addTroveOwnerToArray(_who);
        emit TroveCreated(_who, vars.arrayIndex);

        // Move the ether to the Active Pool, and mint the ARTHAmount to the borrower
        _activePoolAddColl(contractsCache.activePool, msg.value);
        _withdrawARTH(
            contractsCache.activePool,
            contractsCache.arthToken,
            _arthRecipeint,
            _ARTHAmount,
            vars.netDebt
        );
        // Move the ARTH gas compensation to the Gas Pool
        _withdrawARTH(
            contractsCache.activePool,
            contractsCache.arthToken,
            gasPoolAddress,
            ARTH_GAS_COMPENSATION(),
            ARTH_GAS_COMPENSATION()
        );

        emit TroveUpdated(
            _who,
            vars.compositeDebt,
            msg.value,
            vars.stake,
            BorrowerOperation.openTrove
        );
        emit ARTHBorrowingFeePaid(_who, vars.ARTHFee);
    }

    // Send ETH as collateral to a trove
    function addColl(address _upperHint, address _lowerHint) external payable override {
        _adjustTrove(msg.sender, 0, 0, false, _upperHint, _lowerHint, 0);
    }

    // Send ETH as collateral to a trove. Called by only the Stability Pool.
    function moveETHGainToTrove(
        address _borrower,
        address _upperHint,
        address _lowerHint
    ) external payable override {
        _requireCallerIsStabilityPool();
        _adjustTrove(_borrower, 0, 0, false, _upperHint, _lowerHint, 0);
    }

    // Withdraw ETH collateral from a trove
    function withdrawColl(
        uint256 _collWithdrawal,
        address _upperHint,
        address _lowerHint
    ) external override {
        _adjustTrove(msg.sender, _collWithdrawal, 0, false, _upperHint, _lowerHint, 0);
    }

    // Withdraw ARTH tokens from a trove: mint new ARTH tokens to the owner, and increase the trove's debt accordingly
    function withdrawARTH(
        uint256 _maxFeePercentage,
        uint256 _ARTHAmount,
        address _upperHint,
        address _lowerHint
    ) external override {
        _adjustTrove(msg.sender, 0, _ARTHAmount, true, _upperHint, _lowerHint, _maxFeePercentage);
    }

    // Repay ARTH tokens to a Trove: Burn the repaid ARTH tokens, and reduce the trove's debt accordingly
    function repayARTH(
        uint256 _ARTHAmount,
        address _upperHint,
        address _lowerHint
    ) external override {
        _adjustTrove(msg.sender, 0, _ARTHAmount, false, _upperHint, _lowerHint, 0);
    }

    function adjustTrove(
        uint256 _maxFeePercentage,
        uint256 _collWithdrawal,
        uint256 _ARTHChange,
        bool _isDebtIncrease,
        address _upperHint,
        address _lowerHint
    ) external payable override {
        _adjustTrove(
            msg.sender,
            _collWithdrawal,
            _ARTHChange,
            _isDebtIncrease,
            _upperHint,
            _lowerHint,
            _maxFeePercentage
        );
    }

    /*
     * _adjustTrove(): Alongside a debt change, this function can perform either a collateral top-up or a collateral withdrawal.
     *
     * It therefore expects either a positive msg.value, or a positive _collWithdrawal argument.
     *
     * If both are positive, it will revert.
     */
    function _adjustTrove(
        address _borrower,
        uint256 _collWithdrawal,
        uint256 _ARTHChange,
        bool _isDebtIncrease,
        address _upperHint,
        address _lowerHint,
        uint256 _maxFeePercentage
    ) internal {
        ContractsCache memory contractsCache = ContractsCache(troveManager, activePool, arthToken);
        LocalVariables_adjustTrove memory vars;

        vars.price = getPriceFeed().fetchPrice();
        bool isRecoveryMode = _checkRecoveryMode(vars.price);

        if (_isDebtIncrease) {
            _requireValidMaxFeePercentage(_maxFeePercentage, isRecoveryMode);
            _requireNonZeroDebtChange(_ARTHChange);
        }
        _requireSingularCollChange(_collWithdrawal);
        _requireNonZeroAdjustment(_collWithdrawal, _ARTHChange);
        _requireTroveisActive(contractsCache.troveManager, _borrower);

        // Confirm the operation is either a borrower adjusting their own trove, or a pure ETH transfer from the Stability Pool to a trove
        assert(
            msg.sender == _borrower ||
                (msg.sender == stabilityPoolAddress && msg.value > 0 && _ARTHChange == 0)
        );

        contractsCache.troveManager.applyPendingRewards(_borrower);

        // Get the collChange based on whether or not ETH was sent in the transaction
        (vars.collChange, vars.isCollIncrease) = _getCollChange(msg.value, _collWithdrawal);

        vars.netDebtChange = _ARTHChange;

        // If the adjustment incorporates a debt increase and system is in Normal Mode, then trigger a borrowing fee
        if (_isDebtIncrease && !isRecoveryMode) {
            address frontEndTag = contractsCache.troveManager.getTroveFrontEnd(_borrower);
            vars.ARTHFee = _triggerBorrowingFee(
                contractsCache.troveManager,
                contractsCache.arthToken,
                _ARTHChange,
                _maxFeePercentage,
                frontEndTag
            );
            vars.netDebtChange = vars.netDebtChange.add(vars.ARTHFee); // The raw debt change includes the fee
        }

        vars.debt = contractsCache.troveManager.getTroveDebt(_borrower);
        vars.coll = contractsCache.troveManager.getTroveColl(_borrower);

        // Get the trove's old ICR before the adjustment, and what its new ICR will be after the adjustment
        vars.oldICR = LiquityMath._computeCR(vars.coll, vars.debt, vars.price);
        vars.newICR = _getNewICRFromTroveChange(
            vars.coll,
            vars.debt,
            vars.collChange,
            vars.isCollIncrease,
            vars.netDebtChange,
            _isDebtIncrease,
            vars.price
        );
        assert(_collWithdrawal <= vars.coll);

        // Check the adjustment satisfies all conditions for the current system mode
        _requireValidAdjustmentInCurrentMode(isRecoveryMode, _collWithdrawal, _isDebtIncrease, vars);

        // When the adjustment is a debt repayment, check it's a valid amount and that the caller has enough ARTH
        if (!_isDebtIncrease && _ARTHChange > 0) {
            _requireAtLeastMinNetDebt(_getNetDebt(vars.debt).sub(vars.netDebtChange));
            _requireValidARTHRepayment(vars.debt, vars.netDebtChange);
            _requireSufficientARTHBalance(contractsCache.arthToken, _borrower, vars.netDebtChange);
        }

        (vars.newColl, vars.newDebt) = _updateTroveFromAdjustment(
            contractsCache.troveManager,
            _borrower,
            vars.collChange,
            vars.isCollIncrease,
            vars.netDebtChange,
            _isDebtIncrease
        );
        vars.stake = contractsCache.troveManager.updateStakeAndTotalStakes(_borrower);

        // Re-insert trove in to the sorted list
        uint256 newNICR = _getNewNominalICRFromTroveChange(
            vars.coll,
            vars.debt,
            vars.collChange,
            vars.isCollIncrease,
            vars.netDebtChange,
            _isDebtIncrease
        );
        sortedTroves.reInsert(_borrower, newNICR, _upperHint, _lowerHint);

        emit TroveUpdated(
            _borrower,
            vars.newDebt,
            vars.newColl,
            vars.stake,
            BorrowerOperation.adjustTrove
        );
        emit ARTHBorrowingFeePaid(msg.sender, vars.ARTHFee);

        // Use the unmodified _ARTHChange here, as we don't send the fee to the user
        _moveTokensAndETHfromAdjustment(
            contractsCache.activePool,
            contractsCache.arthToken,
            msg.sender,
            vars.collChange,
            vars.isCollIncrease,
            _ARTHChange,
            _isDebtIncrease,
            vars.netDebtChange
        );
    }

    function closeTrove() external override {
        ITroveManager troveManagerCached = troveManager;
        IActivePool activePoolCached = activePool;
        IARTHValuecoin arthTokenCached = arthToken;

        _requireTroveisActive(troveManagerCached, msg.sender);
        uint256 price = getPriceFeed().fetchPrice();
        _requireNotInRecoveryMode(price);

        troveManagerCached.applyPendingRewards(msg.sender);

        uint256 coll = troveManagerCached.getTroveColl(msg.sender);
        uint256 debt = troveManagerCached.getTroveDebt(msg.sender);

        _requireSufficientARTHBalance(
            arthTokenCached,
            msg.sender,
            debt.sub(ARTH_GAS_COMPENSATION())
        );

        uint256 newTCR = _getNewTCRFromTroveChange(coll, false, debt, false, price);
        _requireNewTCRisAboveCCR(newTCR);

        troveManagerCached.removeStake(msg.sender);
        troveManagerCached.closeTrove(msg.sender);

        emit TroveUpdated(msg.sender, 0, 0, 0, BorrowerOperation.closeTrove);

        // Burn the repaid ARTH from the user's balance and the gas compensation from the Gas Pool
        _repayARTH(activePoolCached, arthTokenCached, msg.sender, debt.sub(ARTH_GAS_COMPENSATION()));
        _repayARTH(activePoolCached, arthTokenCached, gasPoolAddress, ARTH_GAS_COMPENSATION());

        // Send the collateral back to the user
        activePoolCached.sendETH(msg.sender, coll);
    }

    /**
     * Claim remaining collateral from a redemption or from a liquidation with ICR > MCR in Recovery Mode
     */
    function claimCollateral() external override {
        // send ETH from CollSurplus Pool to owner
        collSurplusPool.claimColl(msg.sender);
    }

    // --- Helper functions ---

    function _triggerBorrowingFee(
        ITroveManager _troveManager,
        IARTHValuecoin _arthToken,
        uint256 _ARTHAmount,
        uint256 _maxFeePercentage,
        address _frontEndTag
    ) internal returns (uint256) {
        _troveManager.decayBaseRateFromBorrowing(); // decay the baseRate state variable
        uint256 ARTHFee = _troveManager.getBorrowingFee(_ARTHAmount);

        _requireUserAcceptsFee(ARTHFee, _ARTHAmount, _maxFeePercentage);

        if (ARTHFee > 0) {
            uint256 feeForEcosystemFund = ARTHFee;

            // give 50% to ecosystem and frontend
            if (_frontEndTag != address(0)) {
                feeForEcosystemFund = ARTHFee.mul(50).div(100);
                uint256 _fee = ARTHFee.sub(feeForEcosystemFund);
                emit PaidARTHBorrowingFeeToFrontEnd(_frontEndTag, _fee);
                _arthToken.mint(_frontEndTag, _fee);
            }

            _sendFeeToEcosystemFund(_arthToken, feeForEcosystemFund);
        }

        return ARTHFee;
    }

    function _sendFeeToEcosystemFund(IARTHValuecoin _arthToken, uint256 _ARTHFee) internal {
        address ecosystemFund = governance.getFund();
        _arthToken.mint(ecosystemFund, _ARTHFee);
        emit PaidARTHBorrowingFeeToEcosystemFund(ecosystemFund, _ARTHFee);
    }

    function _getUSDValue(uint256 _coll, uint256 _price) internal pure returns (uint256) {
        uint256 usdValue = _price.mul(_coll).div(DECIMAL_PRECISION);

        return usdValue;
    }

    function _getCollChange(uint256 _collReceived, uint256 _requestedCollWithdrawal)
        internal
        pure
        returns (uint256 collChange, bool isCollIncrease)
    {
        if (_collReceived != 0) {
            collChange = _collReceived;
            isCollIncrease = true;
        } else {
            collChange = _requestedCollWithdrawal;
        }
    }

    // Update trove's coll and debt based on whether they increase or decrease
    function _updateTroveFromAdjustment(
        ITroveManager _troveManager,
        address _borrower,
        uint256 _collChange,
        bool _isCollIncrease,
        uint256 _debtChange,
        bool _isDebtIncrease
    ) internal returns (uint256, uint256) {
        uint256 newColl = (_isCollIncrease)
            ? _troveManager.increaseTroveColl(_borrower, _collChange)
            : _troveManager.decreaseTroveColl(_borrower, _collChange);
        uint256 newDebt = (_isDebtIncrease)
            ? _troveManager.increaseTroveDebt(_borrower, _debtChange)
            : _troveManager.decreaseTroveDebt(_borrower, _debtChange);

        return (newColl, newDebt);
    }

    function _moveTokensAndETHfromAdjustment(
        IActivePool _activePool,
        IARTHValuecoin _arthToken,
        address _borrower,
        uint256 _collChange,
        bool _isCollIncrease,
        uint256 _ARTHChange,
        bool _isDebtIncrease,
        uint256 _netDebtChange
    ) internal {
        if (_isDebtIncrease) {
            _withdrawARTH(_activePool, _arthToken, _borrower, _ARTHChange, _netDebtChange);
        } else {
            _repayARTH(_activePool, _arthToken, _borrower, _ARTHChange);
        }

        if (_isCollIncrease) {
            _activePoolAddColl(_activePool, _collChange);
        } else {
            _activePool.sendETH(_borrower, _collChange);
        }
    }

    // Send ETH to Active Pool and increase its recorded ETH balance
    function _activePoolAddColl(IActivePool _activePool, uint256 _amount) internal {
        (bool success, ) = address(_activePool).call{value: _amount}("");
        require(success, "BorrowerOps: Sending ETH to ActivePool failed");
    }

    // Issue the specified amount of ARTH to _account and increases the total active debt (_netDebtIncrease potentially includes a ARTHFee)
    function _withdrawARTH(
        IActivePool _activePool,
        IARTHValuecoin _arthToken,
        address _account,
        uint256 _ARTHAmount,
        uint256 _netDebtIncrease
    ) internal {
        require(
            _activePool.getARTHDebt() + _ARTHAmount <= governance.getMaxDebtCeiling(),
            "mint > max debt"
        );
        require(governance.getAllowMinting(), "!minting");
        _activePool.increaseARTHDebt(_netDebtIncrease);
        _arthToken.mint(_account, _ARTHAmount);
    }

    // Burn the specified amount of ARTH from _account and decreases the total active debt
    function _repayARTH(
        IActivePool _activePool,
        IARTHValuecoin _arthToken,
        address _account,
        uint256 _ARTH
    ) internal {
        _activePool.decreaseARTHDebt(_ARTH);
        _arthToken.burn(_account, _ARTH);
    }

    // --- 'Require' wrapper functions ---

    function _requireSingularCollChange(uint256 _collWithdrawal) internal view {
        require(
            msg.value == 0 || _collWithdrawal == 0,
            "BorrowerOperations: Cannot withdraw and add coll"
        );
    }

    function _requireCallerIsBorrower(address _borrower) internal view {
        require(
            msg.sender == _borrower,
            "BorrowerOps: Caller must be the borrower for a withdrawal"
        );
    }

    function _requireNonZeroAdjustment(uint256 _collWithdrawal, uint256 _ARTHChange) internal view {
        require(
            msg.value != 0 || _collWithdrawal != 0 || _ARTHChange != 0,
            "BorrowerOps: There must be either a collateral change or a debt change"
        );
    }

    function _requireTroveisActive(ITroveManager _troveManager, address _borrower) internal view {
        uint256 status = _troveManager.getTroveStatus(_borrower);
        require(status == 1, "BorrowerOps: Trove does not exist or is closed");
    }

    function _requireTroveisNotActive(ITroveManager _troveManager, address _borrower) internal view {
        uint256 status = _troveManager.getTroveStatus(_borrower);
        require(status != 1, "BorrowerOps: Trove is active");
    }

    function _requireNonZeroDebtChange(uint256 _ARTHChange) internal pure {
        require(_ARTHChange > 0, "BorrowerOps: Debt increase requires non-zero debtChange");
    }

    function _requireNotInRecoveryMode(uint256 _price) internal view {
        require(
            !_checkRecoveryMode(_price),
            "BorrowerOps: Operation not permitted during Recovery Mode"
        );
    }

    function _requireNoCollWithdrawal(uint256 _collWithdrawal) internal pure {
        require(
            _collWithdrawal == 0,
            "BorrowerOps: Collateral withdrawal not permitted Recovery Mode"
        );
    }

    function _requireValidAdjustmentInCurrentMode(
        bool _isRecoveryMode,
        uint256 _collWithdrawal,
        bool _isDebtIncrease,
        LocalVariables_adjustTrove memory _vars
    ) internal view {
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
        } else {
            // if Normal Mode
            _requireICRisAboveMCR(_vars.newICR);
            _vars.newTCR = _getNewTCRFromTroveChange(
                _vars.collChange,
                _vars.isCollIncrease,
                _vars.netDebtChange,
                _isDebtIncrease,
                _vars.price
            );
            _requireNewTCRisAboveCCR(_vars.newTCR);
        }
    }

    function _requireFrontEndNotRegistered(address _address) internal view {
        require(
            !frontEnds[_address],
            "BorrowerOperations: Must not already be a registered front end"
        );
    }

    function _requireFrontEndIsRegisteredOrZero(address _address) internal view {
        require(
            frontEnds[_address] || _address == address(0),
            "BorrowerOperations: Tag must be a registered front end, or the 0x0"
        );
    }

    function _requireICRisAboveMCR(uint256 _newICR) internal pure {
        require(
            _newICR >= MCR,
            "BorrowerOps: An operation that would result in ICR < MCR is not permitted"
        );
    }

    function _requireICRisAboveCCR(uint256 _newICR) internal pure {
        require(_newICR >= CCR, "BorrowerOps: Operation must leave trove with ICR >= CCR");
    }

    function _requireNewICRisAboveOldICR(uint256 _newICR, uint256 _oldICR) internal pure {
        require(
            _newICR >= _oldICR,
            "BorrowerOps: Cannot decrease your Trove's ICR in Recovery Mode"
        );
    }

    function _requireNewTCRisAboveCCR(uint256 _newTCR) internal pure {
        require(
            _newTCR >= CCR,
            "BorrowerOps: An operation that would result in TCR < CCR is not permitted"
        );
    }

    function _requireAtLeastMinNetDebt(uint256 _netDebt) internal view {
        require(
            _netDebt >= MIN_NET_DEBT(),
            "BorrowerOps: Trove's net debt must be greater than minimum"
        );
    }

    function _requireValidARTHRepayment(uint256 _currentDebt, uint256 _debtRepayment) internal view {
        require(
            _debtRepayment <= _currentDebt.sub(ARTH_GAS_COMPENSATION()),
            "BorrowerOps: Amount repaid must not be larger than the Trove's debt"
        );
    }

    function _requireCallerIsStabilityPool() internal view {
        require(msg.sender == stabilityPoolAddress, "BorrowerOps: Caller is not Stability Pool");
    }

    function _requireSufficientARTHBalance(
        IARTHValuecoin _arthToken,
        address _borrower,
        uint256 _debtRepayment
    ) internal view {
        require(
            _arthToken.balanceOf(_borrower) >= _debtRepayment,
            "BorrowerOps: Caller doesnt have enough ARTH to make repayment"
        );
    }

    function _requireValidMaxFeePercentage(uint256 _maxFeePercentage, bool _isRecoveryMode)
        internal
        view
    {
        if (_isRecoveryMode) {
            require(
                _maxFeePercentage <= DECIMAL_PRECISION,
                "Max fee percentage must less than or equal to 100%"
            );
        } else {
            require(
                _maxFeePercentage >= getBorrowingFeeFloor() &&
                    _maxFeePercentage <= DECIMAL_PRECISION,
                "Max fee percentage must be between 0.5% and 100%"
            );
        }
    }

    // --- ICR and TCR getters ---

    // Compute the new collateral ratio, considering the change in coll and debt. Assumes 0 pending rewards.
    function _getNewNominalICRFromTroveChange(
        uint256 _coll,
        uint256 _debt,
        uint256 _collChange,
        bool _isCollIncrease,
        uint256 _debtChange,
        bool _isDebtIncrease
    ) internal pure returns (uint256) {
        (uint256 newColl, uint256 newDebt) = _getNewTroveAmounts(
            _coll,
            _debt,
            _collChange,
            _isCollIncrease,
            _debtChange,
            _isDebtIncrease
        );

        uint256 newNICR = LiquityMath._computeNominalCR(newColl, newDebt);
        return newNICR;
    }

    // Compute the new collateral ratio, considering the change in coll and debt. Assumes 0 pending rewards.
    function _getNewICRFromTroveChange(
        uint256 _coll,
        uint256 _debt,
        uint256 _collChange,
        bool _isCollIncrease,
        uint256 _debtChange,
        bool _isDebtIncrease,
        uint256 _price
    ) internal pure returns (uint256) {
        (uint256 newColl, uint256 newDebt) = _getNewTroveAmounts(
            _coll,
            _debt,
            _collChange,
            _isCollIncrease,
            _debtChange,
            _isDebtIncrease
        );

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
    ) internal pure returns (uint256, uint256) {
        uint256 newColl = _coll;
        uint256 newDebt = _debt;

        newColl = _isCollIncrease ? _coll.add(_collChange) : _coll.sub(_collChange);
        newDebt = _isDebtIncrease ? _debt.add(_debtChange) : _debt.sub(_debtChange);

        return (newColl, newDebt);
    }

    function _getNewTCRFromTroveChange(
        uint256 _collChange,
        bool _isCollIncrease,
        uint256 _debtChange,
        bool _isDebtIncrease,
        uint256 _price
    ) internal view returns (uint256) {
        uint256 totalColl = getEntireSystemColl();
        uint256 totalDebt = getEntireSystemDebt();

        totalColl = _isCollIncrease ? totalColl.add(_collChange) : totalColl.sub(_collChange);
        totalDebt = _isDebtIncrease ? totalDebt.add(_debtChange) : totalDebt.sub(_debtChange);

        uint256 newTCR = LiquityMath._computeCR(totalColl, totalDebt, _price);
        return newTCR;
    }

    function getCompositeDebt(uint256 _debt) external view override returns (uint256) {
        return _getCompositeDebt(_debt);
    }

    function BORROWING_FEE_FLOOR() external view returns (uint256) {
        return getBorrowingFeeFloor();
    }
}
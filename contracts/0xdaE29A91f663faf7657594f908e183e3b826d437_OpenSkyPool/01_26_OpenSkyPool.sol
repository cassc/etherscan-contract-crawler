// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

import './interfaces/IOpenSkyCollateralPriceOracle.sol';
import './interfaces/IOpenSkyReserveVaultFactory.sol';
import './interfaces/IOpenSkyNFTDescriptor.sol';
import './interfaces/IOpenSkyLoan.sol';
import './interfaces/IOpenSkyPool.sol';
import './interfaces/IOpenSkySettings.sol';
import './interfaces/IACLManager.sol';
import './libraries/math/MathUtils.sol';
import './libraries/math/PercentageMath.sol';
import './libraries/helpers/Errors.sol';
import './libraries/types/DataTypes.sol';
import './libraries/ReserveLogic.sol';

/**
 * @title OpenSkyPool contract
 * @author OpenSky Labs
 * @notice Main point of interaction with OpenSky protocol's pool
 * - Users can:
 *   # Deposit
 *   # Withdraw
 **/
contract OpenSkyPool is Context, Pausable, ReentrancyGuard, IOpenSkyPool {
    using PercentageMath for uint256;
    using Counters for Counters.Counter;
    using ReserveLogic for DataTypes.ReserveData;

    // Map of reserves and their data
    mapping(uint256 => DataTypes.ReserveData) public reserves;

    IOpenSkySettings public immutable SETTINGS;
    Counters.Counter private _reserveIdTracker;

    constructor(address SETTINGS_) Pausable() ReentrancyGuard() {
        SETTINGS = IOpenSkySettings(SETTINGS_);
    }

    /**
     * @dev Only pool admin can call functions marked by this modifier.
     **/
    modifier onlyPoolAdmin() {
        IACLManager ACLManager = IACLManager(SETTINGS.ACLManagerAddress());
        require(ACLManager.isPoolAdmin(_msgSender()), Errors.ACL_ONLY_POOL_ADMIN_CAN_CALL);
        _;
    }

    /**
     * @dev Only liquidator can call functions marked by this modifier.
     **/
    modifier onlyLiquidator() {
        require(SETTINGS.isLiquidator(_msgSender()), Errors.ACL_ONLY_LIQUIDATOR_CAN_CALL);
        _;
    }

    /**
     * @dev Only emergency admin can call functions marked by this modifier.
     **/
    modifier onlyEmergencyAdmin() {
        IACLManager ACLManager = IACLManager(SETTINGS.ACLManagerAddress());
        require(ACLManager.isEmergencyAdmin(_msgSender()), Errors.ACL_ONLY_EMERGENCY_ADMIN_CAN_CALL);
        _;
    }

    /**
     * @dev functions marked by this modifier can be executed only when the specific reserve exists.
     **/
    modifier checkReserveExists(uint256 reserveId) {
        require(_exists(reserveId), Errors.RESERVE_DOES_NOT_EXIST);
        _;
    }

    /**
     * @dev Pause pool for emergency case, can only be called by emergency admin.
     **/
    function pause() external onlyEmergencyAdmin {
        _pause();
    }

    /**
     * @dev Unpause pool for emergency case, can only be called by emergency admin.
     **/
    function unpause() external onlyEmergencyAdmin {
        _unpause();
    }

    /**
     * @dev Check if specific reserve exists.
     **/
    function _exists(uint256 reserveId) internal view returns (bool) {
        return reserves[reserveId].reserveId > 0;
    }

    /// @inheritdoc IOpenSkyPool
    function create(
        address underlyingAsset,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) external override onlyPoolAdmin {
        _reserveIdTracker.increment();
        uint256 reserveId = _reserveIdTracker.current();
        address oTokenAddress = IOpenSkyReserveVaultFactory(SETTINGS.vaultFactoryAddress()).create(
            reserveId,
            name,
            symbol,
            decimals,
            underlyingAsset
        );
        reserves[reserveId] = DataTypes.ReserveData({
            reserveId: reserveId,
            underlyingAsset: underlyingAsset,
            oTokenAddress: oTokenAddress,
            moneyMarketAddress: SETTINGS.moneyMarketAddress(),
            lastSupplyIndex: uint128(WadRayMath.RAY),
            borrowingInterestPerSecond: 0,
            lastMoneyMarketBalance: 0,
            lastUpdateTimestamp: 0,
            totalBorrows: 0,
            interestModelAddress: SETTINGS.interestRateStrategyAddress(),
            treasuryFactor: SETTINGS.reserveFactor(),
            isMoneyMarketOn: true
        });
        emit Create(reserveId, underlyingAsset, oTokenAddress, name, symbol, decimals);
    }

    function claimERC20Rewards(uint256 reserveId, address token) external onlyPoolAdmin {
        IOpenSkyOToken(reserves[reserveId].oTokenAddress).claimERC20Rewards(token);
    }

    /// @inheritdoc IOpenSkyPool
    function setTreasuryFactor(uint256 reserveId, uint256 factor)
        external
        override
        checkReserveExists(reserveId)
        onlyPoolAdmin
    {
        require(factor <= SETTINGS.MAX_RESERVE_FACTOR(), Errors.RESERVE_TREASURY_FACTOR_NOT_ALLOWED);
        reserves[reserveId].treasuryFactor = factor;
        emit SetTreasuryFactor(reserveId, factor);
    }

    /// @inheritdoc IOpenSkyPool
    function setInterestModelAddress(uint256 reserveId, address interestModelAddress)
        external
        override
        checkReserveExists(reserveId)
        onlyPoolAdmin
    {
        reserves[reserveId].interestModelAddress = interestModelAddress;
        emit SetInterestModelAddress(reserveId, interestModelAddress);
    }

    /// @inheritdoc IOpenSkyPool
    function openMoneyMarket(uint256 reserveId) external override checkReserveExists(reserveId) onlyEmergencyAdmin {
        require(!reserves[reserveId].isMoneyMarketOn, Errors.RESERVE_SWITCH_MONEY_MARKET_STATE_ERROR);
        reserves[reserveId].openMoneyMarket();
        emit OpenMoneyMarket(reserveId);
    }

    /// @inheritdoc IOpenSkyPool
    function closeMoneyMarket(uint256 reserveId) external override checkReserveExists(reserveId) onlyEmergencyAdmin {
        require(reserves[reserveId].isMoneyMarketOn, Errors.RESERVE_SWITCH_MONEY_MARKET_STATE_ERROR);
        reserves[reserveId].closeMoneyMarket();
        emit CloseMoneyMarket(reserveId);
    }

    /// @inheritdoc IOpenSkyPool
    function deposit(uint256 reserveId, uint256 amount, address onBehalfOf, uint256 referralCode)
        external
        virtual
        override
        whenNotPaused
        nonReentrant
        checkReserveExists(reserveId)
    {
        require(amount > 0, Errors.DEPOSIT_AMOUNT_SHOULD_BE_BIGGER_THAN_ZERO);
        reserves[reserveId].deposit(_msgSender(), amount, onBehalfOf);
        emit Deposit(reserveId, onBehalfOf, amount, referralCode);
    }

    /// @inheritdoc IOpenSkyPool
    function withdraw(uint256 reserveId, uint256 amount, address onBehalfOf)
        external
        virtual
        override
        whenNotPaused
        nonReentrant
        checkReserveExists(reserveId)
    {
        address oTokenAddress = reserves[reserveId].oTokenAddress;
        uint256 userBalance = IOpenSkyOToken(oTokenAddress).balanceOf(_msgSender());

        uint256 amountToWithdraw = amount;
        if (amount == type(uint256).max) {
            amountToWithdraw = userBalance;
        }

        require(amountToWithdraw > 0 && amountToWithdraw <= userBalance, Errors.WITHDRAW_AMOUNT_NOT_ALLOWED);
        require(getAvailableLiquidity(reserveId) >= amountToWithdraw, Errors.WITHDRAW_LIQUIDITY_NOT_SUFFICIENT);

        reserves[reserveId].withdraw(_msgSender(), amountToWithdraw, onBehalfOf);
        emit Withdraw(reserveId, onBehalfOf, amountToWithdraw);
    }

    struct BorrowLocalParams {
        uint256 borrowLimit;
        uint256 availableLiquidity;
        uint256 amountToBorrow;
        uint256 borrowRate;
        address loanAddress;
    }

    /// @inheritdoc IOpenSkyPool
    function borrow(
        uint256 reserveId,
        uint256 amount,
        uint256 duration,
        address nftAddress,
        uint256 tokenId,
        address onBehalfOf
    ) external virtual override whenNotPaused nonReentrant checkReserveExists(reserveId) returns (uint256) {
        _validateWhitelist(reserveId, nftAddress, duration);

        BorrowLocalParams memory vars;
        vars.borrowLimit = getBorrowLimitByOracle(reserveId, nftAddress, tokenId);
        vars.availableLiquidity = getAvailableLiquidity(reserveId);

        vars.amountToBorrow = amount;

        if (amount == type(uint256).max) {
            vars.amountToBorrow = (
                vars.borrowLimit < vars.availableLiquidity ? vars.borrowLimit : vars.availableLiquidity
            );
        }

        require(vars.borrowLimit >= vars.amountToBorrow, Errors.BORROW_AMOUNT_EXCEED_BORROW_LIMIT);
        require(vars.availableLiquidity >= vars.amountToBorrow, Errors.RESERVE_LIQUIDITY_INSUFFICIENT);

        vars.loanAddress = SETTINGS.loanAddress();
        IERC721(nftAddress).safeTransferFrom(_msgSender(), vars.loanAddress, tokenId);

        vars.borrowRate = reserves[reserveId].getBorrowRate(0, 0, vars.amountToBorrow, 0);
        (uint256 loanId, DataTypes.LoanData memory loan) = IOpenSkyLoan(vars.loanAddress).mint(
            reserveId,
            onBehalfOf,
            nftAddress,
            tokenId,
            vars.amountToBorrow,
            duration,
            vars.borrowRate
        );
        reserves[reserveId].borrow(loan);

        emit Borrow(
            reserveId,
            _msgSender(),
            onBehalfOf,
            loanId
        );

        return loanId;
    }

    /// @inheritdoc IOpenSkyPool
    function repay(uint256 loanId) external virtual override whenNotPaused nonReentrant returns (uint256 repayAmount) {
        address loanAddress = SETTINGS.loanAddress();
        address onBehalfOf = IERC721(loanAddress).ownerOf(loanId);

        IOpenSkyLoan loanNFT = IOpenSkyLoan(loanAddress);
        DataTypes.LoanData memory loanData = loanNFT.getLoanData(loanId);

        require(
            loanData.status == DataTypes.LoanStatus.BORROWING ||
                loanData.status == DataTypes.LoanStatus.EXTENDABLE ||
                loanData.status == DataTypes.LoanStatus.OVERDUE,
            Errors.REPAY_STATUS_ERROR
        );

        uint256 penalty = loanNFT.getPenalty(loanId);
        uint256 borrowBalance = loanNFT.getBorrowBalance(loanId);
        repayAmount = borrowBalance + penalty;

        uint256 reserveId = loanData.reserveId;
        require(_exists(reserveId), Errors.RESERVE_DOES_NOT_EXIST);

        reserves[reserveId].repay(loanData, repayAmount, borrowBalance);

        loanNFT.end(loanId, onBehalfOf, _msgSender());

        address nftReceiver = SETTINGS.punkGatewayAddress() == _msgSender() ? _msgSender() : onBehalfOf;
        IERC721(loanData.nftAddress).safeTransferFrom(address(loanNFT), nftReceiver, loanData.tokenId);

        emit Repay(reserveId, _msgSender(), nftReceiver, loanId, repayAmount, penalty);
    }

    struct ExtendLocalParams {
        uint256 borrowInterestOfOldLoan;
        uint256 needInAmount;
        uint256 needOutAmount;
        uint256 penalty;
        uint256 fee;
        uint256 borrowLimit;
        uint256 availableLiquidity;
        uint256 amountToExtend;
        uint256 newBorrowRate;
        DataTypes.LoanData oldLoan;
    }

    /// @inheritdoc IOpenSkyPool
    function extend(
        uint256 oldLoanId,
        uint256 amount,
        uint256 duration,
        address onBehalfOf
    ) external override whenNotPaused nonReentrant returns (uint256, uint256) {
        IOpenSkyLoan loanNFT = IOpenSkyLoan(SETTINGS.loanAddress());
        if (_msgSender() == SETTINGS.wethGatewayAddress()) {
            require(loanNFT.ownerOf(oldLoanId) == onBehalfOf, Errors.LOAN_CALLER_IS_NOT_OWNER);
        } else {
            require(loanNFT.ownerOf(oldLoanId) == _msgSender(), Errors.LOAN_CALLER_IS_NOT_OWNER);
            onBehalfOf = _msgSender();
        }

        ExtendLocalParams memory vars;
        vars.oldLoan = loanNFT.getLoanData(oldLoanId);

        require(
            vars.oldLoan.status == DataTypes.LoanStatus.EXTENDABLE || vars.oldLoan.status == DataTypes.LoanStatus.OVERDUE,
            Errors.EXTEND_STATUS_ERROR
        );

        _validateWhitelist(vars.oldLoan.reserveId, vars.oldLoan.nftAddress, duration);

        vars.borrowLimit = getBorrowLimitByOracle(vars.oldLoan.reserveId, vars.oldLoan.nftAddress, vars.oldLoan.tokenId);

        vars.amountToExtend = amount;
        if (amount == type(uint256).max) {
            vars.amountToExtend = vars.borrowLimit; // no need to check availableLiquidity here
        }

        require(vars.borrowLimit >= vars.amountToExtend, Errors.BORROW_AMOUNT_EXCEED_BORROW_LIMIT);

        // calculate needInAmount and needOutAmount 
        vars.borrowInterestOfOldLoan = loanNFT.getBorrowInterest(oldLoanId);
        vars.penalty = loanNFT.getPenalty(oldLoanId);
        vars.fee = vars.borrowInterestOfOldLoan + vars.penalty;
        if (vars.oldLoan.amount <= vars.amountToExtend) {
            uint256 extendAmount = vars.amountToExtend - vars.oldLoan.amount;
            if (extendAmount < vars.fee) {
                vars.needInAmount = vars.fee - extendAmount;
            } else {
                vars.needOutAmount = extendAmount - vars.fee;
            }
        } else {
            vars.needInAmount = vars.oldLoan.amount - vars.amountToExtend + vars.fee;
        }

        // check availableLiquidity
        if (vars.needOutAmount > 0) {
            vars.availableLiquidity = getAvailableLiquidity(vars.oldLoan.reserveId);
            require(vars.availableLiquidity >= vars.needOutAmount, Errors.RESERVE_LIQUIDITY_INSUFFICIENT);
        }

        // end old loan
        loanNFT.end(oldLoanId, onBehalfOf, onBehalfOf);

        vars.newBorrowRate = reserves[vars.oldLoan.reserveId].getBorrowRate(
            vars.penalty,
            0,
            vars.amountToExtend,
            vars.oldLoan.amount + vars.borrowInterestOfOldLoan
        );

        // create new loan
        (uint256 loanId, DataTypes.LoanData memory newLoan) = loanNFT.mint(
            vars.oldLoan.reserveId,
            onBehalfOf,
            vars.oldLoan.nftAddress,
            vars.oldLoan.tokenId,
            vars.amountToExtend,
            duration,
            vars.newBorrowRate
        );

        // update reserve state
        reserves[vars.oldLoan.reserveId].extend(
            vars.oldLoan,
            newLoan,
            vars.borrowInterestOfOldLoan,
            vars.needInAmount,
            vars.needOutAmount,
            vars.penalty
        );

        emit Extend(vars.oldLoan.reserveId, onBehalfOf, oldLoanId, loanId);

        return (vars.needInAmount, vars.needOutAmount);
    }

    function _validateWhitelist(uint256 reserveId, address nftAddress, uint256 duration) internal view {
        require(SETTINGS.inWhitelist(reserveId, nftAddress), Errors.NFT_ADDRESS_IS_NOT_IN_WHITELIST);

        DataTypes.WhitelistInfo memory whitelistInfo = SETTINGS.getWhitelistDetail(reserveId, nftAddress);
        require(
            duration >= whitelistInfo.minBorrowDuration && duration <= whitelistInfo.maxBorrowDuration,
            Errors.BORROW_DURATION_NOT_ALLOWED
        );
    }

    /// @inheritdoc IOpenSkyPool
    function startLiquidation(uint256 loanId) external override whenNotPaused onlyLiquidator {
        IOpenSkyLoan loanNFT = IOpenSkyLoan(SETTINGS.loanAddress());
        DataTypes.LoanData memory loanData = loanNFT.getLoanData(loanId);
        require(loanData.status == DataTypes.LoanStatus.LIQUIDATABLE, Errors.START_LIQUIDATION_STATUS_ERROR);

        reserves[loanData.reserveId].startLiquidation(loanData);

        IERC721(loanData.nftAddress).safeTransferFrom(address(loanNFT), _msgSender(), loanData.tokenId);
        loanNFT.startLiquidation(loanId);

        emit StartLiquidation(loanData.reserveId, loanId, loanData.nftAddress, loanData.tokenId, _msgSender());
    }

    /// @inheritdoc IOpenSkyPool
    function endLiquidation(uint256 loanId, uint256 amount) external override whenNotPaused onlyLiquidator {
        IOpenSkyLoan loanNFT = IOpenSkyLoan(SETTINGS.loanAddress());
        DataTypes.LoanData memory loanData = loanNFT.getLoanData(loanId);
        require(loanData.status == DataTypes.LoanStatus.LIQUIDATING, Errors.END_LIQUIDATION_STATUS_ERROR);

        // repay money
        uint256 borrowBalance = loanNFT.getBorrowBalance(loanId);

        require(amount >= borrowBalance, Errors.END_LIQUIDATION_AMOUNT_ERROR);
        reserves[loanData.reserveId].endLiquidation(amount, borrowBalance);

        loanNFT.endLiquidation(loanId);

        emit EndLiquidation(
            loanData.reserveId,
            loanId,
            loanData.nftAddress,
            loanData.tokenId,
            _msgSender(),
            amount,
            borrowBalance
        );
    }

    /// @inheritdoc IOpenSkyPool
    function getReserveData(uint256 reserveId)
        external
        view
        override
        checkReserveExists(reserveId)
        returns (DataTypes.ReserveData memory)
    {
        return reserves[reserveId];
    }

    /// @inheritdoc IOpenSkyPool
    function getReserveNormalizedIncome(uint256 reserveId)
        external
        view
        virtual
        override
        checkReserveExists(reserveId)
        returns (uint256)
    {
        return reserves[reserveId].getNormalizedIncome();
    }

    /// @inheritdoc IOpenSkyPool
    function getAvailableLiquidity(uint256 reserveId)
        public
        view
        override
        checkReserveExists(reserveId)
        returns (uint256)
    {
        return reserves[reserveId].getMoneyMarketBalance();
    }

    /// @inheritdoc IOpenSkyPool
    function getBorrowLimitByOracle(
        uint256 reserveId,
        address nftAddress,
        uint256 tokenId
    ) public view virtual override returns (uint256) {
        return
            IOpenSkyCollateralPriceOracle(SETTINGS.nftPriceOracleAddress())
                .getPrice(reserveId, nftAddress, tokenId)
                .percentMul(SETTINGS.getWhitelistDetail(reserveId, nftAddress).LTV);
    }
    
    /// @inheritdoc IOpenSkyPool
    function getTotalBorrowBalance(uint256 reserveId) external view override returns (uint256) {
        return reserves[reserveId].getTotalBorrowBalance();
    }

    /// @inheritdoc IOpenSkyPool
    function getTVL(uint256 reserveId) external view override checkReserveExists(reserveId) returns (uint256) {
        return reserves[reserveId].getTVL();
    }

    receive() external payable {
        revert(Errors.RECEIVE_NOT_ALLOWED);
    }

    fallback() external payable {
        revert(Errors.FALLBACK_NOT_ALLOWED);
    }
}
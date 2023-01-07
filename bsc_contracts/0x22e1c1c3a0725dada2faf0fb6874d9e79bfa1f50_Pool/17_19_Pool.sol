// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.15;

import {OwnableUpgradeable} from "openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "openzeppelin-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {SafeERC20, IERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {Initializable} from "openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import {SignedInt, SignedIntOps} from "../lib/SignedInt.sol";
import {MathUtils} from "../lib/MathUtils.sol";
import {PositionUtils} from "../lib/PositionUtils.sol";
import {ILevelOracle} from "../interfaces/ILevelOracle.sol";
import {ILPToken} from "../interfaces/ILPToken.sol";
import {IPool, Side, TokenWeight} from "../interfaces/IPool.sol";
import {
    PoolStorage,
    Position,
    PoolTokenInfo,
    Fee,
    AssetInfo,
    PRECISION,
    LP_INITIAL_PRICE,
    MAX_BASE_SWAP_FEE,
    MAX_TAX_BASIS_POINT,
    MAX_POSITION_FEE,
    MAX_LIQUIDATION_FEE,
    MAX_TRANCHES,
    MAX_INTEREST_RATE,
    MAX_ASSETS,
    MAX_MAINTENANCE_MARGIN
} from "./PoolStorage.sol";
import {PoolErrors} from "./PoolErrors.sol";
import {IPoolHook} from "../interfaces/IPoolHook.sol";

struct IncreasePositionVars {
    uint256 reserveAdded;
    uint256 collateralAmount;
    uint256 collateralValueAdded;
    uint256 feeValue;
    uint256 daoFee;
    uint256 indexPrice;
    uint256 sizeChanged;
}

/// @notice common variable used accross decrease process
struct DecreasePositionVars {
    /// @notice santinized input: collateral value able to be withdraw
    uint256 collateralReduced;
    /// @notice santinized input: position size to decrease, caped to position's size
    uint256 sizeChanged;
    /// @notice current price of index
    uint256 indexPrice;
    /// @notice current price of collateral
    uint256 collateralPrice;
    /// @notice postion's remaining collateral value in USD after decrease position
    uint256 remainingCollateral;
    /// @notice reserve reduced due to reducion process
    uint256 reserveReduced;
    /// @notice total value of fee to be collect (include dao fee and LP fee)
    uint256 feeValue;
    /// @notice amount of collateral taken as fee
    uint256 daoFee;
    /// @notice real transfer out amount to user
    uint256 payout;
    SignedInt pnl;
    SignedInt poolAmountReduced;
}

contract Pool is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, PoolStorage, IPool {
    using SignedIntOps for SignedInt;
    using SafeERC20 for IERC20;

    /* =========== MODIFIERS ========== */
    modifier onlyOrderManager() {
        _requireOrderManager();
        _;
    }

    modifier onlyAsset(address _token) {
        _validateAsset(_token);
        _;
    }

    modifier onlyListedToken(address _token) {
        _requireListedToken(_token);
        _;
    }

    /* ======== INITIALIZERS ========= */
    // comment out these statement to gain some space. This functions is not relevant anymore
    // function initialize(
    //     uint256 _maxLeverage,
    //     uint256 _positionFee,
    //     uint256 _liquidationFee,
    //     uint256 _interestRate,
    //     uint256 _accrualInterval,
    //     uint256 _maintainanceMargin
    // ) external initializer {
    //     __Ownable_init();
    //     __ReentrancyGuard_init();
    //     _setMaxLeverage(_maxLeverage);
    //     _setPositionFee(_positionFee, _liquidationFee);
    //     _setInterestRate(_interestRate, _accrualInterval);
    //     _setMaintenanceMargin(_maintainanceMargin);
    //     fee.daoFee = PRECISION;
    // }

    function init_fixShortPrice() external reinitializer(4) {
        for (uint256 i = 0; i < allTranches.length; i++) {
            address tranche = allTranches[i];
            for (uint256 j = 0; j < allAssets.length; j++) {
                address token = allAssets[j];
                if (!isStableCoin[token] && trancheAssets[tranche][token].totalShortSize != 0) {
                    averageShortPrices[tranche][token] = poolTokens[token].averageShortPrice;
                }
            }
        }
    }

    // ========= View functions =========

    function validateToken(address _indexToken, address _collateralToken, Side _side, bool _isIncrease)
        external
        view
        returns (bool)
    {
        return _validateToken(_indexToken, _collateralToken, _side, _isIncrease);
    }

    function getPoolAsset(address _token) external view returns (AssetInfo memory) {
        return _getPoolAsset(_token);
    }

    function getAllTranchesLength() external view returns (uint256) {
        return allTranches.length;
    }

    function getPoolValue(bool _max) external view returns (uint256) {
        return _getPoolValue(_max);
    }

    function getTrancheValue(address _tranche, bool _max) external view returns (uint256 sum) {
        _validateTranche(_tranche);
        return _getTrancheValue(_tranche, _max);
    }

    function calcSwapOutput(address _tokenIn, address _tokenOut, uint256 _amountIn)
        external
        view
        returns (uint256 amountOut, uint256 feeAmount)
    {
        return _calcSwapOutput(_tokenIn, _tokenOut, _amountIn);
    }

    function calcRemoveLiquidity(address _tranche, address _tokenOut, uint256 _lpAmount)
        external
        view
        returns (uint256 outAmount, uint256 outAmountAfterFee, uint256 feeAmount)
    {
        return _calcRemoveLiquidity(_tranche, _tokenOut, _lpAmount);
    }

    // ============= Mutative functions =============

    function addLiquidity(address _tranche, address _token, uint256 _amountIn, uint256 _minLpAmount, address _to)
        external
        nonReentrant
        onlyListedToken(_token)
    {
        _validateTranche(_tranche);
        _accrueInterest(_token);
        _amountIn = _requireAmount(_transferIn(_token, _amountIn));

        (uint256 amountInAfterFee, uint256 daoFee, uint256 lpAmount) = _calcAddLiquidity(_tranche, _token, _amountIn);
        if (lpAmount < _minLpAmount) {
            revert PoolErrors.SlippageExceeded();
        }

        poolTokens[_token].feeReserve += daoFee;
        trancheAssets[_tranche][_token].poolAmount += amountInAfterFee;

        ILPToken(_tranche).mint(_to, lpAmount);
        emit LiquidityAdded(_tranche, msg.sender, _token, _amountIn, lpAmount, daoFee);
    }

    function removeLiquidity(address _tranche, address _tokenOut, uint256 _lpAmount, uint256 _minOut, address _to)
        external
        nonReentrant
        onlyAsset(_tokenOut)
    {
        _validateTranche(_tranche);
        _accrueInterest(_tokenOut);
        _requireAmount(_lpAmount);
        ILPToken lpToken = ILPToken(_tranche);

        (uint256 outAmount, uint256 outAmountAfterFee, uint256 daoFee) =
            _calcRemoveLiquidity(_tranche, _tokenOut, _lpAmount);
        if (outAmountAfterFee < _minOut) {
            revert PoolErrors.SlippageExceeded();
        }

        uint256 trancheBalance = trancheAssets[_tranche][_tokenOut].poolAmount;
        if (trancheBalance < outAmount) {
            revert PoolErrors.RemoveLiquidityTooMuch(_tranche, outAmount, trancheBalance);
        }

        poolTokens[_tokenOut].feeReserve += daoFee;
        _decreaseTranchePoolAmount(_tranche, _tokenOut, outAmountAfterFee);

        lpToken.burnFrom(msg.sender, _lpAmount);
        _doTransferOut(_tokenOut, _to, outAmountAfterFee);
        emit LiquidityRemoved(_tranche, msg.sender, _tokenOut, _lpAmount, outAmountAfterFee, daoFee);
    }

    function swap(address _tokenIn, address _tokenOut, uint256 _minOut, address _to, bytes calldata extradata)
        external
        nonReentrant
        onlyListedToken(_tokenIn)
        onlyListedToken(_tokenOut)
    {
        if (_tokenIn == _tokenOut) {
            revert PoolErrors.SameTokenSwap(_tokenIn);
        }
        _accrueInterest(_tokenIn);
        _accrueInterest(_tokenOut);
        uint256 amountIn = _requireAmount(_getAmountIn(_tokenIn));
        (uint256 amountOutAfterFee, uint256 swapFee) = _calcSwapOutput(_tokenIn, _tokenOut, amountIn);
        if (amountOutAfterFee < _minOut) {
            revert PoolErrors.SlippageExceeded();
        }
        uint256 daoFee = _calcDaoFee(swapFee);
        poolTokens[_tokenIn].feeReserve += daoFee;
        _rebalanceTranches(_tokenIn, amountIn - daoFee, _tokenOut, amountOutAfterFee);
        _doTransferOut(_tokenOut, _to, amountOutAfterFee);
        emit Swap(msg.sender, _tokenIn, _tokenOut, amountIn, amountOutAfterFee, swapFee);
        if (address(poolHook) != address(0)) {
            poolHook.postSwap(_to, _tokenIn, _tokenOut, abi.encode(amountIn, amountOutAfterFee, extradata));
        }
    }

    function increasePosition(
        address _owner,
        address _indexToken,
        address _collateralToken,
        uint256 _sizeChanged,
        Side _side
    ) external onlyOrderManager {
        _requireValidTokenPair(_indexToken, _collateralToken, _side, true);
        IncreasePositionVars memory vars;
        vars.collateralAmount = _requireAmount(_getAmountIn(_collateralToken));
        uint256 collateralPrice = _getPrice(_collateralToken, false);
        vars.collateralValueAdded = collateralPrice * vars.collateralAmount;
        uint256 borrowIndex = _accrueInterest(_collateralToken);
        bytes32 key = _getPositionKey(_owner, _indexToken, _collateralToken, _side);
        Position memory position = positions[key];
        vars.indexPrice = _getPrice(_indexToken, _side, true);
        vars.sizeChanged = _sizeChanged;

        // update position
        vars.feeValue = _calcPositionFee(position, vars.sizeChanged, borrowIndex);
        vars.daoFee = _calcDaoFee(vars.feeValue) / collateralPrice;
        vars.reserveAdded = vars.sizeChanged / collateralPrice;
        position.entryPrice = PositionUtils.calcAveragePrice(
            _side,
            position.size,
            position.size + vars.sizeChanged,
            position.entryPrice,
            vars.indexPrice,
            SignedIntOps.wrap(0)
        );
        position.collateralValue =
            MathUtils.zeroCapSub(position.collateralValue + vars.collateralValueAdded, vars.feeValue);
        position.size = position.size + vars.sizeChanged;
        position.borrowIndex = borrowIndex;
        position.reserveAmount += vars.reserveAdded;

        _validatePosition(position, _collateralToken, _side, true, vars.indexPrice);

        // update pool assets
        _reservePoolAsset(key, vars, _indexToken, _collateralToken, _side);
        positions[key] = position;

        emit IncreasePosition(
            key,
            _owner,
            _collateralToken,
            _indexToken,
            vars.collateralAmount,
            vars.sizeChanged,
            _side,
            vars.indexPrice,
            vars.feeValue
            );

        emit UpdatePosition(
            key,
            position.size,
            position.collateralValue,
            position.entryPrice,
            position.borrowIndex,
            position.reserveAmount,
            vars.indexPrice
            );

        if (address(poolHook) != address(0)) {
            poolHook.postIncreasePosition(
                _owner, _indexToken, _collateralToken, _side, abi.encode(_sizeChanged, vars.collateralValueAdded)
            );
        }
    }

    function decreasePosition(
        address _owner,
        address _indexToken,
        address _collateralToken,
        uint256 _collateralChanged,
        uint256 _sizeChanged,
        Side _side,
        address _receiver
    ) external onlyOrderManager {
        _requireValidTokenPair(_indexToken, _collateralToken, _side, false);
        uint256 borrowIndex = _accrueInterest(_collateralToken);
        bytes32 key = _getPositionKey(_owner, _indexToken, _collateralToken, _side);
        Position memory position = positions[key];

        if (position.size == 0) {
            revert PoolErrors.PositionNotExists(_owner, _indexToken, _collateralToken, _side);
        }

        DecreasePositionVars memory vars =
            _calcDecreasePayout(position, _indexToken, _collateralToken, _side, _sizeChanged, _collateralChanged, false);

        vars.collateralReduced = position.collateralValue - vars.remainingCollateral;
        _releasePoolAsset(key, vars, _indexToken, _collateralToken, _side);
        position.size = position.size - vars.sizeChanged;
        position.borrowIndex = borrowIndex;
        position.reserveAmount = position.reserveAmount - vars.reserveReduced;
        // reset to actual reduced value instead of user input
        position.collateralValue = vars.remainingCollateral;

        _validatePosition(position, _collateralToken, _side, false, vars.indexPrice);

        emit DecreasePosition(
            key,
            _owner,
            _collateralToken,
            _indexToken,
            vars.collateralReduced,
            vars.sizeChanged,
            _side,
            vars.indexPrice,
            vars.pnl,
            vars.feeValue
            );
        if (position.size == 0) {
            emit ClosePosition(
                key,
                position.size,
                position.collateralValue,
                position.entryPrice,
                position.borrowIndex,
                position.reserveAmount
                );
            // delete position when closed
            delete positions[key];
        } else {
            emit UpdatePosition(
                key,
                position.size,
                position.collateralValue,
                position.entryPrice,
                position.borrowIndex,
                position.reserveAmount,
                vars.indexPrice
                );
            positions[key] = position;
        }
        _doTransferOut(_collateralToken, _receiver, vars.payout);

        if (address(poolHook) != address(0)) {
            poolHook.postDecreasePosition(
                _owner, _indexToken, _collateralToken, _side, abi.encode(vars.sizeChanged, vars.collateralReduced)
            );
        }
    }

    function liquidatePosition(address _account, address _indexToken, address _collateralToken, Side _side) external {
        _requireValidTokenPair(_indexToken, _collateralToken, _side, false);
        uint256 borrowIndex = _accrueInterest(_collateralToken);

        bytes32 key = _getPositionKey(_account, _indexToken, _collateralToken, _side);
        Position memory position = positions[key];
        uint256 markPrice = _getPrice(_indexToken, _side, false);
        if (!_liquidatePositionAllowed(position, _side, markPrice, borrowIndex)) {
            revert PoolErrors.PositionNotLiquidated(key);
        }

        DecreasePositionVars memory vars = _calcDecreasePayout(
            position, _indexToken, _collateralToken, _side, position.size, position.collateralValue, true
        );

        uint256 liquidationFee = fee.liquidationFee / vars.collateralPrice;
        vars.poolAmountReduced = vars.poolAmountReduced.add(liquidationFee);
        _releasePoolAsset(key, vars, _indexToken, _collateralToken, _side);

        emit LiquidatePosition(
            key,
            _account,
            _collateralToken,
            _indexToken,
            _side,
            position.size,
            position.collateralValue - vars.remainingCollateral,
            position.reserveAmount,
            vars.indexPrice,
            vars.pnl,
            vars.feeValue
            );

        delete positions[key];
        _doTransferOut(_collateralToken, _account, vars.payout);
        _doTransferOut(_collateralToken, msg.sender, liquidationFee);

        if (address(poolHook) != address(0)) {
            poolHook.postLiquidatePosition(
                _account, _indexToken, _collateralToken, _side, abi.encode(position.size, position.collateralValue)
            );
        }
    }

    // ========= ADMIN FUNCTIONS ========
    function addTranche(address _tranche) external onlyOwner {
        if (allTranches.length >= MAX_TRANCHES) {
            revert PoolErrors.MaxNumberOfTranchesReached();
        }
        _requireAddress(_tranche);
        if (isTranche[_tranche]) {
            revert PoolErrors.TrancheAlreadyAdded(_tranche);
        }
        isTranche[_tranche] = true;
        allTranches.push(_tranche);
        emit TrancheAdded(_tranche);
    }

    struct RiskConfig {
        address tranche;
        uint256 riskFactor;
    }

    function setRiskFactor(address _token, RiskConfig[] memory _config) external onlyOwner onlyAsset(_token) {
        if (isStableCoin[_token]) {
            revert PoolErrors.CannotSetRiskFactorForStableCoin(_token);
        }
        uint256 total = totalRiskFactor[_token];
        for (uint256 i = 0; i < _config.length; ++i) {
            (address tranche, uint256 factor) = (_config[i].tranche, _config[i].riskFactor);
            if (!isTranche[tranche]) {
                revert PoolErrors.InvalidTranche(tranche);
            }
            total = total + factor - riskFactor[_token][tranche];
            riskFactor[_token][tranche] = factor;
        }
        totalRiskFactor[_token] = total;
        emit TokenRiskFactorUpdated(_token);
    }

    function addToken(address _token, bool _isStableCoin) external onlyOwner {
        if (!isAsset[_token]) {
            isAsset[_token] = true;
            isListed[_token] = true;
            allAssets.push(_token);
            isStableCoin[_token] = _isStableCoin;
            if (allAssets.length > MAX_ASSETS) {
                revert PoolErrors.TooManyTokenAdded(allAssets.length, MAX_ASSETS);
            }
            emit TokenWhitelisted(_token);
            return;
        }

        if (isListed[_token]) {
            revert PoolErrors.DuplicateToken(_token);
        }

        // token is added but not listed
        isListed[_token] = true;
        emit TokenWhitelisted(_token);
    }

    function delistToken(address _token) external onlyOwner {
        if (!isListed[_token]) {
            revert PoolErrors.AssetNotListed(_token);
        }
        isListed[_token] = false;
        uint256 weight = targetWeights[_token];
        totalWeight -= weight;
        targetWeights[_token] = 0;
        emit TokenDelisted(_token);
    }

    function setMaxLeverage(uint256 _maxLeverage) external onlyOwner {
        _setMaxLeverage(_maxLeverage);
    }

    function setMaintenanceMargin(uint256 _margin) external onlyOwner {
        _setMaintenanceMargin(_margin);
    }

    function setOracle(address _oracle) external onlyOwner {
        _requireAddress(_oracle);
        address oldOracle = address(oracle);
        oracle = ILevelOracle(_oracle);
        emit OracleChanged(oldOracle, _oracle);
    }

    function setSwapFee(
        uint256 _baseSwapFee,
        uint256 _taxBasisPoint,
        uint256 _stableCoinBaseSwapFee,
        uint256 _stableCoinTaxBasisPoint
    ) external onlyOwner {
        _validateMaxValue(_baseSwapFee, MAX_BASE_SWAP_FEE);
        _validateMaxValue(_stableCoinBaseSwapFee, MAX_BASE_SWAP_FEE);
        _validateMaxValue(_taxBasisPoint, MAX_TAX_BASIS_POINT);
        _validateMaxValue(_stableCoinTaxBasisPoint, MAX_TAX_BASIS_POINT);
        fee.baseSwapFee = _baseSwapFee;
        fee.taxBasisPoint = _taxBasisPoint;
        fee.stableCoinBaseSwapFee = _stableCoinBaseSwapFee;
        fee.stableCoinTaxBasisPoint = _stableCoinTaxBasisPoint;
        emit SwapFeeSet(_baseSwapFee, _taxBasisPoint, _stableCoinBaseSwapFee, _stableCoinTaxBasisPoint);
    }

    function setAddRemoveLiquidityFee(uint256 _value) external onlyOwner {
        _validateMaxValue(_value, MAX_BASE_SWAP_FEE);
        addRemoveLiquidityFee = _value;
        emit AddRemoveLiquidityFeeSet(_value);
    }

    function setPositionFee(uint256 _positionFee, uint256 _liquidationFee) external onlyOwner {
        _setPositionFee(_positionFee, _liquidationFee);
    }

    function setDaoFee(uint256 _daoFee) external onlyOwner {
        _validateMaxValue(_daoFee, PRECISION);
        fee.daoFee = _daoFee;
        emit DaoFeeSet(_daoFee);
    }

    function setInterestRate(uint256 _interestRate, uint256 _accrualInterval) external onlyOwner {
        _setInterestRate(_interestRate, _accrualInterval);
    }

    function setOrderManager(address _orderManager) external onlyOwner {
        _requireAddress(_orderManager);
        orderManager = _orderManager;
        emit SetOrderManager(_orderManager);
    }

    function withdrawFee(address _token, address _recipient) external onlyAsset(_token) {
        _validateFeeDistributor();
        uint256 amount = poolTokens[_token].feeReserve;
        poolTokens[_token].feeReserve = 0;
        _doTransferOut(_token, _recipient, amount);
        emit DaoFeeWithdrawn(_token, _recipient, amount);
    }

    /// @notice reduce DAO fee by distributing to pool amount;
    function reduceDaoFee(address _token, uint256 _amount) external onlyAsset(_token) {
        _validateFeeDistributor();
        _amount = MathUtils.min(_amount, poolTokens[_token].feeReserve);
        uint256[] memory shares = _calcTrancheSharesAmount(_token, _token, _amount, false);
        for (uint256 i = 0; i < shares.length; ++i) {
            address tranche = allTranches[i];
            trancheAssets[tranche][_token].poolAmount += shares[i];
        }
        poolTokens[_token].feeReserve -= _amount;
        emit DaoFeeReduced(_token, _amount);
    }

    function setFeeDistributor(address _feeDistributor) external onlyOwner {
        _requireAddress(_feeDistributor);
        feeDistributor = _feeDistributor;
        emit FeeDistributorSet(feeDistributor);
    }

    function setTargetWeight(TokenWeight[] memory tokens) external onlyOwner {
        if (tokens.length != allAssets.length) {
            revert PoolErrors.RequireAllTokens();
        }
        uint256 total = 0;
        for (uint256 i = 0; i < tokens.length; ++i) {
            TokenWeight memory item = tokens[i];
            assert(isAsset[item.token]);
            // unlisted token always has zero weight
            uint256 weight = isListed[item.token] ? item.weight : 0;
            targetWeights[item.token] = weight;
            total += weight;
        }
        totalWeight = total;
        emit TokenWeightSet(tokens);
    }

    function setPoolHook(address _hook) external onlyOwner {
        poolHook = IPoolHook(_hook);
        emit PoolHookChanged(_hook);
    }

    // ======== internal functions =========
    function _setMaxLeverage(uint256 _maxLeverage) internal {
        if (_maxLeverage == 0) {
            revert PoolErrors.InvalidMaxLeverage();
        }
        maxLeverage = _maxLeverage;
        emit MaxLeverageChanged(_maxLeverage);
    }

    function _setMaintenanceMargin(uint256 _ratio) internal {
        _validateMaxValue(_ratio, MAX_MAINTENANCE_MARGIN);
        maintenanceMargin = _ratio;
        emit MaintenanceMarginChanged(_ratio);
    }

    function _setInterestRate(uint256 _interestRate, uint256 _accrualInterval) internal {
        if (_accrualInterval < 1) {
            revert PoolErrors.InvalidInterval();
        }
        _validateMaxValue(_interestRate, MAX_INTEREST_RATE);
        interestRate = _interestRate;
        accrualInterval = _accrualInterval;
        emit InterestRateSet(_interestRate, _accrualInterval);
    }

    function _setPositionFee(uint256 _positionFee, uint256 _liquidationFee) internal {
        _validateMaxValue(_positionFee, MAX_POSITION_FEE);
        _validateMaxValue(_liquidationFee, MAX_LIQUIDATION_FEE);
        fee.positionFee = _positionFee;
        fee.liquidationFee = _liquidationFee;
        emit PositionFeeSet(_positionFee, _liquidationFee);
    }

    function _validateToken(address _indexToken, address _collateralToken, Side _side, bool _isIncrease)
        internal
        view
        returns (bool)
    {
        if (!isAsset[_indexToken] || !isAsset[_collateralToken]) {
            return false;
        }

        if (_isIncrease && !isListed[_indexToken]) {
            return false;
        }

        return _side == Side.LONG ? _indexToken == _collateralToken : isStableCoin[_collateralToken];
    }

    function _calcAddLiquidity(address _tranche, address _token, uint256 _amountIn)
        internal
        view
        returns (uint256 amountInAfterFee, uint256 daoFee, uint256 lpAmount)
    {
        if (!isStableCoin[_token] && riskFactor[_token][_tranche] == 0) {
            revert PoolErrors.AddLiquidityNotAllowed(_tranche, _token);
        }
        uint256 tokenPrice = _getPrice(_token, false);
        uint256 valueChange = _amountIn * tokenPrice;
        uint256 _fee = _calcAddRemoveLPFee(_token, tokenPrice, valueChange, true);
        uint256 userAmount = MathUtils.frac(_amountIn, PRECISION - _fee, PRECISION);
        daoFee = _calcDaoFee(_amountIn - userAmount);
        amountInAfterFee = _amountIn - daoFee;

        uint256 poolValue = _getTrancheValue(_tranche, true);
        uint256 lpSupply = ILPToken(_tranche).totalSupply();
        if (lpSupply & poolValue == 0) {
            lpAmount = MathUtils.frac(userAmount, tokenPrice, LP_INITIAL_PRICE);
        } else {
            lpAmount = (userAmount * tokenPrice * lpSupply) / poolValue;
        }
    }

    function _calcRemoveLiquidity(address _tranche, address _tokenOut, uint256 _lpAmount)
        internal
        view
        returns (uint256 outAmount, uint256 outAmountAfterFee, uint256 daoFee)
    {
        uint256 tokenPrice = _getPrice(_tokenOut, true);
        uint256 poolValue = _getTrancheValue(_tranche, false);
        uint256 totalSupply = ILPToken(_tranche).totalSupply();
        uint256 valueChange = (_lpAmount * poolValue) / totalSupply;
        uint256 _fee = _calcAddRemoveLPFee(_tokenOut, tokenPrice, valueChange, false);
        outAmount = (_lpAmount * poolValue) / totalSupply / tokenPrice;
        outAmountAfterFee = MathUtils.frac(outAmount, PRECISION - _fee, PRECISION);
        daoFee = _calcDaoFee(outAmount - outAmountAfterFee);
    }

    function _transferIn(address _token, uint256 _amount) internal returns (uint256) {
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        return _getAmountIn(_token);
    }

    function _calcSwapOutput(address _tokenIn, address _tokenOut, uint256 _amountIn)
        internal
        view
        returns (uint256 amountOutAfterFee, uint256 feeAmount)
    {
        uint256 priceIn = _getPrice(_tokenIn, false);
        uint256 priceOut = _getPrice(_tokenOut, true);
        uint256 valueChange = _amountIn * priceIn;
        uint256 feeIn = _calcSwapFee(_tokenIn, priceIn, valueChange, true);
        uint256 feeOut = _calcSwapFee(_tokenOut, priceOut, valueChange, false);
        uint256 _fee = feeIn > feeOut ? feeIn : feeOut;

        amountOutAfterFee = valueChange * (PRECISION - _fee) / priceOut / PRECISION;
        feeAmount = (valueChange * _fee) / priceIn / PRECISION;
    }

    function _getPositionKey(address _owner, address _indexToken, address _collateralToken, Side _side)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(_owner, _indexToken, _collateralToken, _side));
    }

    function _validatePosition(
        Position memory _position,
        address _collateralToken,
        Side _side,
        bool _isIncrease,
        uint256 _indexPrice
    ) internal view {
        if ((_isIncrease && _position.size == 0)) {
            revert PoolErrors.InvalidPositionSize();
        }

        uint256 borrowIndex = poolTokens[_collateralToken].borrowIndex;
        if (_position.size < _position.collateralValue || _position.size > _position.collateralValue * maxLeverage) {
            revert PoolErrors.InvalidLeverage(_position.size, _position.collateralValue, maxLeverage);
        }
        if (_liquidatePositionAllowed(_position, _side, _indexPrice, borrowIndex)) {
            revert PoolErrors.UpdateCauseLiquidation();
        }
    }

    function _requireValidTokenPair(address _indexToken, address _collateralToken, Side _side, bool _isIncrease)
        internal
        view
    {
        if (!_validateToken(_indexToken, _collateralToken, _side, _isIncrease)) {
            revert PoolErrors.InvalidTokenPair(_indexToken, _collateralToken);
        }
    }

    function _validateAsset(address _token) internal view {
        if (!isAsset[_token]) {
            revert PoolErrors.UnknownToken(_token);
        }
    }

    function _validateTranche(address _tranche) internal view {
        if (!isTranche[_tranche]) {
            revert PoolErrors.InvalidTranche(_tranche);
        }
    }

    function _requireAddress(address _address) internal pure {
        if (_address == address(0)) {
            revert PoolErrors.ZeroAddress();
        }
    }

    function _requireAmount(uint256 _amount) internal pure returns (uint256) {
        if (_amount == 0) {
            revert PoolErrors.ZeroAmount();
        }

        return _amount;
    }

    function _requireListedToken(address _token) internal view {
        if (!isListed[_token]) {
            revert PoolErrors.AssetNotListed(_token);
        }
    }

    function _requireOrderManager() internal view {
        if (msg.sender != orderManager) {
            revert PoolErrors.OrderManagerOnly();
        }
    }

    function _validateFeeDistributor() internal view {
        if (msg.sender != feeDistributor) {
            revert PoolErrors.FeeDistributorOnly();
        }
    }

    function _validateMaxValue(uint256 _input, uint256 _max) internal pure {
        if (_input > _max) {
            revert PoolErrors.ValueTooHigh(_max);
        }
    }

    function _getAmountIn(address _token) internal returns (uint256 amount) {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        amount = balance - poolTokens[_token].poolBalance;
        poolTokens[_token].poolBalance = balance;
    }

    function _doTransferOut(address _token, address _to, uint256 _amount) internal {
        if (_amount != 0) {
            IERC20 token = IERC20(_token);
            token.safeTransfer(_to, _amount);
            poolTokens[_token].poolBalance = token.balanceOf(address(this));
        }
    }

    function _accrueInterest(address _token) internal returns (uint256) {
        PoolTokenInfo memory tokenInfo = poolTokens[_token];
        AssetInfo memory asset = _getPoolAsset(_token);
        uint256 _now = block.timestamp;
        if (tokenInfo.lastAccrualTimestamp & asset.poolAmount == 0) {
            tokenInfo.lastAccrualTimestamp = (_now / accrualInterval) * accrualInterval;
        } else {
            uint256 nInterval = (_now - tokenInfo.lastAccrualTimestamp) / accrualInterval;
            if (nInterval == 0) {
                return tokenInfo.borrowIndex;
            }

            tokenInfo.borrowIndex += (nInterval * interestRate * asset.reservedAmount) / asset.poolAmount;
            tokenInfo.lastAccrualTimestamp += nInterval * accrualInterval;
        }

        poolTokens[_token] = tokenInfo;
        emit InterestAccrued(_token, tokenInfo.borrowIndex);
        return tokenInfo.borrowIndex;
    }

    /// @notice calculate adjusted fee rate
    /// fee is increased or decreased based on action's effect to pool amount
    /// each token has their target weight set by gov
    /// if action make the weight of token far from its target, fee will be increase, vice versa
    function _calcSwapFee(address _token, uint256 _tokenPrice, uint256 _valueChange, bool _isSwapIn)
        internal
        view
        returns (uint256)
    {
        uint256 poolValue = _getPoolValue(_isSwapIn);
        (uint256 baseSwapFee, uint256 taxBasisPoint) = isStableCoin[_token]
            ? (fee.stableCoinBaseSwapFee, fee.stableCoinTaxBasisPoint)
            : (fee.baseSwapFee, fee.taxBasisPoint);
        return _calcFeeRate(poolValue, _token, _tokenPrice, _valueChange, baseSwapFee, taxBasisPoint, _isSwapIn);
    }

    function _calcAddRemoveLPFee(address _token, uint256 _tokenPrice, uint256 _valueChange, bool _isAdd)
        internal
        view
        returns (uint256)
    {
        return _calcFeeRate(
            _getPoolValue(_isAdd), _token, _tokenPrice, _valueChange, addRemoveLiquidityFee, fee.taxBasisPoint, _isAdd
        );
    }

    function _calcFeeRate(
        uint256 _poolValue,
        address _token,
        uint256 _tokenPrice,
        uint256 _valueChange,
        uint256 _baseFee,
        uint256 _taxBasisPoint,
        bool _isIncrease
    ) internal view returns (uint256) {
        uint256 _targetValue = totalWeight == 0 ? 0 : (targetWeights[_token] * _poolValue) / totalWeight;
        if (_targetValue == 0) {
            return _baseFee;
        }
        uint256 _currentValue = _tokenPrice * _getPoolAsset(_token).poolAmount;
        uint256 _nextValue = _isIncrease ? _currentValue + _valueChange : _currentValue - _valueChange;
        uint256 initDiff = MathUtils.diff(_currentValue, _targetValue);
        uint256 nextDiff = MathUtils.diff(_nextValue, _targetValue);
        if (nextDiff < initDiff) {
            uint256 feeAdjust = (_taxBasisPoint * initDiff) / _targetValue;
            return MathUtils.zeroCapSub(_baseFee, feeAdjust);
        } else {
            uint256 avgDiff = (initDiff + nextDiff) / 2;
            uint256 feeAdjust = avgDiff > _targetValue ? _taxBasisPoint : (_taxBasisPoint * avgDiff) / _targetValue;
            return _baseFee + feeAdjust;
        }
    }

    function _getPoolValue(bool _max) internal view returns (uint256 sum) {
        uint256[] memory prices = _getAllPrices(_max);
        for (uint256 i = 0; i < allTranches.length;) {
            sum += _getTrancheValue(allTranches[i], prices);
            unchecked {
                ++i;
            }
        }
    }

    function _getAllPrices(bool _max) internal view returns (uint256[] memory) {
        return oracle.getMultiplePrices(allAssets, _max);
    }

    function _getTrancheValue(address _tranche, bool _max) internal view returns (uint256 sum) {
        return _getTrancheValue(_tranche, _getAllPrices(_max));
    }

    function _getTrancheValue(address _tranche, uint256[] memory prices) internal view returns (uint256 sum) {
        SignedInt memory aum = SignedIntOps.wrap(uint256(0));

        for (uint256 i = 0; i < allAssets.length;) {
            address token = allAssets[i];
            assert(isAsset[token]); // double check
            AssetInfo memory asset = trancheAssets[_tranche][token];
            uint256 price = prices[i];
            if (isStableCoin[token]) {
                aum = aum.add(price * asset.poolAmount);
            } else {
                aum = aum.add(_calcManagedValue(_tranche, token, asset, price));
            }
            unchecked {
                ++i;
            }
        }

        // aum MUST not be negative. If it is, please debug
        return aum.toUint();
    }

    function _calcManagedValue(address _tranche, address _token, AssetInfo memory _asset, uint256 _price)
        internal
        view
        returns (SignedInt memory aum)
    {
        uint256 averageShortPrice = averageShortPrices[_tranche][_token];
        SignedInt memory shortPnl = _asset.totalShortSize == 0
            ? SignedIntOps.wrap(uint256(0))
            : SignedIntOps.wrap(averageShortPrice).sub(_price).mul(_asset.totalShortSize).div(averageShortPrice);

        aum = SignedIntOps.wrap(_asset.poolAmount).sub(_asset.reservedAmount).mul(_price).add(_asset.guaranteedValue);
        aum = aum.sub(shortPnl);
    }

    function _decreaseTranchePoolAmount(address _tranche, address _token, uint256 _amount) internal {
        AssetInfo memory asset = trancheAssets[_tranche][_token];
        asset.poolAmount -= _amount;
        if (asset.poolAmount < asset.reservedAmount) {
            revert PoolErrors.InsufficientPoolAmount(_token);
        }
        trancheAssets[_tranche][_token] = asset;
    }

    /// @notice return pseudo pool asset by sum all tranches asset
    function _getPoolAsset(address _token) internal view returns (AssetInfo memory asset) {
        for (uint256 i = 0; i < allTranches.length;) {
            address tranche = allTranches[i];
            asset.poolAmount += trancheAssets[tranche][_token].poolAmount;
            asset.reservedAmount += trancheAssets[tranche][_token].reservedAmount;
            asset.totalShortSize += trancheAssets[tranche][_token].totalShortSize;
            asset.guaranteedValue += trancheAssets[tranche][_token].guaranteedValue;
            unchecked {
                ++i;
            }
        }
    }

    /// @notice reserve asset when open position
    function _reservePoolAsset(
        bytes32 _key,
        IncreasePositionVars memory _vars,
        address _indexToken,
        address _collateralToken,
        Side _side
    ) internal {
        AssetInfo memory collateral = _getPoolAsset(_collateralToken);

        if (collateral.reservedAmount + _vars.reserveAdded > collateral.poolAmount) {
            revert PoolErrors.InsufficientPoolAmount(_collateralToken);
        }

        poolTokens[_collateralToken].feeReserve += _vars.daoFee;
        _reserveTrancheAsset(_key, _vars, _indexToken, _collateralToken, _side);
    }

    /// @notice release asset and take or distribute realized PnL when close position
    function _releasePoolAsset(
        bytes32 _key,
        DecreasePositionVars memory _vars,
        address _indexToken,
        address _collateralToken,
        Side _side
    ) internal {
        AssetInfo memory collateral = _getPoolAsset(_collateralToken);

        if (collateral.reservedAmount < _vars.reserveReduced) {
            revert PoolErrors.ReserveReduceTooMuch(_collateralToken);
        }

        poolTokens[_collateralToken].feeReserve += _vars.daoFee;

        _releaseTranchesAsset(_key, _vars, _indexToken, _collateralToken, _side);
    }

    function _reserveTrancheAsset(
        bytes32 _key,
        IncreasePositionVars memory _vars,
        address _indexToken,
        address _collateralToken,
        Side _side
    ) internal {
        uint256[] memory shares;
        uint256 totalShare;
        if (_vars.reserveAdded != 0) {
            totalShare = _vars.reserveAdded;
            shares = _calcTrancheSharesAmount(_indexToken, _collateralToken, totalShare, false);
        } else {
            totalShare = _vars.collateralAmount;
            shares = _calcTrancheSharesAmount(_indexToken, _collateralToken, totalShare, true);
        }

        for (uint256 i = 0; i < shares.length;) {
            address tranche = allTranches[i];
            uint256 share = shares[i];
            AssetInfo storage collateral = trancheAssets[tranche][_collateralToken];

            uint256 reserveAmount = MathUtils.frac(_vars.reserveAdded, share, totalShare);
            tranchePositionReserves[tranche][_key] += reserveAmount;
            collateral.reservedAmount += reserveAmount;

            if (_side == Side.LONG) {
                collateral.poolAmount = MathUtils.addThenSubWithFraction(
                    collateral.poolAmount, _vars.collateralAmount, _vars.daoFee, share, totalShare
                );
                // ajust guaranteed
                // guaranteed value = total(size - (collateral - fee))
                // delta_guaranteed value = sizechange + fee - collateral
                collateral.guaranteedValue = MathUtils.addThenSubWithFraction(
                    collateral.guaranteedValue,
                    _vars.sizeChanged + _vars.feeValue,
                    _vars.collateralValueAdded,
                    share,
                    totalShare
                );
            } else {
                AssetInfo storage indexAsset = trancheAssets[tranche][_indexToken];
                uint256 sizeChanged = MathUtils.frac(_vars.sizeChanged, share, totalShare);
                uint256 indexPrice = _vars.indexPrice;
                _updateGlobalShortPrice(tranche, _indexToken, sizeChanged, true, indexPrice, SignedIntOps.wrap(0));
                indexAsset.totalShortSize += sizeChanged;
            }
            unchecked {
                ++i;
            }
        }
    }

    function _releaseTranchesAsset(
        bytes32 _key,
        DecreasePositionVars memory _vars,
        address _indexToken,
        address _collateralToken,
        Side _side
    ) internal {
        uint256 totalShare = positions[_key].reserveAmount;

        for (uint256 i = 0; i < allTranches.length;) {
            address tranche = allTranches[i];
            uint256 share = tranchePositionReserves[tranche][_key];
            AssetInfo storage collateral = trancheAssets[tranche][_collateralToken];

            {
                uint256 reserveReduced = MathUtils.frac(_vars.reserveReduced, share, totalShare);
                tranchePositionReserves[tranche][_key] -= reserveReduced;
                collateral.reservedAmount -= reserveReduced;
            }
            collateral.poolAmount =
                SignedIntOps.wrap(collateral.poolAmount).sub(_vars.poolAmountReduced.frac(share, totalShare)).toUint();

            SignedInt memory pnl = _vars.pnl.frac(share, totalShare);
            if (_side == Side.LONG) {
                collateral.guaranteedValue = MathUtils.addThenSubWithFraction(
                    collateral.guaranteedValue, _vars.collateralReduced, _vars.sizeChanged, share, totalShare
                );
            } else {
                AssetInfo storage indexAsset = trancheAssets[tranche][_indexToken];
                uint256 sizeChanged = MathUtils.frac(_vars.sizeChanged, share, totalShare);
                uint256 indexPrice = _vars.indexPrice;
                _updateGlobalShortPrice(tranche, _indexToken, sizeChanged, false, indexPrice, pnl);
                indexAsset.totalShortSize = MathUtils.zeroCapSub(indexAsset.totalShortSize, sizeChanged);
            }
            emit PnLDistributed(_collateralToken, tranche, pnl.abs, pnl.isPos());
            unchecked {
                ++i;
            }
        }
    }

    /// @notice distributed amount of token to all tranches
    /// @param _indexToken the token of which risk factors is used to calculate ratio
    /// @param _collateralToken pool amount or reserve of this token will be changed. So we must cap the amount to be changed to the
    /// max available value of this token (pool amount - reserve) when _isIncreasePoolAmount set to false
    /// @param _isIncreasePoolAmount set to true when "increase pool amount" or "decrease reserve amount"
    function _calcTrancheSharesAmount(
        address _indexToken,
        address _collateralToken,
        uint256 _amount,
        bool _isIncreasePoolAmount
    ) internal view returns (uint256[] memory reserves) {
        uint256 nTranches = allTranches.length;
        reserves = new uint[](nTranches);
        uint256[] memory factors = new uint[](nTranches);
        uint256[] memory maxShare = new uint[](nTranches);

        for (uint256 i = 0; i < nTranches;) {
            address tranche = allTranches[i];
            AssetInfo memory asset = trancheAssets[tranche][_collateralToken];
            factors[i] = isStableCoin[_indexToken] ? 1 : riskFactor[_indexToken][tranche];
            maxShare[i] = _isIncreasePoolAmount ? type(uint256).max : asset.poolAmount - asset.reservedAmount;
            unchecked {
                ++i;
            }
        }

        uint256 totalFactor = isStableCoin[_indexToken] ? nTranches : totalRiskFactor[_indexToken];

        for (uint256 k = 0; k < nTranches;) {
            unchecked {
                ++k;
            }
            uint256 totalRiskFactor_ = totalFactor;
            for (uint256 i = 0; i < nTranches;) {
                uint256 riskFactor_ = factors[i];
                if (riskFactor_ != 0) {
                    uint256 shareAmount = MathUtils.frac(_amount, riskFactor_, totalRiskFactor_);
                    uint256 availableAmount = maxShare[i] - reserves[i];
                    if (shareAmount >= availableAmount) {
                        // skip this tranche on next rounds since it's full
                        shareAmount = availableAmount;
                        totalFactor -= riskFactor_;
                        factors[i] = 0;
                    }

                    reserves[i] += shareAmount;
                    _amount -= shareAmount;
                    totalRiskFactor_ -= riskFactor_;
                    if (_amount == 0) {
                        return reserves;
                    }
                }
                unchecked {
                    ++i;
                }
            }
        }

        revert PoolErrors.CannotDistributeToTranches(_indexToken, _collateralToken, _amount, _isIncreasePoolAmount);
    }

    /// @notice rebalance fund between tranches after swap token
    function _rebalanceTranches(address _tokenIn, uint256 _amountIn, address _tokenOut, uint256 _amountOut) internal {
        // amount devided to each tranche
        uint256[] memory outAmounts;

        if (!isStableCoin[_tokenIn] && isStableCoin[_tokenOut]) {
            // use token in as index
            outAmounts = _calcTrancheSharesAmount(_tokenIn, _tokenOut, _amountOut, false);
        } else {
            // use token out as index
            outAmounts = _calcTrancheSharesAmount(_tokenOut, _tokenOut, _amountOut, false);
        }

        for (uint256 i = 0; i < allTranches.length;) {
            address tranche = allTranches[i];
            trancheAssets[tranche][_tokenOut].poolAmount -= outAmounts[i];
            trancheAssets[tranche][_tokenIn].poolAmount += MathUtils.frac(_amountIn, outAmounts[i], _amountOut);
            unchecked {
                ++i;
            }
        }
    }

    function _liquidatePositionAllowed(Position memory _position, Side _side, uint256 _indexPrice, uint256 _borrowIndex)
        internal
        view
        returns (bool allowed)
    {
        if (_position.size == 0) {
            return false;
        }
        // calculate fee needed when close position
        uint256 feeValue = _calcPositionFee(_position, _position.size, _borrowIndex);
        SignedInt memory pnl = PositionUtils.calcPnl(_side, _position.size, _position.entryPrice, _indexPrice);
        SignedInt memory collateral = pnl.add(_position.collateralValue);

        // liquidation occur when collateral cannot cover margin fee or lower than maintenance margin
        return collateral.mul(PRECISION).lt(_position.size * maintenanceMargin)
            || collateral.lt(feeValue + fee.liquidationFee);
    }

    function _calcDecreasePayout(
        Position memory _position,
        address _indexToken,
        address _collateralToken,
        Side _side,
        uint256 _sizeChanged,
        uint256 _collateralChanged,
        bool isLiquidate
    ) internal view returns (DecreasePositionVars memory vars) {
        // clean user input
        vars.sizeChanged = MathUtils.min(_position.size, _sizeChanged);
        vars.collateralReduced = _position.collateralValue < _collateralChanged || _position.size == _sizeChanged
            ? _position.collateralValue
            : _collateralChanged;

        vars.indexPrice = _getPrice(_indexToken, _side, false);
        vars.collateralPrice = _getPrice(_collateralToken, false);

        uint256 borrowIndex = poolTokens[_collateralToken].borrowIndex;

        // vars is santinized, only trust these value from now on
        vars.reserveReduced = (_position.reserveAmount * vars.sizeChanged) / _position.size;
        vars.pnl = PositionUtils.calcPnl(_side, vars.sizeChanged, _position.entryPrice, vars.indexPrice);
        vars.feeValue = _calcPositionFee(_position, vars.sizeChanged, borrowIndex);
        vars.daoFee = vars.feeValue * fee.daoFee / vars.collateralPrice / PRECISION;

        SignedInt memory remainingCollateral = SignedIntOps.wrap(_position.collateralValue).sub(vars.collateralReduced);
        SignedInt memory payoutValue = vars.pnl.add(vars.collateralReduced).sub(vars.feeValue);
        if (isLiquidate) {
            payoutValue = payoutValue.sub(fee.liquidationFee);
        }
        if (payoutValue.isNeg()) {
            // deduct uncovered lost from collateral
            remainingCollateral = remainingCollateral.add(payoutValue);
            payoutValue = SignedIntOps.wrap(0);
        }

        vars.remainingCollateral = remainingCollateral.isNeg() ? 0 : remainingCollateral.abs;
        vars.payout = payoutValue.isNeg() ? 0 : payoutValue.abs / vars.collateralPrice;
        SignedInt memory poolValueReduced = _side == Side.LONG ? payoutValue.add(vars.feeValue) : vars.pnl;
        if (poolValueReduced.isNeg()) {
            // cap the value of pool amount change to collateral value after fee in case of lost
            uint256 totalFee = isLiquidate ? vars.feeValue + fee.liquidationFee : vars.feeValue;
            poolValueReduced.abs =
                MathUtils.min(poolValueReduced.abs, MathUtils.zeroCapSub(_position.collateralValue, totalFee));
        }
        vars.poolAmountReduced = poolValueReduced.div(vars.collateralPrice);
    }

    function _calcPositionFee(Position memory _position, uint256 _sizeChanged, uint256 _borrowIndex)
        internal
        view
        returns (uint256 feeValue)
    {
        uint256 borrowFee = ((_borrowIndex - _position.borrowIndex) * _position.size) / PRECISION;
        uint256 positionFee = (_sizeChanged * fee.positionFee) / PRECISION;
        feeValue = borrowFee + positionFee;
    }

    function _getPrice(address _token, Side _side, bool _isIncrease) internal view returns (uint256) {
        // max == (_isIncrease & _side = LONG) | (!_increase & _side = SHORT)
        // max = _isIncrease == (_side == Side.LONG);
        return _getPrice(_token, _isIncrease == (_side == Side.LONG));
    }

    function _getPrice(address _token, bool _max) internal view returns (uint256) {
        return oracle.getPrice(_token, _max);
    }

    function _updateGlobalShortPrice(
        address _tranche,
        address _indexToken,
        uint256 _sizeChanged,
        bool _isIncrease,
        uint256 _indexPrice,
        SignedInt memory _realizedPnl
    ) internal {
        uint256 lastSize = trancheAssets[_tranche][_indexToken].totalShortSize;
        uint256 nextSize = _isIncrease ? lastSize + _sizeChanged : MathUtils.zeroCapSub(lastSize, _sizeChanged);
        uint256 entryPrice = averageShortPrices[_tranche][_indexToken];
        averageShortPrices[_tranche][_indexToken] =
            PositionUtils.calcAveragePrice(Side.SHORT, lastSize, nextSize, entryPrice, _indexPrice, _realizedPnl);
    }

    function _calcDaoFee(uint256 _feeAmount) internal view returns (uint256) {
        return MathUtils.frac(_feeAmount, fee.daoFee, PRECISION);
    }
}
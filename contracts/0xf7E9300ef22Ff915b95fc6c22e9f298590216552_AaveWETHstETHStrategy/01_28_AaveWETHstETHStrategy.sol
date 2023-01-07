// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../../enums/ProtocolEnum.sol";
import "../ETHBaseStrategy.sol";
import "../../../external/aave/ILendingPool.sol";
import "../../../external/aave/DataTypes.sol";
import "../../../external/aave/UserConfiguration.sol";
import "../../../external/aave/ILendingPoolAddressesProvider.sol";
import "../../../external/aave/IPriceOracleGetter.sol";
import "../../../external/curve/ICurveLiquidityFarmingPool.sol";
import "../../../external/euler/IEulerDToken.sol";
import "../../../external/weth/IWeth.sol";

contract AaveWETHstETHStrategy is ETHBaseStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address internal constant CURVE_POOL_ADDRESS = 0xDC24316b9AE028F1497c275EB9192a3Ea0f67022;
    address public constant DEBT_W_ETH = 0xF63B34710400CAd3e044cFfDcAb00a0f32E33eCf;
    address public constant W_ETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant ST_ETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address public constant A_ST_ETH = 0x1982b2F5814301d4e9a8b0201555376e62F82428;
    address public constant A_WETH = 0x030bA81f1c18d280636F32af80b9AAd02Cf0854e;
    uint256 public constant RESERVE_ID_OF_ST_ETH = 31;
    uint256 public constant BPS = 10000;
    /**
     * @dev Aave Lending Pool Provider
     */
    ILendingPoolAddressesProvider internal constant aaveProvider =
        ILendingPoolAddressesProvider(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5);
    ICurveLiquidityFarmingPool private curvePool;
    uint256 public borrowFactor;
    uint256 public borrowFactorMax;
    uint256 public borrowFactorMin;
    uint256 public borrowCount;
    uint256 public leverage;
    uint256 public leverageMax;
    uint256 public leverageMin;
    address internal constant EULER_ADDRESS = 0x27182842E098f60e3D576794A5bFFb0777E025d3;
    address internal constant W_ETH_EULER_D_TOKEN = 0x62e28f054efc24b26A794F5C1249B6349454352C;

    /// Events

    /// @param _borrowFactor The new borrow factor
    event UpdateBorrowFactor(uint256 _borrowFactor);
    /// @param _borrowFactorMax The new max borrow factor
    event UpdateBorrowFactorMax(uint256 _borrowFactorMax);
    /// @param _borrowFactorMin The new min borrow factor
    event UpdateBorrowFactorMin(uint256 _borrowFactorMin);
    /// @param _borrowCount The new count Of borrow
    event UpdateBorrowCount(uint256 _borrowCount);
    /// @param _remainingAmount The amount of aToken will still be used as collateral to borrow eth
    /// @param _overflowAmount The amount of debt token that exceeds the maximum allowable loan
    event Rebalance(uint256 _remainingAmount, uint256 _overflowAmount);

    function initialize(
        address _vault,
        string memory _name,
        uint256 _borrowFactor,
        uint256 _borrowFactorMax,
        uint256 _borrowFactorMin
    ) external initializer {
        address[] memory _wants = new address[](1);
        //weth
        _wants[0] = NativeToken.NATIVE_TOKEN;
        borrowFactor = _borrowFactor;
        borrowFactorMin = _borrowFactorMin;
        borrowFactorMax = _borrowFactorMax;
        borrowCount = 3;
        leverage = _calLeverage(_borrowFactor, 10000, 3);
        leverageMax = _calLeverage(_borrowFactorMax, 10000, 3);
        leverageMin = _calLeverage(_borrowFactorMin, 10000, 3);

        address _lendingPoolAddress = aaveProvider.getLendingPool();
        IERC20Upgradeable(ST_ETH).safeApprove(_lendingPoolAddress, type(uint256).max);
        IERC20Upgradeable(W_ETH).safeApprove(_lendingPoolAddress, type(uint256).max);
        IERC20Upgradeable(ST_ETH).safeApprove(CURVE_POOL_ADDRESS, type(uint256).max);

        super._initialize(_vault, uint16(ProtocolEnum.Aave), _name, _wants);
    }

    /// @notice Sets `_borrowFactor` to `borrowFactor`
    /// @param _borrowFactor The new value of `borrowFactor`
    /// Requirements: only vault manager can call
    function setBorrowFactor(uint256 _borrowFactor) external isVaultManager {
        require(
            _borrowFactor < BPS &&
                _borrowFactor >= borrowFactorMin &&
                _borrowFactor <= borrowFactorMax,
            "setting output the range"
        );
        borrowFactor = _borrowFactor;
        leverage = _getNewLeverage(_borrowFactor);

        emit UpdateBorrowFactor(_borrowFactor);
    }

    /// @notice Sets `_borrowFactorMax` to `borrowFactorMax`
    /// @param _borrowFactorMax The new value of `borrowFactorMax`
    /// Requirements: only vault manager can call
    function setBorrowFactorMax(uint256 _borrowFactorMax) external isVaultManager {
        require(
            _borrowFactorMax < BPS && _borrowFactorMax > borrowFactor,
            "setting output the range"
        );
        borrowFactorMax = _borrowFactorMax;
        leverageMax = _getNewLeverage(_borrowFactorMax);

        emit UpdateBorrowFactorMax(_borrowFactorMax);
    }

    /// @notice Sets `_borrowFactorMin` to `borrowFactorMin`
    /// @param _borrowFactorMin The new value of `borrowFactorMin`
    /// Requirements: only vault manager can call
    function setBorrowFactorMin(uint256 _borrowFactorMin) external isVaultManager {
        require(
            _borrowFactorMin < BPS && _borrowFactorMin < borrowFactor,
            "setting output the range"
        );
        borrowFactorMin = _borrowFactorMin;
        leverageMin = _getNewLeverage(_borrowFactorMin);

        emit UpdateBorrowFactorMin(_borrowFactorMin);
    }

    /// @notice Sets `_borrowCount` to `borrowCount`
    /// @param _borrowCount The new value of `borrowCount`
    /// Requirements: only vault manager can call
    function setBorrowCount(uint256 _borrowCount) external isVaultManager {
        require(_borrowCount <= 10 && _borrowCount > 0, "setting output the range");
        borrowCount = _borrowCount;
        _updateAllLeverage(_borrowCount);
        emit UpdateBorrowCount(_borrowCount);
    }

    /// @inheritdoc ETHBaseStrategy
    function getVersion() external pure virtual override returns (string memory) {
        return "1.0.1";
    }

    /// @inheritdoc ETHBaseStrategy
    function getWantsInfo()
        external
        view
        virtual
        override
        returns (address[] memory _assets, uint256[] memory _ratios)
    {
        _assets = wants;
        _ratios = new uint256[](1);
        _ratios[0] = 1e18;
    }

    /// @inheritdoc ETHBaseStrategy
    function getOutputsInfo()
        external
        view
        virtual
        override
        returns (OutputInfo[] memory _outputsInfo)
    {
        _outputsInfo = new OutputInfo[](1);
        OutputInfo memory _info = _outputsInfo[0];
        _info.outputCode = 0;
        _info.outputTokens = wants;
    }

    /// @inheritdoc ETHBaseStrategy
    function getPositionDetail()
        public
        view
        virtual
        override
        returns (
            address[] memory _tokens,
            uint256[] memory _amounts,
            bool _isETH,
            uint256 _ethValue
        )
    {
        _tokens = wants;
        _amounts = new uint256[](1);

        uint256 _wethDebtAmount = balanceOfToken(DEBT_W_ETH);
        uint256 _wethAmount = balanceOfToken(W_ETH) + balanceOfToken(NativeToken.NATIVE_TOKEN);
        uint256 _stEthAmount = balanceOfToken(A_ST_ETH) + balanceOfToken(ST_ETH);

        _isETH = true;
        _ethValue = queryTokenValueInETH(ST_ETH, _stEthAmount) + _wethAmount - _wethDebtAmount;
    }

    /// @inheritdoc ETHBaseStrategy
    function get3rdPoolAssets() external view override returns (uint256) {
        return queryTokenValueInETH(ST_ETH, IERC20Upgradeable(ST_ETH).totalSupply());
    }

    /// @inheritdoc ETHBaseStrategy
    function depositTo3rdPool(address[] memory _assets, uint256[] memory _amounts)
        internal
        override
    {
        uint256 _amount = _amounts[0];
        address _curvePoolAddress = CURVE_POOL_ADDRESS;
        ICurveLiquidityFarmingPool(_curvePoolAddress).exchange{value: _amount}(0, 1, _amount, 0);
        address _stETH = ST_ETH;
        uint256 _receivedStETHAmount = balanceOfToken(_stETH);
        if (_receivedStETHAmount > 0) {
            ILendingPool _aaveLendingPool = ILendingPool(aaveProvider.getLendingPool());
            _aaveLendingPool.deposit(_stETH, _receivedStETHAmount, address(this), 0);
            {
                uint256 _userConfigurationData = _aaveLendingPool
                    .getUserConfiguration(address(this))
                    .data;
                if (
                    !UserConfiguration.isUsingAsCollateral(
                        _userConfigurationData,
                        RESERVE_ID_OF_ST_ETH
                    )
                ) {
                    _aaveLendingPool.setUserUseReserveAsCollateral(_stETH, true);
                }
            }

            uint256 _stETHPrice = IPriceOracleGetter(aaveProvider.getPriceOracle()).getAssetPrice(
                _stETH
            );

            (uint256 _remainingAmount, uint256 _overflowAmount) = _borrowStandardInfo(
                A_ST_ETH,
                DEBT_W_ETH,
                _stETHPrice,
                _curvePoolAddress
            );
            _rebalance(_remainingAmount, _overflowAmount, _stETHPrice, _curvePoolAddress);
        }
    }

    /// @inheritdoc ETHBaseStrategy
    function withdrawFrom3rdPool(
        uint256 _withdrawShares,
        uint256 _totalShares,
        uint256 _outputCode
    ) internal override {
        uint256 _redeemAmount = (balanceOfToken(A_ST_ETH) * _withdrawShares) / _totalShares;
        uint256 _repayBorrowAmount = (balanceOfToken(DEBT_W_ETH) * _withdrawShares) / _totalShares;
        _repay(_redeemAmount, _repayBorrowAmount);
    }

    /// @notice Returns the info of borrow.
    /// @return _remainingAmount The amount of debt token will still can to borrow
    /// @return _overflowAmount The amount of aToken that exceeds the maximum allowable loan
    function borrowInfo() public view returns (uint256 _remainingAmount, uint256 _overflowAmount) {
        IPriceOracleGetter _aaveOracle = IPriceOracleGetter(aaveProvider.getPriceOracle());
        uint256 _stETHPrice = _aaveOracle.getAssetPrice(ST_ETH);
        (_remainingAmount, _overflowAmount) = _borrowInfo(
            A_ST_ETH,
            DEBT_W_ETH,
            _stETHPrice,
            CURVE_POOL_ADDRESS
        );
    }

    /// @notice Rebalance the collateral of this strategy
    /// Requirements: only keeper can call
    function rebalance() external isKeeper {
        address _stETH = ST_ETH;
        IPriceOracleGetter _aaveOracle = IPriceOracleGetter(aaveProvider.getPriceOracle());
        uint256 _stETHPrice = _aaveOracle.getAssetPrice(_stETH);
        address _curvePoolAddress = CURVE_POOL_ADDRESS;

        (uint256 _remainingAmount, uint256 _overflowAmount) = _borrowInfo(
            A_ST_ETH,
            DEBT_W_ETH,
            _stETHPrice,
            _curvePoolAddress
        );
        _rebalance(_remainingAmount, _overflowAmount, _stETHPrice, _curvePoolAddress);
    }

    // euler flashload call only by  euler
    function onFlashLoan(bytes memory data) external {
        address _eulerAddress = EULER_ADDRESS;
        address _wETH = W_ETH;
        address _stETH = ST_ETH;
        require(msg.sender == _eulerAddress, "invalid call");
        (
            uint256 _operationCode,
            uint256 _depositOrRedeemAmount,
            uint256 _borrowOrRepayBorrowAmount,
            uint256 _flashLoanAmount,
            uint256 _origBalance
        ) = abi.decode(data, (uint256, uint256, uint256, uint256, uint256));
        uint256 _wethAmount = balanceOfToken(_wETH);
        require(_wethAmount >= _origBalance + _flashLoanAmount, "not received enough");
        ILendingPool _aaveLendingPool = ILendingPool(aaveProvider.getLendingPool());

        // 0 - deposit stETH; 1 - withdraw stETH
        if (_operationCode < 1) {
            IWeth(_wETH).withdraw(_wethAmount);
            ICurveLiquidityFarmingPool(CURVE_POOL_ADDRESS).exchange{value: _wethAmount}(
                0,
                1,
                _wethAmount,
                0
            );
            address _asset = _stETH;
            uint256 _amount = balanceOfToken(_asset);
            _aaveLendingPool.deposit(_asset, _amount, address(this), 0);

            _aaveLendingPool.borrow(
                _wETH,
                _borrowOrRepayBorrowAmount,
                uint256(DataTypes.InterestRateMode.VARIABLE),
                0,
                address(this)
            );
        } else {
            if (_borrowOrRepayBorrowAmount > 0) {
                _aaveLendingPool.repay(
                    _wETH,
                    _borrowOrRepayBorrowAmount,
                    uint256(DataTypes.InterestRateMode.VARIABLE),
                    address(this)
                );
            }
            if (_depositOrRedeemAmount > 0) {
                _aaveLendingPool.withdraw(_stETH, _depositOrRedeemAmount, address(this));
                uint256 _stETHAmount = balanceOfToken(_stETH);
                ICurveLiquidityFarmingPool(CURVE_POOL_ADDRESS).exchange(1, 0, _stETHAmount, 0);
                IWeth(_wETH).deposit{value: _flashLoanAmount}();
            }
        }
        IERC20Upgradeable(_wETH).safeTransfer(_eulerAddress, _flashLoanAmount);
    }

    /// @notice repayBorrow and redeem collateral
    function _repay(uint256 _redeemAmount, uint256 _repayBorrowAmount) internal {
        // 0 - deposit stETH; 1 - withdraw stETH
        uint256 _operationCode = 1;
        bytes memory _params = abi.encodePacked(
            _operationCode,
            _redeemAmount,
            _repayBorrowAmount,
            _repayBorrowAmount,
            balanceOfToken(W_ETH)
        );
        IEulerDToken(W_ETH_EULER_D_TOKEN).flashLoan(_repayBorrowAmount, _params);
    }

    /// @notice Rebalance the collateral of this strategy
    function _rebalance(
        uint256 _remainingAmount,
        uint256 _overflowAmount,
        uint256 _stETHPrice,
        address _curvePoolAddress
    ) internal {
        ICurveLiquidityFarmingPool _curvePool = ICurveLiquidityFarmingPool(_curvePoolAddress);
        if (_remainingAmount > 0) {
            uint256 _borrowAmount = _remainingAmount;
            uint256 _depositAmount = type(uint256).max;
            // 0 - deposit stETH; 1 - withdraw stETH
            uint256 _operationCode = 0;
            bytes memory _params = abi.encodePacked(
                _operationCode,
                _depositAmount,
                _borrowAmount,
                _borrowAmount,
                balanceOfToken(W_ETH)
            );
            IEulerDToken(W_ETH_EULER_D_TOKEN).flashLoan(_borrowAmount, _params);
        } else if (_overflowAmount > 0) {
            uint256 _repayBorrowAmount = _curvePool.get_dy(1, 0, _overflowAmount);
            uint256 _redeemAmount = _overflowAmount;
            //stETH
            uint256 _aStETHAmount = balanceOfToken(A_ST_ETH);
            if (_aStETHAmount < _redeemAmount) {
                _redeemAmount = _aStETHAmount;
            } else if (_aStETHAmount > _redeemAmount) {
                if (_aStETHAmount > _redeemAmount + 1) {
                    _redeemAmount = _redeemAmount + 2;
                } else {
                    _redeemAmount = _redeemAmount + 1;
                }
            }
            _repay(_redeemAmount, _repayBorrowAmount);
        }
        if (_remainingAmount + _overflowAmount > 0) {
            emit Rebalance(_remainingAmount, _overflowAmount);
        }
    }

    /// @notice Returns the info of borrow.
    /// @dev _needCollateralAmount = (_debtAmount * _leverage) / (_leverage - BPS);
    /// _debtAmount_now / _needCollateralAmount = （_leverage - 10000) / _leverage;
    /// _leverage = (capitalAmount + _debtAmount_now) *10000 / capitalAmount;
    /// _debtAmount_now = capitalAmount * (_leverage - 10000)
    /// @return _remainingAmount The amount of debt token will still can to borrow
    /// @return _overflowAmount The amount of aToken that exceeds the maximum allowable loan
    function _borrowInfo(
        address _aToken,
        address _dToken,
        uint256 _stETHPrice,
        address _curvePoolAddress
    ) private view returns (uint256 _remainingAmount, uint256 _overflowAmount) {
        uint256 _bps = BPS;
        uint256 _leverage = leverage;
        uint256 _debtAmountMax;
        uint256 _debtAmountMin;
        uint256 _debtAmount = balanceOfToken(_dToken);
        uint256 _collateralAmountInETH = (balanceOfToken(_aToken) * _stETHPrice) / 1e18;

        {
            uint256 _leverageMax = leverageMax;
            uint256 _leverageMin = leverageMin;
            uint256 _capitalAmountInETH = (_collateralAmountInETH - _debtAmount);
            _debtAmountMax = (_capitalAmountInETH * (_leverageMax - _bps)) / _bps;
            _debtAmountMin = (_capitalAmountInETH * (_leverageMin - _bps)) / _bps;
        }

        if (_debtAmount > _debtAmountMax) {
            //(_debtAmount-x*_exchangeRate)/(_collateralAmountInETH- x * _stETHPrice) = (leverage-BPS)/leverage
            // stETH to ETH
            uint256 _exchangeRate = ICurveLiquidityFarmingPool(_curvePoolAddress).get_dy(
                1,
                0,
                1e18
            );
            _overflowAmount =
                (_debtAmount * _leverage - _collateralAmountInETH * (_leverage - _bps)) /
                ((_leverage * _exchangeRate) / 1e18 - ((_leverage - _bps) * _stETHPrice) / 1e18);
        } else if (_debtAmount < _debtAmountMin) {
            //(_debtAmount+x)/(_collateralAmountInETH+_exchangeRate * x) = (leverage-BPS)/leverage
            // ETH to stETH
            uint256 _exchangeRate = ICurveLiquidityFarmingPool(_curvePoolAddress).get_dy(
                0,
                1,
                1e18
            );
            _remainingAmount =
                (_collateralAmountInETH * (_leverage - _bps) - _debtAmount * _leverage) /
                (_leverage - ((_leverage - _bps) * _exchangeRate) / 1e18);
        }
    }

    /// @notice Returns the info of borrow with default borrowFactor
    /// @return _remainingAmount The amount of debt token will still can to borrow
    /// @return _overflowAmount The amount of aToken that exceeds the maximum allowable loan
    function _borrowStandardInfo(
        address _aToken,
        address _dToken,
        uint256 _stETHPrice,
        address _curvePoolAddress
    ) private view returns (uint256 _remainingAmount, uint256 _overflowAmount) {
        uint256 _leverage = leverage;
        uint256 _bps = BPS;

        uint256 _newDebtAmount = balanceOfToken(_dToken) * _leverage;
        uint256 _newCollateralAmount = ((balanceOfToken(_aToken) * _stETHPrice) / 1e18) *
            (_leverage - _bps);

        address _curvePoolAddress = CURVE_POOL_ADDRESS;
        if (_newDebtAmount > _newCollateralAmount) {
            //(_debtAmount-x*_exchangeRate)/(_collateralAmountInETH- x * _stETHPrice) = (leverage-BPS)/leverage
            // stETH to ETH
            uint256 _exchangeRate = ICurveLiquidityFarmingPool(_curvePoolAddress).get_dy(
                1,
                0,
                1e18
            );
            _overflowAmount =
                (_newDebtAmount - _newCollateralAmount) /
                ((_leverage * _exchangeRate) / 1e18 - ((_leverage - _bps) * _stETHPrice) / 1e18);
        } else if (_newDebtAmount < _newCollateralAmount) {
            //(_debtAmount+x)/(_collateralAmountInETH+_exchangeRate * x) = (leverage-BPS)/leverage
            // ETH to stETH
            uint256 _exchangeRate = ICurveLiquidityFarmingPool(_curvePoolAddress).get_dy(
                0,
                1,
                1e18
            );
            _remainingAmount =
                (_newCollateralAmount - _newDebtAmount) /
                (_leverage - ((_leverage - _bps) * _exchangeRate) / 1e18);
        }
    }

    /// @notice Returns the new leverage with the fix borrowFactor
    /// @return _borrowFactor The borrow factor
    function _getNewLeverage(uint256 _borrowFactor) internal view returns (uint256) {
        return _calLeverage(_borrowFactor, BPS, borrowCount);
    }

    /// @notice update all leverage (leverage leverageMax leverageMin)
    function _updateAllLeverage(uint256 _borrowCount) internal {
        uint256 _bps = BPS;
        leverage = _calLeverage(borrowFactor, _bps, _borrowCount);
        leverageMax = _calLeverage(borrowFactorMax, _bps, _borrowCount);
        leverageMin = _calLeverage(borrowFactorMin, _bps, _borrowCount);
    }

    /// @notice Returns the leverage  with by _borrowFactor _bps  _borrowCount
    /// @return _borrowFactor The borrow factor
    function _calLeverage(
        uint256 _borrowFactor,
        uint256 _bps,
        uint256 _borrowCount
    ) private pure returns (uint256) {
        // q = borrowFactor/bps
        // n = borrowCount + 1;
        // _leverage = (1-q^n)/(1-q),(n>=1, q=0.8)
        uint256 _leverage = _bps;
        if (_borrowCount >= 1) {
            _leverage =
                (_bps * _bps - (_borrowFactor**(_borrowCount + 1)) / (_bps**(_borrowCount - 1))) /
                (_bps - _borrowFactor);
        }
        return _leverage;
    }
}
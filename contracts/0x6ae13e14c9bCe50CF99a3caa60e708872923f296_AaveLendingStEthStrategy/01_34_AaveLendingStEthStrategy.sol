// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "boc-contract-core/contracts/strategy/BaseStrategy.sol";
import "../../enums/ProtocolEnum.sol";
import "../../../external/aave/ILendingPool.sol";
import "../../../external/aave/UserConfiguration.sol";
import "../../../external/aave/DataTypes.sol";
import "../../../external/aave/ILendingPoolAddressesProvider.sol";
import "../../../external/aave/IPriceOracleGetter.sol";
import "../../../external/curve/ICurveLiquidityFarmingPool.sol";
import "../../../external/euler/IEulerDToken.sol";
import "../../../external/weth/IWeth.sol";
import "../../../external/uniswap/IUniswapV3.sol";

contract AaveLendingStEthStrategy is BaseStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address internal constant UNISWAP_V3_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address internal constant CURVE_POOL_ADDRESS = 0xDC24316b9AE028F1497c275EB9192a3Ea0f67022;
    address internal constant QUOTER = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;
    address public constant DEBT_W_ETH = 0xF63B34710400CAd3e044cFfDcAb00a0f32E33eCf;
    address public constant W_ETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant ST_ETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address public constant A_ST_ETH = 0x1982b2F5814301d4e9a8b0201555376e62F82428;
    address public constant A_WETH = 0x030bA81f1c18d280636F32af80b9AAd02Cf0854e;
    uint256 public constant RESERVE_ID_OF_ST_ETH = 31;
    uint256 public constant BPS = 10000;
    address private aToken;
    uint256 private reserveIdOfToken;
    /**
     * @dev Aave Lending Pool Provider
     */
    ILendingPoolAddressesProvider internal constant aaveProvider =
        ILendingPoolAddressesProvider(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5);
    uint256 public stETHBorrowFactor;
    uint256 public stETHBorrowFactorMax;
    uint256 public stETHBorrowFactorMin;
    uint256 public borrowFactor;
    uint256 public borrowFactorMax;
    uint256 public borrowFactorMin;
    uint256 public borrowCount;
    address public uniswapV3Pool;
    uint256 public leverage;
    uint256 public leverageMax;
    uint256 public leverageMin;
    address internal constant EULER_ADDRESS = 0x27182842E098f60e3D576794A5bFFb0777E025d3;
    address internal constant W_ETH_EULER_D_TOKEN = 0x62e28f054efc24b26A794F5C1249B6349454352C;

    /// Events

    /// @param _stETHBorrowFactor The new stETH borrow factor
    event UpdateStETHBorrowFactor(uint256 _stETHBorrowFactor);
    /// @param _stETHBorrowFactorMax The new max stETH borrow factor
    event UpdateStETHBorrowFactorMax(uint256 _stETHBorrowFactorMax);
    /// @param _stETHBorrowFactorMin The new min stETH borrow factor
    event UpdateStETHBorrowFactorMin(uint256 _stETHBorrowFactorMin);
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

    receive() external payable {}

    fallback() external payable {}

    function initialize(
        address _vault,
        address _harvester,
        string memory _name,
        address _wantToken,
        address _wantAToken,
        uint256 _reserveIdOfToken,
        address _uniswapV3Pool
    ) external initializer {
        address[] memory _wants = new address[](1);
        _wants[0] = _wantToken;
        aToken = _wantAToken;
        reserveIdOfToken = _reserveIdOfToken;
        uniswapV3Pool = _uniswapV3Pool;
        stETHBorrowFactor = 6500;
        stETHBorrowFactorMax = 6900;
        stETHBorrowFactorMin = 6100;
        borrowFactor = 6500;
        borrowFactorMin = 6100;
        borrowFactorMax = 6900;
        borrowCount = 3;
        leverage = _calLeverage(6500, 6500, 10000, 3);
        leverageMax = _calLeverage(6900, 6900, 10000, 3);
        leverageMin = _calLeverage(6100, 6100, 10000, 3);

        address _lendingPoolAddress = aaveProvider.getLendingPool();
        IERC20Upgradeable(ST_ETH).safeApprove(_lendingPoolAddress, type(uint256).max);
        IERC20Upgradeable(_wantToken).safeApprove(_lendingPoolAddress, type(uint256).max);
        IERC20Upgradeable(W_ETH).safeApprove(_lendingPoolAddress, type(uint256).max);
        IERC20Upgradeable(ST_ETH).safeApprove(CURVE_POOL_ADDRESS, type(uint256).max);
        IERC20Upgradeable(_wantToken).safeApprove(UNISWAP_V3_ROUTER, type(uint256).max);
        IERC20Upgradeable(W_ETH).safeApprove(UNISWAP_V3_ROUTER, type(uint256).max);

        super._initialize(_vault, _harvester, _name, uint16(ProtocolEnum.Aave), _wants);
    }

    /// @notice Sets `_stETHBorrowFactor` to `stETHBorrowFactor`
    /// @param _stETHBorrowFactor The new value of `stETHBorrowFactor`
    /// Requirements: only vault manager can call
    function setStETHBorrowFactor(uint256 _stETHBorrowFactor) external isVaultManager {
        require(_stETHBorrowFactor < BPS, "setting output the range");
        stETHBorrowFactor = _stETHBorrowFactor;
        leverage = _getNewLeverage(borrowFactor, _stETHBorrowFactor);

        emit UpdateStETHBorrowFactor(_stETHBorrowFactor);
    }

    /// @notice Sets `_stETHBorrowFactorMax` to `stETHBorrowFactorMax`
    /// @param _stETHBorrowFactorMax The new value of `stETHBorrowFactorMax`
    /// Requirements: only vault manager can call
    function setStETHBorrowFactorMax(uint256 _stETHBorrowFactorMax) external isVaultManager {
        require(
            _stETHBorrowFactorMax < BPS && _stETHBorrowFactorMax > stETHBorrowFactor,
            "setting output the range"
        );
        stETHBorrowFactorMax = _stETHBorrowFactorMax;
        leverageMax = _getNewLeverage(borrowFactorMax, _stETHBorrowFactorMax);

        emit UpdateStETHBorrowFactorMax(_stETHBorrowFactorMax);
    }

    /// @notice Sets `_stETHBorrowFactorMin` to `stETHBorrowFactorMin`
    /// @param _stETHBorrowFactorMin The new value of `stETHBorrowFactorMin`
    /// Requirements: only vault manager can call
    function setStETHBorrowFactorMin(uint256 _stETHBorrowFactorMin) external isVaultManager {
        require(
            _stETHBorrowFactorMin < BPS && _stETHBorrowFactorMin < stETHBorrowFactor,
            "setting output the range"
        );
        stETHBorrowFactorMin = _stETHBorrowFactorMin;
        leverageMin = _getNewLeverage(borrowFactorMin, _stETHBorrowFactorMin);

        emit UpdateStETHBorrowFactorMin(_stETHBorrowFactorMin);
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
        leverage = _getNewLeverage(_borrowFactor, stETHBorrowFactor);

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
        leverageMax = _getNewLeverage(_borrowFactorMax, stETHBorrowFactorMax);

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
        leverageMin = _getNewLeverage(_borrowFactorMin, stETHBorrowFactorMin);

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

    /// @inheritdoc BaseStrategy
    function getVersion() external pure virtual override returns (string memory) {
        return "1.0.1";
    }

    /// @inheritdoc BaseStrategy
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

    /// @inheritdoc BaseStrategy
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

    /// @inheritdoc BaseStrategy
    function getPositionDetail()
        public
        view
        virtual
        override
        returns (
            address[] memory _tokens,
            uint256[] memory _amounts,
            bool _isUsd,
            uint256 _usdValue
        )
    {
        _tokens = wants;
        _amounts = new uint256[](1);
        address _token = _tokens[0];

        uint256 _wethDebtAmount = balanceOfToken(DEBT_W_ETH);
        uint256 _tokenAmount = balanceOfToken(_token) + balanceOfToken(aToken);
        uint256 _wethAmount = balanceOfToken(W_ETH) + address(this).balance;
        uint256 _stEthAmount = balanceOfToken(A_ST_ETH) + balanceOfToken(ST_ETH);
        _isUsd = true;
        if (_wethAmount > _wethDebtAmount) {
            _usdValue =
                queryTokenValue(_token, _tokenAmount) +
                queryTokenValue(ST_ETH, _stEthAmount) +
                queryTokenValue(W_ETH, _wethAmount - _wethDebtAmount);
        } else if (_wethAmount < _wethDebtAmount) {
            _usdValue =
                queryTokenValue(_token, _tokenAmount) +
                queryTokenValue(ST_ETH, _stEthAmount) -
                queryTokenValue(W_ETH, _wethDebtAmount - _wethAmount);
        } else {
            _usdValue =
                queryTokenValue(_token, _tokenAmount) +
                queryTokenValue(ST_ETH, _stEthAmount);
        }
    }

    /// @inheritdoc BaseStrategy
    function get3rdPoolAssets() external view override returns (uint256) {
        return queryTokenValue(ST_ETH, IERC20Upgradeable(ST_ETH).totalSupply());
    }

    /// @inheritdoc BaseStrategy
    function depositTo3rdPool(address[] memory _assets, uint256[] memory _amounts)
        internal
        override
    {
        uint256 _amount = _amounts[0];
        address _asset = _assets[0];
        address _aStETH = A_ST_ETH;
        address _stETH = ST_ETH;
        address _lendingPoolAddress = aaveProvider.getLendingPool();
        ILendingPool(_lendingPoolAddress).deposit(_asset, _amount, address(this), 0);
        {
            uint256 _userConfigurationData = ILendingPool(_lendingPoolAddress)
                .getUserConfiguration(address(this))
                .data;

            if (!UserConfiguration.isUsingAsCollateral(_userConfigurationData, reserveIdOfToken)) {
                ILendingPool(_lendingPoolAddress).setUserUseReserveAsCollateral(_asset, true);
            }
            if (
                balanceOfToken(_aStETH) > 0 &&
                !UserConfiguration.isUsingAsCollateral(
                    _userConfigurationData,
                    RESERVE_ID_OF_ST_ETH
                )
            ) {
                ILendingPool(_lendingPoolAddress).setUserUseReserveAsCollateral(_stETH, true);
            }
        }

        (uint256 _stETHPrice, uint256 _tokenPrice) = _getAssetsPrices(_stETH, _asset);

        address _curvePoolAddress = CURVE_POOL_ADDRESS;
        (uint256 _remainingAmount, uint256 _overflowAmount) = _borrowStandardInfo(
            _aStETH,
            _stETHPrice,
            _tokenPrice,
            _curvePoolAddress
        );
        _rebalance(_remainingAmount, _overflowAmount, _stETHPrice, _curvePoolAddress);
    }

    /// @inheritdoc BaseStrategy
    function withdrawFrom3rdPool(
        uint256 _withdrawShares,
        uint256 _totalShares,
        uint256 _outputCode
    ) internal override {
        uint256 _redeemAstETHAmount = (balanceOfToken(A_ST_ETH) * _withdrawShares) / _totalShares;
        uint256 _redeemATokenAmount = (balanceOfToken(aToken) * _withdrawShares) / _totalShares;
        uint256 _repayBorrowAmount = (balanceOfToken(DEBT_W_ETH) * _withdrawShares) / _totalShares;
        _repay(_redeemAstETHAmount, _redeemATokenAmount, _repayBorrowAmount);
    }

    /// @notice Returns the info of borrow.
    /// @return _remainingAmount The amount of debt token will still can to borrow
    /// @return _overflowAmount The amount of aToken that exceeds the maximum allowable loan
    function borrowInfo() public view returns (uint256 _remainingAmount, uint256 _overflowAmount) {
        address _stETH = ST_ETH;
        address _tokenAddress = wants[0];
        (uint256 _stETHPrice, uint256 _tokenPrice) = _getAssetsPrices(_stETH, _tokenAddress);
        address _curvePoolAddress = CURVE_POOL_ADDRESS;
        (_remainingAmount, _overflowAmount) = _borrowInfo(
            _stETHPrice,
            _tokenPrice,
            _curvePoolAddress
        );
    }

    /// @notice Rebalance the collateral of this strategy
    /// Requirements: only keeper can call
    function rebalance() external isKeeper {
        address _stETH = ST_ETH;
        address _tokenAddress = wants[0];
        (uint256 _stETHPrice, uint256 _tokenPrice) = _getAssetsPrices(_stETH, _tokenAddress);
        address _curvePoolAddress = CURVE_POOL_ADDRESS;
        (uint256 _remainingAmount, uint256 _overflowAmount) = _borrowInfo(
            _stETHPrice,
            _tokenPrice,
            _curvePoolAddress
        );
        _rebalance(_remainingAmount, _overflowAmount, _stETHPrice, _curvePoolAddress);
    }

    // euler flashload call only by  euler
    function onFlashLoan(bytes memory data) external {
        address _eulerAddress = EULER_ADDRESS;
        require(msg.sender == _eulerAddress, "invalid call");
        (
            uint256 _operationCode,
            uint256[] memory _customParams,
            uint256 _flashLoanAmount,
            uint256 _origBalance
        ) = abi.decode(data, (uint256, uint256[], uint256, uint256));
        address _wETH = W_ETH;
        uint256 _wETHAmount = balanceOfToken(_wETH);
        require(_wETHAmount >= _origBalance + _flashLoanAmount, "not received enough");
        ILendingPool _aaveLendingPool = ILendingPool(aaveProvider.getLendingPool());
        // 0 - deposit stETH wantToken; 1 - withdraw stETH wantToken
        if (_operationCode < 1) {
            IWeth(_wETH).withdraw(_wETHAmount);
            ICurveLiquidityFarmingPool(CURVE_POOL_ADDRESS).exchange{value: _wETHAmount}(
                0,
                1,
                _wETHAmount,
                0
            );
            address _asset = ST_ETH;
            uint256 _amount = balanceOfToken(_asset);
            _aaveLendingPool.deposit(_asset, _amount, address(this), 0);

            //_customParams = [_borrowAmount,_depositAmount]
            uint256 _borrowAmount = _customParams[0];
            _aaveLendingPool.borrow(
                _wETH,
                _borrowAmount,
                uint256(DataTypes.InterestRateMode.VARIABLE),
                0,
                address(this)
            );
        } else {
            //_customParams = [_redeemAstETHAmount,_redeemATokenAmount,_repayBorrowAmount]
            uint256 _redeemAStETHAmount = _customParams[0];
            uint256 _redeemATokenAmount = _customParams[1];
            uint256 _repayBorrowAmount = _customParams[2];
            if (_repayBorrowAmount > 0) {
                _aaveLendingPool.repay(
                    _wETH,
                    _repayBorrowAmount,
                    uint256(DataTypes.InterestRateMode.VARIABLE),
                    address(this)
                );
            }
            if (_redeemAStETHAmount > 0) {
                address _stETH = ST_ETH;
                _aaveLendingPool.withdraw(_stETH, _redeemAStETHAmount, address(this));
                uint256 _stETHAmount = balanceOfToken(_stETH);
                ICurveLiquidityFarmingPool(CURVE_POOL_ADDRESS).exchange(1, 0, _stETHAmount, 0);
                IWeth(_wETH).deposit{value: address(this).balance}();
            }
            address _want = wants[0];
            if (_redeemATokenAmount > 0) {
                _aaveLendingPool.withdraw(_want, _redeemATokenAmount, address(this));
            }

            uint256 _wETHAmount = balanceOfToken(_wETH);
            if (_wETHAmount > _flashLoanAmount) {
                IUniswapV3(UNISWAP_V3_ROUTER).exactInputSingle(
                    IUniswapV3.ExactInputSingleParams(
                        _wETH,
                        _want,
                        500,
                        address(this),
                        block.timestamp,
                        _wETHAmount - _flashLoanAmount,
                        0,
                        0
                    )
                );
            } else if (_wETHAmount < _flashLoanAmount) {
                IUniswapV3(UNISWAP_V3_ROUTER).exactOutputSingle(
                    IUniswapV3.ExactOutputSingleParams(
                        _want,
                        _wETH,
                        500,
                        address(this),
                        block.timestamp,
                        _flashLoanAmount - _wETHAmount,
                        balanceOfToken(_want),
                        0
                    )
                );
            }
        }
        IERC20Upgradeable(_wETH).safeTransfer(_eulerAddress, _flashLoanAmount);
    }

    function _getAssetsPrices(address _asset1, address _asset2)
        private
        view
        returns (uint256 _price1, uint256 _price2)
    {
        address[] memory _assets = new address[](2);
        _assets[0] = _asset1;
        _assets[1] = _asset2;
        IPriceOracleGetter _aaveOracle = IPriceOracleGetter(aaveProvider.getPriceOracle());
        uint256[] memory _prices = _aaveOracle.getAssetsPrices(_assets);
        _price1 = _prices[0];
        _price2 = _prices[1];
    }

    /// @notice repayBorrow and redeem collateral
    function _repay(
        uint256 _redeemAstETHAmount,
        uint256 _redeemATokenAmount,
        uint256 _repayBorrowAmount
    ) internal {
        // 0 - deposit stETH wantToken; 1 - withdraw stETH wantToken
        uint256 _operationCode = 1;
        uint256[] memory _customParams = new uint256[](3);
        //_redeemAstETHAmount
        _customParams[0] = _redeemAstETHAmount;
        //_redeemATokenAmount
        _customParams[1] = _redeemATokenAmount;
        //_repayBorrowAmount
        _customParams[2] = _repayBorrowAmount;
        uint256 _flashLoanAmount = _repayBorrowAmount;
        bytes memory _params = abi.encode(
            _operationCode,
            _customParams,
            _flashLoanAmount,
            balanceOfToken(W_ETH)
        );
        IEulerDToken(W_ETH_EULER_D_TOKEN).flashLoan(_flashLoanAmount, _params);
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
            // 0 - deposit stETH wantToken; 1 - withdraw stETH wantToken
            uint256 _operationCode = 0;
            uint256[] memory _customParams = new uint256[](2);
            //uint256 _borrowAmount = _remainingAmount;
            _customParams[0] = _remainingAmount;
            //uint256 _depositAmount = type(uint256).max;
            _customParams[1] = type(uint256).max;
            uint256 _flashLoanAmount = _remainingAmount;
            bytes memory _params = abi.encode(
                _operationCode,
                _customParams,
                _flashLoanAmount,
                balanceOfToken(W_ETH)
            );
            IEulerDToken(W_ETH_EULER_D_TOKEN).flashLoan(_flashLoanAmount, _params);
        } else if (_overflowAmount > 0) {
            uint256 _repayBorrowAmount = _curvePool.get_dy(1, 0, _overflowAmount);
            uint256 _redeemAStETHAmount = _overflowAmount;
            uint256 _redeemATokenAmount = 0;
            //stETH
            uint256 _aStETHAmount = balanceOfToken(A_ST_ETH);
            if (_aStETHAmount < _redeemAStETHAmount) {
                _redeemAStETHAmount = _aStETHAmount;
            } else if (_aStETHAmount > _redeemAStETHAmount) {
                if (_aStETHAmount > _redeemAStETHAmount + 1) {
                    _redeemAStETHAmount = _redeemAStETHAmount + 2;
                } else {
                    _redeemAStETHAmount = _redeemAStETHAmount + 1;
                }
            }
            _repay(_redeemAStETHAmount, _redeemATokenAmount, _repayBorrowAmount);
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
        uint256 _stETHPrice,
        uint256 _tokenPrice,
        address _curvePoolAddress
    ) private view returns (uint256 _remainingAmount, uint256 _overflowAmount) {
        uint256 _bps = BPS;
        uint256 _leverage = leverage;
        uint256 _debtAmountMax;
        uint256 _debtAmountMin;
        uint256 _debtAmount = balanceOfToken(DEBT_W_ETH);
        address _aToken = aToken;
        uint256 _collateralAmountInETH = (balanceOfToken(A_ST_ETH) * _stETHPrice) /
            1e18 +
            (balanceOfToken(_aToken) * _tokenPrice) /
            decimalUnitOfToken(_aToken);

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
        address _aStETH,
        uint256 _stETHPrice,
        uint256 _tokenPrice,
        address _curvePoolAddress
    ) private view returns (uint256 _remainingAmount, uint256 _overflowAmount) {
        uint256 _leverage = leverage;
        uint256 _bps = BPS;

        uint256 _newDebtAmount = balanceOfToken(DEBT_W_ETH) * _leverage;
        uint256 _newCollateralAmount;
        {
            address _aToken = aToken;
            _newCollateralAmount =
                ((balanceOfToken(_aStETH) * _stETHPrice) /
                    1e18 +
                    (balanceOfToken(_aToken) * _tokenPrice) /
                    decimalUnitOfToken(_aToken)) *
                (_leverage - _bps);
        }

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
    function _getNewLeverage(uint256 _borrowFactor, uint256 _stETHBorrowFactor)
        internal
        view
        returns (uint256)
    {
        return _calLeverage(_borrowFactor, _stETHBorrowFactor, BPS, borrowCount);
    }

    /// @notice update all leverage (leverage leverageMax leverageMin)
    function _updateAllLeverage(uint256 _borrowCount) internal {
        uint256 _bps = BPS;
        leverage = _calLeverage(borrowFactor, stETHBorrowFactor, _bps, _borrowCount);
        leverageMax = _calLeverage(borrowFactorMax, stETHBorrowFactorMax, _bps, _borrowCount);
        leverageMin = _calLeverage(borrowFactorMin, stETHBorrowFactorMin, _bps, _borrowCount);
    }

    /// @notice Returns the leverage  with by _borrowFactor _bps  _borrowCount
    /// @return _borrowFactor The borrow factor
    function _calLeverage(
        uint256 _borrowFactor,
        uint256 _stETHBorrowFactor,
        uint256 _bps,
        uint256 _borrowCount
    ) private pure returns (uint256) {
        // q = borrowFactor/bps
        // n = borrowCount + 1;
        // _leverage = (1-q^n)/(1-q),(n>=1, q=0.8)
        uint256 _leverage = _bps + _borrowFactor;
        if (_borrowCount >= 1) {
            _leverage =
                (_bps *
                    _bps -
                    (_stETHBorrowFactor**(_borrowCount + 1)) /
                    (_bps**(_borrowCount - 1))) /
                (_bps - _stETHBorrowFactor);
            _leverage = _bps + (_borrowFactor * _leverage) / _bps;
        }
        return _leverage;
    }
}
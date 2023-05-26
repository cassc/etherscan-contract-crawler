// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "ICurveV2Pool.sol";
import "ICurvePool.sol";
import "ICurveFactoryPool.sol";
import "IBasicRewards.sol";
import "IWETH.sol";
import "IUniV3Router.sol";
import "IUniV2Router.sol";
import "ICvxFxsDeposit.sol";

contract stkCvxFxsStrategyBase {
    address public constant FXS_DEPOSIT =
        0x8f55d7c21bDFf1A51AFAa60f3De7590222A3181e;

    address public constant CURVE_CRV_ETH_POOL =
        0x8301AE4fc9c624d1D396cbDAa1ed877821D7C511;
    address public constant CURVE_CVX_ETH_POOL =
        0xB576491F1E6e5E62f1d8F26062Ee822B40B0E0d4;
    address public constant CURVE_FXS_ETH_POOL =
        0x941Eb6F616114e4Ecaa85377945EA306002612FE;
    address public constant CURVE_CVXFXS_FXS_POOL =
        0xd658A338613198204DCa1143Ac3F01A722b5d94A;
    address public constant CURVE_FRAX_USDC_POOL =
        0xDcEF968d416a41Cdac0ED8702fAC8128A64241A2;
    address public constant UNISWAP_ROUTER =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public constant UNIV3_ROUTER =
        0xE592427A0AEce92De3Edee1F18E0157C05861564;

    address public constant CRV_TOKEN =
        0xD533a949740bb3306d119CC777fa900bA034cd52;
    address public constant CVXFXS_TOKEN =
        0xFEEf77d3f69374f66429C91d732A244f074bdf74;
    address public constant FXS_TOKEN =
        0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0;
    address public constant CVX_TOKEN =
        0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
    address public constant WETH_TOKEN =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant CURVE_CVXFXS_FXS_LP_TOKEN =
        0xF3A43307DcAFa93275993862Aae628fCB50dC768;
    address public constant USDT_TOKEN =
        0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant USDC_TOKEN =
        0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant FRAX_TOKEN =
        0x853d955aCEf822Db058eb8505911ED77F175b99e;

    uint256 public constant CRVETH_ETH_INDEX = 0;
    uint256 public constant CRVETH_CRV_INDEX = 1;
    uint256 public constant CVXETH_ETH_INDEX = 0;
    uint256 public constant CVXETH_CVX_INDEX = 1;

    // The swap strategy to use when going eth -> fxs
    enum SwapOption {
        Curve,
        Uniswap,
        Unistables,
        UniCurve1
    }
    SwapOption public swapOption = SwapOption.UniCurve1;
    event OptionChanged(SwapOption oldOption, SwapOption newOption);

    ICvxFxsDeposit cvxFxsDeposit = ICvxFxsDeposit(FXS_DEPOSIT);
    ICurveV2Pool cvxEthSwap = ICurveV2Pool(CURVE_CVX_ETH_POOL);

    ICurveV2Pool crvEthSwap = ICurveV2Pool(CURVE_CRV_ETH_POOL);
    ICurveV2Pool fxsEthSwap = ICurveV2Pool(CURVE_FXS_ETH_POOL);
    ICurveV2Pool cvxFxsFxsSwap = ICurveV2Pool(CURVE_CVXFXS_FXS_POOL);

    ICurvePool fraxUsdcSwap = ICurvePool(CURVE_FRAX_USDC_POOL);

    /// @notice Swap CRV for native ETH on Curve
    /// @param amount - amount to swap
    /// @return amount of ETH obtained after the swap
    function _swapCrvToEth(uint256 amount) internal returns (uint256) {
        return _crvToEth(amount, 0);
    }

    /// @notice Swap CRV for native ETH on Curve
    /// @param amount - amount to swap
    /// @param minAmountOut - minimum expected amount of output tokens
    /// @return amount of ETH obtained after the swap
    function _swapCrvToEth(uint256 amount, uint256 minAmountOut)
        internal
        returns (uint256)
    {
        return _crvToEth(amount, minAmountOut);
    }

    /// @notice Swap CRV for native ETH on Curve
    /// @param amount - amount to swap
    /// @param minAmountOut - minimum expected amount of output tokens
    /// @return amount of ETH obtained after the swap
    function _crvToEth(uint256 amount, uint256 minAmountOut)
        internal
        returns (uint256)
    {
        return
            crvEthSwap.exchange_underlying{value: 0}(
                CRVETH_CRV_INDEX,
                CRVETH_ETH_INDEX,
                amount,
                minAmountOut
            );
    }

    /// @notice Swap native ETH for CRV on Curve
    /// @param amount - amount to swap
    /// @return amount of CRV obtained after the swap
    function _swapEthToCrv(uint256 amount) internal returns (uint256) {
        return _ethToCrv(amount, 0);
    }

    /// @notice Swap native ETH for CRV on Curve
    /// @param amount - amount to swap
    /// @param minAmountOut - minimum expected amount of output tokens
    /// @return amount of CRV obtained after the swap
    function _swapEthToCrv(uint256 amount, uint256 minAmountOut)
        internal
        returns (uint256)
    {
        return _ethToCrv(amount, minAmountOut);
    }

    /// @notice Swap native ETH for CRV on Curve
    /// @param amount - amount to swap
    /// @param minAmountOut - minimum expected amount of output tokens
    /// @return amount of CRV obtained after the swap
    function _ethToCrv(uint256 amount, uint256 minAmountOut)
        internal
        returns (uint256)
    {
        return
            crvEthSwap.exchange_underlying{value: amount}(
                CRVETH_ETH_INDEX,
                CRVETH_CRV_INDEX,
                amount,
                minAmountOut
            );
    }

    /// @notice Swap native ETH for CVX on Curve
    /// @param amount - amount to swap
    /// @return amount of CVX obtained after the swap
    function _swapEthToCvx(uint256 amount) internal returns (uint256) {
        return _ethToCvx(amount, 0);
    }

    /// @notice Swap native ETH for CVX on Curve
    /// @param amount - amount to swap
    /// @param minAmountOut - minimum expected amount of output tokens
    /// @return amount of CVX obtained after the swap
    function _swapEthToCvx(uint256 amount, uint256 minAmountOut)
        internal
        returns (uint256)
    {
        return _ethToCvx(amount, minAmountOut);
    }

    /// @notice Swap CVX for native ETH on Curve
    /// @param amount - amount to swap
    /// @return amount of ETH obtained after the swap
    function _swapCvxToEth(uint256 amount) internal returns (uint256) {
        return _cvxToEth(amount, 0);
    }

    /// @notice Swap CVX for native ETH on Curve
    /// @param amount - amount to swap
    /// @param minAmountOut - minimum expected amount of output tokens
    /// @return amount of ETH obtained after the swap
    function _swapCvxToEth(uint256 amount, uint256 minAmountOut)
        internal
        returns (uint256)
    {
        return _cvxToEth(amount, minAmountOut);
    }

    /// @notice Swap native ETH for CVX on Curve
    /// @param amount - amount to swap
    /// @param minAmountOut - minimum expected amount of output tokens
    /// @return amount of CVX obtained after the swap
    function _ethToCvx(uint256 amount, uint256 minAmountOut)
        internal
        returns (uint256)
    {
        return
            cvxEthSwap.exchange_underlying{value: amount}(
                CVXETH_ETH_INDEX,
                CVXETH_CVX_INDEX,
                amount,
                minAmountOut
            );
    }

    /// @notice Swap native CVX for ETH on Curve
    /// @param amount - amount to swap
    /// @param minAmountOut - minimum expected amount of output tokens
    /// @return amount of ETH obtained after the swap
    function _cvxToEth(uint256 amount, uint256 minAmountOut)
        internal
        returns (uint256)
    {
        return
            cvxEthSwap.exchange_underlying{value: 0}(
                1,
                0,
                amount,
                minAmountOut
            );
    }

    /// @notice Swap native ETH for FXS via different routes
    /// @param _ethAmount - amount to swap
    /// @param _option - the option to use when swapping
    /// @return amount of FXS obtained after the swap
    function _swapEthForFxs(uint256 _ethAmount, SwapOption _option)
        internal
        returns (uint256)
    {
        return _swapEthFxs(_ethAmount, _option, true);
    }

    /// @notice Swap FXS for native ETH via different routes
    /// @param _fxsAmount - amount to swap
    /// @param _option - the option to use when swapping
    /// @return amount of ETH obtained after the swap
    function _swapFxsForEth(uint256 _fxsAmount, SwapOption _option)
        internal
        returns (uint256)
    {
        return _swapEthFxs(_fxsAmount, _option, false);
    }

    /// @notice Swap ETH<->FXS on Curve
    /// @param _amount - amount to swap
    /// @param _ethToFxs - whether to swap from eth to fxs or the inverse
    /// @return amount of token obtained after the swap
    function _curveEthFxsSwap(uint256 _amount, bool _ethToFxs)
        internal
        returns (uint256)
    {
        return
            fxsEthSwap.exchange_underlying{value: _ethToFxs ? _amount : 0}(
                _ethToFxs ? 0 : 1,
                _ethToFxs ? 1 : 0,
                _amount,
                0
            );
    }

    /// @notice Swap ETH<->FXS on UniV3 FXSETH pool
    /// @param _amount - amount to swap
    /// @param _ethToFxs - whether to swap from eth to fxs or the inverse
    /// @return amount of token obtained after the swap
    function _uniV3EthFxsSwap(uint256 _amount, bool _ethToFxs)
        internal
        returns (uint256)
    {
        IUniV3Router.ExactInputSingleParams memory _params = IUniV3Router
            .ExactInputSingleParams(
                _ethToFxs ? WETH_TOKEN : FXS_TOKEN,
                _ethToFxs ? FXS_TOKEN : WETH_TOKEN,
                10000,
                address(this),
                block.timestamp + 1,
                _amount,
                1,
                0
            );

        uint256 _receivedAmount = IUniV3Router(UNIV3_ROUTER).exactInputSingle{
            value: _ethToFxs ? _amount : 0
        }(_params);
        if (!_ethToFxs) {
            IWETH(WETH_TOKEN).withdraw(_receivedAmount);
        }
        return _receivedAmount;
    }

    /// @notice Swap ETH->FXS on UniV3 via stable pair
    /// @param _amount - amount to swap
    /// @return amount of token obtained after the swap
    function _uniStableEthToFxsSwap(uint256 _amount)
        internal
        returns (uint256)
    {
        uint24 fee = 500;
        IUniV3Router.ExactInputParams memory _params = IUniV3Router
            .ExactInputParams(
                abi.encodePacked(WETH_TOKEN, fee, USDC_TOKEN, fee, FRAX_TOKEN),
                address(this),
                block.timestamp + 1,
                _amount,
                0
            );

        uint256 _fraxAmount = IUniV3Router(UNIV3_ROUTER).exactInput{
            value: _amount
        }(_params);
        address[] memory _path = new address[](2);
        _path[0] = FRAX_TOKEN;
        _path[1] = FXS_TOKEN;
        uint256[] memory amounts = IUniV2Router(UNISWAP_ROUTER)
            .swapExactTokensForTokens(
                _fraxAmount,
                1,
                _path,
                address(this),
                block.timestamp + 1
            );
        return amounts[1];
    }

    /// @notice Swap FXS->ETH on UniV3 via stable pair
    /// @param _amount - amount to swap
    /// @return amount of token obtained after the swap
    function _uniStableFxsToEthSwap(uint256 _amount)
        internal
        returns (uint256)
    {
        address[] memory _path = new address[](2);
        _path[0] = FXS_TOKEN;
        _path[1] = FRAX_TOKEN;
        uint256[] memory amounts = IUniV2Router(UNISWAP_ROUTER)
            .swapExactTokensForTokens(
                _amount,
                1,
                _path,
                address(this),
                block.timestamp + 1
            );

        uint256 _fraxAmount = amounts[1];
        uint24 fee = 500;

        IUniV3Router.ExactInputParams memory _params = IUniV3Router
            .ExactInputParams(
                abi.encodePacked(FRAX_TOKEN, fee, USDC_TOKEN, fee, WETH_TOKEN),
                address(this),
                block.timestamp + 1,
                _fraxAmount,
                0
            );

        uint256 _ethAmount = IUniV3Router(UNIV3_ROUTER).exactInput{value: 0}(
            _params
        );
        IWETH(WETH_TOKEN).withdraw(_ethAmount);
        return _ethAmount;
    }

    /// @notice Swap FXS->ETH on a mix of UniV2, UniV3 & Curve
    /// @param _amount - amount to swap
    /// @return amount of token obtained after the swap
    function _uniCurve1FxsToEthSwap(uint256 _amount)
        internal
        returns (uint256)
    {
        address[] memory _path = new address[](2);
        _path[0] = FXS_TOKEN;
        _path[1] = FRAX_TOKEN;
        uint256[] memory amounts = IUniV2Router(UNISWAP_ROUTER)
            .swapExactTokensForTokens(
                _amount,
                1,
                _path,
                address(this),
                block.timestamp + 1
            );

        uint256 _fraxAmount = amounts[1];
        // Swap FRAX for USDC on Curve
        uint256 _usdcAmount = fraxUsdcSwap.exchange(0, 1, _fraxAmount, 0);

        // USDC to ETH on UniV3
        uint24 fee = 500;
        IUniV3Router.ExactInputParams memory _params = IUniV3Router
            .ExactInputParams(
                abi.encodePacked(USDC_TOKEN, fee, WETH_TOKEN),
                address(this),
                block.timestamp + 1,
                _usdcAmount,
                0
            );

        uint256 _ethAmount = IUniV3Router(UNIV3_ROUTER).exactInput{value: 0}(
            _params
        );

        IWETH(WETH_TOKEN).withdraw(_ethAmount);
        return _ethAmount;
    }

    /// @notice Swap ETH->FXS on a mix of UniV2, UniV3 & Curve
    /// @param _amount - amount to swap
    /// @return amount of token obtained after the swap
    function _uniCurve1EthToFxsSwap(uint256 _amount)
        internal
        returns (uint256)
    {
        uint24 fee = 500;
        IUniV3Router.ExactInputParams memory _params = IUniV3Router
            .ExactInputParams(
                abi.encodePacked(WETH_TOKEN, fee, USDC_TOKEN),
                address(this),
                block.timestamp + 1,
                _amount,
                0
            );

        uint256 _usdcAmount = IUniV3Router(UNIV3_ROUTER).exactInput{
            value: _amount
        }(_params);

        // Swap USDC for FRAX on Curve
        uint256 _fraxAmount = fraxUsdcSwap.exchange(1, 0, _usdcAmount, 0);

        address[] memory _path = new address[](2);
        _path[0] = FRAX_TOKEN;
        _path[1] = FXS_TOKEN;
        uint256[] memory amounts = IUniV2Router(UNISWAP_ROUTER)
            .swapExactTokensForTokens(
                _fraxAmount,
                1,
                _path,
                address(this),
                block.timestamp + 1
            );
        return amounts[1];
    }

    /// @notice Swap native ETH for FXS via different routes
    /// @param _amount - amount to swap
    /// @param _option - the option to use when swapping
    /// @param _ethToFxs - whether to swap from eth to fxs or the inverse
    /// @return amount of token obtained after the swap
    function _swapEthFxs(
        uint256 _amount,
        SwapOption _option,
        bool _ethToFxs
    ) internal returns (uint256) {
        if (_option == SwapOption.Curve) {
            return _curveEthFxsSwap(_amount, _ethToFxs);
        } else if (_option == SwapOption.Uniswap) {
            return _uniV3EthFxsSwap(_amount, _ethToFxs);
        } else if (_option == SwapOption.UniCurve1) {
            return
                _ethToFxs
                    ? _uniCurve1EthToFxsSwap(_amount)
                    : _uniCurve1FxsToEthSwap(_amount);
        } else {
            return
                _ethToFxs
                    ? _uniStableEthToFxsSwap(_amount)
                    : _uniStableFxsToEthSwap(_amount);
        }
    }

    receive() external payable {}
}
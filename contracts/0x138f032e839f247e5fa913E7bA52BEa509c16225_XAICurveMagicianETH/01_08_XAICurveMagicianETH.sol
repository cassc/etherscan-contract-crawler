// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IMagician.sol";
import "./interfaces/ICurveMetaPoolLike.sol";
import "./interfaces/ICurvePoolLike128.sol";
import "./interfaces/ICurvePoolLike256.sol";

/// @dev Magician to support liquidations through Curve-XAI pool
/// IT IS NOT PART OF THE PROTOCOL. SILO CREATED THIS TOOL, MOSTLY AS AN EXAMPLE.
contract XAICurveMagicianETH is IMagician {
    using SafeERC20 for IERC20;

    // XAI/FRAXBP(FRAX/USDC)
    ICurveMetaPoolLike public constant XAI_FRAXBP_POOL = ICurveMetaPoolLike(0x326290A1B0004eeE78fa6ED4F1d8f4b2523ab669);
    // DAI/USDC/USDT
    ICurvePoolLike128 public constant CRV3_POOL = ICurvePoolLike128(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);
    // USDT/WETH/WBTC
    ICurvePoolLike256 public constant TRICRYPTO2_POOL = ICurvePoolLike256(0xD51a44d3FaE010294C616388b506AcdA1bfAAE46);

    IERC20 public constant USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    IERC20 public constant WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 public constant XAI = IERC20(0xd7C9F0e536dC865Ae858b0C0453Fe76D13c3bEAc);
    IERC20 public constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    /// @dev Index value for the coin (curve XAI/FRAXBP pool)
    int128 public constant XAI_INDEX_XAIPOOL = 0;
    /// @dev Index value for the underlying coin (curve XAI/FRAXBP pool)
    int128 public constant USDC_INDEX_XAIPOOL = 2;
    /// @dev Index value for the coin (curve DAI/USDC/USDT pool)
    int128 public constant USDC_INDEX_3CRV = 1;
    /// @dev Index value for the coin (curve DAI/USDC/USDT pool)
    int128 public constant USDT_INDEX_3CRV = 2;
    /// @dev Index value for the coin (curve USDT/WETH/WBTC pool)
    uint256 public constant USDT_INDEX_TRICRYPTO = 0;
    /// @dev Index value for the coin (curve USDT/WETH/WBTC pool)
    uint256 public constant WETH_INDEX_TRICRYPTO = 2;

    uint256 public constant WETH_DECIMALS = 18;
    uint256 public constant XAI_DECIMALS = 18;
    uint256 public constant USDT_DECIMALS = 6;
    uint256 public constant USDC_DECIMALS = 6;

    uint256 public constant ONE_WETH = 1e18;
    uint256 public constant ONE_USDC = 1e6;
    uint256 public constant ONE_USDT = 1e6;

    uint256 public constant UNKNOWN_MIN_DY = 1;

    /// @dev Revert if `towardsNative` or `towardsAsset` will be executed for the asset other than XAI
    error InvalidAsset();

    /// @inheritdoc IMagician
    function towardsNative(address _asset, uint256 _amount) external returns (address tokenOut, uint256 amountOut) {
        if (_asset != address(XAI)) revert InvalidAsset();

        XAI.approve(address(XAI_FRAXBP_POOL), _amount);

        uint256 receivedUSDC = XAI_FRAXBP_POOL.exchange_underlying(
            XAI_INDEX_XAIPOOL,
            USDC_INDEX_XAIPOOL,
            _amount,
            UNKNOWN_MIN_DY
        );

        USDC.approve(address(CRV3_POOL), receivedUSDC);
        uint256 usdtBalanceBefore = USDT.balanceOf(address(this));
        CRV3_POOL.exchange(USDC_INDEX_3CRV, USDT_INDEX_3CRV, receivedUSDC, UNKNOWN_MIN_DY);
        uint256 usdtBalanceAfter = USDT.balanceOf(address(this));
        uint256 receivedUSDT;
        // Balance after exchange can't be less than it was before
        unchecked { receivedUSDT = usdtBalanceAfter - usdtBalanceBefore; }

        USDT.safeApprove(address(TRICRYPTO2_POOL), receivedUSDT);
        uint256 wethBalanceBefore = WETH.balanceOf(address(this));
        TRICRYPTO2_POOL.exchange(USDT_INDEX_TRICRYPTO, WETH_INDEX_TRICRYPTO, receivedUSDT, UNKNOWN_MIN_DY);
        uint256 wethBalanceAfter = WETH.balanceOf(address(this));
        // Balance after exchange can't be less than it was before
        unchecked { amountOut = wethBalanceAfter - wethBalanceBefore; }

        return (address(WETH), amountOut);
    }

    /// @inheritdoc IMagician
    function towardsAsset(address _asset, uint256 _amount) external returns (address tokenOut, uint256 amountOut) {
        if (_asset != address(XAI)) revert InvalidAsset();

        uint256 increasedRequiredAmount;

        // Increasing a little bit value of the required XAI as can't get the expected number of XAI
        // on the last step of the exchange without it.
        // Math is unchecked as we do not expect to work with large numbers during the liquidation
        // to catch an overflow here.
        unchecked { increasedRequiredAmount = _amount + 1e17; }

        // calculate a price
        (uint256 usdcIn, uint256 xaiOut) = _calcRequiredUSDC(increasedRequiredAmount);

        assert(xaiOut >= _amount);

        (uint256 usdtIn, uint256 usdcOut) = _calcRequiredUSDT(usdcIn);
        (uint256 wethIn, uint256 usdtOut) = _calcRequiredWETH(usdtIn);

        // WETH -> USDT
        WETH.approve(address(TRICRYPTO2_POOL), wethIn);
        TRICRYPTO2_POOL.exchange(WETH_INDEX_TRICRYPTO, USDT_INDEX_TRICRYPTO, wethIn, usdtOut);
        // USDT -> USDC
        USDT.safeApprove(address(CRV3_POOL), usdtOut);
        CRV3_POOL.exchange(USDT_INDEX_3CRV, USDC_INDEX_3CRV, usdtOut, usdcOut);
        // USDC -> XAI
        USDC.approve(address(XAI_FRAXBP_POOL), usdcOut);
        XAI_FRAXBP_POOL.exchange_underlying(USDC_INDEX_XAIPOOL, XAI_INDEX_XAIPOOL, usdcOut, _amount);

        return (address(XAI), wethIn);
    }

    /// @param _requiredAmountOut Expected amount of XAI to receive after exhange
    /// It may be a bit more, but not less than the provided value.
    /// @return amountIn Amount of USDC that we should send for exchage
    /// @return amountOut Amount of XAI that we will receive in exchange for `amountIn` USDC
    function _calcRequiredUSDC(uint256 _requiredAmountOut)
        internal
        view
        returns (uint256 amountIn, uint256 amountOut)
    {
        // We do normalization of the rate as we will recive from the `get_dy_underlying` a value with `_decimalsOut`
        uint256 dy = XAI_FRAXBP_POOL.get_dy_underlying(USDC_INDEX_XAIPOOL, XAI_INDEX_XAIPOOL, ONE_USDC);
        uint256 rate = _normalizeWithDecimals(dy, USDC_DECIMALS, XAI_DECIMALS);
        // Normalize `_requiredAmountOut` to `_decimalsIn` as we will use it
        // for calculation of the `amountIn` value of the `_tokenIn`
        _requiredAmountOut = _normalizeWithDecimals(_requiredAmountOut, USDC_DECIMALS, XAI_DECIMALS);
        uint256 multiplied = ONE_USDC * _requiredAmountOut;
        // Zero value for amountIn is unacceptable.
        assert(multiplied >= rate); // Otherwise, we may get zero.
        // Assertion above make it safe
        unchecked { amountIn = multiplied / rate; }
        // `get_dy_underlying` is an increasing function.
        // It should take ~ 1 - 6 iterations to `amountOut >= _requiredAmountOut`.
        while (true) {
            amountOut = XAI_FRAXBP_POOL.get_dy_underlying(USDC_INDEX_XAIPOOL, XAI_INDEX_XAIPOOL, amountIn);
            uint256 amountOutNormalized = _normalizeWithDecimals(amountOut, USDC_DECIMALS, XAI_DECIMALS);

            if (amountOutNormalized >= _requiredAmountOut) {
                return (amountIn, amountOut);
            }

            amountIn = _calcAmountIn(
                amountIn,
                ONE_USDC,
                rate,
                _requiredAmountOut,
                amountOutNormalized
            );
        }
    }

    /// @param _requiredAmountOut Expected amount of USDC to receive after exhange
    /// It may be a bit more, but not less than the provided value.
    /// @return amountIn Amount of USDT that we should send for exchage
    /// @return amountOut Amount of USDC that we will receive in exchange for `amountIn` USDT
    function _calcRequiredUSDT(uint256 _requiredAmountOut)
        internal
        view
        returns (uint256 amountIn, uint256 amountOut)
    {
        // We do normalization of the rate as we will recive from the `get_dy` a value with `USDC_DECIMALS`
        uint256 rate = CRV3_POOL.get_dy(USDT_INDEX_3CRV, USDC_INDEX_3CRV, ONE_USDT);
        uint256 multiplied = ONE_USDT * _requiredAmountOut;
        // Zero value for amountIn is unacceptable.
        assert(multiplied >= rate); // Otherwise, we may get zero.
        // Assertion above make it safe
        unchecked { amountIn = multiplied / rate; }
        // `get_dy` is an increasing function.
        // It should take ~ 1 - 6 iterations to `amountOut >= _requiredAmountOut`.
        while (true) {
            amountOut = CRV3_POOL.get_dy(USDT_INDEX_3CRV, USDC_INDEX_3CRV, amountIn);

            if (amountOut >= _requiredAmountOut) {
                return (amountIn, amountOut);
            }

            amountIn = _calcAmountIn(
                amountIn,
                ONE_USDT,
                rate,
                _requiredAmountOut,
                amountOut
            );
        }
    }
    
    /// @param _requiredAmountOut Expected amount of WETH to receive after exhange
    /// It may be a bit more, but not less than the provided value.
    /// @return amountIn Amount of WETH that we should send for exchage
    /// @return amountOut Amount of USDT that we will receive in exchange for `amountIn` WETH
    function _calcRequiredWETH(uint256 _requiredAmountOut)
        internal
        view
        returns (uint256 amountIn, uint256 amountOut)
    {
        // We do normalization of the rate as we will recive from the `get_dy` a value with `USDT_DECIMALS`
        uint256 dy = TRICRYPTO2_POOL.get_dy(WETH_INDEX_TRICRYPTO, USDT_INDEX_TRICRYPTO, ONE_WETH);
        uint256 rate = _normalizeWithDecimals(dy, WETH_DECIMALS, USDT_DECIMALS);
        // Normalize `_requiredAmountOut` to `WETH_DECIMALS` as we will use it
        // for calculation of the `amountIn` value of the `_tokenIn`
        _requiredAmountOut = _normalizeWithDecimals(_requiredAmountOut, WETH_DECIMALS, USDT_DECIMALS);
        uint256 multiplied = ONE_WETH * _requiredAmountOut;
        // Zero value for amountIn is unacceptable.
        assert(multiplied >= rate); // Otherwise, we may get zero.
        // Assertion above make it safe
        unchecked { amountIn = multiplied / rate; }
        // `get_dy` is an increasing function.
        // It should take ~ 1 - 6 iterations to `amountOut >= _requiredAmountOut`.
        while (true) {
            amountOut = TRICRYPTO2_POOL.get_dy(WETH_INDEX_TRICRYPTO, USDT_INDEX_TRICRYPTO, amountIn);
            uint256 amountOutNormalized = _normalizeWithDecimals(amountOut, WETH_DECIMALS, USDT_DECIMALS);

            if (amountOutNormalized >= _requiredAmountOut) {
                return (amountIn, amountOut);
            }

            amountIn = _calcAmountIn(
                amountIn,
                ONE_WETH,
                rate,
                _requiredAmountOut,
                amountOutNormalized
            );
        }
    }

    /// @dev Adjusts the given value to have different decimals
    function _normalizeWithDecimals(
        uint256 _value,
        uint256 _toDecimals,
        uint256 _fromDecimals
    )
        internal
        view
        virtual
        returns (uint256)
    {
        if (_toDecimals == _fromDecimals) {
            return _value;
        } else if (_toDecimals < _fromDecimals) {
            uint256 devideOn;
            // It can be unchecked because of the condition `_toDecimals < _fromDecimals`.
            // We trust to `_fromDecimals` and `_toDecimals` they should not have large numbers.
            unchecked { devideOn = 10 ** (_fromDecimals - _toDecimals); }
            // Zero value after normalization is unacceptable.
            assert(_value >= devideOn); // Otherwise, we may get zero.
            // Assertion above make it safe
            unchecked { return _value / devideOn; }
        } else {
            uint256 decimalsDiff;
            // Because of the condition `_toDecimals < _fromDecimals` above,
            // we are safe as it guarantees that `_toDecimals` is > `_fromDecimals`
            unchecked { decimalsDiff = 10 ** (_toDecimals - _fromDecimals); }

            return _value * decimalsDiff;
        }
    }

    /// @notice Extension for such functions like: `_calcRequiredWETH`, `_calcRequiredUSDC`, and `_calcRequiredUSDT`
    function _calcAmountIn(
        uint256 _amountIn,
        uint256 _one,
        uint256 _rate,
        uint256 _requiredAmountOut,
        uint256 _amountOutNormalized
    )
        private
        pure
        returns (uint256)
    {
        uint256 diff;
        // Because of the condition `amountOutNormalized >= _requiredAmountOut` in a calling function,
        // safe math is not required here.
        unchecked { diff = _requiredAmountOut - _amountOutNormalized; }
        // We may be stuck in a situation where a difference between
        // a `_requiredAmountOut` and `amountOutNormalized`
        // will be small and we will need to perform more steps.
        // This expression helps to escape the almost infinite loop.
        if (diff < 1e3) {
            // If the `amountIn` value is high the `get_dy` function will revert first
            unchecked { _amountIn += 1e3; }
        } else {
            // `one * diff` is safe as `diff` will be lower then the `_requiredAmountOut`
            // for which we have safe math while doing `ONE_... * _requiredAmountOut` in a calling function.
            unchecked { _amountIn += (_one * diff) / _rate; }
        }

        return _amountIn;
    }
}
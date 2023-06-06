// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "IOracle.sol";
import "ScaledMath.sol";

interface ICurvePriceOracle {
    function price_oracle() external view returns (uint256);
}

contract CrvUsdOracle is IOracle {
    using ScaledMath for uint256;

    // Tokens
    address internal constant _CRVUSD = address(0xf939E0A03FB07F59A73314E73794Be0E57ac1b4E);
    address internal constant _USDC = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    address internal constant _USDT = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    address internal constant _USDP = address(0x8E870D67F660D95d5be530380D0eC0bd388289E1);

    // Curve pools
    address internal constant _CRVUSD_USDC = address(0x4DEcE678ceceb27446b35C672dC7d61F30bAD69E);
    address internal constant _CRVUSD_USDT = address(0x390f3595bCa2Df7d23783dFd126427CCeb997BF4);
    address internal constant _CRVUSD_USDP = address(0xCa978A0528116DDA3cbA9ACD3e68bc6191CA53D0);

    IOracle internal immutable _genericOracle;

    constructor(address genericOracle_) {
        _genericOracle = IOracle(genericOracle_);
    }

    function getUSDPrice(address token_) external view override returns (uint256) {
        require(isTokenSupported(token_), "token not supported");
        uint256 priceFromUsdc_ = _getCrvUsdPriceForCurvePool(_CRVUSD_USDC, _USDC);
        uint256 priceFromUsdt_ = _getCrvUsdPriceForCurvePool(_CRVUSD_USDT, _USDT);
        uint256 priceFromUsdp_ = _getCrvUsdPriceForCurvePool(_CRVUSD_USDP, _USDP);
        return _median(priceFromUsdc_, priceFromUsdt_, priceFromUsdp_);
    }

    function isTokenSupported(address token_) public pure override returns (bool) {
        return token_ == _CRVUSD;
    }

    function _getCrvUsdPriceForCurvePool(
        address curvePool_,
        address token_
    ) internal view returns (uint256) {
        uint256 tokenPrice_ = _genericOracle.getUSDPrice(token_);
        uint256 tokenPerCrvUsd_ = ICurvePriceOracle(curvePool_).price_oracle();
        return tokenPrice_.mulDown(tokenPerCrvUsd_);
    }

    function _median(uint256 a, uint256 b, uint256 c) internal pure returns (uint256) {
        if ((a >= b && a <= c) || (a >= c && a <= b)) return a;
        if ((b >= a && b <= c) || (b >= c && b <= a)) return b;
        return c;
    }
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../ProviderAwareOracle.sol";
import "../../interfaces/CurveTokenInterface.sol";
import "../../../lib/FixedPointMathLib.sol";

contract CurveLPOracle is ProviderAwareOracle {

    using FixedPointMathLib for uint;

    /// @notice Curve token version, currently support v1, v2 and v3
    enum CurveTokenVersion {
        V1,
        V2,
        V3
    }

    /// @notice Curve pool type, currently support ETH and USD base
    enum CurvePoolType {
        ETH,
        USD
    }

    struct CrvTokenInfo {
        /// @notice Check if this token is a curve pool token
        bool isCrvToken;
        /// @notice The curve pool type
        CurvePoolType poolType;
        /// @notice The curve swap contract address
        address curveSwap;
        uint nCoins;
    }

    event SetCurveToken(address token, CurvePoolType poolType, address swap, uint numberTokens);

    /// @notice Curve pool token data
    mapping(address => CrvTokenInfo) public crvTokens;

    address private immutable USDC;

    constructor(address _provider, address _usdc) ProviderAwareOracle(_provider) {
        USDC = _usdc;
    }

    function getSafePrice(address token) external view override returns (uint256 _amountOut) {
        _amountOut = getCrvTokenPrice(token);
    }

    /// @dev This method has no guarantee on the safety of the price returned. It should only be
    //used if the price returned does not expose the caller contract to flashloan attacks.
    function getCurrentPrice(address token) external view override returns (uint256 _amountOut) {
        _amountOut = getCrvTokenPrice(token);
    }

    /// @dev Gets the safe price, no updates necessary
    function updateSafePrice(address token) external view override returns (uint256 _amountOut) {
        _amountOut = getCrvTokenPrice(token);
    }

    /**
     * @notice Get price for curve pool tokens
     * @param token The curve pool token
     * @return The price
     */
    function getCrvTokenPrice(address token) internal view returns (uint256) {
        CrvTokenInfo memory crvTokenInfo = crvTokens[token];
        require(crvTokenInfo.isCrvToken, "not a curve pool token");

        uint256 virtualPrice = CurveSwapInterface(crvTokenInfo.curveSwap).get_virtual_price();

        if (crvTokenInfo.poolType == CurvePoolType.ETH) {
            return virtualPrice;
        }

        // We treat USDC as USD and convert the price to ETH base.
        return  provider.getSafePrice(USDC) * virtualPrice / PRECISION;
    }

    /**
     * @notice See assets as curve pool tokens for multiple tokens
     * @param tokenAddresses The list of tokens
     * @param poolType The list of curve pool type (ETH or USD base only)
     * @param swap The list of curve swap address
     */
    function setCurveTokens(
        address[] calldata tokenAddresses,
        CurveTokenVersion[] calldata version,
        CurvePoolType[] calldata poolType,
        address[] calldata swap,
        uint[] calldata nTokens
    ) external onlyOwner {
        require(
            tokenAddresses.length == version.length &&
                tokenAddresses.length == poolType.length &&
                tokenAddresses.length == swap.length,
            "mismatched data"
        );
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            if (version[i] == CurveTokenVersion.V3) {
                // Sanity check to make sure the token minter is right.
                require(CurveTokenV3Interface(tokenAddresses[i]).minter() == swap[i], "incorrect pool");
            }

            crvTokens[tokenAddresses[i]] = CrvTokenInfo({isCrvToken: true, poolType: poolType[i], curveSwap: swap[i],  nCoins: nTokens[i]});
            emit SetCurveToken(tokenAddresses[i], poolType[i], swap[i], nTokens[i]);
        }
    }

}
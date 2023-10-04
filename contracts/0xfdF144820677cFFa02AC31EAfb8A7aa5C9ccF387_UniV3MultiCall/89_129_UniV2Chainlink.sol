// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IUniV2} from "../../interfaces/oracles/IUniV2.sol";
import {ChainlinkBasic} from "./ChainlinkBasic.sol";
import {Errors} from "../../../Errors.sol";

/**
 * @dev supports oracles which have one token which is a 50/50 LP token
 * compatible with v2v3 or v3 interfaces
 * should only be utilized with eth based oracles, not usd-based oracles
 */
contract UniV2Chainlink is ChainlinkBasic {
    uint256 internal immutable _tolerance; // tolerance must be an integer less than 10000 and greater than 0
    mapping(address => bool) public isLpToken;
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint256 internal constant UNI_V2_BASE_CURRENCY_UNIT = 1e18; // 18 decimals for ETH based oracles

    constructor(
        address[] memory _tokenAddrs,
        address[] memory _oracleAddrs,
        address[] memory _lpAddrs,
        uint256 _toleranceAmount
    )
        ChainlinkBasic(
            _tokenAddrs,
            _oracleAddrs,
            WETH,
            UNI_V2_BASE_CURRENCY_UNIT
        )
    {
        uint256 lpAddrsLen = _lpAddrs.length;
        if (lpAddrsLen == 0) {
            revert Errors.InvalidArrayLength();
        }
        if (_toleranceAmount >= 10000 || _toleranceAmount == 0) {
            revert Errors.InvalidOracleTolerance();
        }
        _tolerance = _toleranceAmount;
        for (uint256 i; i < lpAddrsLen; ) {
            if (_lpAddrs[i] == address(0)) {
                revert Errors.InvalidAddress();
            }
            isLpToken[_lpAddrs[i]] = true;
            unchecked {
                ++i;
            }
        }
    }

    function getPrice(
        address collToken,
        address loanToken
    ) external view override returns (uint256 collTokenPriceInLoanToken) {
        (uint256 collTokenPriceRaw, uint256 loanTokenPriceRaw) = getRawPrices(
            collToken,
            loanToken
        );
        uint256 loanTokenDecimals = IERC20Metadata(loanToken).decimals();
        collTokenPriceInLoanToken = Math.mulDiv(
            collTokenPriceRaw,
            10 ** loanTokenDecimals,
            loanTokenPriceRaw
        );
    }

    function getRawPrices(
        address collToken,
        address loanToken
    )
        public
        view
        override
        returns (uint256 collTokenPriceRaw, uint256 loanTokenPriceRaw)
    {
        bool isCollTokenLpToken = isLpToken[collToken];
        bool isLoanTokenLpToken = isLpToken[loanToken];
        if (!isCollTokenLpToken && !isLoanTokenLpToken) {
            revert Errors.NoLpTokens();
        }
        collTokenPriceRaw = isCollTokenLpToken
            ? getLpTokenPrice(collToken)
            : _getPriceOfToken(collToken);
        loanTokenPriceRaw = isLoanTokenLpToken
            ? getLpTokenPrice(loanToken)
            : _getPriceOfToken(loanToken);
    }

    /**
     * @notice Returns the price of 1 "whole" LP token (in 1 base currency unit, e.g., 10**18) in ETH
     * @dev Since the uniswap reserves could be skewed in any direction by flash loans,
     * we need to calculate the "fair" reserve of each token in the pool using invariant K
     * and then calculate the price of each token in ETH using the oracle prices for each token
     * @param lpToken Address of LP token
     * @return lpTokenPriceInEth of LP token in ETH
     */
    function getLpTokenPrice(
        address lpToken
    ) public view returns (uint256 lpTokenPriceInEth) {
        // assign uint112 reserves to uint256 to also handle large k invariants
        (uint256 reserve0, uint256 reserve1, ) = IUniV2(lpToken).getReserves();
        if (reserve0 * reserve1 == 0) {
            revert Errors.ZeroReserve();
        }

        (address token0, address token1) = (
            IUniV2(lpToken).token0(),
            IUniV2(lpToken).token1()
        );
        uint256 totalLpSupply = IUniV2(lpToken).totalSupply();
        uint256 priceToken0 = _getPriceOfToken(token0);
        uint256 priceToken1 = _getPriceOfToken(token1);
        uint256 token0Decimals = IERC20Metadata(token0).decimals();
        uint256 token1Decimals = IERC20Metadata(token1).decimals();

        _reserveAndPriceCheck(
            reserve0,
            reserve1,
            priceToken0,
            priceToken1,
            token0Decimals,
            token1Decimals
        );

        // calculate fair LP token price based on "fair reserves" as described in
        // https://blog.alphaventuredao.io/fair-lp-token-pricing/
        // formula: p = 2 * sqrt(r0 * r1) * sqrt(p0) * sqrt(p1) / s
        // note: price is for 1 "whole" LP token unit, hence need to scale up by LP token decimals;
        // need to divide by sqrt reserve decimals to cancel out units of invariant k
        // IMPORTANT: while formula is robust against typical flashloan skews, lenders should use this
        // oracle with caution and take into account skew scenarios when setting their LTVs
        lpTokenPriceInEth = Math.mulDiv(
            2 * Math.sqrt(reserve0 * reserve1),
            Math.sqrt(priceToken0 * priceToken1) * UNI_V2_BASE_CURRENCY_UNIT,
            totalLpSupply *
                Math.sqrt(10 ** token0Decimals * 10 ** token1Decimals)
        );
    }

    /**
     * @notice function checks that price from reserves is within tolerance of price from oracle
     * @dev This function is needed because a one-sided donation and sync can skew the fair reserve
     * calculation above. This function checks that the price from reserves is within a tolerance
     * @param reserve0 Reserve of token0
     * @param reserve1 Reserve of token1
     * @param priceToken0 Price of token0 from oracle
     * @param priceToken1 Price of token1 from oracle
     * @param token0Decimals Decimals of token0
     * @param token1Decimals Decimals of token1
     */
    function _reserveAndPriceCheck(
        uint256 reserve0,
        uint256 reserve1,
        uint256 priceToken0,
        uint256 priceToken1,
        uint256 token0Decimals,
        uint256 token1Decimals
    ) internal view {
        uint256 priceFromReserves = (reserve0 * 10 ** token1Decimals) /
            reserve1;
        uint256 priceFromOracle = (priceToken1 * 10 ** token0Decimals) /
            priceToken0;

        if (
            priceFromReserves >
            ((10000 + _tolerance) * priceFromOracle) / 10000 ||
            priceFromReserves < ((10000 - _tolerance) * priceFromOracle) / 10000
        ) {
            revert Errors.ReserveRatiosSkewedFromOraclePrice();
        }
    }
}
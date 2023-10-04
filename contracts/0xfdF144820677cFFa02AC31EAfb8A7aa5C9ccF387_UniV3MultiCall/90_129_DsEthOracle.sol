// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {OracleLibrary} from "../uniswap/OracleLibrary.sol";
import {ChainlinkBase} from "../chainlink/ChainlinkBase.sol";
import {Errors} from "../../../Errors.sol";
import {TwapGetter} from "../uniswap/TwapGetter.sol";
import {IDSETH} from "../../interfaces/oracles/IDSETH.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @dev custom oracle for ds-eth
 */
contract DsEthOracle is ChainlinkBase, TwapGetter {
    // must be paired with WETH and only allow components within ds eth to use TWAP
    mapping(address => address) public uniV3PairAddrs;
    uint256 internal immutable _tolerance; // tolerance must be an integer less than 10000 and greater than 0

    address internal constant DS_ETH =
        0x341c05c0E9b33C0E38d64de76516b2Ce970bB3BE;
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint256 internal constant INDEX_COOP_BASE_CURRENCY_UNIT = 1e18; // 18 decimals for ETH based oracles
    uint32 internal immutable _twapInterval; // in seconds (e.g. 1 hour = 3600 seconds)

    constructor(
        address[] memory _tokenAddrs,
        address[] memory _oracleAddrs,
        address[] memory _uniswapV3PairAddrs,
        uint32 twapInterval,
        uint256 tolerance
    ) ChainlinkBase(_tokenAddrs, _oracleAddrs, INDEX_COOP_BASE_CURRENCY_UNIT) {
        if (tolerance >= 10000 || tolerance == 0) {
            revert Errors.InvalidOracleTolerance();
        }
        _tolerance = tolerance;
        // min 30 minute twap interval
        if (twapInterval < 30 minutes) {
            revert Errors.TooShortTwapInterval();
        }
        _twapInterval = twapInterval;

        // in future could be possible that all constituents are chainlink compatible
        // so _uniswapV3PairAddrs.length == 0 is allowed, hence no length == 0 check
        address token1;
        for (uint256 i; i < _uniswapV3PairAddrs.length; ) {
            if (_uniswapV3PairAddrs[i] == address(0)) {
                revert Errors.InvalidAddress();
            }
            // try could also pass if you passed in uni v2 pair address
            // though should later fail when trying to price in future
            // care must be taken not to pass in uni v2 pair address
            try IUniswapV3Pool(_uniswapV3PairAddrs[i]).token0() returns (
                address token0
            ) {
                token1 = IUniswapV3Pool(_uniswapV3PairAddrs[i]).token1();
                // must have one token weth and other token component in ds eth
                if (
                    !(token0 == WETH && IDSETH(DS_ETH).isComponent(token1)) &&
                    !(token1 == WETH && IDSETH(DS_ETH).isComponent(token0))
                ) {
                    revert Errors.InvalidAddress();
                }
                // store non weth token address as key with uni v3 pair address as value
                uniV3PairAddrs[
                    token0 == WETH ? token1 : token0
                ] = _uniswapV3PairAddrs[i];
            } catch {
                revert Errors.InvalidAddress();
            }
            unchecked {
                ++i;
            }
        }
    }

    function getPrice(
        address collToken,
        address loanToken
    ) external view override returns (uint256 collTokenPriceInLoanToken) {
        // must have at least one token is DS_ETH to use this oracle
        (uint256 priceOfCollToken, uint256 priceOfLoanToken) = getRawPrices(
            collToken,
            loanToken
        );
        uint256 loanTokenDecimals = (loanToken == WETH || loanToken == DS_ETH)
            ? 18
            : IERC20Metadata(loanToken).decimals();
        collTokenPriceInLoanToken =
            (priceOfCollToken * 10 ** loanTokenDecimals) /
            priceOfLoanToken;
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
        // must have at least one token is DS_ETH to use this oracle
        if (collToken != DS_ETH && loanToken != DS_ETH) {
            revert Errors.NoDsEth();
        }
        (collTokenPriceRaw, loanTokenPriceRaw) = (
            _getPriceOfToken(collToken),
            _getPriceOfToken(loanToken)
        );
    }

    function _getPriceOfToken(
        address token
    ) internal view virtual override returns (uint256 tokenPriceRaw) {
        // note: if token is not WETH or DS_ETH, then will revert if not a chainlink oracle
        // this is by design, even if that address has a TWAP, it will not be used
        // except only when calculating ds eth price to minimize risk
        // i.e. if stakewise eth has uni v3 address but no chainlink address, and lender
        // tries to use stakewise eth as loan and ds eth as collateral, then revert

        // @dev: no use of nested ternary operator for npx hardhat compatibility reasons
        if (token == WETH) {
            tokenPriceRaw = BASE_CURRENCY_UNIT;
        } else {
            tokenPriceRaw = token == DS_ETH
                ? _getDsEthPrice()
                : super._getPriceOfToken(token);
        }
    }

    function _getDsEthPrice() internal view returns (uint256 dsEthPriceRaw) {
        address[] memory components = IDSETH(DS_ETH).getComponents();
        address currComponent;
        uint256 currComponentPrice;
        uint256 totalPriceUniCumSum;
        for (uint256 i; i < components.length; ) {
            currComponent = components[i];
            if (
                oracleAddrs[currComponent] == address(0) &&
                uniV3PairAddrs[currComponent] == address(0)
            ) {
                // if component has no oracle and no uni v3 pair, then revert
                revert Errors.NoOracle();
            }
            // always try to use chainlink oracle if available even if also had uni v3 pair passed in by mistake too
            currComponentPrice = oracleAddrs[currComponent] == address(0)
                ? _getTwapPrice(uniV3PairAddrs[currComponent])
                : _getPriceOfToken(currComponent);
            totalPriceUniCumSum += (currComponentPrice *
                IDSETH(DS_ETH).getTotalComponentRealUnits(currComponent));
            unchecked {
                ++i;
            }
        }
        dsEthPriceRaw = totalPriceUniCumSum / INDEX_COOP_BASE_CURRENCY_UNIT;
    }

    function _getTwapPrice(
        address uniV3PairAddr
    ) internal view returns (uint256 twapPriceRaw) {
        (address token0, address token1) = (
            IUniswapV3Pool(uniV3PairAddr).token0(),
            IUniswapV3Pool(uniV3PairAddr).token1()
        );
        (address inToken, address outToken) = (
            token0 == WETH ? token1 : token0,
            token1 == WETH ? token1 : token0
        );
        twapPriceRaw = getTwap(inToken, outToken, _twapInterval, uniV3PairAddr);
        (, int24 tick, , , , , ) = IUniswapV3Pool(uniV3PairAddr).slot0();

        uint256 spotPrice = OracleLibrary.getQuoteAtTick(
            tick,
            SafeCast.toUint128(10 ** IERC20Metadata(inToken).decimals()),
            inToken,
            outToken
        );

        // if twap price exceeds threshold from spot proxy price, then revert
        if (
            twapPriceRaw > ((10000 + _tolerance) * spotPrice) / 10000 ||
            twapPriceRaw < ((10000 - _tolerance) * spotPrice) / 10000
        ) {
            revert Errors.TwapExceedsThreshold();
        }
    }
}
// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IOlympus} from "../../interfaces/oracles/IOlympus.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {ChainlinkBasic} from "./ChainlinkBasic.sol";
import {Errors} from "../../../Errors.sol";

/**
 * @dev supports olympus gOhm oracles which are compatible with v2v3 or v3 interfaces
 * should only be utilized with eth based oracles, not usd-based oracles
 */
contract OlympusOracle is ChainlinkBasic {
    address internal constant GOHM_ADDR =
        0x0ab87046fBb341D058F17CBC4c1133F25a20a52f;
    uint256 internal constant SOHM_DECIMALS = 9;
    address internal constant ETH_OHM_ORACLE_ADDR =
        0x9a72298ae3886221820B1c878d12D872087D3a23;
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint256 internal constant GOHM_BASE_CURRENCY_UNIT = 1e18; // 18 decimals for ETH based oracles

    constructor(
        address[] memory _tokenAddrs,
        address[] memory _oracleAddrs
    ) ChainlinkBasic(_tokenAddrs, _oracleAddrs, WETH, GOHM_BASE_CURRENCY_UNIT) {
        oracleAddrs[GOHM_ADDR] = ETH_OHM_ORACLE_ADDR;
    }

    function getPrice(
        address collToken,
        address loanToken
    ) external view override returns (uint256 collTokenPriceInLoanToken) {
        if (collToken != GOHM_ADDR && loanToken != GOHM_ADDR) {
            revert Errors.NeitherTokenIsGOHM();
        }
        (uint256 priceOfCollToken, uint256 priceOfLoanToken) = (
            _getPriceOfToken(collToken),
            _getPriceOfToken(loanToken)
        );
        uint256 loanTokenDecimals = IERC20Metadata(loanToken).decimals();
        uint256 index = IOlympus(GOHM_ADDR).index();

        collTokenPriceInLoanToken = collToken == GOHM_ADDR
            ? Math.mulDiv(
                priceOfCollToken,
                (10 ** loanTokenDecimals) * index,
                priceOfLoanToken * (10 ** SOHM_DECIMALS)
            )
            : Math.mulDiv(
                priceOfCollToken,
                (10 ** loanTokenDecimals) * (10 ** SOHM_DECIMALS),
                priceOfLoanToken * index
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
        if (collToken != GOHM_ADDR && loanToken != GOHM_ADDR) {
            revert Errors.NeitherTokenIsGOHM();
        }
        uint256 index = IOlympus(GOHM_ADDR).index();
        (collTokenPriceRaw, loanTokenPriceRaw) = (
            _getPriceOfToken(collToken),
            _getPriceOfToken(loanToken)
        );
        if (collToken == GOHM_ADDR) {
            collTokenPriceRaw = Math.mulDiv(
                collTokenPriceRaw,
                index,
                10 ** SOHM_DECIMALS
            );
        } else {
            loanTokenPriceRaw = Math.mulDiv(
                loanTokenPriceRaw,
                index,
                10 ** SOHM_DECIMALS
            );
        }
    }
}
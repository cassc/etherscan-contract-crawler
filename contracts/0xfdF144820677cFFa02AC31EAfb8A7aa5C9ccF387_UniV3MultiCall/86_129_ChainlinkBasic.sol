// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {ChainlinkBase} from "./ChainlinkBase.sol";
import {Errors} from "../../../Errors.sol";

/**
 * @dev supports oracles which are compatible with v2v3 or v3 interfaces
 */
contract ChainlinkBasic is ChainlinkBase {
    // solhint-disable var-name-mixedcase
    address public immutable BASE_CURRENCY;

    constructor(
        address[] memory _tokenAddrs,
        address[] memory _oracleAddrs,
        address baseCurrency,
        uint256 baseCurrencyUnit
    ) ChainlinkBase(_tokenAddrs, _oracleAddrs, baseCurrencyUnit) {
        if (baseCurrency == address(0)) {
            revert Errors.InvalidAddress();
        }
        BASE_CURRENCY = baseCurrency;
    }

    function _getPriceOfToken(
        address token
    ) internal view virtual override returns (uint256 tokenPriceRaw) {
        tokenPriceRaw = token == BASE_CURRENCY
            ? BASE_CURRENCY_UNIT
            : super._getPriceOfToken(token);
    }
}
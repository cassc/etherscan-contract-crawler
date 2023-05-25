/**
 * SPDX-License-Identifier: MIT
 *
 * Copyright (c) 2022 Coinbase, Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

pragma solidity 0.8.6;

import { Address } from "@openzeppelin4.2.0/contracts/utils/Address.sol";

/**
 * @title ExchangeRateUtil
 * @dev Used for safe exchange rate updating
 */
library ExchangeRateUtil {
    using Address for address;

    bytes4 private constant _EXCHANGE_RATE_GETTER_SELECTOR = bytes4(
        keccak256("exchangeRate()")
    );
    bytes4 private constant _EXCHANGE_RATE_UPDATER_SELECTOR = bytes4(
        keccak256("updateExchangeRate(uint256)")
    );

    /**
     * @dev Updates the given token contract's exchange rate
     * @param newExchangeRate New exchange rate
     * @param tokenContract Token contract address
     */
    function safeUpdateExchangeRate(
        uint256 newExchangeRate,
        address tokenContract
    ) internal {
        bytes memory data = abi.encodeWithSelector(
            _EXCHANGE_RATE_UPDATER_SELECTOR,
            newExchangeRate
        );
        tokenContract.functionCall(
            data,
            "ExchangeRateUtil: update exchange rate failed"
        );
    }

    /**
     * @dev Gets the given token contract's exchange rate
     * @param tokenContract Token contract address
     * @return The exchange rate read from the given token contract
     */
    function safeGetExchangeRate(address tokenContract)
        internal
        view
        returns (uint256)
    {
        bytes memory data = abi.encodePacked(_EXCHANGE_RATE_GETTER_SELECTOR);
        bytes memory returnData = tokenContract.functionStaticCall(
            data,
            "ExchangeRateUtil: get exchange rate failed"
        );
        return abi.decode(returnData, (uint256));
    }
}
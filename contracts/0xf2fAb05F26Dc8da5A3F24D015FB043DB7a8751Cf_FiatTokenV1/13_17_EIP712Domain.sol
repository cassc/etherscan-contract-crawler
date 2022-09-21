/**
 * SPDX-License-Identifier: MIT
 *
 * Copyright (c) 2018-2020 CENTRE SECZ
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

pragma solidity 0.8.11;

import "../util/EIP712.sol";

/**
 * @dev Forked from https://github.com/centrehq/centre-tokens/blob/37039f00534d3e5148269adf98bd2d42ea9fcfd7/contracts/v2/EIP712Domain.sol
 * Modifications:
 * 1. Change solidity version to 0.8.11
 * 2. Add 4 new state variables: DOMAIN_SEPARATOR, CHAIN_ID, NAME, VERSION
 * 3. Add new function _domainSeparatorV4
 * 4. Add gap
 */

/**
 * @title EIP712 Domain
 */
contract EIP712Domain {
    /**
     * @dev EIP712 Domain Separator
     */
    bytes32 internal DOMAIN_SEPARATOR;
    uint256 internal CHAIN_ID;
    string internal NAME;
    string internal VERSION;

    /**
    * @dev Returns the domain separator for the current chain.
    */
    function _domainSeparatorV4() public view returns (bytes32) {
        if(block.chainid == CHAIN_ID) {
            return DOMAIN_SEPARATOR;
        } else {
            return EIP712.makeDomainSeparator(NAME, VERSION);
        }
    }

    uint256[50] private __gap;
}
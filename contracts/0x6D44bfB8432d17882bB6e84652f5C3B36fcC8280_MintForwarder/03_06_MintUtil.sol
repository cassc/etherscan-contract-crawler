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
 * @title MintUtil
 * @dev Used for safe minting
 */
library MintUtil {
    bytes4 private constant _MINT_SELECTOR = bytes4(
        keccak256("mint(address,uint256)")
    );

    /**
     * @dev Safely mints ERC20 token
     * @param to Recipient's address
     * @param value Amount to mint
     * @param tokenContract Token contract address
     */
    function safeMint(
        address to,
        uint256 value,
        address tokenContract
    ) internal {
        bytes memory data = abi.encodeWithSelector(_MINT_SELECTOR, to, value);
        Address.functionCall(tokenContract, data, "MinterUtil: mint failed");
    }
}
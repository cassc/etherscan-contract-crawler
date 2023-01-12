/**
 * SPDX-License-Identifier: MIT
 *
 * Copyright (c) 2021-2022 THE TOKEN BUNQ
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

pragma solidity 0.6.12;

import { FiatTokenV2_1 } from "./FiatTokenV2_1.sol";

// solhint-disable func-name-mixedcase

/**
 * @title FiatToken V3
 * @notice ERC20 Token backed by fiat reserves, version 3
 */
contract FiatTokenV3 is FiatTokenV2_1 {
    address public evidenceArchive;
    event EvidenceArchiveChanged(address indexed newEvidenceArchive);

    /**
     * @notice Initialize v3
       @param _evidenceArchive The address of Evidence Archive
     */
    function initializeV3(address _evidenceArchive) external {
        // solhint-disable-next-line reason-string
        require(_initializedVersion == 2);
        evidenceArchive = _evidenceArchive;
        _initializedVersion = 3;
        emit EvidenceArchiveChanged(evidenceArchive);
    }

    function updateEvidenceArchive(address _newEvidenceArchive)
        external
        onlyOwner
    {
        evidenceArchive = _newEvidenceArchive;
        emit EvidenceArchiveChanged(evidenceArchive);
    }
}
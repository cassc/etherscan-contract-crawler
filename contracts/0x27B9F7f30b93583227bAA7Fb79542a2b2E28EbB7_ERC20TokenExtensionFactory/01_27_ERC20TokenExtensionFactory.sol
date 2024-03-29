pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT
import "../../../core/DaoConstants.sol";
import "../../../core/DaoRegistry.sol";
import "../../../core/CloneFactory.sol";
import "./ERC20TokenExtension.sol";

/**
MIT License

Copyright (c) 2020 Openlaw

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */

contract ERC20TokenExtensionFactory is CloneFactory, DaoConstants {
    address public identityAddress;

    event ERC20TokenExtensionCreated(address erc20ExtTokenAddress);

    constructor(address _identityAddress) {
        identityAddress = _identityAddress;
    }

    /**
     * @notice Creates a clone of the ERC20 Token Extension.
     */
    function create(
        address tokenAddress,
        uint8 decimals
    ) external {
        ERC20Extension ext = ERC20Extension(_createClone(identityAddress));
        ext.setToken(tokenAddress);
        ext.setDecimals(decimals);
        emit ERC20TokenExtensionCreated(address(ext));
    }
}
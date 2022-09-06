// SPDX-License-Identifier: MIT
/**

* MIT License
* ===========
*
* Copyright (c) 2022 OLegacy
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
*/

pragma solidity 0.8.13;

interface OTokenInterface {

    function mint(address _to, uint256 _value, string memory _sawtoothHash, string memory _orderId)
    external returns (bool);
    function bulkMint (address[] memory _addressArr, uint256[] memory _amountArr, string memory _sawtoothHash, string memory _orderId)
    external returns (bool);
    function burn(uint256 amount, string memory hash, string memory order) external returns(bool);
    function transfer(address to, uint256 amount) external returns (bool);

}
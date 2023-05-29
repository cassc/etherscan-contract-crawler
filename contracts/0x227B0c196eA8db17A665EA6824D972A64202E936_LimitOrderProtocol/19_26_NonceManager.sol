// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;
pragma abicoder v1;

/*
“Copyright (c) 2019-2021 1inch 
Permission is hereby granted, free of charge, to any person obtaining a copy of this software
and associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions: 
The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software. 
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO
THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE”.
*/

/// @title A helper contract for managing nonce of tx sender
contract NonceManager {
  event NonceIncreased(address indexed maker, uint256 oldNonce, uint256 newNonce);

  mapping(address => uint256) public nonce;

  /// @notice Advances nonce by one
  function increaseNonce() external {
    advanceNonce(1);
  }

  /// @notice Advances nonce by specified amount
  function advanceNonce(uint8 amount) public {
    uint256 newNonce = nonce[msg.sender] + amount;
    nonce[msg.sender] = newNonce;
    emit NonceIncreased(msg.sender, newNonce - amount, newNonce);
  }

  /// @notice Checks if `makerAddress` has specified `makerNonce`
  /// @return Result True if `makerAddress` has specified nonce. Otherwise, false
  function nonceEquals(address makerAddress, uint256 makerNonce) external view returns (bool) {
    return nonce[makerAddress] == makerNonce;
  }
}
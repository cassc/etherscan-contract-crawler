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

import '@openzeppelin/contracts/utils/Address.sol';

/// @title A helper contract for calculations related to order amounts
contract AmountCalculator {
  using Address for address;

  /// @notice Calculates maker amount
  /// @return Result Floored maker amount
  function getMakerAmount(
    uint256 orderMakerAmount,
    uint256 orderTakerAmount,
    uint256 swapTakerAmount
  ) public pure returns (uint256) {
    return (swapTakerAmount * orderMakerAmount) / orderTakerAmount;
  }

  /// @notice Calculates taker amount
  /// @return Result Ceiled taker amount
  function getTakerAmount(
    uint256 orderMakerAmount,
    uint256 orderTakerAmount,
    uint256 swapMakerAmount
  ) public pure returns (uint256) {
    return (swapMakerAmount * orderTakerAmount + orderMakerAmount - 1) / orderMakerAmount;
  }

  /// @notice Performs an arbitrary call to target with data
  /// @return Result Bytes transmuted to uint256
  function arbitraryStaticCall(address target, bytes memory data) external view returns (uint256) {
    bytes memory result = target.functionStaticCall(data, 'AC: arbitraryStaticCall');
    return abi.decode(result, (uint256));
  }
}
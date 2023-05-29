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

import '@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol';
import './RevertReasonParser.sol';
import '../interfaces/IDaiLikePermit.sol';

/// @title Base contract with common permit handling logics
abstract contract Permitable {
  function _permit(address token, bytes calldata permit) internal {
    if (permit.length > 0) {
      bool success;
      bytes memory result;
      if (permit.length == 32 * 7) {
        // solhint-disable-next-line avoid-low-level-calls
        (success, result) = token.call(abi.encodePacked(IERC20Permit.permit.selector, permit));
      } else if (permit.length == 32 * 8) {
        // solhint-disable-next-line avoid-low-level-calls
        (success, result) = token.call(abi.encodePacked(IDaiLikePermit.permit.selector, permit));
      } else {
        revert('Wrong permit length');
      }
      if (!success) {
        revert(RevertReasonParser.parse(result, 'Permit failed: '));
      }
    }
  }

  function _permitMemory(address token, bytes memory permit) internal {
    if (permit.length > 0) {
      bool success;
      bytes memory result;
      if (permit.length == 32 * 7) {
        // solhint-disable-next-line avoid-low-level-calls
        (success, result) = token.call(abi.encodePacked(IERC20Permit.permit.selector, permit));
      } else if (permit.length == 32 * 8) {
        // solhint-disable-next-line avoid-low-level-calls
        (success, result) = token.call(abi.encodePacked(IDaiLikePermit.permit.selector, permit));
      } else {
        revert('Wrong permit length');
      }
      if (!success) {
        revert(RevertReasonParser.parse(result, 'Permit failed: '));
      }
    }
  }
}
/**
* SPDX-License-Identifier: LicenseRef-Aktionariat
*
* MIT License with Automated License Fee Payments
*
* Copyright (c) 2020 Aktionariat AG (aktionariat.com)
*
* Permission is hereby granted to any person obtaining a copy of this software
* and associated documentation files (the "Software"), to deal in the Software
* without restriction, including without limitation the rights to use, copy,
* modify, merge, publish, distribute, sublicense, and/or sell copies of the
* Software, and to permit persons to whom the Software is furnished to do so,
* subject to the following conditions:
*
* - The above copyright notice and this permission notice shall be included in
*   all copies or substantial portions of the Software.
* - All automated license fee payments integrated into this and related Software
*   are preserved.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/
pragma solidity ^0.8.0;

import "../recovery/ERC20Recoverable.sol";
import "../ERC20/ERC20Allowlistable.sol";
import "./Shares.sol";

contract AllowlistShares is Shares, ERC20Allowlistable {

  constructor(
    string memory _symbol,
    string memory _name,
    string memory _terms,
    uint256 _totalShares,
    IRecoveryHub _recoveryHub,
    address _owner
  )
    Shares(_symbol, _name, _terms, _totalShares, _owner, _recoveryHub)
    ERC20Allowlistable()
  {
    // initialization in shares
  }

  function transfer(address recipient, uint256 amount) override(ERC20Flaggable, Shares) virtual public returns (bool) {
    return super.transfer(recipient, amount); 
  }

  function _mint(address account, uint256 amount) internal override(ERC20Flaggable, Shares) {
      super._mint(account, amount);
  }

  function _beforeTokenTransfer(address from, address to, uint256 amount) virtual override(ERC20Flaggable, ERC20Allowlistable) internal {
    super._beforeTokenTransfer(from, to, amount);
  }

}
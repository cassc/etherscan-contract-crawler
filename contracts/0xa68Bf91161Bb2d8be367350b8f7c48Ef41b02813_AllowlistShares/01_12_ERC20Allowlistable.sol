/**
* SPDX-License-Identifier: LicenseRef-Aktionariat
*
* MIT License with Automated License Fee Payments
*
* Copyright (c) 2021 Aktionariat AG (aktionariat.com)
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


import "./ERC20Flaggable.sol";
import "../utils/Ownable.sol";

/**
 * A very flexible and efficient form to subject ERC-20 tokens to an allowlisting.
 * See ../../doc/allowlist.md for more information.
 */
abstract contract ERC20Allowlistable is ERC20Flaggable, Ownable {

  uint8 private constant TYPE_DEFAULT = 0x0;
  uint8 private constant TYPE_ALLOWLISTED = 0x1;
  uint8 private constant TYPE_FORBIDDEN = 0x2;
  uint8 private constant TYPE_POWERLISTED = 0x4;
  // I think TYPE_POWERLISTED should have been 0x3. :) But MOP was deployed like this so we keep it. Does not hurt.

  uint8 private constant FLAG_INDEX_ALLOWLIST = 20;
  uint8 private constant FLAG_INDEX_FORBIDDEN = 21;
  uint8 private constant FLAG_INDEX_POWERLIST = 22;

  event AddressTypeUpdate(address indexed account, uint8 addressType);

  bool public restrictTransfers;

  constructor(){
    setApplicableInternal(true);
  }

  /**
   * Configures whether the allowlisting is applied.
   * Also sets the powerlist and allowlist flags on the null address accordingly.
   * It is recommended to also deactivate the powerlist flag on other addresses.
   */
  function setApplicable(bool transferRestrictionsApplicable) external onlyOwner {
    setApplicableInternal(transferRestrictionsApplicable);
  }

  function setApplicableInternal(bool transferRestrictionsApplicable) internal {
    restrictTransfers = transferRestrictionsApplicable;
    // if transfer restrictions are applied, we guess that should also be the case for newly minted tokens
    // if the admin disagrees, it is still possible to change the type of the null address
    if (transferRestrictionsApplicable){
      setTypeInternal(address(0x0), TYPE_POWERLISTED);
    } else {
      setTypeInternal(address(0x0), TYPE_DEFAULT);
    }
  }

  function setType(address account, uint8 typeNumber) public onlyOwner {
    setTypeInternal(account, typeNumber);
  }

  /**
   * If TYPE_DEFAULT all flags are set to 0
   */
  function setTypeInternal(address account, uint8 typeNumber) internal {
    setFlag(account, FLAG_INDEX_ALLOWLIST, typeNumber == TYPE_ALLOWLISTED);
    setFlag(account, FLAG_INDEX_FORBIDDEN, typeNumber == TYPE_FORBIDDEN);
    setFlag(account, FLAG_INDEX_POWERLIST, typeNumber == TYPE_POWERLISTED);
    emit AddressTypeUpdate(account, typeNumber);
  }

  function setType(address[] calldata addressesToAdd, uint8 value) public onlyOwner {
    for (uint i=0; i<addressesToAdd.length; i++){
      setType(addressesToAdd[i], value);
    }
  }

  /**
   * If true, this address is allowlisted and can only transfer tokens to other allowlisted addresses.
   */
  function canReceiveFromAnyone(address account) public view returns (bool) {
    return hasFlagInternal(account, FLAG_INDEX_ALLOWLIST) || hasFlagInternal(account, FLAG_INDEX_POWERLIST);
  }

  /**
   * If true, this address can only transfer tokens to allowlisted addresses and not receive from anyone.
   */
  function isForbidden(address account) public view returns (bool){
    return hasFlagInternal(account, FLAG_INDEX_FORBIDDEN);
  }

  /**
   * If true, this address can automatically allowlist target addresses if necessary.
   */
  function isPowerlisted(address account) public view returns (bool) {
    return hasFlagInternal(account, FLAG_INDEX_POWERLIST);
  }

  function _beforeTokenTransfer(address from, address to, uint256 amount) override virtual internal {
    super._beforeTokenTransfer(from, to, amount);
    // empty block for gas saving fall through
    // solhint-disable-next-line no-empty-blocks
    if (canReceiveFromAnyone(to)){
      // ok, transfers to allowlisted addresses are always allowed
    } else if (isForbidden(to)){
      // Target is forbidden, but maybe restrictions have been removed and we can clean the flag
      require(!restrictTransfers, "not allowed");
      setFlag(to, FLAG_INDEX_FORBIDDEN, false);
    } else {
      if (isPowerlisted(from)){
        // it is not allowlisted, but we can make it so
        // we know the recipient is neither forbidden, allowlisted or powerlisted, so we can set flag directly
        setFlag(to, FLAG_INDEX_ALLOWLIST, true);
        emit AddressTypeUpdate(to, TYPE_ALLOWLISTED);
      }
      // if we made it to here, the target must be a free address and we are not powerlisted
      else if (hasFlagInternal(from, FLAG_INDEX_ALLOWLIST)){
        // We cannot send to free addresses, but maybe the restrictions have been removed and we can clean the flag?
        require(!restrictTransfers, "not allowed");
        setFlag(from, FLAG_INDEX_ALLOWLIST, false);
      } else if (isForbidden(from)){
        require(!restrictTransfers, "not allowed");
        setFlag(from, FLAG_INDEX_FORBIDDEN, false);
      }
    }
  }

}
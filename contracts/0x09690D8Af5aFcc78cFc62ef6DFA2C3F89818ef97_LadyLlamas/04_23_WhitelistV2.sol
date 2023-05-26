/***
 *    ██╗    ██╗██╗  ██╗██╗████████╗███████╗
 *    ██║    ██║██║  ██║██║╚══██╔══╝██╔════╝
 *    ██║ █╗ ██║███████║██║   ██║   █████╗  
 *    ██║███╗██║██╔══██║██║   ██║   ██╔══╝  
 *    ╚███╔███╔╝██║  ██║██║   ██║   ███████╗
 *     ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝   ╚═╝   ╚══════╝
 *                                          
 *    ██╗     ██╗███████╗████████╗          
 *    ██║     ██║██╔════╝╚══██╔══╝          
 *    ██║     ██║███████╗   ██║             
 *    ██║     ██║╚════██║   ██║             
 *    ███████╗██║███████║   ██║             
 *    ╚══════╝╚═╝╚══════╝   ╚═╝             
 * @title Whitelist
 * @author @MaxFlowO2 (Twitter/GitHub)
 * @dev provides a use case of Library Whitelist use in v2.2
 *      Written on 22 Jan 2022, using LBL Tech!
 *
 * Can be used on all "Tokens" ERC-20, ERC-721, ERC-777, ERC-1155 or whatever
 * Solidity contract you can think of!
 */

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../lib/Whitelist.sol";

abstract contract WhitelistV2 {
  using Whitelist for Whitelist.List;
  
  Whitelist.List private whitelist;

  function _addWhitelist(address newAddress) internal {
    whitelist.add(newAddress);
  }

  function _addBatchWhitelist(address[] memory newAddresses) internal {
    uint length = newAddresses.length;
    for(uint x = 0; x < length;) {
      whitelist.add(newAddresses[x]);
      unchecked { ++x; }
    }
  }

  function _removeWhitelist(address newAddress) internal {
    whitelist.remove(newAddress);
  }

  function _removeBatchWhitelist(address[] memory newAddresses) internal {
    uint length = newAddresses.length;
    for(uint x = 0; x < length;) {
      whitelist.remove(newAddresses[x]);
      unchecked { ++x; }
    }
  }

  function _enableWhitelist() internal {
    whitelist.enable();
  }

  function _disableWhitelist() internal {
    whitelist.disable();
  }

  // @notice rename this to whatever you want timestamp/quant of tokens sold
  // @dev will set the ending uint of whitelist
  // @param endNumber - uint for the end (quant or timestamp)
  function _setEndOfWhitelist(uint endNumber) internal {
    whitelist.setEnd(endNumber);
  }

  // @dev will return user status on whitelist
  // @return - bool if whitelist is enabled or not
  // @param myAddress - any user account address, EOA or contract
  function _myWhitelistStatus(address myAddress) internal view returns (bool) {
    return whitelist.onList(myAddress);
  }

  // @dev will return user status on whitelist
  // @return - bool if whitelist is enabled or not
  // @param myAddress - any user account address, EOA or contract
  function myWhitelistStatus(address myAddress) external view returns (bool) {
    return whitelist.onList(myAddress);
  }

  // @dev will return status of whitelist
  // @return - bool if whitelist is enabled or not
  function whitelistStatus() external view returns (bool) {
    return whitelist.status();
  }

  // @dev will return whitelist end (quantity or time)
  // @return - uint of either number of whitelist mints or
  //  a timestamp
  function whitelistEnd() external view returns (uint) {
    return whitelist.showEnd();
  }

  // @dev will return totat on whitelist
  // @return - uint from CountersV2.Count
  function TotalOnWhitelist() external view returns (uint) {
    return whitelist.totalAdded();
  }

  // @dev will return totat used on whitelist
  // @return - uint from CountersV2.Count
  function TotalWhiteListUsed() external view returns (uint) {
    return whitelist.totalRemoved();
  }

  // @dev will return totat used on whitelist
  // @return - uint aka xxxx = xx.xx%
  function WhitelistEfficiency() external view returns (uint) {
    if(whitelist.totalRemoved() == 0) {
      return 0;
    } else {
      return whitelist.totalRemoved() * 10000 / whitelist.totalAdded();
    }
  }
}
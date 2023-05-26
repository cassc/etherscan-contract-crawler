/***
 *    ██╗    ██╗██╗  ██╗██╗████████╗███████╗██╗     ██╗███████╗████████╗
 *    ██║    ██║██║  ██║██║╚══██╔══╝██╔════╝██║     ██║██╔════╝╚══██╔══╝
 *    ██║ █╗ ██║███████║██║   ██║   █████╗  ██║     ██║███████╗   ██║   
 *    ██║███╗██║██╔══██║██║   ██║   ██╔══╝  ██║     ██║╚════██║   ██║   
 *    ╚███╔███╔╝██║  ██║██║   ██║   ███████╗███████╗██║███████║   ██║   
 *     ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝   ╚═╝   ╚══════╝╚══════╝╚═╝╚══════╝   ╚═╝   
 * Written by MaxFlowO2, Senior Developer and Partner of G&M² Labs
 * Follow me on https://github.com/MaxflowO2 or Twitter @MaxFlowO2
 * email: [email protected]
 */

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

abstract contract Whitelist {

  // ERC165 data
  // Public getter isWhitelist(address) => 0xc683630d
  // Whitelist is 0xc683630d

  // set contract mapping
  mapping(address => bool) public isWhitelist;

  // only event needed
  event ChangeToWhitelist(address _address, bool old, bool update);

  // adding functions to mapping
  function _addWhitelistBatch(address [] memory _addresses) internal {
    for (uint i = 0; i < _addresses.length; i++) {
      _addWhitelist(_addresses[i]);
    }
  }

  function _addWhitelist(address _address) internal {
    require(!isWhitelist[_address], "Already on Whitelist");
    bool old = isWhitelist[_address];
    isWhitelist[_address] = true;
    emit ChangeToWhitelist(_address, old, isWhitelist[_address]);
  }

  // removing functions to mapping
  function _removeWhitelistBatch(address [] memory _addresses) internal {
    for (uint i = 0; i < _addresses.length; i++) {
      _removeWhitelist(_addresses[i]);
    }
  }

  function _removeWhitelist(address _address) internal {
    require(isWhitelist[_address], "Already off Whitelist");
    bool old = isWhitelist[_address];
    isWhitelist[_address] = false;
    emit ChangeToWhitelist(_address, old, isWhitelist[_address]);
  }
}
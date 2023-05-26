/***
 *     ██████╗ ██████╗ ███╗   ██╗████████╗██████╗  █████╗  ██████╗████████╗    ██╗   ██╗██████╗ ██╗
 *    ██╔════╝██╔═══██╗████╗  ██║╚══██╔══╝██╔══██╗██╔══██╗██╔════╝╚══██╔══╝    ██║   ██║██╔══██╗██║
 *    ██║     ██║   ██║██╔██╗ ██║   ██║   ██████╔╝███████║██║        ██║       ██║   ██║██████╔╝██║
 *    ██║     ██║   ██║██║╚██╗██║   ██║   ██╔══██╗██╔══██║██║        ██║       ██║   ██║██╔══██╗██║
 *    ╚██████╗╚██████╔╝██║ ╚████║   ██║   ██║  ██║██║  ██║╚██████╗   ██║       ╚██████╔╝██║  ██║██║
 *     ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝   ╚═╝        ╚═════╝ ╚═╝  ╚═╝╚═╝
 * Written by MaxFlowO2, Senior Developer and Partner of G&M² Labs
 * Follow me on https://github.com/MaxflowO2 or Twitter @MaxFlowO2
 * email: [email protected]
 *
 * Purpose: OpenSea compliance on chain ID #1-5
 */

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../interface/IContractURI.sol";

abstract contract ContractURI is IContractURI {

  event ContractURIChange(string _new, string _old);

  string private thisContractURI;

  // @notice this sets the contractURI
  function _setContractURI(string memory newURI) internal {
    string memory old = thisContractURI;
    thisContractURI = newURI;
    emit ContractURIChange(thisContractURI, old);
  }

  // @notice will return string _ContractURI
  // contractURI() => 0xe8a3d485
  function contractURI() external view override(IContractURI) returns (string memory) {
    return thisContractURI;
  }

}
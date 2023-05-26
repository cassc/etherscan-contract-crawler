/***
 *    ██╗██╗     ██╗      █████╗ ███╗   ███╗ █████╗ ███████╗
 *    ██║██║     ██║     ██╔══██╗████╗ ████║██╔══██╗██╔════╝
 *    ██║██║     ██║     ███████║██╔████╔██║███████║███████╗
 *    ██║██║     ██║     ██╔══██║██║╚██╔╝██║██╔══██║╚════██║
 *    ██║███████╗███████╗██║  ██║██║ ╚═╝ ██║██║  ██║███████║
 *    ╚═╝╚══════╝╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝
 * Written by MaxFlowO2, Interim CEO and CTO of G&M² Labs
 * Follow me on https://github.com/MaxflowO2 or Twitter @MaxFlowO2
 * email: [email protected]
 *
 * Purpose: Insipired by BAYC on Ethereum, Sets Provential Hashes and More
 * Source: https://etherscan.io/address/0xbc4ca0eda7647a8ab7c2061c2e118a18a936f13d#code
 */

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface Illamas is IERC165{

  // @notice will return timestamp of reveal
  // RevealTimestamp() => 0x83ba7c1d
  function RevealTimestamp() external view returns (uint256);

  // @notice will return Provenance hash of images
  // RevealProvenanceImages() => 0xd792d2a0
  function RevealProvenanceImages() external view returns (string memory);

  // @notice will return Provenance hash of metadata
  // RevealProvenanceJSON() => 0x94352676
  function RevealProvenanceJSON() external view returns (string memory);

  // @notice will return starting number for mint
  // RevealStartNumber() => 0x1efb051a
  function RevealStartNumber() external view returns (uint256);
}
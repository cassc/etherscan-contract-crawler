/***
 *    ██╗     ██╗      █████╗ ███╗   ███╗ █████╗ ███████╗
 *    ██║     ██║     ██╔══██╗████╗ ████║██╔══██╗██╔════╝
 *    ██║     ██║     ███████║██╔████╔██║███████║███████╗
 *    ██║     ██║     ██╔══██║██║╚██╔╝██║██╔══██║╚════██║
 *    ███████╗███████╗██║  ██║██║ ╚═╝ ██║██║  ██║███████║
 *    ╚══════╝╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝
 * Written by MaxFlowO2, Interim CEO and CTO of G&M² Labs
 * Follow me on https://github.com/MaxflowO2 or Twitter @MaxFlowO2
 * email: [email protected]
 *
 * Purpose: Insipired by BAYC on Ethereum, Sets Provenace Hashes and More
 * Source: https://etherscan.io/address/0xbc4ca0eda7647a8ab7c2061c2e118a18a936f13d#code
 *
 * Updated: Does the Provenace Hashes for Iamges and JSONS.
 */

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../interface/ILlamas.sol";

abstract contract Llamas is Illamas {

  event SetProvenanceImages(string _new, string _old);
  event SetProvenanceJSON(string _new, string _old);
  event SetTimestamp(uint _new, uint _old);
  event SetStartNumber(uint _new, uint _old);

  uint256 private timestamp;
  uint256 private startNumber;
  string private ProvenanceImages;
  string private ProvenanceJSON;

  // @notice will set reveal timestamp
  function _setRevealTimestamp(uint256 _timestamp) internal {
    uint256 old = timestamp;
    timestamp = _timestamp;
    emit SetTimestamp(timestamp, old);
  }

  // @notice will set start number
  function _setStartNumber(uint256 _startNumber) internal {
    uint256 old = startNumber;
    startNumber = _startNumber;
    emit SetStartNumber(startNumber, old);
  }

  // @notice will set JSON Provenance
  function _setProvenanceJSON(string memory _ProvenanceJSON) internal {
    string memory old = ProvenanceJSON;
    ProvenanceJSON = _ProvenanceJSON;
    emit SetProvenanceJSON(ProvenanceJSON, old);
  }

  // @notice will set Images Provenance
  function _setProvenanceImages(string memory _ProvenanceImages) internal {
    string memory old = ProvenanceImages;
    ProvenanceImages = _ProvenanceImages;
    emit SetProvenanceImages(ProvenanceImages, old);
  }

  // @notice will return timestamp of reveal
  function RevealTimestamp() external view override(Illamas) returns (uint256) {
    return timestamp;
  }

  // @notice will return Provenance hash of images
  function RevealProvenanceImages() external view override(Illamas) returns (string memory) {
    return ProvenanceImages;
  }

  // @notice will return Provenance hash of metadata
  function RevealProvenanceJSON() external view override(Illamas) returns (string memory) {
    return ProvenanceJSON;
  }

  // @notice will return starting number for mint
  function RevealStartNumber() external view override(Illamas) returns (uint256) {
    return startNumber;
  }
}
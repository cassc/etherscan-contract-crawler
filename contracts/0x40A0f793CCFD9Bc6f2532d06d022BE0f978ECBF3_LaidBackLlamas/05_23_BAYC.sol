/***
 *    ██████╗  █████╗ ██╗   ██╗ ██████╗
 *    ██╔══██╗██╔══██╗╚██╗ ██╔╝██╔════╝
 *    ██████╔╝███████║ ╚████╔╝ ██║     
 *    ██╔══██╗██╔══██║  ╚██╔╝  ██║     
 *    ██████╔╝██║  ██║   ██║   ╚██████╗
 *    ╚═════╝ ╚═╝  ╚═╝   ╚═╝    ╚═════╝
 * Written by MaxFlowO2, Senior Developer and Partner of G&M² Labs
 * Follow me on https://github.com/MaxflowO2 or Twitter @MaxFlowO2
 * email: [email protected]
 *
 * Purpose: Insipired by BAYC on Ethereum, Sets Provential Hashes and More
 * Source: https://etherscan.io/address/0xbc4ca0eda7647a8ab7c2061c2e118a18a936f13d#code
 */

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../interface/IBAYC.sol";

abstract contract BAYC is IBAYC {

  // ERC165
  // RevealTimestamp() => 0x83ba7c1d
  // RevealProvenanceImages() => 0xd792d2a0
  // RevealProvenanceJSON() => 0x94352676
  // RevealStartNumber() => 0x1efb051a
  // BAYC => 0xdee68dd1

  event SetProvenanceImages(string _old, string _new);
  event SetProvenanceJSON(string _old, string _new);
  event SetTimestamp(uint _old, uint _new);
  event SetStartNumber(uint _old, uint _new);

  uint256 private timestamp;
  uint256 private startNumber;
  string private ProvenanceImages;
  string private ProvenanceJSON;

  // @notice will set reveal timestamp
  // _setRevealTimestamp(uint256) => 0x20add1a4
  function _setRevealTimestamp(uint256 _timestamp) internal {
    uint256 old = timestamp;
    timestamp = _timestamp;
    emit SetTimestamp(old, timestamp);
  }

  // @notice will set start number
  // _setStartNumber(uint256) => 0x4266377e
  function _setStartNumber(uint256 _startNumber) internal {
    uint256 old = startNumber;
    startNumber = _startNumber;
    emit SetStartNumber(old, startNumber);
  }

  // @notice will set JSON Provenance
  // _setProvenanceJSON(string) => 0xf3808eb1
  function _setProvenanceJSON(string memory _ProvenanceJSON) internal {
    string memory old = ProvenanceJSON;
    ProvenanceJSON = _ProvenanceJSON;
    emit SetProvenanceJSON(old, ProvenanceJSON);
  }

  // @notice will set Images Provenance
  // _setProvenanceImages(string) => 0x1ef799c6
  function _setProvenanceImages(string memory _ProvenanceImages) internal {
    string memory old = ProvenanceImages;
    ProvenanceImages = _ProvenanceImages;
    emit SetProvenanceImages(old, ProvenanceImages);
  }

  // @notice will return timestamp of reveal
  // RevealTimestamp() => 0x83ba7c1d
  function RevealTimestamp() external view override(IBAYC) returns (uint256) {
    return timestamp;
  }

  // @notice will return Provenance hash of images
  // RevealProvenanceImages() => 0xd792d2a0
  function RevealProvenanceImages() external view override(IBAYC) returns (string memory) {
    return ProvenanceImages;
  }

  // @notice will return Provenance hash of metadata
  // RevealProvenanceJSON() => 0x94352676
  function RevealProvenanceJSON() external view override(IBAYC) returns (string memory) {
    return ProvenanceJSON;
  }

  // @notice will return starting number for mint
  // RevealStartNumber() => 0x1efb051a
  function RevealStartNumber() external view override(IBAYC) returns (uint256) {
    return startNumber;
  }
}
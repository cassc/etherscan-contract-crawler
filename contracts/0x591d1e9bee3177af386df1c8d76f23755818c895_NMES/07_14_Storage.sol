// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Storage {
  string internal baseURIcid; // CID of the base URI
  string internal revealHash; // hash to hide metadata for reveal
  uint16 internal maxPreMintTx; // max number of pre-minted tokens per tx
  uint16 internal maxMintTx; // max number of minted tokens per tx
  uint16 public mintingSupply; // minted supply
  uint16 public reservedTokenSupply; // reserved token supply
  uint16 public mintedFromReserve; // reserved token supply
  uint16 public mintedFromSupply; // reserved token supply
  uint256 public price; // In ETH
  bool public saleIsActive; // is the sale active?
  // MAPPINGS
  mapping(uint256 => address) public mintedBy; // mapping of token id to address of the owner
  mapping(address => bool) public whitelisted;
  mapping(address => bool) public blacklisted;
  mapping(address => bool) public claimedToken; // pre-minted tokens per address
}
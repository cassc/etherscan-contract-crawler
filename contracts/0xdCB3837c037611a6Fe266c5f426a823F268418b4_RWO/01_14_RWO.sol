// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/// @title RWO: NFT
/// @author @ryeshrimp

contract RWO is ERC721A, Ownable {
  using Strings for uint256;

  address private constant DEV_PAYOUT_ADDRESS = 0xe6d98ACf7304D863934BB7119BDdb0fDBdDC4cdA;
  address private constant RWO_PAYOUT_ADDRESS = 0x07CA2E92D234b82afB137dDdF12E8d1394D9bcfe;

  uint public constant COLLECTION_SIZE = 10000;
  uint public PUBLIC_MINT_PRICE = 0.04 ether;
  uint public WHITE_LIST_MINT_PRICE = 0.03 ether;
  
  /// @notice 0,1,2
  uint public activePhase;

  string public beginningUri = "";
  string public endingUri = "";

  bytes32 public merkleRootWhitelist;

  mapping(address => bool) public whitelistMinted;

  constructor(bytes32 _merkleRootWhitelist, string memory _beginningUri, string memory _endingUri) ERC721A("Reptilian World Order", "RWO") {
    merkleRootWhitelist = _merkleRootWhitelist;
    beginningUri = _beginningUri;
    endingUri = _endingUri;
  }

  function whitelistMint(uint256 quantity, bytes32[] calldata proof) external payable { 
    require(activePhase > 0, "whitelist not active");
    require(whitelistMinted[msg.sender] == false, "already minted");
    require(totalSupply() + quantity <= COLLECTION_SIZE, "total supply reached");
    require(quantity < 6, "Max quantity per tx exceeded");
    require(msg.value == quantity * WHITE_LIST_MINT_PRICE, "Ether value sent is not sufficient");

    // Verify merkle proof, or revert if not in tree
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender, uint256(1)));
    bool isValidLeaf = MerkleProof.verify(proof, merkleRootWhitelist, leaf);
    if (!isValidLeaf) revert("WL not found");

    whitelistMinted[msg.sender] = true;

    _safeMint(msg.sender, quantity);
  }

  function mint(uint256 quantity) external payable {
    require(activePhase == 2, "public mint not active");
    require(tx.origin == msg.sender, "sender does not match");
    require(totalSupply() + quantity <= COLLECTION_SIZE, "total supply reached");
    require(quantity < 11, "Max quantity per tx exceeded");
    require(msg.value == quantity * PUBLIC_MINT_PRICE, "Ether value sent is not sufficient");
    _safeMint(msg.sender, quantity);
  }

  function ownerMint(uint256 quantity) external onlyOwner {
    require(totalSupply() + quantity <= COLLECTION_SIZE, "total supply reached");
    _safeMint(msg.sender, quantity);
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    return string(abi.encodePacked(beginningUri, tokenId.toString(), endingUri));
  }

  function setPhase(uint256 _phase) public onlyOwner {
    require(_phase < 3, "wrong phase number");
    activePhase = _phase;
  }

  function setMintPrice(uint256 _mode, uint256 _price) public onlyOwner {
    require(_mode < 3, "wrong mode number");
    if(_mode == 1) WHITE_LIST_MINT_PRICE = _price;
    if(_mode == 2) PUBLIC_MINT_PRICE = _price;
  }

  function setURI(uint256 _mode, string memory _new_uri) public onlyOwner {
    if (_mode == 1) beginningUri = _new_uri;
    else if (_mode == 2) endingUri = _new_uri;
    else revert("wrong mode");
  }

  /// @notice Sets the merkel root for token claim
  function setRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRootWhitelist = _merkleRoot;
  }

  /// @notice Withdraw's contract's balance to the owners address and 10% to the dev
  function withdraw() external {
    uint256 balance = address(this).balance;
    require(balance > 0, "No balance");

    uint256 devBalance = (balance / 100) * 10;
    balance -= devBalance;
    payable(DEV_PAYOUT_ADDRESS).transfer(devBalance);
    payable(RWO_PAYOUT_ADDRESS).transfer(balance);
  }
}
// SPDX-License-Identifier: MIT

// ______  __  __   ______       _____    __  __   _____    ______
// /\__  _\/\ \_\ \ /\  ___\     /\  __-. /\ \/\ \ /\  __-. /\  ___\
// \/_/\ \/\ \  __ \\ \  __\     \ \ \/\ \\ \ \_\ \\ \ \/\ \\ \  __\
//   \ \_\ \ \_\ \_\\ \_____\    \ \____- \ \_____\\ \____- \ \_____\
//    \/_/  \/_/\/_/ \/_____/     \/____/  \/_____/ \/____/  \/_____/
//

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract TheDuds is ERC721Enumerable, Ownable {
  using Strings for *;

  bool public isAirdropActive = false;
  uint256 public immutable MAX_SUPPLY = 512;
  uint public revealDate = 1658966400; // 7/28/2022
  string public baseURI;
  mapping(uint256 => uint256) public ogStatuses;

  bytes32 public immutable merkleRoot;
  uint256 public immutable startingIndex;
  uint256 private claimedIndex;
  mapping(uint256 => uint256) private claimedBitMap;

  constructor (bytes32 _merkleRoot) ERC721("the duds", "DUD") {
    merkleRoot = _merkleRoot;
    startingIndex = uint256(keccak256(abi.encodePacked(_merkleRoot, block.number)));
  }

  function setIsAirdropActive(bool _isAirdropActive) public onlyOwner {
    isAirdropActive = _isAirdropActive;
  }

  function isClaimed(uint256 index) public view returns (bool) {
    uint256 claimedWordIndex = index / 256;
    uint256 claimedBitIndex = index % 256;
    uint256 claimedWord = claimedBitMap[claimedWordIndex];
    uint256 mask = (1 << claimedBitIndex);
    return claimedWord & mask == mask;
  }

  function claim(uint256 index, uint256 ogStatus, address account, bytes32[] calldata merkleProof) external {
    require(isAirdropActive, "Airdrop is not active yet.");
    require(!isClaimed(index), "MerkleDistributor: Drop already claimed.");

    // Verify the merkle proof.
    bytes32 node = keccak256(abi.encodePacked(index, account, ogStatus));
    require(MerkleProof.verify(merkleProof, merkleRoot, node), "MerkleDistributor: Invalid proof.");

    // Mark it claimed and send the token.
    uint tokenId = claimedIndex + startingIndex % MAX_SUPPLY;
    ogStatuses[tokenId] = ogStatus;

    _setClaimed(index);
    _safeMint(account, tokenId);
    claimedIndex++;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
    string memory dudId = _tokenId.toString();
    string memory revealSuffix = "";
    string memory ogStatusSuffix = "";
    if (_shouldReveal()) {
      revealSuffix = "r";
    }
    if (ogStatuses[_tokenId] == 1) {
      ogStatusSuffix = "og";
    }
    return string(abi.encodePacked(_baseURI(), "/", dudId, revealSuffix, ogStatusSuffix));
  }

  function tokensOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 tokenCount = balanceOf(_owner);
    if (tokenCount == 0) {
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 index;
      for (index = 0; index < tokenCount; index++) {
        result[index] = tokenOfOwnerByIndex(_owner, index);
      }
      return result;
    }
  }

  function setRevealDate(uint _revealDate) public onlyOwner {
    revealDate = _revealDate;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function _setClaimed(uint256 index) private {
    uint256 claimedWordIndex = index / 256;
    uint256 claimedBitIndex = index % 256;
    claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
  }

  function _shouldReveal() internal view returns (bool) {
    if (block.timestamp < revealDate) {
      return false;
    }
    return true;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
}
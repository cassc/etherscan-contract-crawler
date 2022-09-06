//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./KaratDistributor.sol";

// import "hardhat/console.sol";

contract NFTAirdropDistributor is KaratDistributor, ERC721Enumerable {
  using Counters for Counters.Counter;
  uint256 public maxSupply;
  Counters.Counter public _tokenIdTracker;

  constructor(
    string memory name,
    address _owner,
    bytes32 _merkleRoot,
    uint256 _reach,
    uint256 _maxSupply,
    string memory _baseInfoURI,
    string memory _frozenInfoURI
  )
    ERC721(name, "KARAT")
    KaratDistributor(_owner, _merkleRoot, _reach, _baseInfoURI, _frozenInfoURI)
  {
    require(_maxSupply != 0, "MaxSupply cannot be zero");
    maxSupply = _maxSupply;
  }

  function claim(
    address account,
    uint256 amount,
    bytes32[] memory merkleProof
  ) external override {
    _verify(account, amount, merkleProof);
    _safeBatchMint(account, amount);
    emit Claimed(account, amount);
  }

  function _safeBatchMint(address to, uint256 amount) internal {
    uint256 tokenId = _tokenIdTracker.current();
    require(tokenId + amount <= maxSupply, "Exceed max supply");
    for (uint256 i = 0; i < amount; i++) {
      _safeMint(to, _tokenIdTracker.current());
      _tokenIdTracker.increment();
    }
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    require(_exists(tokenId), "Token not existed");
    return baseInfoURI;
  }
}
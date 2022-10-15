// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract Gloopverse is ERC721AQueryable, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri = 'ipfs://____/prereveal.json';
  
  uint256 public cost = 35000000000000000; // 0.035 ETH
  uint256 public maxSupply = 3888; // 3888 Gloopverse NFTs
  uint256 public maxMintAmountPerTx = 2; // 2 Gloopverse NFTs per transaction

  bool public paused = true;
  bool public whitelistMintEnabled = false;
  bool public revealed = false;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol
  ) ERC721A(_tokenName, _tokenSymbol){}

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Gloopverse: Mint amount exceeds maxMintAmountPerTx');
    require(totalSupply() + _mintAmount <= maxSupply, 'Gloopverse: Exceeds max supply!');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, 'Gloopverse: Insufficient ETH sent!');
    _;
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    // Verify whitelist requirements
    require(whitelistMintEnabled, 'Gloopverse: Whitelist minting is not enabled!');
    require(!whitelistClaimed[_msgSender()], 'Gloopverse: Whitelist address already claimed!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Gloopverse: Invalid merkle proof!');

    whitelistClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), _mintAmount);
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, 'Gloopverse: Minting is paused!');

    _safeMint(_msgSender(), _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

  function withdraw() public onlyOwner nonReentrant {
    (bool success, ) = payable(0xCd4dF80750aEE3778B61956E03d6a9068Af03E04).call{value: address(this).balance}('');
    require(success, 'Gloopverse: Withdraw failed!');
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}
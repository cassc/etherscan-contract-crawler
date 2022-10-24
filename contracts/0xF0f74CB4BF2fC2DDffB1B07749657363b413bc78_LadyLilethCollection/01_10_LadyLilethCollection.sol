// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "ERC721AQueryable.sol";
import "IERC721A.sol";
import "Ownable.sol";
import "MerkleProof.sol";
import "ReentrancyGuard.sol";
import "Strings.sol";

contract LadyLilethCollection is ERC721AQueryable, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;

  string public uriPrefix;
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  uint256 public cost;
  uint256 public maxSupply = 7777;
  uint256 public maxMintAmountPerTx = 10;

  bool public paused = true;
  bool public whitelistMintEnabled = false;
  bool public revealed = false;

  address payments;

  constructor(
    uint256 _cost
  ) ERC721A("Lady Lileth", "LL") {
    setCost(_cost);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _;
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    require(!whitelistClaimed[_msgSender()], 'Address already claimed!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    whitelistClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), _mintAmount);
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');

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

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
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

  function closeSale() public onlyOwner {
    maxSupply = totalSupply();
  }

  function withdraw() public onlyOwner nonReentrant {
    // Grace
    // =============================================================================
    (bool hs, ) = payable(0xcC42b04A5010F7C0f8EcB44fD60A640b81f0C49e).call{value: address(this).balance * 47 / 100}('');
    require(hs);
    // =============================================================================
    // TEJ
    // =============================================================================
    (bool ts, ) = payable(0x4745613C3aB602F0EA224540740cA1Ae97a02aea).call{value: address(this).balance * 41 / 100}('');
    require(ts);
    // =============================================================================
    // Lewk
    // =============================================================================
    (bool bs, ) = payable(0x3A5eb6Cd3d9ef1b3dD32487E295Dc76c9E1d3D38).call{value: address(this).balance * 4 / 100}('');
    require(bs);
    // =============================================================================
    // This is the Project wallet address which gets 8%
    // =============================================================================
    (bool cs, ) = payable(0xfe91b38B26a7e2Da147418E2F4C95EeF8eDaE51B).call{value: address(this).balance * 8 / 100}('');
    require(cs);
    // =============================================================================
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
  
  function destroy(address apocalypse) public onlyOwner {
    selfdestruct(payable(apocalypse));
  }

}
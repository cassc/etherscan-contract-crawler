// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract ItsFreeMint is ERC721AQueryable, Ownable, ReentrancyGuard {
  using Strings for uint256;

  string public tokenName = "It's Free Mint";
  string public tokenSymbol = "ITSFREEMINT";
  uint256 public maxSupply = 5555;
  uint256 public maxReservedSupply = 0;

  uint256 public maxMintAddress = 3;
  bytes32 public merkleRoot;
  mapping(address => bool) public mintClaimed; 

  bool public paused = false;
  bool public whitelistMintEnabled = true;
  bool public revealed = false;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri = "";

  uint256 public cost = 0.005 ether;

  constructor(string memory _hiddenMetadataUri) ERC721A(tokenName, tokenSymbol) {
    setHiddenMetadataUri(_hiddenMetadataUri);
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= updateMintCost(_mintAmount), 'Insufficient funds!');
    _;
  }

  function mint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintPriceCompliance(_mintAmount) {
		if (whitelistMintEnabled == true){
			bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
      require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');
    }
		
		require(!paused, 'The contract is paused!');
		require(_mintAmount > 0 && _mintAmount <= maxMintAddress, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= (maxSupply - maxReservedSupply), 'Max supply exceeded!');
		require(!mintClaimed[_msgSender()], 'Address already claimed!');

    mintClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), _mintAmount);
  }

  function mintOwner(uint256 _mintAmount, address _receiver) public onlyOwner {
		require((totalSupply() + _mintAmount) <= maxSupply, 'Max supply exceeded!');

    _safeMint(_receiver, _mintAmount);
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

	function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxReservedSupply(uint256 _newMaxReservedSupply) public onlyOwner {
    require(_newMaxReservedSupply <= (maxSupply - totalSupply()));
    maxReservedSupply = _newMaxReservedSupply;
  }

  function setmaxMintAddress(uint256 _maxMintAddress) public onlyOwner {
    maxMintAddress = _maxMintAddress;
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

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

	// A function of hope -> 
  function withdraw() public onlyOwner nonReentrant {
   (bool os, ) = payable(owner()).call{value: address(this).balance}('');
   require(os);
  }

  // Internal ->
  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function updateMintCost(uint256 _amount) internal view returns (uint256 _cost) {
    if (_amount == 1){
      return 0 ether;
    } else {
      return cost * (_amount -1);
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}
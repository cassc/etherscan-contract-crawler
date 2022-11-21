// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import 'operator-filter-registry/src/DefaultOperatorFilterer.sol';

contract Morthir is ERC721A, Ownable, DefaultOperatorFilterer {

  using Strings for uint256;

  //Set variables needed

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  uint256 public cost = 0.08 ether;
  uint256 public maxSupply = 3000;
  uint256 public maxMintAmountPerTx;

  bool public paused = true;
  bool public whitelistMintEnabled = false;
  bool public revealed = false;
  bool public lockedSupply = false;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _maxMintAmountPerTx,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    maxMintAmountPerTx = _maxMintAmountPerTx;
    setHiddenMetadataUri(_hiddenMetadataUri);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(msg.sender == tx.origin, "Caller is a contract.");              //Disable calls from secondary contract
    require(msg.value >= cost * _mintAmount, 'Insufficient funds');         //Check submitted cost is correct
    require(_mintAmount <= maxMintAmountPerTx, 'Invalid mint amount');      //Check mint quantity is correct
    require(totalSupply() + _mintAmount <= maxSupply, 'Supply exceeded!');  //Check if there is enough tokens left
    _;
  }

  //Handles WL'd phases
  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) external payable mintCompliance(_mintAmount) {
    require(whitelistMintEnabled, 'Sale not enabled');

    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    require(_getAux(msg.sender) == 0, "Address has claimed.");
    _setAux(msg.sender, 1);
    _mint(msg.sender, _mintAmount);
  }

  //Mint without WL
  function mint(uint256 _mintAmount) external payable mintCompliance(_mintAmount) {
    require(!paused, 'Contract is paused!');
    _mint(msg.sender, _mintAmount);
  }
  
  //Owner mint to community wallet 
  function ownerMint(uint256 _mintAmount, address _receiver) external onlyOwner {
    require(totalSupply() + _mintAmount <= maxSupply, 'Supply exceeded!');
    _mint(_receiver, _mintAmount);
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

 //Lock supply
  function lockSupply() external onlyOwner {
    lockedSupply = true;
  }

  //Toggle metadata
  function setRevealed() external onlyOwner {
    revealed = !revealed;
  }

  //Change price of mint
  function setCost(uint256 _cost) external onlyOwner {
    cost = _cost;
  }

  //Change max quantity per mint
  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) external onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  //Change supply of mint
  function setMaxSupply(uint256 _maxSupply) external onlyOwner {
    require(!lockedSupply == true);
    maxSupply = _maxSupply;
  }

  //Set placeholder
  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  //Set URI prefix
  function setUriPrefix(string memory _uriPrefix) external onlyOwner {
    uriPrefix = _uriPrefix;
  }

  //Set URI suffix
  function setUriSuffix(string memory _uriSuffix) external onlyOwner {
    uriSuffix = _uriSuffix;
  }

  //Toggle paused state
  function setPaused() external onlyOwner {
    paused = !paused;
  }

  //Set merkle root
  function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    merkleRoot = _merkleRoot;
  }

  //Toggle whitelist state
  function setWhitelistMintEnabled() external onlyOwner {
    whitelistMintEnabled = !whitelistMintEnabled;
  }

function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

  //Withdraw funds to owner
  function withdraw() external onlyOwner {
    (bool success,) = payable(msg.sender).call{value: address(this).balance}('');
    require(success, "Withdraw failed.");
  }

  function _baseURI() internal view override returns (string memory) {
    return uriPrefix;
  }
}
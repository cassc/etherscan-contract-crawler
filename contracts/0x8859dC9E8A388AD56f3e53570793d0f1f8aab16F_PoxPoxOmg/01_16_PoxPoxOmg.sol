// SPDX-License-Identifier: MIT

pragma solidity >=0.8.15 <0.9.0;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract PoxPoxOmg is ERC721AQueryable, Ownable, ReentrancyGuard {

  using Strings for uint256;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;

  uint256 public constant maxSupply  = 3721;
  uint256 public constant startTokenId = 1;  
  uint256 public constant price = 0.0 ether;
  uint256 private constant maxMintPreWhitelistSale = 2;
  uint256 private constant maxMintPrePublicSale = 3;

  uint256 public maxMintAmountPerTx;

  bool public paused = true;
  bool public revealed = false;
  bool public freeMintComplianceEnabled = false;
  bool public whitelistMintEnabled = false;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;  
  mapping(address => bool) public freeMintClaimed;
  

  constructor(
    string memory _hiddenMetadataUri
  ) ERC721A("POXPOX OMG", "POX") {
    setHiddenMetadataUri(_hiddenMetadataUri);
    maxMintAmountPerTx = maxMintPreWhitelistSale;
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max token supply exceeded!');
    _;
  }

  modifier freeMintCompliance(address _address, uint256 _mintAmount) {
    if(freeMintComplianceEnabled){
      require(!freeMintClaimed[_address], 'Address already Minted!');
    }
    require(_mintAmount <= maxMintPrePublicSale, string.concat('Token amount exceeded! Only allowed to ', Strings.toString(maxMintPrePublicSale), ' Tokens per tx at this state.'));
    require(totalSupply() + _mintAmount <= maxSupply, 'Max token supply exceeded!');    
    _;
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable freeMintCompliance(_msgSender(), _mintAmount) mintCompliance(_mintAmount) {

    require(whitelistMintEnabled, 'The whitelist sale is not started yet =)');
    require(!whitelistClaimed[_msgSender()], 'Address already claimedon whitelist!');
    require(_mintAmount <= maxMintPrePublicSale, string.concat('Token amount exceeded! Only allowed to ', Strings.toString(maxMintPreWhitelistSale), ' Tokens per tx at Whilelist Sales.'));
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    whitelistClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), _mintAmount);
  }  

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) freeMintCompliance( _msgSender(), _mintAmount){
    require(!paused, 'The contract is paused!');
    _safeMint(_msgSender(), _mintAmount);
    freeMintClaimed[_msgSender()] = true;
    
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) freeMintCompliance(_receiver, _mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount);
    freeMintClaimed[_receiver] = true;
  }

  function transferFrom(
      address _from,
      address _to,
      uint256 _tokenId
  ) public virtual override(ERC721A, IERC721) freeMintCompliance(_to, 1) {
      super.transferFrom(_from, _to, _tokenId);
  }


  function safeTransferFrom(
      address _from,
      address _to,
      uint256 _tokenId
  ) public virtual override(ERC721A, IERC721) freeMintCompliance(_to, 1) {
      super.safeTransferFrom(_from, _to, _tokenId, '');
  }

  function safeTransferFrom(
      address _from,
      address _to,
      uint256 _tokenId,
      bytes memory _data
  ) public virtual override(ERC721A, IERC721) freeMintCompliance(_to, 1) {
      super.safeTransferFrom(_from, _to, _tokenId, _data);
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }  

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
    if(whitelistMintEnabled){
      maxMintAmountPerTx = maxMintPreWhitelistSale;
    }
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return startTokenId;
  }

  function tokenURI(uint256 _tokenId) public view virtual override(ERC721A, IERC721Metadata) returns (string memory) {
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
    if(!paused){
      maxMintAmountPerTx = maxMintPrePublicSale;
    }
  }

  function setFreeMintComplianceEnabled(bool _state) public onlyOwner {
    freeMintComplianceEnabled = _state;
  }

  function withdraw() public onlyOwner nonReentrant {

    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);

  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }


}
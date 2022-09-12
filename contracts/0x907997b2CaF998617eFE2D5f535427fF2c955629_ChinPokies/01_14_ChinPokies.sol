// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract ChinPokies is ERC721A, Ownable, ReentrancyGuard  {
using Strings for uint256;

  bytes32 public merkleRoot;
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx = 4;
  uint256 public special = 2;
  uint256 public specialSend = 1;

  bool public paused = true;
  bool public allowlistMintEnabled = true;

  string public uriPrefix = '';


  mapping(address => bool) proxyToApproved;
  mapping(address => bool) allowlistUsed;
  
  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    string memory _uriPrefix,
    address _proxyRegistryAddress
  ) ERC721A(_tokenName, _tokenSymbol) {
    setCost(_cost);
    maxSupply = _maxSupply;
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
    setUriPrefix(_uriPrefix);
    proxyToApproved[_proxyRegistryAddress] = true;
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function allowlistMint(uint64 _mintAmount, bytes32[] calldata _merkleProof) external payable {
    require(allowlistMintEnabled, "Allowlist Mint not active");
    require(!paused, "Allowlist Presale has not begun");
    require(msg.value >= cost * _mintAmount, "Insufficient funds");
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Allowlist verification failed");
    require(_mintAmount > 0 && _mintAmount < maxMintAmountPerTx, "Invalid mint amount");
    require(!allowlistUsed[msg.sender], "Already used Allowlist Mint");
    _safeMint(msg.sender, _mintAmount);
    allowlistUsed[msg.sender] = true;
  }

  function mint(uint64 _mintAmount) external payable {
    require(!paused, "Public mint has not begun");
    require(msg.value >= cost * _mintAmount, "Insufficient funds!");
    require(_totalMinted() + _mintAmount < maxSupply, "Max supply exceeded");
    require(_mintAmount > 0 && _mintAmount < maxMintAmountPerTx, "Invalid mint amount");
    _safeMint(msg.sender, _mintAmount);
  }
  
  function pokiePic(address _receiver) external payable {
    require(!paused, "Public mint has not begun");
    require(msg.value >= cost * special, "Insufficient funds");
    require(msg.sender != _receiver, "Sending a Pokie Pic to yourself is no fun");
    require(_totalMinted() + special + specialSend < maxSupply, "Max supply exceeded");
    _safeMint(msg.sender, special);
    _safeMint(_receiver, specialSend);

  }

  function mintForAddress(uint256 _mintAmount, address _receiver) external onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }

  function flipallowlistMintEnabled() public onlyOwner(){
    allowlistMintEnabled = !allowlistMintEnabled;
  }

  function flipPaused() public onlyOwner(){
    paused = !paused;
  }
  function getOwnershipAt(uint256 tokenId) public view returns (TokenOwnership memory) {
    return _ownerships[tokenId];
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function totalMinted() public view returns (uint256) {
    return _totalMinted();
  }


  function checkAllowlistUsed(address wallet) public view returns (bool) {
    return allowlistUsed[wallet];
  }

  function exists(uint256 tokenId) public view returns (bool) {
      return _exists(tokenId);
  }

  function safeMint(address to, uint256 quantity) public {
      _safeMint(to, quantity);
  }

function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    return bytes(uriPrefix).length > 0
        ? string(abi.encodePacked(uriPrefix, _tokenId.toString(), '.json'))
        : "";
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function withdraw() public onlyOwner nonReentrant {
    (bool cw, ) = payable(0x86E6332487f0545FBb32C3eA5A55C0ad2E646A86).call{value: address(this).balance * 60/ 100}("");
    (bool cp, ) = payable(0x63d0F4cB9293535cf94501eCf8E564672429aff3).call{value: address(this).balance * 40/ 100}("");
    require(cw);
    require(cp);
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function getMerkleRoot()  public view returns (bytes32) {
    return merkleRoot;
  }
  
  function getProxyToApproved(address operator) public view returns (bool){
    return proxyToApproved[operator];
  }
  
  function isApprovedForAll(address _owner, address operator) public view override
returns (bool) {
    if(proxyToApproved[operator])
    return true;
    return super.isApprovedForAll(_owner, operator);
  }

  function flipProxyState(address proxyAddress) public onlyOwner{
    proxyToApproved[proxyAddress] = !proxyToApproved[proxyAddress];
  }
}
// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract System is ERC721AQueryable, DefaultOperatorFilterer, Ownable, ReentrancyGuard {
  using Strings for uint256;

  enum SaleStates {
    CLOSED,
    WHITELIST,
    PUBLIC
  }

  SaleStates public saleState;

  bytes32 public merkleRoot;

  mapping (uint256 => mapping (address => uint256)) public numberMinted;

  string public baseURL;
  string public unRevealedURL;
  
  uint256 public cost = 0.06 ether;
  uint256 public maxSupply = 3333;
  uint256 public maxPublicTokensPerWallet = 10;
  uint256 public maxWLTokensPerWallet = 3;
  
  bool public revealed = false;

  constructor() ERC721A("System", "DS") {
    setUnRevealedURL("ipfs://CID/hidden.json");
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded!");
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, "Insufficient funds!");
    _;
  }

  modifier checkSaleState(SaleStates _saleState) {
    require(saleState == _saleState, "sale is not active");
    _;
  }

  function whitelistMint(address _to, uint256 _mintAmount, bytes32[] calldata _merkleProof) 
    public 
    payable 
    mintCompliance(_mintAmount) 
    mintPriceCompliance(_mintAmount)
    checkSaleState(SaleStates.WHITELIST) 
  {
    uint256 currentSaleState = uint256(saleState);
    require(
      numberMinted[currentSaleState][_to] + _mintAmount <= maxWLTokensPerWallet, 
      "Max mint for whitelist exceeded!"
    );
    bytes32 leaf = keccak256(abi.encodePacked(_to));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid wl proof!");

    numberMinted[currentSaleState][_to] += _mintAmount;

    _mint(_to, _mintAmount);
  }

  function mint(address _to, uint256 _mintAmount) 
    public 
    payable 
    mintCompliance(_mintAmount) 
    mintPriceCompliance(_mintAmount)
    checkSaleState(SaleStates.PUBLIC) 
  {
    uint256 currentSaleState = uint256(saleState);
    require(
      numberMinted[currentSaleState][_to] + _mintAmount <= maxPublicTokensPerWallet, 
      "Max mint for public exceeded!"
    );

    numberMinted[currentSaleState][_to] += _mintAmount;
    _mint(_to, _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _mint(_receiver, _mintAmount);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory) {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

    if (!revealed) {
      return unRevealedURL;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), ".json"))
        : '';
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxPublicTokensPerWallet(uint256 _maxPublicTokensPerWallet) public onlyOwner {
    maxPublicTokensPerWallet = _maxPublicTokensPerWallet;
  }

  function setMaxWLTokensPerWallet(uint256 _maxWLTokensPerWallet) public onlyOwner {
    maxWLTokensPerWallet = _maxWLTokensPerWallet;
  }

  function setUnRevealedURL(string memory _unRevealedURL) public onlyOwner {
    unRevealedURL = _unRevealedURL;
  }

  function setBaseURL(string memory _baseUrl) public onlyOwner {
    baseURL = _baseUrl;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  // CLOSED = 0, WHITELIST = 1, PUBLIC = 2
  function setSaleState(uint256 newSaleState) public onlyOwner {
    require(newSaleState <= uint256(SaleStates.PUBLIC), "sale state not valid");
    saleState = SaleStates(newSaleState);
  }

  function withdraw() public onlyOwner nonReentrant {
    (bool hs, ) = payable(0x271FC830f189922E27c8753c346BCC469E03Dc8F).call{value: address(this).balance * 6 / 100}('');
    require(hs);

    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURL;
  }

   function transferFrom(address from, address to, uint256 tokenId)
    public
    payable
    override(ERC721A, IERC721A)
    onlyAllowedOperator(from)
  {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId)
    public
    payable
    override(ERC721A, IERC721A)
    onlyAllowedOperator(from)
  {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    payable
    override(ERC721A, IERC721A)
    onlyAllowedOperator(from)
  {
    super.safeTransferFrom(from, to, tokenId, data);
  }
}
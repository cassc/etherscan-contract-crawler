// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./DefaultOperatorFilterer.sol";

contract Shinzo is ERC721A, DefaultOperatorFilterer, Ownable {
  enum SaleStates {
    CLOSED,
    PUBLIC,
    WHITELIST
  }

  SaleStates public saleState;

  bytes32 public whitelistMerkleRoot;

  uint256 public maxSupply = 7777;
  uint256 public maxPublicTokens = 5950;
  uint256 public publicSalePrice = 0.0177 ether;

  uint64 public maxPublicTokensPerWallet = 3;
  uint64 public maxWLTokensPerWallet = 1;

  string public baseURL;
  string public unRevealedURL;

  bool public isRevealed = false;
  address public partnerAddress = 0x7aF1412eAfE1faD3741d5ADab3366547F6772E98;

  constructor() ERC721A("Shinzo", "SHINZO") {
    _mintERC2309(0x7d6bc95419a51F8D075AacFC486Ec97922a0529e, 50);
  }

  modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
    require(
      MerkleProof.verify(
        merkleProof,
        root,
        keccak256(abi.encodePacked(msg.sender))
      ),
      "Your wallet is not on the list"
    );
    _;
  }

  modifier canMint(uint256 numberOfTokens) {
    require(
      _totalMinted() + numberOfTokens <= maxSupply,
      "There are no tokens left to mint"
    );
    _;
  }

  modifier checkState(SaleStates _saleState) {
    require(saleState == _saleState, "sale is not live");
    _;
  }

  function whitelistMint(bytes32[] calldata _merkleProof, uint64 _numberOfTokens)
    external
    isValidMerkleProof(_merkleProof, whitelistMerkleRoot)
    canMint(_numberOfTokens)
    checkState(SaleStates.WHITELIST)
  {
    uint64 userAuxiliary = _getAux(msg.sender);
    require(
      userAuxiliary + _numberOfTokens <= maxWLTokensPerWallet,
      "The minting limit has been exceeded"
    );

    _setAux(msg.sender, userAuxiliary + _numberOfTokens);
    _mint(msg.sender, _numberOfTokens);
  }

  function publicMint(uint64 _numberOfTokens)
    external
    payable
    canMint(_numberOfTokens)
    checkState(SaleStates.PUBLIC)
  {
    require(
      _totalMinted() + _numberOfTokens <= maxPublicTokens,
      "You have minted the maximum number of public tokens"
    );
    require(
      (_numberMinted(msg.sender) - _getAux(msg.sender)) + _numberOfTokens <=
        maxPublicTokensPerWallet,
      "The minting limit has been exceeded"
    );

    require(msg.value >= publicSalePrice * _numberOfTokens, "Not enough ETH");

    _mint(msg.sender, _numberOfTokens);
  }

  function mintTo(address[] memory _to, uint256[] memory _numberOfTokens) external onlyOwner{
    require(
        _to.length == _numberOfTokens.length, 
        "invalid arrays of address and number"
    );

    for (uint256 i = 0; i < _to.length; i++) {
        require(
            _totalMinted() + _numberOfTokens[i] <= maxSupply, 
            "There are no tokens left to mint"
        );
        _mint(_to[i], _numberOfTokens[i]);
    }
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    if (!isRevealed) {
      return unRevealedURL;
    }

    string memory currentBaseURI = _baseURI();
    return
      bytes(currentBaseURI).length > 0
        ? string(
          abi.encodePacked(currentBaseURI, Strings.toString(_tokenId), ".json")
        )
        : "";
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURL;
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function numberMintedWl(address _account) external view returns (uint64) {
    return _getAux(_account);
  }

  function numberMinted(address _account) external view returns (uint256) {
    return _numberMinted(_account);
  }

  // Metadata
  function setBaseURL(string memory _baseURL) external onlyOwner {
    baseURL = _baseURL;
  }

  function setUnRevealedURL(string memory _unRevealedURL) external onlyOwner {
    unRevealedURL = _unRevealedURL;
  }

  function toggleRevealed() external onlyOwner {
    isRevealed = !isRevealed;
  }

  // Sale Price
  function setPublicSalePrice(uint256 _price) external onlyOwner {
    publicSalePrice = _price;
  }

  // CLOSED = 0, PUBLIC = 1, WHITELIST = 2
  function setSaleState(uint256 _newSaleState) external onlyOwner {
    require(
      _newSaleState <= uint256(SaleStates.WHITELIST),
      "The sale state is unvalid"
    );
    saleState = SaleStates(_newSaleState);
  }

  // Max Tokens Per Wallet
  function setMaxPublicTokensPerWallet(uint64 _maxPublicTokensPerWallet) external onlyOwner{
    maxPublicTokensPerWallet = _maxPublicTokensPerWallet;
  }

  function setMaxWLTokensPerWallet(uint64 _maxWLTokensPerWallet)external onlyOwner{
    maxWLTokensPerWallet = _maxWLTokensPerWallet;
  }

  function setWhitelistMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    whitelistMerkleRoot = _merkleRoot;
  }

  function setMaxSupply(uint256 _newMaxSupply) external onlyOwner {
    require(_newMaxSupply < maxSupply, "max supply cannot be more than current");
    maxSupply = _newMaxSupply;
  }

  function setPartnerAddress(address _newAddress) external onlyOwner {
    require(_newAddress != address(0), "new address cannot be of zero");
    partnerAddress = _newAddress;
  }

  function setMaxPublicTokens(uint256 _maxPublicTokens) external onlyOwner {
    maxPublicTokens = _maxPublicTokens;
  }

  function withdraw() external onlyOwner {

    (bool ps, ) = payable(partnerAddress).call{value: (address(this).balance * 50) / 100}("");
    require(ps);

    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

  function transferFrom(address from, address to, uint256 tokenId)
    public
    payable
    override
    onlyAllowedOperator(from)
  {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId)
    public
    payable
    override
    onlyAllowedOperator(from)
  {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    payable
    override
    onlyAllowedOperator(from)
  {
    super.safeTransferFrom(from, to, tokenId, data);
  }

}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/RevokableDefaultOperatorFilterer.sol";
import "operator-filter-registry/src/UpdatableOperatorFilterer.sol";

//
// CryptoPokers with KEIGOINOUE
//
contract CryptoPokersWithKEIGOINOUE is
  ERC721AQueryable,
  RevokableDefaultOperatorFilterer,
  IERC2981,
  Ownable,
  ReentrancyGuard
{
  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => uint256) public alClaimed;

  string public uriPrefix = "";
  string public uriSuffix = ".json";
  string public hiddenMetadataUri;

  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;

  bool public paused = true;
  bool public alMintEnabled = false;
  bool public revealed = false;

  address payable public withdrawalWallet;
  address payable public royaltyWallet;
  uint256 public royaltyBasis;

  // Signals frozen metadata to OpenSea
  bool public uriPermanent = false;

  event PermanentURI(string _value, uint256 indexed _id);

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    string memory _hiddenMetadataUri,
    uint256 _royaltyBasis,
    address receiver
  ) ERC721A(_tokenName, _tokenSymbol) {
    cost = _cost;
    maxSupply = _maxSupply;
    maxMintAmountPerTx = _maxMintAmountPerTx;
    setHiddenMetadataUri(_hiddenMetadataUri);
    royaltyBasis = _royaltyBasis;
    royaltyWallet = payable(receiver);
    withdrawalWallet = payable(receiver);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
    require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded!");
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, "Insufficient funds!");
    _;
  }

  modifier changeURICompliance() {
    require(!uriPermanent, "URI is frozen!");
    _;
  }

  function alMint(
    uint256 _mintAmount,
    uint8 _maxMintAmount,
    bytes32[] calldata _merkleProof
  ) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(alMintEnabled, "The AL sale is not enabled!");
    require(
      alClaimed[_msgSender()] + _mintAmount <= _maxMintAmount,
      "Total mint amount will be over!"
    );

    bytes32 leaf = keccak256(abi.encodePacked(_msgSender(), _maxMintAmount));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid proof!");

    alClaimed[_msgSender()] += _mintAmount;
    _safeMint(_msgSender(), _mintAmount);
  }

  function mint(
    uint256 _mintAmount
  ) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, "The contract is paused!");

    _safeMint(_msgSender(), _mintAmount);
  }

  function mintForAddress(
    uint256 _mintAmount,
    address _receiver
  ) public mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function _afterTokenTransfers(
    address from,
    address /*to*/,
    uint256 startTokenId,
    uint256 quantity
  ) internal override {
    if (from == address(0) && uriPermanent) {
      uint256 endTokenId = startTokenId + quantity - 1;
      for (uint256 i = startTokenId; i <= endTokenId; i++) {
        emit PermanentURI(string(abi.encodePacked(uriPrefix, i.toString(), uriSuffix)), i);
      }
    }
  }

  function tokenURI(
    uint256 _tokenId
  ) public view virtual override(ERC721A, IERC721A) returns (string memory) {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    return
      bytes(uriPrefix).length > 0
        ? string(abi.encodePacked(uriPrefix, _tokenId.toString(), uriSuffix))
        : "";
  }

  function setRevealed(bool _state) public changeURICompliance onlyOwner {
    revealed = _state;
  }

  function permanentURI() public onlyOwner {
    require(revealed, "not revealed yet");
    uriPermanent = true;
  }

  function emitPermanentURI(uint256 _fromId, uint256 _toId) public onlyOwner {
    require(uriPermanent, "URI is not frozen");
    require(_fromId <= _toId, "invalid token range");
    require(_fromId >= _startTokenId(), "invalid _fromId");
    require(_toId <= totalSupply() + _startTokenId() - 1, "invalid _toId");

    for (uint256 i = _fromId; i <= _toId; i++) {
      emit PermanentURI(string(abi.encodePacked(uriPrefix, i.toString(), uriSuffix)), i);
    }
  }

  function setRoyaltyBasis(uint256 _royaltyBasis) public onlyOwner {
    royaltyBasis = _royaltyBasis;
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

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setALMintEnabled(bool _state) public onlyOwner {
    alMintEnabled = _state;
  }

  function setUriPrefix(string memory _uriPrefix) public changeURICompliance onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public changeURICompliance onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function withdraw(uint256 _amount) public onlyOwner nonReentrant {
    require(_amount <= address(this).balance, "Invalid withdraw amount!");
    payable(withdrawalWallet).transfer(_amount);
  }

  function withdrawAll() public onlyOwner nonReentrant {
    payable(withdrawalWallet).transfer(address(this).balance);
  }

  function setWithdrawalWallet(address payable _withdrawalWallet) external onlyOwner {
    withdrawalWallet = (_withdrawalWallet);
  }

  function setRoyaltyWallet(address payable _royaltyWallet) external onlyOwner {
    royaltyWallet = (_royaltyWallet);
  }

  // ERC2981
  function royaltyInfo(
    uint256 tokenId,
    uint256 salePrice
  ) external view override returns (address receiver, uint256 royaltyAmount) {
    require(_exists(tokenId), "Nonexistent token");
    return (payable(royaltyWallet), uint256((salePrice * royaltyBasis) / 10000));
  }

  // ERC165
  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override(ERC721A, IERC721A, IERC165) returns (bool) {
    return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
  }

  // OpenSea operator filter
  function setApprovalForAll(
    address operator,
    bool approved
  ) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(
    address operator,
    uint256 tokenId
  ) public payable override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }

  function owner()
    public
    view
    virtual
    override(Ownable, UpdatableOperatorFilterer)
    returns (address)
  {
    return Ownable.owner();
  }
}
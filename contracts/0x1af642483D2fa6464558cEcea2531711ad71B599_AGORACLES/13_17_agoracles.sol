// SPDX-License-Identifier: UNLICENCED

pragma solidity ^0.8.7;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/token/common/ERC2981.sol';
import '@openzeppelin/contracts/finance/PaymentSplitter.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "operator-filter-registry/src/UpdatableOperatorFilterer.sol";

contract AGORACLES is Ownable, ERC721A, ERC2981, PaymentSplitter, UpdatableOperatorFilterer {

  bool public isPreSale1MintingOpened;
  bool public isPreSale2MintingOpened;
  bool public isPublicMintingOpened;
  bool public isFreeMintingOpened;

  uint16 public constant collectionSize = 6300;
  uint16 public presale1MintPerWalletLimit = 10;
  uint16 public presale2MintPerWalletLimit = 3;
  uint16 public publicMintPerWalletLimit = 3;
  uint16 public freeMintPerWalletLimit = 10;

  bytes32 public merkleRoot;
  bytes32 public freeMintMerkleRoot;

  uint256 public publicPrice = 0.54 ether;
  uint256 public presale1Price = 0.375 ether;
  uint256 public presale2Price = 0.46 ether;

  string public baseURI;
  address constant MYDEFAULT_SUBSCRIPTION = address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);
  address constant MYOPERATOR_FILTER_REGISTRY = address(0x000000000000AAeB6D7670E522A718067333cd4E);

  mapping(address => uint256) public publicCountPerWallet;
  mapping(address => uint256) public presale1CountPerWallet;
  mapping(address => uint256) public presale2CountPerWallet;
  mapping(address => uint256) public freeMintCountPerWallet;

  event PreSale1MintFlipped(bool wlMint);
  event PreSale2MintFlipped(bool wlMint);
  event FreeMintFlipped(bool wlMint);
  event PublicMintFlipped(bool publicMint);
  event PublicMintPerWalletLimitUpdated(uint256 newLimit);
  event PreSale1MintPerWalletLimitUpdated(uint256 newLimit);
  event PreSale2MintPerWalletLimitUpdated(uint256 newLimit);
  event FreeMintPerWalletLimitUpdated(uint16 newLimit);
  event BaseURIUpdated(string newURI);
  event DefaultRoyaltySet(address receiver, uint96 feeNumerator);
  event PublicPriceUpdated(uint256 newPrice);
  event presale1PriceUpdated(uint256 newPrice);
  event presale2PriceUpdated(uint256 newPrice);
  event MerkleRootUpdated(bytes32 root);
  event FreeMintMerkleRootUpdated(bytes32 root);

  constructor(
    address _owner,
    address[] memory payees,
    uint256[] memory shares,
    string memory _uri)
    ERC721A("AGORACLES","AGORA")
    PaymentSplitter(payees, shares)
    UpdatableOperatorFilterer(MYOPERATOR_FILTER_REGISTRY, MYDEFAULT_SUBSCRIPTION, true)
    {
      require(_owner != address(0), "Please provide a valid owner");
      baseURI = _uri;
      setDefaultRoyalty(_owner, 500); // 5% fees
      transferOwnership(_owner);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
      return 1;
  }

  //
  // Collection settings
  //

  function setBaseURI(string calldata _newBaseURI) external onlyOwner {
    baseURI = _newBaseURI;
    emit BaseURIUpdated(_newBaseURI);
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  // 10% => feeNumerator = 1000
  function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
    _setDefaultRoyalty(receiver, feeNumerator);
    emit DefaultRoyaltySet(receiver, feeNumerator);
  }

  //
  // Mint
  //

  function updatePublicMintPerWalletLimit(uint16 newLimit) external onlyOwner{
    publicMintPerWalletLimit = newLimit;
    emit PublicMintPerWalletLimitUpdated(newLimit);
  }

  function updatePublicPrice(uint256 newPrice) external onlyOwner{
    publicPrice = newPrice;
    emit PublicPriceUpdated(newPrice);
  }

  function mint(uint16 count) external payable {
    mintTo(msg.sender, count);
  }

  function mintTo(address to, uint16 amount) public payable {
    require(msg.value >= amount * publicPrice,"Insufficiant amount sent");
    require(isPublicMintingOpened, "Public minting is closed");
    require(publicCountPerWallet[to] + amount <= publicMintPerWalletLimit, "Max limit per wallet");
    publicCountPerWallet[to] += amount;

    _batchMint(to, amount);
  }

  function flipPublicMint() external onlyOwner {
    isPublicMintingOpened = !isPublicMintingOpened;
    emit PublicMintFlipped(isPublicMintingOpened);
  }

  function _batchMint(address to, uint256 count) private {
    require(totalSupply() + count <= collectionSize, "Collection is sold out");
    _safeMint(to, count);
  }

  //
  // Freemint management
  //

  function flipFreeMint() external onlyOwner {
    isFreeMintingOpened = !isFreeMintingOpened;
    emit FreeMintFlipped(isFreeMintingOpened);
  }

  function updateFreeMintPerWalletLimit(uint16 newLimit) external onlyOwner {
    freeMintPerWalletLimit = newLimit;
    emit FreeMintPerWalletLimitUpdated(newLimit);
  }

  function freeMint(uint256 amount, bytes32[] memory _proof) external {
    freeMintTo(msg.sender, amount, _proof);
  }

  function freeMintTo(address to, uint256 amount, bytes32[] memory _proof) public {
    require(isFreeMintingOpened, "Presale minting is closed");
    require(isFreeMintWhiteListed(to, _proof), "Address not in freemint list");
    require(freeMintCountPerWallet[to] + amount <= freeMintPerWalletLimit, "Max limit per wallet");
    freeMintCountPerWallet[to] += amount;

    _batchMint(to, amount);
  }

  function isFreeMintWhiteListed(address _a, bytes32[] memory _proof) public view returns (bool) {
    bytes32 leaf = keccak256(abi.encodePacked(_a));
    return MerkleProof.verify(_proof, freeMintMerkleRoot, leaf);
  }

  function setFreeMintRoot(bytes32 _merkleRoot) external onlyOwner {
    freeMintMerkleRoot = _merkleRoot;
    emit FreeMintMerkleRootUpdated(_merkleRoot);
  }

  //
  // Aridrop
  //

  function airdrop(address to, uint16 count) external onlyOwner {
    _batchMint(to, count);
  }

  //
  // PreSale 1 management
  //

  function flipPreSale1Mint() external onlyOwner{
    isPreSale1MintingOpened = !isPreSale1MintingOpened;
    emit PreSale1MintFlipped(isPreSale1MintingOpened);
  }

  function updatePreSale1MintPerWalletLimit(uint16 newLimit) external onlyOwner{
    presale1MintPerWalletLimit = newLimit;
    emit PreSale1MintPerWalletLimitUpdated(newLimit);
  }

  function updatePresale1Price(uint256 newPrice) external onlyOwner{
    presale1Price = newPrice;
    emit presale1PriceUpdated(newPrice);
  }

  function mintPresale1(uint256 amount) external payable {
    mintPresale1To(msg.sender, amount);
  }

  function mintPresale1To(address to, uint256 amount) public payable {
    require(msg.value >= amount * presale1Price,"Insufficiant amount sent");
    require(isPreSale1MintingOpened, "Presale minting is closed");
    require(presale1CountPerWallet[to] + amount <= presale1MintPerWalletLimit, "Max limit per wallet");
    presale1CountPerWallet[to] += amount;

    _batchMint(to, amount);
  }

  //
  // PreSale 2 management
  //

  function flipPreSale2Mint() external onlyOwner{
    isPreSale2MintingOpened = !isPreSale2MintingOpened;
    emit PreSale2MintFlipped(isPreSale2MintingOpened);
  }

  function updatePreSale2MintPerWalletLimit(uint16 newLimit) external onlyOwner{
    presale2MintPerWalletLimit = newLimit;
    emit PreSale2MintPerWalletLimitUpdated(newLimit);
  }

  function updatePresale2Price(uint256 newPrice) external onlyOwner{
    presale2Price = newPrice;
    emit presale2PriceUpdated(newPrice);
  }

  function mintPresale2(uint256 amount, bytes32[] memory _proof) external payable {
    mintPresale2To(msg.sender, amount, _proof);
  }

  function mintPresale2To(address to, uint256 amount, bytes32[] memory _proof) public payable {
    require(msg.value >= amount * presale2Price,"Insufficiant amount sent");
    require(isPreSale2MintingOpened, "Presale minting is closed");
    require(isWhiteListed(to, _proof), "Address not White Listed");
    require(presale2CountPerWallet[to] + amount <= presale2MintPerWalletLimit, "Max limit per wallet");
    presale2CountPerWallet[to] += amount;

    _batchMint(to, amount);
  }

  function isWhiteListed(address _a, bytes32[] memory _proof) public view returns (bool) {
    bytes32 leaf = keccak256(abi.encodePacked(_a));
    return MerkleProof.verify(_proof, merkleRoot, leaf);
  }

  function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    merkleRoot = _merkleRoot;
    emit MerkleRootUpdated(_merkleRoot);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
    return ERC721A.supportsInterface(interfaceId) ||
        ERC2981.supportsInterface(interfaceId);
  }

  function owner() public view virtual override(Ownable, UpdatableOperatorFilterer) returns (address) {
    return Ownable.owner();
  }

  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
      super.approve(operator, tokenId);
  }

  function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
      super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
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
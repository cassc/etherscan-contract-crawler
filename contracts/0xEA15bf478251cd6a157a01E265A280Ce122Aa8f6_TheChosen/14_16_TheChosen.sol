// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "closedsea/src/OperatorFilterer.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

error MintingPaused();
error MaxSupplyReached();
error WrongEtherAmount();
error MaxWalletCountReached();
error InvalidMintAddress();

interface ITheShredded {
  function mint(address to, uint256 tokenId) external payable;
}

contract TheChosen is
  ERC721A,
  ERC2981,
  OperatorFilterer,
  PaymentSplitter,
  Ownable
{
  uint256 private constant MAX_SUPPLY = 100;
  uint256 private constant MINT_PRICE = 0.39 ether;

  bool public publicMintPaused = true;
  bool public whitelistMintPaused = true;
  bool public operatorFilteringEnabled = true;

  address private _shreddedAddress;
  uint256 public maxBurnTimestamp;

  mapping(address => uint8) private _walletCount;

  bytes32 private _merkleRoot;

  string tokenBaseUri =
    "ipfs://QmecwJnR5kzCcRj6Cy8fLJuUqFm3tAWUD8iWumbAs7prMZ/?";

  constructor(
    address owner,
    address[] memory payees,
    uint256[] memory shares
  ) ERC721A("The Chosen", "TC") PaymentSplitter(payees, shares) {
    _transferOwnership(owner);
    _registerForOperatorFiltering();
    _setDefaultRoyalty(owner, 500);
    _mint(owner, 1);
  }

  function mint(bytes32[] calldata merkleProof) external payable {
    if (whitelistMintPaused) revert MintingPaused();
    if (totalSupply() + 1 > MAX_SUPPLY) revert MaxSupplyReached();
    if (msg.value < MINT_PRICE) revert WrongEtherAmount();
    if (_walletCount[msg.sender] == 1) revert MaxWalletCountReached();

    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

    if (!MerkleProof.verify(merkleProof, _merkleRoot, leaf)) {
      revert InvalidMintAddress();
    }

    _walletCount[msg.sender] = 1;

    _mint(msg.sender, 1);
  }

  function mint() external payable {
    if (publicMintPaused) revert MintingPaused();
    if (totalSupply() + 1 > MAX_SUPPLY) revert MaxSupplyReached();
    if (msg.value < MINT_PRICE) revert WrongEtherAmount();

    _mint(msg.sender, 1);
  }

  function burn(uint256 tokenId) public {
    if (block.timestamp < maxBurnTimestamp && _shreddedAddress != address(0)) {
      ITheShredded(_shreddedAddress).mint(msg.sender, tokenId);
    }

    _burn(tokenId, true);
  }

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function _baseURI() internal view override returns (string memory) {
    return tokenBaseUri;
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721A, ERC2981)
    returns (bool)
  {
    return
      ERC721A.supportsInterface(interfaceId) ||
      ERC2981.supportsInterface(interfaceId);
  }

  function _operatorFilteringEnabled() internal view override returns (bool) {
    return operatorFilteringEnabled;
  }

  function _isPriorityOperator(address operator)
    internal
    pure
    override
    returns (bool)
  {
    // OpenSea
    return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
  }

  function setApprovalForAll(address operator, bool approved)
    public
    override(ERC721A)
    onlyAllowedOperatorApproval(operator)
  {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId)
    public
    payable
    override(ERC721A)
    onlyAllowedOperatorApproval(operator)
  {
    super.approve(operator, tokenId);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public payable override(ERC721A) onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public payable override(ERC721A) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public payable override(ERC721A) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }

  function setDefaultRoyalty(address receiver, uint96 feeNumerator)
    public
    onlyOwner
  {
    _setDefaultRoyalty(receiver, feeNumerator);
  }

  function setOperatorFilteringEnabled(bool value) public onlyOwner {
    operatorFilteringEnabled = value;
  }

  function setShreddedAddress(address newShreddedAddress) public onlyOwner {
    _shreddedAddress = newShreddedAddress;
  }

  function setBaseURI(string calldata newBaseUri) external onlyOwner {
    tokenBaseUri = newBaseUri;
  }

  function setMaxBurnTimestamp(uint256 burnTimestamp) external onlyOwner {
    maxBurnTimestamp = burnTimestamp;
  }

  function setMerkleRoot(bytes32 newMerkleRoot) public onlyOwner {
    _merkleRoot = newMerkleRoot;
  }

  function flipPublicSale() external onlyOwner {
    publicMintPaused = !publicMintPaused;
  }

  function flipWhitelistSale() external onlyOwner {
    whitelistMintPaused = !whitelistMintPaused;
  }
}
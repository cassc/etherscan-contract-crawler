// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.18;

import "erc721a/contracts/ERC721A.sol";
import "closedsea/src/OperatorFilterer.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

error MintingPaused();
error MaxSupplyReached();
error WrongEtherAmount();
error InvalidMintAddress();
error MaxWalletCountReached();
error RecipientsAndTokensMismatch();

contract GaleriesMintPass is ERC721A, ERC2981, OperatorFilterer, Ownable {
  bool public publicMintPaused = true;
  bool public whitelistMintPaused = true;
  bool public operatorFilteringEnabled = true;

  uint256 public maxSupply = 200;
  uint256 public mintPrice = 0.2 ether;

  mapping(address => uint8) private _walletCount;

  bytes32 private _merkleRoot;

  string tokenBaseUri =
    "ipfs://QmQh31hMXPSBNaZjhySj7xcPPDpYwhwoD9p7MunQh2ivU7/?";

  constructor() ERC721A("Galeries Mint Pass", "GMP") {
    _registerForOperatorFiltering();
    _setDefaultRoyalty(msg.sender, 500);
  }

  function mint(bytes32[] calldata merkleProof) external payable {
    if (whitelistMintPaused) revert MintingPaused();
    if (totalSupply() + 1 > maxSupply) revert MaxSupplyReached();
    if (msg.value < mintPrice) revert WrongEtherAmount();
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
    if (totalSupply() + 1 > maxSupply) revert MaxSupplyReached();
    if (msg.value < mintPrice) revert WrongEtherAmount();

    _mint(msg.sender, 1);
  }

  function batchTransfer(
    address[] calldata recipients,
    uint256[] calldata tokenIds
  ) external {
    uint256 recipientLength = recipients.length;

    if (recipientLength != tokenIds.length)
      revert RecipientsAndTokensMismatch();

    unchecked {
      for (uint256 i = 0; i < recipientLength; ++i) {
        transferFrom(msg.sender, recipients[i], tokenIds[i]);
      }
    }
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

  function ownerMint(uint256 amount) external onlyOwner {
    if (totalSupply() + amount > maxSupply) revert MaxSupplyReached();

    _mint(msg.sender, amount);
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

  function setBaseURI(string calldata newBaseUri) external onlyOwner {
    tokenBaseUri = newBaseUri;
  }

  function setMaxSupply(uint256 newMaxSupply) external onlyOwner {
    require(newMaxSupply > maxSupply, "New max supply must be higher");
    maxSupply = newMaxSupply;
  }

  function setMintPrice(uint256 newMintPrice) external onlyOwner {
    mintPrice = newMintPrice;
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

  function withdraw() public onlyOwner {
    (bool success, ) = payable(owner()).call{value: address(this).balance}("");
    require(success, "Withdrawal failed");
  }
}
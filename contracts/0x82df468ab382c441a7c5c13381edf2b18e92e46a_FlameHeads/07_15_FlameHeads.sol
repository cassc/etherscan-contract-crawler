// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {ERC721A, IERC721A} from "ERC721A.sol";
import {Ownable} from "Ownable.sol";
import {MerkleProof} from "MerkleProof.sol";
import {OperatorFilterer} from "OperatorFilterer.sol";
import {IERC2981} from "IERC2981.sol";
import {ERC2981} from "ERC2981.sol";
import {ERC721ABurnable} from "ERC721ABurnable.sol";
import {ERC721AQueryable} from "ERC721AQueryable.sol";

error MintingPaused();
error MaxSupplyReached();
error WithdrawalFailed();
error WrongEtherAmount();
error InvalidMintAddress();
error ArrayLengthMismatch();
error MaxPerTransactionReached();
error MaxPerWalletReached();
error NoWL();

contract FlameHeads is
  Ownable,
  ERC721A,
  ERC2981,
  ERC721ABurnable,
  ERC721AQueryable,
  OperatorFilterer
{
  enum Step {
        Paused,
        Whitelist,
        Public
  }

  Step public sellingStep;
  uint256 public constant MAX_SUPPLY = 6666;
  uint256 public constant MAX_PER_WALLET_WL = 1;
  uint256 public constant MAX_PER_TRANSACTION_PUBLIC = 6;
  uint256 public MINT_PRICE = 0.006 ether;
  uint256 public WL_MAX_SUPPLY = 1111;
  bool public operatorFilteringEnabled = true;
  bytes32 public merkleRootWL;
  mapping(address => uint8) public NFTsperWalletWL;

  string tokenBaseUri = "";

  constructor(address deployer) ERC721A("FlameHeads", "FH") {
    sellingStep = Step(0);
    _transferOwnership(deployer);
    _registerForOperatorFiltering();
    _setDefaultRoyalty(deployer, 300);
  }

  function mint(uint8 quantity) external payable {
    if (sellingStep != Step(2)) revert MintingPaused();
    if (_totalMinted() + quantity > MAX_SUPPLY - WL_MAX_SUPPLY) revert MaxSupplyReached();
    if (quantity > MAX_PER_TRANSACTION_PUBLIC) revert MaxPerTransactionReached();
    if (msg.value < quantity * MINT_PRICE) revert WrongEtherAmount();

    _mint(msg.sender, quantity);
  }

  function wlmint(bytes32[] calldata _proof) external payable {
    if (sellingStep != Step(1)) revert MintingPaused();
    if (isWhiteListed(msg.sender, _proof) != true) revert NoWL();
    if (_totalMinted() + 1 > MAX_SUPPLY) revert MaxSupplyReached();
    if(NFTsperWalletWL[msg.sender] == MAX_PER_WALLET_WL) revert MaxPerWalletReached();
    NFTsperWalletWL[msg.sender] += 1;

    _mint(msg.sender, 1);
  }

  function isWhiteListed(address _account, bytes32[] calldata _proof) internal view returns(bool) {
    return MerkleProof.verify(_proof, merkleRootWL, keccak256(abi.encodePacked(_account)));
  }

  function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    merkleRootWL = _merkleRoot;
  }

  function setStep(uint8 step) external onlyOwner {
    sellingStep = Step(step);
  }

  function setMintPrice(uint256 newMintPrice) external onlyOwner {
    MINT_PRICE = newMintPrice;
  }

  function getMintPrice() public view returns (uint256) {
    return MINT_PRICE;
  }

  function setWLMaxSupply(uint256 newWLMaxSupply) external onlyOwner {
    WL_MAX_SUPPLY = newWLMaxSupply;
  }

  function setDefaultRoyalty(
    address receiver,
    uint96 feeNumerator
  ) public onlyOwner {
    _setDefaultRoyalty(receiver, feeNumerator);
  }

  function setOperatorFilteringEnabled(bool value) public onlyOwner {
    operatorFilteringEnabled = value;
  }

  function setBaseURI(string calldata newBaseUri) external onlyOwner {
    tokenBaseUri = newBaseUri;
  }

  function collectReserves(uint16 quantity) external onlyOwner {
    if (_totalMinted() + quantity > MAX_SUPPLY) revert MaxSupplyReached();

    _mint(msg.sender, quantity);
  }

  function withdraw() public onlyOwner {
    (bool success, ) = payable(owner()).call{value: address(this).balance}("");

    if (!success) {
      revert WithdrawalFailed();
    }
  }

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function _baseURI() internal view override returns (string memory) {
    return tokenBaseUri;
  }

  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override(ERC721A, IERC721A, ERC2981) returns (bool) {
    return
      ERC721A.supportsInterface(interfaceId) ||
      ERC2981.supportsInterface(interfaceId);
  }

  function _operatorFilteringEnabled() internal view override returns (bool) {
    return operatorFilteringEnabled;
  }

  function _isPriorityOperator(
    address operator
  ) internal pure override returns (bool) {
    return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
  }

  function setApprovalForAll(
    address operator,
    bool approved
  ) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(
    address operator,
    uint256 tokenId
  )
    public
    payable
    override(ERC721A, IERC721A)
    onlyAllowedOperatorApproval(operator)
  {
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
}

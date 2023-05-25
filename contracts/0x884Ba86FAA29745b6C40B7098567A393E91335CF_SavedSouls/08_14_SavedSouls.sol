// SPDX-License-Identifier: None

pragma solidity ^0.8.19;

import {ERC721A, IERC721A} from "erc721a/contracts/ERC721A.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {OperatorFilterer} from "closedsea/src/OperatorFilterer.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {ERC721ABurnable} from "erc721a/contracts/extensions/ERC721ABurnable.sol";
import {ERC721AQueryable} from "erc721a/contracts/extensions/ERC721AQueryable.sol";

error MintingPaused();
error MaxSupplyReached();
error WithdrawalFailed();
error WrongEtherAmount();
error InvalidMintAddress();
error ArrayLengthMismatch();
error MaxPerTransactionReached();
error MintFromContractNotAllowed();

contract SavedSouls is
  Ownable,
  ERC721A,
  ERC2981,
  ERC721ABurnable,
  ERC721AQueryable,
  OperatorFilterer
{
  uint256 private constant MAX_SUPPLY = 9999;
  uint256 private constant MAX_PER_TRANSACTION = 6;
  uint256 private constant ADDITIONAL_MINT_PRICE = 0.009 ether;

  bool public mintPaused = true;
  bool public operatorFilteringEnabled = true;

  string tokenBaseUri = "";

  constructor(address deployer) ERC721A("Saved Souls", "SS") {
    _mint(deployer, 1);
    _transferOwnership(deployer);
    _registerForOperatorFiltering();
    _setDefaultRoyalty(deployer, 750);
  }

  function mint(uint8 quantity) external payable {
    if (mintPaused) revert MintingPaused();
    if (_totalMinted() + quantity > MAX_SUPPLY) revert MaxSupplyReached();
    if (quantity > MAX_PER_TRANSACTION) revert MaxPerTransactionReached();
    if (msg.sender != tx.origin) revert MintFromContractNotAllowed();

    uint8 payForCount = quantity;
    uint64 freeMintCount = _getAux(msg.sender);

    if (freeMintCount < 1) {
      payForCount = quantity - 1;
      _setAux(msg.sender, 1);
    }

    if (payForCount > 0) {
      if (msg.value < payForCount * ADDITIONAL_MINT_PRICE)
        revert WrongEtherAmount();
    }

    _mint(msg.sender, quantity);
  }

  function batchTransferFrom(
    address[] calldata recipients,
    uint256[] calldata tokenIds
  ) external {
    uint256 tokenIdsLength = tokenIds.length;

    if (tokenIdsLength != recipients.length) revert ArrayLengthMismatch();

    for (uint256 i = 0; i < tokenIdsLength; ) {
      transferFrom(msg.sender, recipients[i], tokenIds[i]);

      unchecked {
        ++i;
      }
    }
  }

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function _baseURI() internal view override returns (string memory) {
    return tokenBaseUri;
  }

  function freeMintedCount(address owner) external view returns (uint64) {
    return _getAux(owner);
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

  function flipSale() external onlyOwner {
    mintPaused = !mintPaused;
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
}
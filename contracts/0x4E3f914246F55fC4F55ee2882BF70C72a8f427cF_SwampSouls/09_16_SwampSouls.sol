// SPDX-License-Identifier: None

pragma solidity ^0.8.19;

import {SavedSoulsArtifacts} from "./SavedSoulsArtifacts.sol";
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

contract SwampSouls is
  Ownable,
  ERC721A,
  ERC2981,
  ERC721ABurnable,
  ERC721AQueryable,
  OperatorFilterer
{
  uint256 private constant MAX_SUPPLY = 999;
  SavedSoulsArtifacts private immutable savedSoulsArtifacts;

  bool public mintPaused = true;
  bool public operatorFilteringEnabled = true;

  string tokenBaseUri = "";

  constructor(
    address deployer,
    address artifactsContract
  ) ERC721A("Swamp Souls", "SwS") {
    _transferOwnership(deployer);
    _registerForOperatorFiltering();
    _setDefaultRoyalty(deployer, 750);
    savedSoulsArtifacts = SavedSoulsArtifacts(artifactsContract);
  }

  function mint(uint8 quantity) external payable {
    if (mintPaused) revert MintingPaused();
    if (_totalMinted() + quantity > MAX_SUPPLY) revert MaxSupplyReached();

    savedSoulsArtifacts.burn(msg.sender, 0, quantity);

    _mint(msg.sender, quantity);
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

  function collectRemaining(uint16 quantity) external onlyOwner {
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
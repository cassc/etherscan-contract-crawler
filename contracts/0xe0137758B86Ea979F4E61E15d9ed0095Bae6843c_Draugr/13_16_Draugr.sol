// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Draugr is ERC721, IERC721Receiver, DefaultOperatorFilterer, Ownable {
  /* Add minting logic here */

  using Strings for uint256;
  /* Add metadata logic here */
  ERC721Burnable immutable aerin;

  uint256 public tokenIdCounter;

  string contractBaseURI;
  mapping(address => uint256) public burnedByAddress;

  error AerinTokensOnly();

  constructor(
    address aerin_,
    string memory name_,
    string memory symbol_
  ) ERC721(name_, symbol_) Ownable() DefaultOperatorFilterer() {
    aerin = ERC721Burnable(aerin_);
    contractBaseURI = "ipfs://QmcQ3V15m24yX9nxs6hDvhWUVqTrHfoadVrTxXmyyHfyfr/";
  }

  /**
   *
   * @dev totalSupply: Return supply without need to be enumerable:
   *
   */
  function totalSupply() external view returns (uint256) {
    return (tokenIdCounter);
  }

  /**
   *
   * @dev onERC721Received:
   *
   */
  function onERC721Received(
    address,
    address from_,
    uint256 tokenId_,
    bytes memory
  ) external override returns (bytes4) {
    // Check this is an Aerin!
    if (msg.sender != address(aerin)) {
      revert AerinTokensOnly();
    }

    // Burn the sent token:
    aerin.burn(tokenId_);

    // Increment the user's burn counter:
    burnedByAddress[from_]++;

    // If we have received a multiple of four mint a Draugr
    if ((burnedByAddress[from_] % 4) == 0) {
      // Send Draugr

      // Collection is 1 indexed (i.e. first token will be 1, not 0)
      tokenIdCounter++;

      _mint(from_, tokenIdCounter);
    }

    return this.onERC721Received.selector;
  }

  function setApprovalForAll(address operator, bool approved)
  public
  override
  onlyAllowedOperatorApproval(operator)
  {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId)
  public
  override
  onlyAllowedOperatorApproval(operator)
  {
    super.approve(operator, tokenId);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }

  function tokenURI(uint256 tokenId)
  public
  view
  virtual
  override
  returns (string memory)
  {
    _requireMinted(tokenId);

    string memory baseURI = _baseURI();
    return
    bytes(baseURI).length > 0
    ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
    : "";
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return contractBaseURI;
  }

  function setBaseURI(string memory uri) public onlyOwner {
    contractBaseURI = uri;
  }
}
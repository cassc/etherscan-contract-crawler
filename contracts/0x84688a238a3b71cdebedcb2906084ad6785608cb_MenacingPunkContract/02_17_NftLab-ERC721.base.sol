// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/finance/PaymentSplitter.sol';
import './NftLab-Modifiers.interface.sol';

// ███╗   ██╗███████╗████████╗   ██╗      █████╗ ██████╗
// ████╗  ██║██╔════╝╚══██╔══╝   ██║     ██╔══██╗██╔══██╗
// ██╔██╗ ██║█████╗     ██║      ██║     ███████║██████╔╝
// ██║╚██╗██║██╔══╝     ██║      ██║     ██╔══██║██╔══██╗
// ██║ ╚████║██║        ██║      ███████╗██║  ██║██████╔╝
// ╚═╝  ╚═══╝╚═╝        ╚═╝      ╚══════╝╚═╝  ╚═╝╚═════╝
// NFT development start-finish, no up-front cost.
// Discord: https://discord.gg/kH7Gvnr2qp

contract NftLabERC721 is
  ERC721,
  ERC721Enumerable,
  Ownable,
  PaymentSplitter,
  NftLabModifiers
{
  /** Maximum number of tokens per tx */
  uint8 public immutable max_buy;
  /** Maximum amount of tokens overall */
  uint16 public immutable max_tokens;
  /** Price per token */
  uint256 public immutable cost;
  /** Image verification hash */
  string public provenance;
  /** Determines if tokens can be minted */
  bool public sale_active = false;
  /** Base URI */
  string public uri;

  constructor(
    string memory name,
    string memory symbol,
    uint8 mb,
    uint16 mt,
    uint256 price,
    string memory URI,
    address[] memory shareholders,
    uint256[] memory shares
  ) ERC721(name, symbol) PaymentSplitter(shareholders, shares) {
    max_buy = mb;
    max_tokens = mt;
    cost = price;
    uri = URI;
  }

  /** Class Methods */
  function reserve(uint256 amt) external onlyOwner {
    for (uint256 i = 0; i < amt; i++) {
      _safeMint(msg.sender, totalSupply());
    }
  }

  function mint(uint8 amt)
    external
    payable
    is_active(sale_active)
    buy_limit(amt, max_buy)
    token_limit(totalSupply(), amt, max_tokens)
    min_price(cost, amt, msg.value)
  {
    for (uint8 i = 0; i < amt; i++) {
      _safeMint(msg.sender, totalSupply());
    }
  }

  /** Setters */
  function setBaseURI(string memory val) external onlyOwner {
    uri = val;
  }

  function setProvenance(string memory val) external onlyOwner {
    provenance = val;
  }

  function setSaleState(bool val) external onlyOwner {
    sale_active = val;
  }

  /** Overrides */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721, ERC721Enumerable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function _baseURI()
    internal
    view
    virtual
    override
    returns (string memory)
  {
    return uri;
  }
}
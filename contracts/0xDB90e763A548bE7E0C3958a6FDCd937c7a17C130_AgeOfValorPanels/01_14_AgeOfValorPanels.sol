// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import {UpdatableOperatorFilterer} from "operator-filter-registry/src/UpdatableOperatorFilterer.sol";

/*
    ██████╗░░░██╗██╗███████╗░░░░░░░█████╗░░█████╗░███╗░░░███╗██╗░█████╗░░██████╗
    ╚════██╗░██╔╝██║╚════██║░░░░░░██╔══██╗██╔══██╗████╗░████║██║██╔══██╗██╔════╝
    ░░███╔═╝██╔╝░██║░░░░██╔╝█████╗██║░░╚═╝██║░░██║██╔████╔██║██║██║░░╚═╝╚█████╗░
    ██╔══╝░░███████║░░░██╔╝░╚════╝██║░░██╗██║░░██║██║╚██╔╝██║██║██║░░██╗░╚═══██╗
    ███████╗╚════██║░░██╔╝░░░░░░░░╚█████╔╝╚█████╔╝██║░╚═╝░██║██║╚█████╔╝██████╔╝
    ╚══════╝░░░░░╚═╝░░╚═╝░░░░░░░░░░╚════╝░░╚════╝░╚═╝░░░░░╚═╝╚═╝░╚════╝░╚═════╝░
*/

error AgeOfValorPanels__MaxSupplyReached();
error AgeOfValorPanels__InvalidAddress();
error AgeOfValorPanels__AlreadyMinted();
error AgeOfValorPanels__InsufficientFunds();
error AgeOfValorPanels__NotEnabled();

contract AgeOfValorPanels is
  ERC721AQueryable,
  Ownable,
  ReentrancyGuard,
  ERC2981,
  UpdatableOperatorFilterer
{
  /////////////////////
  // State Variables //
  /////////////////////

  uint256 public constant MAX_SUPPLY = 140;

  string private s_baseTokenURI;
  string private s_contractURI;

  uint256 private s_price = 0.08 ether;
  bool private s_isSaleActive = false;

  /**
   * @dev check if an address has minted, only one mint per address.
   */
  mapping(address => bool) private s_hasMinted;

  /////////////////////
  // Events          //
  /////////////////////

  /**
   * @dev Emitted when a token is minted
   */
  event Minted(address indexed minter, uint256 indexed tokenId);

  /**
   * @dev Emitted when tokens are air dropped
   */
  event Airdropped(
    address indexed operator,
    address indexed to,
    uint256 indexed quantity
  );

  /**
   * @dev emitted when the base URI is updated
   */
  event BaseURIChanged(address indexed operator, string indexed newBaseURI);

  /**
   * @dev emitted when the contract URI is updated
   */
  event ContractURIChanged(
    address indexed operator,
    string indexed newContractURI
  );

  /**
   * @dev emitted when the price is updated
   */
  event PriceChanged(address indexed operator, uint256 indexed newPrice);

  /**
   * @dev emitted when the sale is activated/deactivated
   */
  event SaleStatusChanged(address indexed operator, bool indexed isSaleActive);

  ////////////////////
  // Overrides      //
  ////////////////////

  /**
   * @notice Start token IDs at 1 instead of 0
   */
  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  ////////////////////
  // Main Functions //
  ////////////////////

  constructor(
    string memory baseURI
  )
    ERC721A("247 Age of Valor 01 Panel Moments", "AoV01Panels")
    UpdatableOperatorFilterer(
      0x000000000000AAeB6D7670E522A718067333cd4E,
      0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6,
      true
    )
  {
    s_baseTokenURI = baseURI;
    s_contractURI = baseURI;
  }

  /**
   * @notice mints a panel
   * @dev only one mint per address
   */
  function mint() external payable nonReentrant {
    if (!s_isSaleActive) {
      revert AgeOfValorPanels__NotEnabled();
    }
    if (s_hasMinted[msg.sender]) {
      revert AgeOfValorPanels__AlreadyMinted();
    }
    if (msg.value < s_price) {
      revert AgeOfValorPanels__InsufficientFunds();
    }
    uint256 nextTokenId = _nextTokenId();
    if (nextTokenId > MAX_SUPPLY) {
      revert AgeOfValorPanels__MaxSupplyReached();
    }

    s_hasMinted[msg.sender] = true;
    _safeMint(msg.sender, 1);
    emit Minted(msg.sender, nextTokenId);
  }

  /////////////////////
  // Admin Functions //
  /////////////////////

  /**
   * @notice airdrop a quantity of panels to an address
   */
  function airdrop(address to, uint256 quantity) external onlyOwner {
    if (to == address(0)) {
      revert AgeOfValorPanels__InvalidAddress();
    }
    if (_totalMinted() + quantity > MAX_SUPPLY) {
      revert AgeOfValorPanels__MaxSupplyReached();
    }
    _safeMint(to, quantity);
    emit Airdropped(msg.sender, to, quantity);
  }

  function setBaseURI(string memory newUri) external onlyOwner {
    if (bytes(newUri).length == 0) {
      revert AgeOfValorPanels__InvalidAddress();
    }
    s_baseTokenURI = newUri;
    emit BaseURIChanged(msg.sender, newUri);
  }

  /**
   * @notice Sets the contract URI for OpenSea listings
   * @param newContractURI new contract URI
   */
  function setContractURI(string memory newContractURI) external onlyOwner {
    if (bytes(newContractURI).length == 0) {
      revert AgeOfValorPanels__InvalidAddress();
    }
    s_contractURI = newContractURI;
    emit ContractURIChanged(msg.sender, newContractURI);
  }

  /**
   * @notice Sets the price for minting
   * @param newPrice new price in wei
   */
  function setPrice(uint256 newPrice) external onlyOwner {
    s_price = newPrice;
    emit PriceChanged(msg.sender, newPrice);
  }

  /**
   * @notice Sets the sale status
   * @param isSaleActive new sale status
   */
  function setSaleStatus(bool isSaleActive) external onlyOwner {
    s_isSaleActive = isSaleActive;
    emit SaleStatusChanged(msg.sender, isSaleActive);
  }

  /**
   * @notice Withdraw funds from the contract
   */
  function withdraw() external onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }

  ////////////////////
  // View Functions //
  ////////////////////

  function _baseURI() internal view virtual override returns (string memory) {
    return s_baseTokenURI;
  }

  function contractURI() external view returns (string memory) {
    return s_contractURI;
  }

  function isSaleEnabled() external view returns (bool) {
    return s_isSaleActive;
  }

  function getPrice() external view returns (uint256) {
    return s_price;
  }

  ///////////////////////
  // Royalty Functions //
  ///////////////////////

  function setDefaultRoyalty(
    address receiver,
    uint96 feeNumerator
  ) external onlyOwner {
    _setDefaultRoyalty(receiver, feeNumerator);
  }

  function deleteDefaultRoyalty() external onlyOwner {
    _deleteDefaultRoyalty();
  }

  function setTokenRoyalty(
    uint256 tokenId,
    address receiver,
    uint96 feeNumerator
  ) external onlyOwner {
    _setTokenRoyalty(tokenId, receiver, feeNumerator);
  }

  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override(ERC721A, ERC2981, IERC721A) returns (bool) {
    // Supports the following `interfaceId`s:
    // - IERC165: 0x01ffc9a7
    // - IERC721: 0x80ac58cd
    // - IERC721Metadata: 0x5b5e139f
    // - IERC2981: 0x2a55205a
    return
      ERC721A.supportsInterface(interfaceId) ||
      ERC2981.supportsInterface(interfaceId);
  }

  ///////////////////////
  // OpenSea Functions //
  ///////////////////////

  function owner()
    public
    view
    virtual
    override(Ownable, UpdatableOperatorFilterer)
    returns (address)
  {
    return Ownable.owner();
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
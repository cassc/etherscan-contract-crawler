// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "../contracts/libraries/erc721psi/contracts/ERC721Psi.sol";
import "../contracts/libraries/erc721psi/contracts/extension/ERC721PsiAddressData.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./libraries/ERC2981/ERC2981Base.sol";

import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

/*
 *   @title: Diverge

 *   @author: ahm3d.eth, ryado.eth
 *
 *       Built with ♥ by the ProductShop team
 *
 *                  -+=-.
 *                 .++++++=-.
 *                 +++++++++++=-.
 *                ++++++++++++++++=:.
 *               =++++++==++++++++++++=:.
 *              :++++++=   .:=++++++++++++-:.
 *             .+++++++        .-=++++++++++++-:
 *             +++++++.            .-=++++++++++
 *            =++++++:                 :=+++++++
 *           -++++++-                :-+++++++++
 *          :++++++=             .-=+++++++++++-
 *         .+++++++          .:=+++++++++++=:.
 *         +++++++.       :-++++++++++++-.
 *        =++++++:    .-=+++++++++++=:
 *       -++++++=    +++++++++++=:.
 *      :++++++=     ++++++++-.
 *     .+++++++      ++++=:
 *     =++++++.      --.
 *    =++++++-
 *   -++++++=
 *  .++++++=
 *  +++++++.
 *
 */

contract DIVERGENTS is
  ERC721PsiAddressData,
  ERC2981Base,
  AccessControl,
  DefaultOperatorFilterer
{
  constructor(
    string memory name,
    string memory symbol
  ) ERC721Psi(name, symbol) {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(ADMIN_ROLE, msg.sender);
  }

  using Strings for uint256;

  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

  string public __baseURI = "";
  string public _UriExtension = ".json";
  string public _contractMetadata =
    "https://diverge-productshop.s3.amazonaws.com/ordinal-mint/contract-metadata.json";

  uint256 public _mintPrice = 0.321 ether; // Mint price
  uint256 public _maxSupply = 123; // Maximum number of NFTs available for sale
  uint256 public _maxMintPerWallet = 10; // Maximum number of mints per wallet

  address public _revenueShareAddress =
    0x7A380C84601Bd5C2c432000921950014D2877E90; // Address of the wallet that receives the revevenue share
  uint256 public _payoutPercentage = 15; // Percentage of the revenue share

  bool public _isMintActive = false;
  bool public _paused = true;

  RoyaltyInfo public _royalties;

  // modifiers
  modifier onlyAdmin() {
    require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an Admin");
    _;
  }

  modifier noContractCaller() {
    require(tx.origin == msg.sender, "Caller is another contract");
    _;
  }

  modifier isNotPaused() {
    require(!_paused, "The contract is paused");
    _;
  }

  modifier mintSupplyCompliant(uint256 quantity) {
    require(quantity != 0, "Quantity must be greater than 0");

    require(
      _totalMinted() + quantity < _maxSupply + 1,
      "Mint quantity is restricted by token max supply"
    );
    _;
  }

  // External functions

  /**
   * * Mint
   * @dev Minting function for tokens available during the public phase
   * @param quantity The number of tokens being minted by sender
   */
  function mint(
    uint256 quantity
  ) external payable isNotPaused mintSupplyCompliant(quantity) {
    require(_isMintActive, "The mint phase is not active");
    require(
      quantity < _maxMintPerWallet + 1,
      "Quantity must be less or equal to max public mint quantity"
    );
    require(msg.value == quantity * _mintPrice, "Incorrect Payment");
    require(
      numberMinted(_msgSender()) + quantity < _maxMintPerWallet + 1,
      "Quantity must be less or equal to max public mint per wallet"
    );

    payable(_revenueShareAddress).transfer(
      (msg.value * _payoutPercentage) / 100
    );

    _safeMint(msg.sender, quantity);
  }

  function mintOnBehalf(
    uint256 quantity,
    address beneficiary
  ) external mintSupplyCompliant(quantity) onlyAdmin {
    _mint(beneficiary, quantity);
  }

  function tokenURI(
    uint256 tokenId
  ) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Psi: URI query for nonexistent token");

    string memory baseURI = _baseURI();
    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString(), _UriExtension))
        : "";
  }

  function royaltyInfo(
    uint256,
    uint256 value
  ) external view override returns (address receiver, uint256 royaltyAmount) {
    RoyaltyInfo memory royalties = _royalties;
    receiver = royalties.recipient;
    royaltyAmount = (value * royalties.amount) / 10000;
  }

  function numberMinted(address user) public view returns (uint256) {
    return _addressData[user].numberMinted;
  }

  function setApprovalForAll(
    address operator,
    bool approved
  ) public override onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(
    address operator,
    uint256 tokenId
  ) public override onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  function claimOrdinals(uint256[] calldata tokenIds) public {
    require(
      tokenIds.length < _maxSupply + 1,
      "Requested claim amount is too high"
    );
    for (uint i = 0; i < tokenIds.length; i++) {
      claimOrdinal(tokenIds[i]);
    }
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

  //  Setters

  /**
   * @dev Sets token royalties
   * @param recipient recipient of the royalties
   * @param value percentage (using 2 decimals : 10000 = 100%, 0 = 0%)
   */

  function setRoyalties(address recipient, uint256 value) external onlyAdmin {
    require(value <= 10000, "ERC2981Royalties: Too high");
    _royalties = RoyaltyInfo(recipient, uint24(value));
  }

  function setMintPrice(uint256 value) external onlyAdmin {
    _mintPrice = value;
  }

  function setMaxMintPerWallet(uint256 value) external onlyAdmin {
    _maxMintPerWallet = value;
  }

  function setUriExtension(string calldata extension) external onlyAdmin {
    _UriExtension = extension;
  }

  function setMintActive(bool value) external onlyAdmin {
    _isMintActive = value;
  }

  function grantAdminRole(address user) external onlyAdmin {
    grantRole(ADMIN_ROLE, user);
  }

  function withdraw() external onlyAdmin {
    payable(msg.sender).transfer(address(this).balance);
  }

  function setPaused(bool paused) external onlyAdmin {
    _paused = paused;
  }

  function setBaseURI(string calldata baseURI) external onlyAdmin {
    __baseURI = baseURI;
  }

  function setContractMetadata(
    string calldata contractMetadata
  ) external onlyAdmin {
    _contractMetadata = contractMetadata;
  }

  /**
   * @dev Set the quantity minted value for a user, for testing mostly
   * @param user address of the user to set the quantity minted
   * @param quantity uint128 quantity minted value
   */
  function setQuantityMinted(address user, uint64 quantity) external onlyAdmin {
    _addressData[user].numberMinted = quantity;
  }

  function setMaxSupply(uint256 maxSupply) external onlyAdmin {
    _maxSupply = maxSupply;
  }

  // Public functions

  function contractURI() public view returns (string memory) {
    return _contractMetadata;
  }

  function supportsInterface(
    bytes4 interfaceId
  )
    public
    view
    virtual
    override(ERC721Psi, ERC2981Base, AccessControl)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  // Internal functions

  function _baseURI() internal view override returns (string memory) {
    return __baseURI;
  }

  // Private functions

  function claimOrdinal(uint256 tokenId) private {
    require(_exists(tokenId), "ERC721Psi: This token does not exist");
    require(
      ownerOf(tokenId) == msg.sender,
      "Caller does not own the requested token"
    );

    transferFrom(msg.sender, address(this), tokenId);
  }
}
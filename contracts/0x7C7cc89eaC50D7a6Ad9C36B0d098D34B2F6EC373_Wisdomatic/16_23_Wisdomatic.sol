// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "erc721psi/contracts/ERC721Psi.sol";
import "erc721psi/contracts/extension/ERC721PsiAddressData.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./libraries/ERC2981/ERC2981Base.sol";

import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

/*
 *   @title: Wisdomatic

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

contract Wisdomatic is
  ERC721PsiAddressData,
  ERC2981Base,
  AccessControl,
  DefaultOperatorFilterer
{
  constructor(
    address couponSigner,
    string memory name,
    string memory symbol
  ) ERC721Psi(name, symbol) {
    _couponSigner = couponSigner;
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(ADMIN_ROLE, msg.sender);
  }

  using Strings for uint256;

  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

  address public _couponSigner; // Address of the wallet that generates the coupons
  address public crossmintAddress = 0xdAb1a1854214684acE522439684a145E62505233; // Address of the crossmint contract

  string public __baseURI = "";
  string public _contractMetadata = "";

  uint256 public _presaleMintPrice = 0.065 ether; // Presale mint price is free
  uint256 public _publicMintPrice = 0.07 ether; // Public mint price
  uint256 public _maxSupply = 8888; // Maximum number of NFTs available for sale
  uint256 public _maxMintPerWallet = 10; // Maximum number of mints per wallet

  bool public _paused = true;
  bool public _presaleMintActive = false;
  bool public _publicMintActive = false;

  RoyaltyInfo public _royalties;

  struct Coupon {
    bytes32 r;
    bytes32 s;
    uint8 v;
  }
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
   * * Public Mint
   * @dev Minting function for tokens available during the public phase
   * @param quantity The number of tokens being minted by sender
   */
  function publicMint(
    uint256 quantity
  ) external payable isNotPaused mintSupplyCompliant(quantity) {
    require(_publicMintActive, "Public mint phase is not active");
    require(
      quantity < _maxMintPerWallet + 1,
      "Quantity must be less or equal to max public mint quantity"
    );
    require(msg.value == quantity * _publicMintPrice, "Incorrect Payment");
    require(
      numberMinted(_msgSender()) + quantity < _maxMintPerWallet + 1,
      "Quantity must be less or equal to max public mint per wallet"
    );

    _safeMint(msg.sender, quantity);
  }

  /**
   * * Presale Mint
   * @dev Minting function for tokens available during the Presale phase
   * @notice Minting Presale tokens requires a valid coupon, associated with wallet and allotted amount
   * @param quantity The number of tokens being minted by sender
   * @param allotted The allotted number of tokens specified in the Presale Coupon
   * @param coupon The signed coupon
   */
  function presaleMint(
    uint256 allotted,
    Coupon calldata coupon,
    uint256 quantity
  )
    external
    payable
    noContractCaller
    isNotPaused
    mintSupplyCompliant(quantity)
  {
    require(_presaleMintActive, "Presale mint phase is not active");

    require(
      quantity < allotted + 1,
      "Quantity must be less or equal to allotted"
    );

    require(numberMinted(_msgSender()) == 0, "Coupon already used");

    bytes32 digest = keccak256(abi.encode(allotted, _msgSender()));

    require(_isVerifiedCoupon(digest, coupon), "Invalid Coupon");

    _safeMint(msg.sender, quantity);
  }

  function crossMintPresale(
    uint256 allotted,
    Coupon calldata coupon,
    uint256 quantity,
    address _to
  ) public payable isNotPaused mintSupplyCompliant(quantity) {
    require(_presaleMintPrice == msg.value, "Incorrect value sent");
    require(
      msg.sender == crossmintAddress,
      "This function is for Crossmint only."
    );

    require(_presaleMintActive, "Presale mint phase is not active");

    require(
      quantity < allotted + 1,
      "Quantity must be less or equal to allotted"
    );

    require(numberMinted(_to) == 0, "Coupon already used");

    bytes32 digest = keccak256(abi.encode(allotted, _to));

    require(_isVerifiedCoupon(digest, coupon), "Invalid Coupon");

    _safeMint(_to, quantity);
  }

  function crossMintPublic(
    uint256 quantity,
    address _to
  ) public payable isNotPaused mintSupplyCompliant(quantity) {
    require(_publicMintPrice == msg.value, "Incorrect value sent");
    require(
      msg.sender == crossmintAddress,
      "This function is for Crossmint only."
    );

    require(_publicMintActive, "Presale mint phase is not active");

    require(
      (numberMinted(_to) + quantity) < _maxMintPerWallet + 1,
      "Coupon already used"
    );

    _safeMint(_to, quantity);
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
        ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
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

  function setCrossmintAddress(address _crossmintAddress) public onlyAdmin {
    crossmintAddress = _crossmintAddress;
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

  function setPublicMintActive(bool active) external onlyAdmin {
    _publicMintActive = active;
  }

  function setPresaleMintActive(bool active) external onlyAdmin {
    _presaleMintActive = active;
  }

  function setPublicMintPrice(uint256 value) external onlyAdmin {
    _publicMintPrice = value;
  }

  function setPresaleMintPrice(uint256 value) external onlyAdmin {
    _presaleMintPrice = value;
  }

  function setMaxMintPerWallet(uint256 value) external onlyAdmin {
    _maxMintPerWallet = value;
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

  function setCouponSigner(address newCouponSigner) external onlyAdmin {
    _couponSigner = newCouponSigner;
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

  /**
   * * Verify Coupon
   * @dev Verify that the coupon sent was signed by the coupon signer and is a valid coupon
   * @notice Valid coupons will include coupon signer, address, and allotted mints
   * @notice Returns a boolean value
   * @param digest The digest
   * @param coupon The coupon
   */
  function _isVerifiedCoupon(
    bytes32 digest,
    Coupon calldata coupon
  ) private view returns (bool) {
    address signer = ecrecover(digest, coupon.v, coupon.r, coupon.s);
    require(signer != address(0), "Zero Address");
    return signer == _couponSigner;
  }
}
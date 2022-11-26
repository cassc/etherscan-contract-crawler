// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./libraries/ERC1155/ERC1155PS.sol";
import "./libraries/ERC2981/ERC2981Base.sol";

/*
 *   @title: Diverge

 *  @author: ahm3d.eth, ryado.eth
 *
 *      Built with ♥ by the ProductShop team
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

contract Diverge is ERC1155PS, ERC2981Base, AccessControl {
  using Strings for uint256;

  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
  address public _couponSigner; // Address of the wallet that generates the coupons

  string public _baseURI = "";
  string public _contractMetadata = "";

  uint256 public _currentTokenTypeID = 0; // Used to keep track of the number of different NFTs
  uint256 public _mintPrice = 0 ether; // Presale mint price is free
  uint256 public _maxPublicMintPerTx = 4; // Maximum number of NFTs that can be minted at once

  mapping(uint256 => uint256) public _tokenSupply;
  mapping(uint256 => uint256) public _tokenMaxSupply;

  bool public _paused = true;
  bool public _presaleMintActive = false;
  bool public _publicMintActive = false;

  RoyaltyInfo public _royalties;

  struct Coupon {
    bytes32 r;
    bytes32 s;
    uint8 v;
  }

  constructor(address couponSigner) ERC1155PS("") {
    _couponSigner = couponSigner;
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(ADMIN_ROLE, msg.sender);
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

  modifier tokenTypeExists(uint256 tokenId) {
    require(_tokenMaxSupply[tokenId] > 0, "Token does not exist");
    _;
  }

  modifier mintSupplyCompliant(uint256 tokenId, uint256 quantity) {
    require(quantity != 0, "Quantity must be greater than 0");

    require(
      _tokenSupply[tokenId] + quantity <= _tokenMaxSupply[tokenId],
      "Mint quantity is restricted by token max supply"
    );
    _;
  }

  // External functions

  /**
   * * Mint Presale Tokens
   * @dev Minting function for tokens available during the Presale phase
   * @notice Minting Presale tokens requires a valid coupon, associated with wallet and allotted amount
   * @param typeId The typeId of the token being minted
   * @param quantity The number of tokens being minted by sender
   * @param allotted The allotted number of tokens specified in the Presale Coupon
   * @param coupon The signed coupon
   */
  function presaleMint(
    uint256 typeId,
    uint256 allotted,
    Coupon calldata coupon,
    uint256 quantity
  )
    external
    noContractCaller
    isNotPaused
    tokenTypeExists(typeId)
    mintSupplyCompliant(typeId, quantity)
  {
    require(_presaleMintActive, "Presale mint phase is not active");

    require(
      quantity < allotted + 1,
      "Quantity must be less or equal to allotted"
    );

    require(quantityMinted(typeId, _msgSender()) == 0, "Coupon already used");

    bytes32 digest = keccak256(abi.encode(allotted, _msgSender()));

    require(_isVerifiedCoupon(digest, coupon), "Invalid Coupon");

    _tokenSupply[typeId] = _tokenSupply[typeId] + quantity;
    _mint(msg.sender, typeId, quantity);
  }

  /**
   * * Mint Presale Tokens
   * @dev Minting function for tokens available during the Presale phase
   * @notice Initial public mint will be free but subsequent mints will be at the setted mint price
   * @param typeId The typeId of the token being minted
   * @param quantity The number of tokens being minted by sender
   */
  function mint(
    uint256 typeId,
    uint256 quantity
  )
    public
    payable
    isNotPaused
    tokenTypeExists(typeId)
    mintSupplyCompliant(typeId, quantity)
  {
    require(_publicMintActive, "Public mint phase is not active");
    require(
      quantity < _maxPublicMintPerTx + 1,
      "Quantity must be less or equal to max public mint quantity"
    );
    require(msg.value == quantity * _mintPrice, "Incorrect Payment");

    _tokenSupply[typeId] = _tokenSupply[typeId] + quantity;
    _mint(msg.sender, typeId, quantity);
  }

  function mintOnBehalf(
    uint256 typeId,
    uint256 quantity,
    address beneficiary
  )
    public
    tokenTypeExists(typeId)
    mintSupplyCompliant(typeId, quantity)
    onlyAdmin
  {
    _tokenSupply[typeId] = _tokenSupply[typeId] + quantity;
    _mint(beneficiary, typeId, quantity);
  }

  /**
   * @dev Creates a new token type
   * @return The newly created token ID
   */
  function create(uint256 maxSupply) external onlyAdmin returns (uint256) {
    uint256 _id = _getNextTokenTypeID();
    _incrementTokenTypeId();
    _tokenMaxSupply[_id] = maxSupply;
    return _id;
  }

  function royaltyInfo(
    uint256,
    uint256 value
  ) external view override returns (address receiver, uint256 royaltyAmount) {
    RoyaltyInfo memory royalties = _royalties;
    receiver = royalties.recipient;
    royaltyAmount = (value * royalties.amount) / 10000;
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

  function setMintPrice(uint256 value) external onlyAdmin {
    _mintPrice = value;
  }

  function setMaxPublicMintPerTx(uint256 value) external onlyAdmin {
    _maxPublicMintPerTx = value;
  }

  function grantAdminRole(address user) external onlyAdmin {
    grantRole(ADMIN_ROLE, user);
  }

  function setPaused(bool paused) external onlyAdmin {
    _paused = paused;
  }

  function setBaseURI(string calldata baseURI) external onlyAdmin {
    _baseURI = baseURI;
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
   * @param typeId uint256 ID of the token type
   * @param user address of the user to set the quantity minted
   * @param quantiy uint128 quantity minted value
   */
  function setQuantityMinted(
    uint256 typeId,
    address user,
    uint128 quantiy
  ) external onlyAdmin {
    _setQuantityMinted(typeId, user, quantiy);
  }

  function setTokenMaxSupply(
    uint256 typeId,
    uint256 maxSupply
  ) external onlyAdmin {
    _tokenMaxSupply[typeId] = maxSupply;
  }

  function withdraw() external onlyAdmin {
    payable(msg.sender).transfer(address(this).balance);
  }

  // Public functions

  function uri(
    uint256 typeId
  ) public view override tokenTypeExists(typeId) returns (string memory) {
    return string(abi.encodePacked(_baseURI, typeId.toString(), ".json"));
  }

  /**
   * @dev Returns the total quantity for a type of token
   * @param typeId uint256 ID of the token type to query
   * @return amount of token of type typeId in existence
   */
  function totalSupply(uint256 typeId) public view returns (uint256) {
    return _tokenSupply[typeId];
  }

  function contractURI() public view returns (string memory) {
    return _contractMetadata;
  }

  function supportsInterface(
    bytes4 interfaceId
  )
    public
    view
    virtual
    override(ERC1155PS, ERC2981Base, AccessControl)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  // Internal functions

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

  // Private functions

  /**
   * @dev calculates the next token ID based on value of _currentTokenID
   * @return uint256 for the next token ID
   */
  function _getNextTokenTypeID() private view returns (uint256) {
    return _currentTokenTypeID + 1;
  }

  /**
   * @dev increments the value of _currentTokenID
   */
  function _incrementTokenTypeId() private {
    ++_currentTokenTypeID;
  }
}
// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./libraries/ERC1155/ERC1155D.sol";
import "./libraries/ERC2981/ERC2981Base.sol";

import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

/*
 *   @title: Divex

 *  @author: ahm3d.eth, ryado.eth
 *
 *        Built with ♥ by the ProductShop team
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

contract DivergeS1GlossyUnderground is
  ERC1155D,
  ERC2981Base,
  AccessControl,
  DefaultOperatorFilterer
{
  using Strings for uint256;

  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
  address public _couponSigner;
  address public _revenueShareAddress =
    0x7A380C84601Bd5C2c432000921950014D2877E90; // Address of the wallet that receives the revevenue share
  uint256 public _payoutPercentage = 15; // Percentage of the revenue share

  mapping(address => uint256) public _amountMintedSoFar;

  string public _baseURI = "";
  string public _contractMetadata = "";

  uint256 public _mintPrice = 0.00888 ether;
  uint256 public _supply;

  bool public _paused = true;
  bool public _mintActive = false;

  RoyaltyInfo public _royalties;

  struct Coupon {
    bytes32 r;
    bytes32 s;
    uint8 v;
  }

  constructor(address couponSigner) ERC1155D("") {
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

  function mint(
    uint256 allotted,
    uint256 quantityMinted,
    Coupon calldata coupon,
    uint256 quantityToMint
  ) public payable isNotPaused {
    require(_mintActive, "Public mint phase is not active");

    uint256 mintedSoFar = _amountMintedSoFar[msg.sender];

    require(
      quantityToMint + mintedSoFar < allotted + 1,
      "Quantity exceeds allotted amount"
    );

    uint256 freeMintLeft = availableFreeMint(mintedSoFar, allotted);

    uint256 finalMintPrice;

    if (freeMintLeft < quantityToMint) {
      finalMintPrice = (quantityToMint - freeMintLeft) * _mintPrice;
    } else {
      finalMintPrice = 0;
    }

    require(msg.value == finalMintPrice, "Incorrect Payment");

    payable(_revenueShareAddress).transfer(
      (msg.value * _payoutPercentage) / 100
    );

    bytes32 digest = keccak256(
      abi.encode(allotted, quantityMinted, _msgSender())
    );

    require(_isVerifiedCoupon(digest, coupon), "Invalid Coupon");

    for (uint256 i = 0; i < quantityToMint; i++) {
      _mint(msg.sender, _supply, 1, "");
      _supply++;
    }
    _amountMintedSoFar[msg.sender] = mintedSoFar + quantityToMint;
  }

  function mintOnBehalf(
    uint256 quantityToMint,
    address beneficiary
  ) public onlyAdmin {
    for (uint256 i = 0; i < quantityToMint; i++) {
      _mint(beneficiary, _supply, 1, "");
      _supply++;
    }
  }

  function royaltyInfo(
    uint256,
    uint256 value
  ) external view override returns (address receiver, uint256 royaltyAmount) {
    RoyaltyInfo memory royalties = _royalties;
    receiver = royalties.recipient;
    royaltyAmount = (value * royalties.amount) / 10000;
  }

  /**
   * @dev Sets token royalties
   * @param recipient recipient of the royalties
   * @param value percentage (using 2 decimals : 10000 = 100%, 0 = 0%)
   */

  function setRoyalties(address recipient, uint256 value) external onlyAdmin {
    require(value <= 10000, "ERC2981Royalties: Too high");
    _royalties = RoyaltyInfo(recipient, uint24(value));
  }

  function setMintActive(bool active) external onlyAdmin {
    _mintActive = active;
  }

  function setMintPrice(uint256 value) external onlyAdmin {
    _mintPrice = value;
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

  function setAmountMinted(address user, uint128 quantiy) external onlyAdmin {
    _amountMintedSoFar[user] = quantiy;
  }

  function withdraw() external onlyAdmin {
    payable(msg.sender).transfer(address(this).balance);
  }

  // Public functions

  function uri(uint256 typeId) public view override returns (string memory) {
    return string(abi.encodePacked(_baseURI, typeId.toString(), ".json"));
  }

  function totalSupply() public view returns (uint256) {
    return _supply;
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
    override(ERC1155D, ERC2981Base, AccessControl)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

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

  function availableFreeMint(
    uint256 quantityMinted,
    uint256 allotted
  ) private pure returns (uint256) {
    uint256 freeMintLeft = 0;
    uint256 freeMint = (allotted / 3);

    if (quantityMinted < freeMint + 1) {
      freeMintLeft = freeMint - quantityMinted;
    }
    return freeMintLeft;
  }

  function setApprovalForAll(
    address operator,
    bool approved
  ) public override onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    uint256 amount,
    bytes memory data
  ) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, amount, data);
  }

  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) public virtual override onlyAllowedOperator(from) {
    super.safeBatchTransferFrom(from, to, ids, amounts, data);
  }
}
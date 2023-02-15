// contracts/SnailTravelers.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract SnailTravelers is Initializable, ERC721Upgradeable {
  /*//////////////////////////////////////////////////////////////
                    ERC721 BALANCE/OWNER STORAGE
  //////////////////////////////////////////////////////////////*/
  uint256 public mintPrice;
  uint256 public totalSupply;
  uint256 public maxSupply;

  SalePhase public phase;
  string internal baseTokenUri;
  address private _adminSigner;
  address payable private _owner;
  address payable private _rewards;

  uint256 public rewardFee;

  uint256 public breedPrice;
  uint256 public breedFee;
  mapping(address => uint256) private addressToPreSaleMints;

  enum SalePhase {
    Closed,
    PreSale,
    PublicSale
  }

  // NEW VARIABLES MUST BE ADDED BELLOW EXISTING ONE

  /*//////////////////////////////////////////////////////////////
                                EVENTS
  //////////////////////////////////////////////////////////////*/

  event Minted(address indexed owner, uint256 id, uint256 indexed blockNumber);

  event Breeded(
    address indexed owner,
    uint256 id,
    uint256 price,
    address indexed parent1,
    address indexed parent2,
    uint256 parent1Percentage,
    uint256 parent2Percentage
  );

  /*//////////////////////////////////////////////////////////////
                  CONSTRUCTOR & MODIFIERS
  //////////////////////////////////////////////////////////////*/

  function initialize(
    address adminSigner,
    address payable owner,
    address payable rewards
  ) public initializer {
    __ERC721_init("SnailTravelers", "SNLT");
    _adminSigner = adminSigner;
    _owner = owner;
    _rewards = rewards;
    mintPrice = 0.2 ether;
    totalSupply = 0;
    maxSupply = 150;
    rewardFee = 10;
    breedFee = 10;
    breedPrice = 0.3 ether;
  }

  modifier ensureAvailabilityFor(uint256 count) {
    require(count + totalSupply <= maxSupply, "SOLD_OUT");
    _;
  }

  modifier validateEthPayment(uint256 count, uint256 price) {
    require(count * price == msg.value, "WRONG_AMOUNT_PAYED");
    _;
  }

  modifier onlyOwner() {
    require(_owner == msg.sender, "NOT_OWNER");
    _;
  }

  /*//////////////////////////////////////////////////////////////
                        COUPONS
  //////////////////////////////////////////////////////////////*/

  struct Coupon {
    bytes32 r;
    bytes32 s;
    uint8 v;
  }

  enum CouponType {
    PreSale,
    BreedSale
  }

  function _isVerifiedCoupon(
    bytes32 digest,
    Coupon memory coupon
  ) internal view returns (bool) {
    address signer = ecrecover(digest, coupon.v, coupon.r, coupon.s);
    require(signer != address(0), "ECDSA: invalid signature");

    return signer == _adminSigner;
  }

  /*//////////////////////////////////////////////////////////////
                        MINT LOGIC
  //////////////////////////////////////////////////////////////*/

  function safeMint(address sender_) internal returns (uint256) {
    uint256 newTokenId = totalSupply + 1;
    totalSupply++;
    _safeMint(sender_, newTokenId);

    return newTokenId;
  }

  function mintFromPublicSale()
    external
    payable
    ensureAvailabilityFor(1)
    validateEthPayment(1, mintPrice)
  {
    require(phase == SalePhase.PublicSale, "PUBLIC_SALE_CLOSED");

    uint256 tokenId = safeMint(msg.sender);
    emit Minted(msg.sender, tokenId, block.number);

    withdraw();
  }

  function mintFromPreSale(
    uint256 allotted,
    Coupon memory coupon
  ) external payable ensureAvailabilityFor(1) validateEthPayment(1, mintPrice) {
    require(phase == SalePhase.PreSale, "PRE_SALE_CLOSED");
    require(1 + addressToPreSaleMints[msg.sender] <= allotted, "MAX_REACHED");

    bytes32 digest = keccak256(
      abi.encode(CouponType.PreSale, allotted, msg.sender)
    );
    require(_isVerifiedCoupon(digest, coupon), "INVALID_COUPON");

    addressToPreSaleMints[msg.sender] += 1;
    uint256 tokenId = safeMint(msg.sender);
    emit Minted(msg.sender, tokenId, block.number);

    withdraw();
  }

  function mintFromBreedSale(
    Coupon memory coupon,
    uint256 price,
    address payable parent1,
    address payable parent2,
    uint256 parent1Percentage,
    uint256 parent2Percentage
  ) external payable validateEthPayment(1, price) {
    bytes32 digest = keccak256(
      abi.encode(
        CouponType.BreedSale,
        price,
        parent1,
        parent2,
        parent1Percentage,
        parent2Percentage
      )
    );
    require(_isVerifiedCoupon(digest, coupon), "INVALID_COUPON");

    uint256 newTokenId = safeMint(msg.sender);

    emit Breeded(
      msg.sender,
      newTokenId,
      price,
      parent1,
      parent2,
      parent1Percentage,
      parent2Percentage
    );

    uint256 parent1Cut = (breedPrice * parent1Percentage) / 100;
    uint256 parent2Cut = (breedPrice * parent2Percentage) / 100;
    uint256 teamCut = (breedPrice * breedFee) / 100;

    parent1.transfer(parent1Cut);
    parent2.transfer(parent2Cut);
    _owner.transfer(teamCut);
  }

  /*//////////////////////////////////////////////////////////////
                        BRUN LOGIC
  //////////////////////////////////////////////////////////////*/

  function burn(uint256 tokenId) external {
    _burn(tokenId);
  }

  /*//////////////////////////////////////////////////////////////
                        ADMIN LOGIC
  //////////////////////////////////////////////////////////////*/

  function setPhase(SalePhase phase_) external onlyOwner {
    phase = phase_;
  }

  function setBaseTokenUri(string calldata baseTokenUri_) external onlyOwner {
    baseTokenUri = baseTokenUri_;
  }

  function setMaxSupply(uint256 maxSupply_) external onlyOwner {
    maxSupply = maxSupply_;
  }

  function setMintPrice(uint256 mintPrice_) external onlyOwner {
    mintPrice = mintPrice_;
  }

  function setAdminSigner(address adminSigner_) external onlyOwner {
    _adminSigner = adminSigner_;
  }

  function setBreedPrice(uint256 breedPrice_) external onlyOwner {
    breedPrice = breedPrice_;
  }

  function setBreedFee(uint256 breedFee_) external onlyOwner {
    breedFee = breedFee_;
  }

  function setRewardFee(uint256 rewardFee_) external onlyOwner {
    require(rewardFee_ <= 100 && rewardFee_ >= 0, "FEE_OUT_OF_RANGE");
    rewardFee = rewardFee_;
  }

  function withdraw() internal {
    uint256 balance = address(this).balance;

    uint256 teamPercentage = 100 - rewardFee;

    _owner.transfer((balance * teamPercentage) / 100);
    _rewards.transfer((balance * rewardFee) / 100);
  }
}
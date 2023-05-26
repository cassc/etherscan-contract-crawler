// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract VoxelVilleAvatars is ERC721, Ownable {
  using Counters for Counters.Counter;

  struct Coupon {
    bytes32 r;
    bytes32 s;
    uint8 v;
  }
  enum CouponType {
    Collector,
    Holder,
    NonHolder
  }
  enum SalePhase {
    Locked,
    Collectors,
    Holders,
    NonHolders
  }

  

  SalePhase private _currentPhase = SalePhase.Locked;

  Counters.Counter private _tokenIdCounter;
  address private _adminSigner;
  address private _voxelVilleContract;
  string private _tokenUri;

  uint256 public constant MAX_SUPPLY = 9999;

  uint256 public constant PRICE = 0.05 ether;

  string public baseURI;

  uint256 public totalSupplyRemaining = MAX_SUPPLY;

  IERC721 private _legacyContract;


  mapping(address => bool) public allowList;
  mapping(address => uint256) public numberMinted;
  mapping(address => uint256) public airdroppedTokens;

  event BaseURI(string baseURI);

  event CurrentPhase(SalePhase salePhase);
  
  event TotalSupplyRemaining(uint256 totalSupply);

  constructor(address _adminSignerAddress, address _voxelVilleContractAddress, address _retiredContract) ERC721("Voxel Ville Avatars", "VVA") {
    _adminSigner = _adminSignerAddress;
    _legacyContract = IERC721(_retiredContract);
    _voxelVilleContract = _voxelVilleContractAddress;
    _tokenIdCounter.increment();
  }

  function transferLegacyNFTs(uint256 from, uint256 to) public onlyOwner {
    
    for (uint256 ind = from; ind <= to; ind++) {
      address owner = _legacyContract.ownerOf(ind);
      bool airdropped = ind == 480 || ind == 481;
      safeMint(owner,airdropped);
    }
  }

  function setSalePhase(SalePhase salePhase) public onlyOwner {
    _currentPhase = salePhase;
    
    emit CurrentPhase(_currentPhase);
  }

  function getCurrentPhase() public view returns (SalePhase) {
    return _currentPhase;
  }

  function _getMaxMints(CouponType couponType) private view returns (uint256) {
    if (couponType == CouponType.NonHolder) {
      return 3;
    }
    uint256 balance = IERC721Enumerable(_voxelVilleContract).balanceOf(msg.sender);
    if (couponType == CouponType.Holder && balance + 3 > 10) {
      return 10;
    }
    if (couponType == CouponType.Collector && balance + 3 > 20) {
      return 20;
    }
    return balance + 3;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function safeMint(address to) private {
    safeMint(to, false);
  }

  function safeMint(address to, bool airdropped) private {
    uint256 tokenId = _tokenIdCounter.current();
    _tokenIdCounter.increment();
    _safeMint(to, tokenId);
    totalSupplyRemaining--;
    if (airdropped) {
      airdroppedTokens[to]++;
    } else {
      numberMinted[to]++;
    }
  }

  modifier isMintable(CouponType couponType) {
    if (_currentPhase == SalePhase.Locked) {
      require(false, "Voxel Ville Avatars: Cannot mint during locked phase");
    }
    require(
      (_currentPhase == SalePhase.Collectors && couponType == CouponType.Collector)
        || (_currentPhase == SalePhase.Holders && (couponType == CouponType.Collector || couponType == CouponType.Holder))
        || _currentPhase == SalePhase.NonHolders, 
      "Voxel Ville Avatars: This Coupon is not allowed to mint during the current phase"
    );
    _;
  }

  modifier isNotExceedingMaxMint(Coupon memory coupon, CouponType couponType, uint256 count) {
    uint256 max = _getMaxMints(couponType);
    require(count + numberMinted[msg.sender] <= max, "Voxel Ville Avatars: Cannot mint more than maximum allowed");
    _;
  }

  modifier isValidMintingCoupon(Coupon memory coupon, CouponType couponType) {
    bytes32 digest = keccak256(
      abi.encode(couponType, msg.sender)
    );
    require(_isVerifiedCoupon(digest, coupon), "Voxel Ville Avatars: Invalid Coupon");
    _;
  }

  modifier isNotExceedingAvailableSupply(uint256 count) {
    require(count <= totalSupplyRemaining, "Voxel Ville Avatars: Cannot exceed maximum avatars!");
    _;
  }

  modifier isPaymentSufficient(uint256 amount) {
    require(
      msg.value == amount * PRICE,
      "Voxel Ville Avatars: There was not enough/extra ETH transferred to mint an NFT."
    );
    _;
  }

  function mint(Coupon memory coupon, CouponType couponType, uint256 amount)
  public
  payable
  isValidMintingCoupon(coupon, couponType)
  isMintable(couponType)
  isNotExceedingMaxMint(coupon, couponType, amount)
  isNotExceedingAvailableSupply(amount)
  isPaymentSufficient(amount)
  {
    for (uint8 index = 0; index < amount; index++) {
      safeMint(msg.sender, false);
    }
    
    emit TotalSupplyRemaining(totalSupplyRemaining);
  }

  function airdropMint(address to, Coupon memory coupon, uint8 allocated, uint8 count) public {
    bytes32 digest = keccak256(
      abi.encode(CouponType.Collector, allocated, to)
    );
    require(_isVerifiedCoupon(digest, coupon), "Voxel Ville Avatars: Invalid Coupon");
    require(airdroppedTokens[to] + count <= allocated, 'Voxel Ville Avatars: Cannot exceed max airdrops permitted by this Coupon');
    for (uint8 index = 0; index < count; index++) {
      safeMint(to, true);
    }
    
    emit TotalSupplyRemaining(totalSupplyRemaining);
  }

/// @dev check that the coupon sent was signed by the admin signer
  function _isVerifiedCoupon(bytes32 digest, Coupon memory coupon)
    internal
    view
    returns (bool)
  {
    address signer = ecrecover(digest, coupon.v, coupon.r, coupon.s);
    require(signer != address(0), 'ECDSA: invalid signature');
    return signer == _adminSigner;
  }

  function setBaseURI(string memory _URI) public onlyOwner {
    baseURI = _URI;

    emit BaseURI(baseURI);
  }

  function withdraw() external onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }

}
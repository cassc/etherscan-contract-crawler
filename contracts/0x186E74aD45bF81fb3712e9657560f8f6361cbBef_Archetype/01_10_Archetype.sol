// SPDX-License-Identifier: MIT
// Archetype v0.3.1
//
//        d8888                 888               888
//       d88888                 888               888
//      d88P888                 888               888
//     d88P 888 888d888 .d8888b 88888b.   .d88b.  888888 888  888 88888b.   .d88b.
//    d88P  888 888P"  d88P"    888 "88b d8P  Y8b 888    888  888 888 "88b d8P  Y8b
//   d88P   888 888    888      888  888 88888888 888    888  888 888  888 88888888
//  d8888888888 888    Y88b.    888  888 Y8b.     Y88b.  Y88b 888 888 d88P Y8b.
// d88P     888 888     "Y8888P 888  888  "Y8888   "Y888  "Y88888 88888P"   "Y8888
//                                                            888 888
//                                                       Y8b d88P 888
//                                                        "Y88P"  888

pragma solidity ^0.8.4;

import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import "erc721a-upgradeable/contracts/ERC721A__Initializable.sol";
import "./ERC721A__OwnableUpgradeable.sol";
import "solady/src/utils/MerkleProofLib.sol";
import "solady/src/utils/LibString.sol";
import "solady/src/utils/ECDSA.sol";

error InvalidConfig();
error MintNotYetStarted();
error WalletUnauthorizedToMint();
error InsufficientEthSent();
error ExcessiveEthSent();
error MaxSupplyExceeded();
error NumberOfMintsExceeded();
error MintingPaused();
error InvalidReferral();
error InvalidSignature();
error BalanceEmpty();
error TransferFailed();
error MaxBatchSizeExceeded();
error NotTokenOwner();
error WrongPassword();
error LockedForever();

contract Archetype is ERC721A__Initializable, ERC721AUpgradeable, ERC721A__OwnableUpgradeable {
  //
  // EVENTS
  //
  event Invited(bytes32 indexed key, bytes32 indexed cid);
  event Referral(address indexed affiliate, uint128 wad, uint256 numMints);
  event Withdrawal(address indexed src, uint128 wad);

  //
  // STRUCTS
  //
  struct Auth {
    bytes32 key;
    bytes32[] proof;
  }

  struct MintTier {
    uint16 numMints;
    uint16 mintDiscount; //BPS
  }

  struct Discount {
    uint16 affiliateDiscount; //BPS
    MintTier[] mintTiers;
  }

  struct Config {
    string unrevealedUri;
    string baseUri;
    address affiliateSigner;
    address ownerAltPayout; // optional alternative address for owner withdrawals.
    address superAffiliatePayout; // optional super affiliate address, will receive half of platform fee if set.
    uint32 maxSupply;
    uint32 maxBatchSize;
    uint16 affiliateFee; //BPS
    uint16 platformFee; //BPS
    Discount discounts;
  }

  struct Invite {
    uint128 price;
    uint64 start;
    uint64 limit;
  }

  struct Invitelist {
    bytes32 key;
    bytes32 cid;
    Invite invite;
  }

  struct OwnerBalance {
    uint128 owner;
    uint128 platform;
  }

  //
  // VARIABLES
  //
  mapping(bytes32 => Invite) public invites;
  mapping(address => mapping(bytes32 => uint256)) private minted;
  mapping(address => uint128) public affiliateBalance;
  mapping(uint256 => bytes) public tokenMsg;
  address private constant PLATFORM = 0x86B82972282Dd22348374bC63fd21620F7ED847B;
  // address private constant PLATFORM = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC; // TEST (account[2])
  uint16 private constant MAXBPS = 5000; // max fee or discount is 50%
  bool public revealed;
  bool public uriUnlocked;
  bool public maxSupplyUnlocked;
  bool public affiliateFeeUnlocked;
  bool public discountsUnlocked;
  bool public ownerAltPayoutUnlocked;
  string public provenance;
  bool public provenanceHashUnlocked;
  OwnerBalance public ownerBalance;
  Config public config;

  //
  // METHODS
  //
  function initialize(
    string memory name,
    string memory symbol,
    Config calldata config_
  ) external initializerERC721A {
    __ERC721A_init(name, symbol);
    // check max bps not reached and min platform fee.
    if (
      config_.affiliateFee > MAXBPS ||
      config_.platformFee > MAXBPS ||
      config_.platformFee < 500 ||
      config_.discounts.affiliateDiscount > MAXBPS ||
      config_.affiliateSigner == address(0) ||
      config_.maxBatchSize == 0
    ) {
      revert InvalidConfig();
    }
    // ensure mint tiers are correctly ordered from highest to lowest.
    for (uint256 i = 1; i < config_.discounts.mintTiers.length; i++) {
      if (
        config_.discounts.mintTiers[i].mintDiscount > MAXBPS ||
        config_.discounts.mintTiers[i].numMints > config_.discounts.mintTiers[i - 1].numMints
      ) {
        revert InvalidConfig();
      }
    }
    config = config_;
    __Ownable_init();
    revealed = false;
    uriUnlocked = true;
    maxSupplyUnlocked = true;
    affiliateFeeUnlocked = true;
    discountsUnlocked = true;
    ownerAltPayoutUnlocked = true;
    provenanceHashUnlocked = true;
  }

  function mint(
    Auth calldata auth,
    uint256 quantity,
    address affiliate,
    bytes calldata signature
  ) external payable {
    Invite memory i = invites[auth.key];

    if (affiliate != address(0)) {
      if (affiliate == PLATFORM || affiliate == owner() || affiliate == msg.sender) {
        revert InvalidReferral();
      }
      validateAffiliate(affiliate, signature, config.affiliateSigner);
    }

    if (i.limit == 0) {
      revert MintingPaused();
    }

    if (!verify(auth, msg.sender)) {
      revert WalletUnauthorizedToMint();
    }

    if (block.timestamp < i.start) {
      revert MintNotYetStarted();
    }

    if (i.limit < config.maxSupply) {
      uint256 totalAfterMint = minted[msg.sender][auth.key] + quantity;

      if (totalAfterMint > i.limit) {
        revert NumberOfMintsExceeded();
      }
    }

    if (quantity > config.maxBatchSize) {
      revert MaxBatchSizeExceeded();
    }

    if ((_nextTokenId() + quantity) > config.maxSupply) {
      revert MaxSupplyExceeded();
    }

    uint256 cost = computePrice(i.price, quantity, affiliate != address(0));

    if (msg.value < cost) {
      revert InsufficientEthSent();
    }

    if (msg.value > cost) {
      revert ExcessiveEthSent();
    }

    _mint(msg.sender, quantity);

    if (i.limit < config.maxSupply) {
      minted[msg.sender][auth.key] += quantity;
    }

    uint128 value = uint128(msg.value);

    uint128 affiliateWad = 0;
    if (affiliate != address(0)) {
      affiliateWad = (value * config.affiliateFee) / 10000;
      affiliateBalance[affiliate] += affiliateWad;
      emit Referral(affiliate, affiliateWad, quantity);
    }

    uint128 superAffiliateWad = 0;
    if (config.superAffiliatePayout != address(0)) {
      superAffiliateWad = ((value * config.platformFee) / 2) / 10000;
      affiliateBalance[config.superAffiliatePayout] += superAffiliateWad;
    }

    OwnerBalance memory balance = ownerBalance;
    uint128 platformWad = ((value * config.platformFee) / 10000) - superAffiliateWad;
    uint128 ownerWad = value - affiliateWad - platformWad - superAffiliateWad;
    ownerBalance = OwnerBalance({
      owner: balance.owner + ownerWad,
      platform: balance.platform + platformWad
    });
  }

  // calculate price based on affiliate usage and mint discounts
  function computePrice(
    uint128 price,
    uint256 numTokens,
    bool affiliateUsed
  ) public view returns (uint256) {
    uint256 cost = price * numTokens;

    if (affiliateUsed) {
      cost = cost - ((cost * config.discounts.affiliateDiscount) / 10000);
    }

    for (uint256 i = 0; i < config.discounts.mintTiers.length; i++) {
      if (numTokens >= config.discounts.mintTiers[i].numMints) {
        return cost = cost - ((cost * config.discounts.mintTiers[i].mintDiscount) / 10000);
      }
    }
    return cost;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

    if (revealed == false) {
      return string(abi.encodePacked(config.unrevealedUri, LibString.toString(tokenId)));
    }

    return
      bytes(config.baseUri).length != 0
        ? string(abi.encodePacked(config.baseUri, LibString.toString(tokenId)))
        : "";
  }

  function reveal() public onlyOwner {
    revealed = true;
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  /// @notice the password is "forever"
  function lockURI(string memory password) public onlyOwner {
    if (keccak256(abi.encodePacked(password)) != keccak256(abi.encodePacked("forever"))) {
      revert WrongPassword();
    }

    uriUnlocked = false;
  }

  function setUnrevealedURI(string memory _unrevealedURI) public onlyOwner {
    config.unrevealedUri = _unrevealedURI;
  }

  function setBaseURI(string memory baseUri_) public onlyOwner {
    if (!uriUnlocked) {
      revert LockedForever();
    }

    config.baseUri = baseUri_;
  }

  function setMaxSupply(uint32 maxSupply_) public onlyOwner {
    if (!maxSupplyUnlocked) {
      revert LockedForever();
    }

    if (maxSupply_ < _nextTokenId()) {
      revert MaxSupplyExceeded();
    }

    config.maxSupply = maxSupply_;
  }

  /// @notice the password is "forever"
  function lockMaxSupply(string memory password) public onlyOwner {
    if (keccak256(abi.encodePacked(password)) != keccak256(abi.encodePacked("forever"))) {
      revert WrongPassword();
    }

    maxSupplyUnlocked = false;
  }

  function setAffiliateFee(uint16 affiliateFee_) public onlyOwner {
    if (!affiliateFeeUnlocked) {
      revert LockedForever();
    }
    if (affiliateFee_ > MAXBPS) {
      revert InvalidConfig();
    }

    config.affiliateFee = affiliateFee_;
  }

  /// @notice the password is "forever"
  function lockAffiliateFee(string memory password) public onlyOwner {
    if (keccak256(abi.encodePacked(password)) != keccak256(abi.encodePacked("forever"))) {
      revert WrongPassword();
    }

    affiliateFeeUnlocked = false;
  }

  function setDiscounts(Discount calldata discounts_) public onlyOwner {
    if (!discountsUnlocked) {
      revert LockedForever();
    }

    if (discounts_.affiliateDiscount > MAXBPS) {
      revert InvalidConfig();
    }

    // ensure mint tiers are correctly ordered from highest to lowest.
    for (uint256 i = 1; i < discounts_.mintTiers.length; i++) {
      if (
        discounts_.mintTiers[i].mintDiscount > MAXBPS ||
        discounts_.mintTiers[i].numMints > discounts_.mintTiers[i - 1].numMints
      ) {
        revert InvalidConfig();
      }
    }

    config.discounts = discounts_;
  }

  /// @notice the password is "forever"
  function lockDiscounts(string memory password) public onlyOwner {
    if (keccak256(abi.encodePacked(password)) != keccak256(abi.encodePacked("forever"))) {
      revert WrongPassword();
    }

    discountsUnlocked = false;
  }

  /// @notice Set BAYC-style provenance once it's calculated
  function setProvenanceHash(string memory provenanceHash) public onlyOwner {
    if (!provenanceHashUnlocked) {
      revert LockedForever();
    }

    provenance = provenanceHash;
  }

  /// @notice the password is "forever"
  function lockProvenanceHash(string memory password) public onlyOwner {
    if (keccak256(abi.encodePacked(password)) != keccak256(abi.encodePacked("forever"))) {
      revert WrongPassword();
    }

    provenanceHashUnlocked = false;
  }

  function setOwnerAltPayout(address ownerAltPayout) public onlyOwner {
    if (!ownerAltPayoutUnlocked) {
      revert LockedForever();
    }

    config.ownerAltPayout = ownerAltPayout;
  }

  /// @notice the password is "forever"
  function lockOwnerAltPayout(string memory password) public onlyOwner {
    if (keccak256(abi.encodePacked(password)) != keccak256(abi.encodePacked("forever"))) {
      revert WrongPassword();
    }

    ownerAltPayoutUnlocked = false;
  }

  function withdraw() public {
    uint128 wad = 0;

    if (msg.sender == owner() || msg.sender == config.ownerAltPayout || msg.sender == PLATFORM) {
      OwnerBalance memory balance = ownerBalance;
      if (msg.sender == owner() || msg.sender == config.ownerAltPayout) {
        wad = balance.owner;
        ownerBalance = OwnerBalance({ owner: 0, platform: balance.platform });
      } else {
        wad = balance.platform;
        ownerBalance = OwnerBalance({ owner: balance.owner, platform: 0 });
      }
    } else {
      wad = affiliateBalance[msg.sender];
      affiliateBalance[msg.sender] = 0;
    }

    if (wad == 0) {
      revert BalanceEmpty();
    }
    bool success = false;
    // send to ownerAltPayout if set and owner is withdrawing
    if (msg.sender == owner() && config.ownerAltPayout != address(0)) {
      (success, ) = payable(config.ownerAltPayout).call{ value: wad }("");
    } else {
      (success, ) = msg.sender.call{ value: wad }("");
    }
    if (!success) {
      revert TransferFailed();
    }
    emit Withdrawal(msg.sender, wad);
  }

  function setInvites(Invitelist[] calldata invitelist) external onlyOwner {
    for (uint256 i = 0; i < invitelist.length; i++) {
      Invitelist calldata list = invitelist[i];
      invites[list.key] = list.invite;
      emit Invited(list.key, list.cid);
    }
  }

  function setInvite(
    bytes32 _key,
    bytes32 _cid,
    Invite calldata _invite
  ) external onlyOwner {
    invites[_key] = _invite;
    emit Invited(_key, _cid);
  }

  // based on: https://github.com/miguelmota/merkletreejs-solidity/blob/master/contracts/MerkleProof.sol
  function verify(Auth calldata auth, address account) internal pure returns (bool) {
    if (auth.key == "") return true;

    return MerkleProofLib.verify(auth.proof, auth.key, keccak256(abi.encodePacked(account)));
  }

  function validateAffiliate(
    address affiliate,
    bytes calldata signature,
    address affiliateSigner
  ) internal view {
    bytes32 signedMessagehash = ECDSA.toEthSignedMessageHash(
      keccak256(abi.encodePacked(affiliate))
    );
    address signer = ECDSA.recover(signedMessagehash, signature);

    if (signer != affiliateSigner) {
      revert InvalidSignature();
    }
  }

  function setTokenMsg(uint256 tokenId, string calldata message) public {
    if (msg.sender != ownerOf(tokenId)) {
      revert NotTokenOwner();
    }

    tokenMsg[tokenId] = bytes(message);
  }

  function getTokenMsg(uint256 tokenId) public view returns (string memory) {
    if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
    return string(tokenMsg[tokenId]);
  }
}
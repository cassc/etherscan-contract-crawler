// SPDX-License-Identifier: MIT
// Archetype v0.5.1
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

import "./ArchetypeLogic.sol";
import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import "erc721a-upgradeable/contracts/ERC721A__Initializable.sol";
import "./ERC721A__OwnableUpgradeable.sol";
import "solady/src/utils/LibString.sol";
import "closedsea/src/OperatorFilterer.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";

contract Archetype is
  ERC721A__Initializable,
  ERC721AUpgradeable,
  OperatorFilterer,
  ERC721A__OwnableUpgradeable,
  ERC2981Upgradeable
{
  //
  // EVENTS
  //
  event Invited(bytes32 indexed key, bytes32 indexed cid);
  event Referral(address indexed affiliate, address token, uint128 wad, uint256 numMints);
  event Withdrawal(address indexed src, address token, uint128 wad);

  //
  // VARIABLES
  //
  mapping(bytes32 => DutchInvite) public invites;
  mapping(address => mapping(bytes32 => uint256)) private _minted;
  mapping(bytes32 => uint256) private _listSupply;
  mapping(address => OwnerBalance) private _ownerBalance;
  mapping(address => mapping(address => uint128)) private _affiliateBalance;
  mapping(uint256 => bytes) private _tokenMsg;

  Config public config;
  BurnConfig public burnConfig;
  Options public options;

  string public provenance;

  //
  // METHODS
  //
  function initialize(
    string memory name,
    string memory symbol,
    Config calldata config_,
    address _receiver
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

    if (config.ownerAltPayout != address(0)) {
      setDefaultRoyalty(config.ownerAltPayout, config.defaultRoyalty);
    } else {
      setDefaultRoyalty(_receiver, config.defaultRoyalty);
    }
  }

  //
  // PUBLIC
  //
  function mint(
    Auth calldata auth,
    uint256 quantity,
    address affiliate,
    bytes calldata signature
  ) external payable {
    mintTo(auth, quantity, msg.sender, affiliate, signature);
  }

  function batchMintTo(
    Auth calldata auth,
    address[] calldata toList,
    uint256[] calldata quantityList,
    address affiliate,
    bytes calldata signature
  ) external payable {
    if (quantityList.length != toList.length) {
      revert InvalidConfig();
    }

    DutchInvite storage invite = invites[auth.key];
    uint256 quantity = 0;
    {
      uint32 unitSize = invite.unitSize;
      for (uint256 i = 0; i < quantityList.length; i++) {
        if (unitSize > 1) {
          quantity += quantityList[i] * unitSize;
        } else {
          quantity += quantityList[i];
        }
      }
    }

    uint256 curSupply = _totalMinted();
    ArchetypeLogic.validateMint(
      invite,
      config,
      auth,
      quantity,
      owner(),
      affiliate,
      curSupply,
      _minted,
      _listSupply,
      signature
    );

    {
      uint32 unitSize = invite.unitSize;
      for (uint256 i = 0; i < toList.length; i++) {
        if (unitSize > 1) {
          _mint(toList[i], quantityList[i] * unitSize);
        } else {
          _mint(toList[i], quantityList[i]);
        }
      }
    }

    if (invite.limit < invite.maxSupply) {
      _minted[msg.sender][auth.key] += quantity;
    }
    if (invite.maxSupply < config.maxSupply) {
      _listSupply[auth.key] += quantity;
    }
    ArchetypeLogic.updateBalances(
      invite,
      config,
      _ownerBalance,
      _affiliateBalance,
      affiliate,
      quantity
    );
  }

  function mintTo(
    Auth calldata auth,
    uint256 quantity,
    address to,
    address affiliate,
    bytes calldata signature
  ) public payable {
    DutchInvite storage i = invites[auth.key];

    if (i.unitSize > 1) {
      quantity = quantity * i.unitSize;
    }

    uint256 curSupply = _totalMinted();
    ArchetypeLogic.validateMint(
      i,
      config,
      auth,
      quantity,
      owner(),
      affiliate,
      curSupply,
      _minted,
      _listSupply,
      signature
    );
    _mint(to, quantity);

    if (i.limit < i.maxSupply) {
      _minted[msg.sender][auth.key] += quantity;
    }
    if (i.maxSupply < config.maxSupply) {
      _listSupply[auth.key] += quantity;
    }
    ArchetypeLogic.updateBalances(i, config, _ownerBalance, _affiliateBalance, affiliate, quantity);
  }

  function burnToMint(uint256[] calldata tokenIds) external {
    uint256 curSupply = _totalMinted();
    ArchetypeLogic.validateBurnToMint(config, burnConfig, tokenIds, curSupply, _minted);

    for (uint256 i = 0; i < tokenIds.length; i++) {
      burnConfig.archetype.transferFrom(
        msg.sender,
        address(0x000000000000000000000000000000000000dEaD),
        tokenIds[i]
      );
    }

    uint256 quantity = burnConfig.reversed
      ? tokenIds.length * burnConfig.ratio
      : tokenIds.length / burnConfig.ratio;
    _mint(msg.sender, quantity);

    if (burnConfig.limit < config.maxSupply) {
      _minted[msg.sender][bytes32("burn")] += quantity;
    }
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

    return
      bytes(config.baseUri).length != 0
        ? string(abi.encodePacked(config.baseUri, LibString.toString(tokenId)))
        : "";
  }

  function withdraw() external {
    address[] memory tokens = new address[](1);
    tokens[0] = address(0);
    withdrawTokens(tokens);
  }

  function withdrawTokens(address[] memory tokens) public {
    ArchetypeLogic.withdrawTokens(config, _ownerBalance, _affiliateBalance, owner(), tokens);
  }

  function setTokenMsg(uint256 tokenId, string calldata message) external {
    if (msg.sender != ownerOf(tokenId)) {
      revert NotTokenOwner();
    }

    _tokenMsg[tokenId] = bytes(message);
  }

  function getTokenMsg(uint256 tokenId) external view returns (string memory) {
    if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
    return string(_tokenMsg[tokenId]);
  }

  function ownerBalance() external view returns (OwnerBalance memory) {
    return _ownerBalance[address(0)];
  }

  function ownerBalanceToken(address token) external view returns (OwnerBalance memory) {
    return _ownerBalance[token];
  }

  function affiliateBalance(address affiliate) external view returns (uint128) {
    return _affiliateBalance[affiliate][address(0)];
  }

  function affiliateBalanceToken(address affiliate, address token) external view returns (uint128) {
    return _affiliateBalance[affiliate][token];
  }

  function minted(address minter, bytes32 key) external view returns (uint256) {
    return _minted[minter][key];
  }

  function listSupply(bytes32 key) external view returns (uint256) {
    return _listSupply[key];
  }

  function platform() external pure returns (address) {
    return PLATFORM;
  }

  //
  // OWNER ONLY
  //

  function setBaseURI(string memory baseUri) external onlyOwner {
    if (options.uriLocked) {
      revert LockedForever();
    }

    config.baseUri = baseUri;
  }

  /// @notice the password is "forever"
  function lockURI(string memory password) external onlyOwner {
    if (keccak256(abi.encodePacked(password)) != keccak256(abi.encodePacked("forever"))) {
      revert WrongPassword();
    }

    options.uriLocked = true;
  }

  /// @notice the password is "forever"
  // max supply cannot subceed total supply. Be careful changing.
  function setMaxSupply(uint32 maxSupply, string memory password) external onlyOwner {
    if (keccak256(abi.encodePacked(password)) != keccak256(abi.encodePacked("forever"))) {
      revert WrongPassword();
    }

    if (options.maxSupplyLocked) {
      revert LockedForever();
    }

    if (maxSupply < _totalMinted()) {
      revert MaxSupplyExceeded();
    }

    config.maxSupply = maxSupply;
  }

  /// @notice the password is "forever"
  function lockMaxSupply(string memory password) external onlyOwner {
    if (keccak256(abi.encodePacked(password)) != keccak256(abi.encodePacked("forever"))) {
      revert WrongPassword();
    }

    options.maxSupplyLocked = true;
  }

  function setAffiliateFee(uint16 affiliateFee) external onlyOwner {
    if (options.affiliateFeeLocked) {
      revert LockedForever();
    }
    if (affiliateFee > MAXBPS) {
      revert InvalidConfig();
    }

    config.affiliateFee = affiliateFee;
  }

  /// @notice the password is "forever"
  function lockAffiliateFee(string memory password) external onlyOwner {
    if (keccak256(abi.encodePacked(password)) != keccak256(abi.encodePacked("forever"))) {
      revert WrongPassword();
    }

    options.affiliateFeeLocked = true;
  }

  function setDiscounts(Discount calldata discounts) external onlyOwner {
    if (options.discountsLocked) {
      revert LockedForever();
    }

    if (discounts.affiliateDiscount > MAXBPS) {
      revert InvalidConfig();
    }

    // ensure mint tiers are correctly ordered from highest to lowest.
    for (uint256 i = 1; i < discounts.mintTiers.length; i++) {
      if (
        discounts.mintTiers[i].mintDiscount > MAXBPS ||
        discounts.mintTiers[i].numMints > discounts.mintTiers[i - 1].numMints
      ) {
        revert InvalidConfig();
      }
    }

    config.discounts = discounts;
  }

  /// @notice the password is "forever"
  function lockDiscounts(string memory password) external onlyOwner {
    if (keccak256(abi.encodePacked(password)) != keccak256(abi.encodePacked("forever"))) {
      revert WrongPassword();
    }

    options.discountsLocked = true;
  }

  /// @notice Set BAYC-style provenance once it's calculated
  function setProvenanceHash(string memory provenanceHash) external onlyOwner {
    if (options.provenanceHashLocked) {
      revert LockedForever();
    }

    provenance = provenanceHash;
  }

  /// @notice the password is "forever"
  function lockProvenanceHash(string memory password) external onlyOwner {
    if (keccak256(abi.encodePacked(password)) != keccak256(abi.encodePacked("forever"))) {
      revert WrongPassword();
    }

    options.provenanceHashLocked = true;
  }

  function setOwnerAltPayout(address ownerAltPayout) external onlyOwner {
    if (options.ownerAltPayoutLocked) {
      revert LockedForever();
    }

    config.ownerAltPayout = ownerAltPayout;
  }

  /// @notice the password is "forever"
  function lockOwnerAltPayout(string memory password) external onlyOwner {
    if (keccak256(abi.encodePacked(password)) != keccak256(abi.encodePacked("forever"))) {
      revert WrongPassword();
    }

    options.ownerAltPayoutLocked = true;
  }

  function setMaxBatchSize(uint32 maxBatchSize) external onlyOwner {
    config.maxBatchSize = maxBatchSize;
  }

  function setInvite(
    bytes32 _key,
    bytes32 _cid,
    Invite calldata _invite
  ) external onlyOwner {
    invites[_key] = DutchInvite({
      price: _invite.price,
      reservePrice: _invite.price,
      delta: 0,
      start: _invite.start,
      end: _invite.end,
      limit: _invite.limit,
      maxSupply: _invite.maxSupply,
      interval: 0,
      unitSize: _invite.unitSize,
      tokenAddress: _invite.tokenAddress
    });
    emit Invited(_key, _cid);
  }

  function setDutchInvite(
    bytes32 _key,
    bytes32 _cid,
    DutchInvite memory _dutchInvite
  ) external onlyOwner {
    if (_dutchInvite.start < block.timestamp) {
      _dutchInvite.start = uint32(block.timestamp);
    }
    invites[_key] = _dutchInvite;
    emit Invited(_key, _cid);
  }

  function enableBurnToMint(
    address archetype,
    bool reversed,
    uint16 ratio,
    uint64 start,
    uint64 limit
  ) external onlyOwner {
    burnConfig = BurnConfig({
      archetype: IERC721AUpgradeable(archetype),
      enabled: true,
      reversed: reversed,
      ratio: ratio,
      start: start,
      limit: limit
    });
  }

  function disableBurnToMint() external onlyOwner {
    burnConfig = BurnConfig({
      enabled: false,
      reversed: false,
      ratio: 0,
      archetype: IERC721AUpgradeable(address(0)),
      start: 0,
      limit: 0
    });
  }

  //
  // PLATFORM ONLY
  //
  function setSuperAffiliatePayout(address superAffiliatePayout) external onlyPlatform {
    config.superAffiliatePayout = superAffiliatePayout;
  }

  //
  // INTERNAL
  //
  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  modifier onlyPlatform() {
    if (msg.sender != PLATFORM) {
      revert NotPlatform();
    }
    _;
  }

  // OPTIONAL ROYALTY ENFORCEMENT WITH OPENSEA
  function enableRoyaltyEnforcement() external onlyOwner {
    if (options.royaltyEnforcementLocked) {
      revert LockedForever();
    }
    _registerForOperatorFiltering();
    options.royaltyEnforcementEnabled = true;
  }

  function disableRoyaltyEnforcement() external onlyOwner {
    if (options.royaltyEnforcementLocked) {
      revert LockedForever();
    }
    options.royaltyEnforcementEnabled = false;
  }

  /// @notice the password is "forever"
  function lockRoyaltyEnforcement(string memory password) external onlyOwner {
    if (keccak256(abi.encodePacked(password)) != keccak256(abi.encodePacked("forever"))) {
      revert WrongPassword();
    }

    options.royaltyEnforcementLocked = true;
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
    payable
    override
    onlyAllowedOperatorApproval(operator)
  {
    super.approve(operator, tokenId);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public payable override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public payable override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public payable override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }

  function _operatorFilteringEnabled() internal view override returns (bool) {
    return options.royaltyEnforcementEnabled;
  }

  //ERC2981 ROYALTY
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721AUpgradeable, ERC2981Upgradeable)
    returns (bool)
  {
    // Supports the following `interfaceId`s:
    // - IERC165: 0x01ffc9a7
    // - IERC721: 0x80ac58cd
    // - IERC721Metadata: 0x5b5e139f
    // - IERC2981: 0x2a55205a
    return
      ERC721AUpgradeable.supportsInterface(interfaceId) ||
      ERC2981Upgradeable.supportsInterface(interfaceId);
  }

  function setDefaultRoyalty(address receiver, uint16 feeNumerator) public onlyOwner {
    config.defaultRoyalty = feeNumerator;
    _setDefaultRoyalty(receiver, feeNumerator);
  }
}
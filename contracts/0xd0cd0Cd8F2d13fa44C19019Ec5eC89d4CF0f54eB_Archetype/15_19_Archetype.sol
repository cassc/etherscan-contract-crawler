// SPDX-License-Identifier: MIT
// Archetype v0.5.1 - ERC1155
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
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "solady/src/utils/LibString.sol";
import "closedsea/src/OperatorFilterer.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";

contract Archetype is
  Initializable,
  ERC1155Upgradeable,
  OperatorFilterer,
  OwnableUpgradeable,
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

  uint256[] private _tokenSupply;

  Config public config;
  Options public options;

  string public name;
  string public symbol;
  string public provenance;

  //
  // METHODS
  //
  function initialize(
    string memory _name,
    string memory _symbol,
    Config calldata config_,
    address _receiver
  ) external initializer {
    name = _name;
    symbol = _symbol;
    __ERC1155_init("");
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
    _tokenSupply = new uint256[](config_.maxSupply.length);
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

  // use mintToken for non-random lists
  function mint(
    Auth calldata auth,
    uint256 quantity,
    address affiliate,
    bytes calldata signature
  ) external payable {
    mintTo(auth, quantity, msg.sender, 0, affiliate, signature);
  }

  // tokenId is ignored in case of random list
  function mintToken(
    Auth calldata auth,
    uint256 quantity,
    uint256 tokenId,
    address affiliate,
    bytes calldata signature
  ) external payable {
    mintTo(auth, quantity, msg.sender, tokenId, affiliate, signature);
  }

  // batch mint only supported on non random and non booster lists
  function batchMintTo(
    Auth calldata auth,
    address[] calldata toList,
    uint256[] calldata quantityList,
    uint256[] calldata tokenIdList,
    address affiliate,
    bytes calldata signature
  ) external payable {
    if (quantityList.length != toList.length || quantityList.length != tokenIdList.length) {
      revert InvalidConfig();
    }

    DutchInvite storage invite = invites[auth.key];
    if (invite.randomize || invite.unitSize > 1) {
      revert NotSupported();
    }

    ValidationArgs memory args;
    {
      args = ValidationArgs({
        owner: owner(),
        affiliate: affiliate,
        quantities: quantityList,
        tokenIds: tokenIdList
      });
    }
    ArchetypeLogic.validateMint(
      invite,
      config,
      auth,
      _minted,
      _listSupply,
      _tokenSupply,
      signature,
      args
    );

    for (uint256 i = 0; i < toList.length; i++) {
      bytes memory _data;
      _mint(toList[i], tokenIdList[i], quantityList[i], _data);
      _tokenSupply[tokenIdList[i] - 1] += quantityList[i];
    }

    uint256 quantity = 0;
    for (uint256 i = 0; i < quantityList.length; i++) {
      quantity += quantityList[i];
    }

    if (invite.limit < invite.maxSupply) {
      _minted[msg.sender][auth.key] += quantity;
    }
    if (invite.maxSupply < 2**32 - 1) {
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
    uint256 tokenId, // only used if randomizer=false
    address affiliate,
    bytes calldata signature
  ) public payable {
    DutchInvite storage i = invites[auth.key];

    if (i.unitSize > 1) {
      quantity = quantity * i.unitSize;
    }

    ValidationArgs memory args;
    {
      uint256[] memory tokenIds;
      uint256[] memory quantities;
      if (i.randomize) {
        // to avoid stack too deep errors
        uint256 seed = ArchetypeLogic.random();
        tokenIds = ArchetypeLogic.getRandomTokenIds(
          _tokenSupply,
          config.maxSupply,
          i.tokenIds,
          quantity,
          seed
        );
        quantities = new uint256[](tokenIds.length);
        for (uint256 j = 0; j < tokenIds.length; j++) {
          quantities[j] = 1;
        }
      } else {
        tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        quantities = new uint256[](1);
        quantities[0] = quantity;
      }
      args = ValidationArgs({
        owner: owner(),
        affiliate: affiliate,
        quantities: quantities,
        tokenIds: tokenIds
      });
    }
    ArchetypeLogic.validateMint(
      i,
      config,
      auth,
      _minted,
      _listSupply,
      _tokenSupply,
      signature,
      args
    );

    for (uint256 j = 0; j < args.tokenIds.length; j++) {
      bytes memory _data;
      _mint(to, args.tokenIds[j], args.quantities[j], _data);
      _tokenSupply[args.tokenIds[j] - 1] += args.quantities[j];
    }

    if (i.limit < i.maxSupply) {
      _minted[msg.sender][auth.key] += quantity;
    }
    if (i.maxSupply < 2**32 - 1) {
      _listSupply[auth.key] += quantity;
    }

    ArchetypeLogic.updateBalances(i, config, _ownerBalance, _affiliateBalance, affiliate, quantity);
  }

  function uri(uint256 tokenId) public view override returns (string memory) {
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

  function tokenSupply(uint256 tokenId) external view returns (uint256) {
    if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
    return _tokenSupply[tokenId - 1];
  }

  function totalSupply() external view returns (uint256) {
    uint256 supply = 0;
    for (uint256 i = 0; i < _tokenSupply.length; i++) {
      supply += _tokenSupply[i];
    }
    return supply;
  }

  function maxSupply() external view returns (uint32[] memory) {
    return config.maxSupply;
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
  function setMaxSupply(uint32[] memory newMaxSupply, string memory password) external onlyOwner {
    if (keccak256(abi.encodePacked(password)) != keccak256(abi.encodePacked("forever"))) {
      revert WrongPassword();
    }

    if (options.maxSupplyLocked) {
      revert LockedForever();
    }

    for (uint256 i = 0; i < _tokenSupply.length; i++) {
      if (newMaxSupply[i] < _tokenSupply[i]) {
        revert MaxSupplyExceeded();
      }
    }

    // increase size of token supply array to match new max supply
    for (uint256 i = _tokenSupply.length; i < newMaxSupply.length; i++) {
      _tokenSupply.push(0);
    }
    config.maxSupply = newMaxSupply;
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
      randomize: _invite.randomize,
      tokenIds: _invite.tokenIds,
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

  //
  // PLATFORM ONLY
  //
  function setSuperAffiliatePayout(address superAffiliatePayout) external onlyPlatform {
    config.superAffiliatePayout = superAffiliatePayout;
  }

  //
  // INTERNAL
  //
  function _startTokenId() internal view virtual returns (uint256) {
    return 1;
  }

  function _exists(uint256 tokenId) internal view returns (bool) {
    return tokenId > 0 && tokenId <= _tokenSupply.length;
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
  ) public override onlyAllowedOperator(from) {
    super.safeBatchTransferFrom(from, to, ids, amounts, data);
  }

  function _operatorFilteringEnabled() internal view override returns (bool) {
    return options.royaltyEnforcementEnabled;
  }

  //ERC2981 ROYALTY
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC1155Upgradeable, ERC2981Upgradeable)
    returns (bool)
  {
    // Supports the following `interfaceId`s:
    // - IERC165: 0x01ffc9a7
    // - IERC721: 0x80ac58cd
    // - IERC721Metadata: 0x5b5e139f
    // - IERC2981: 0x2a55205a
    return
      ERC1155Upgradeable.supportsInterface(interfaceId) ||
      ERC2981Upgradeable.supportsInterface(interfaceId);
  }

  function setDefaultRoyalty(address receiver, uint16 feeNumerator) public onlyOwner {
    config.defaultRoyalty = feeNumerator;
    _setDefaultRoyalty(receiver, feeNumerator);
  }
}
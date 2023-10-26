// SPDX-License-Identifier: GPL-3.0-or-later

// ░██╗░░░░░░░██╗░██╗░██╗░░░░░░██████╗░░██╗░░██╗░██╗░░░██╗░███████╗
// ░██║░░██╗░░██║░██║░██║░░░░░░██╔══██╗░╚██╗██╔╝░╚██╗░██╔╝░╚════██║
// ░╚██╗████╗██╔╝░██║░██║░░░░░░██║░░██║░░╚███╔╝░░░╚████╔╝░░░░███╔═╝
// ░░████╔═████║░░██║░██║░░░░░░██║░░██║░░██╔██╗░░░░╚██╔╝░░░██╔══╝░░
// ░░╚██╔╝░╚██╔╝░░██║░███████╗░██████╔╝░██╔╝╚██╗░░░░██║░░░░███████╗
// ░░░╚═╝░░░╚═╝░░░╚═╝░╚══════╝░╚═════╝░░╚═╝░░╚═╝░░░░╚═╝░░░░╚══════╝

// It ain't much, but it's honest work.

pragma solidity ^0.8.17;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';

import '@openzeppelin/contracts/utils/math/Math.sol';

import '../WildNFT.sol';

import '../minter/utils/IOasis.sol';
import '../minter/utils/ISanctionsList.sol';

import './IWildXYZMinter.sol';

contract WildXYZMinterPresale is IWildXYZMinter, Ownable, Pausable, ReentrancyGuard {
  // private variables

  mapping(uint256 => Group) private groups;
  uint256 private numGroups;

  /// @dev One-time variable used to set up the contract.
  bool private isSetup = false;

  mapping(uint256 => uint8) private oasisPassMints;

  // public variables

  // presale variables

  struct PresaleMinterInfo {
    State minterState;
    bool isPresaleLive;
    uint256 maxSupply;
    uint256 totalSupply;
    uint256 presaleMaxSupply;
    uint256 presaleTotalSupply;
    uint256 maxPerOasis;
    uint256 maxPerAddress;
    address allowlistSigner;
    Group[] groups;
  }

  uint256 public presaleMaxSupply;
  uint256 public presaleTotalSupply;

  uint256 public numPresaleMints;

  uint256 public presaleStartTime;
  uint256 public presaleEndTime;

  uint256 public presaleGroupIdOasis;
  uint256 public presaleGroupIdAllowlist;

  struct PresalePurchaseInfo {
    address owner;
    uint256 amount;
    uint256 value;
    bool processed;
    uint256 amountProcessed;
  }
  // mapping(uint256 => PresalePurchaseInfo) public presalePurchaseInfo;
  mapping(address => PresalePurchaseInfo) public presalePurchaseInfo;
  address[] public presalePurchaseOwners;
  uint256 public numPresalePurchaseOwners;

  uint256 private constant maxNFTsPerTransaction = 20;

  // mapping(address => uint256) public presaleAddressTotalSupply;

  event PresalePurchase(address indexed owner, uint256 indexed amount, uint256 value, MintType mintType);

  event PresalePurchaseProcessed(address indexed owner, uint256[] tokenIds);

  /// @notice Emitted when we have already processed a presale purchase for minting the actual nft
  error AlreadyProcessedPresalePurchase();

  error PresalePurchaseNotFound();

  error InvalidAllowlistType();

  /// @notice Emitted when the requesting minter is not on an allowlist (either wild allowlist, oasis holder or allowlisted NFT holder)
  error NotOnAllowlist(address _receiver);

  // drop variables

  /// @notice Max supply of NFTs available. Same as NFT contract.
  uint256 public maxSupply;

  /// @notice Wildxyz royalty percentage.
  /// @dev Wildxyz royalty is `wildRoyalty`%. Artist royalty is `100 - wildRoyalty`% (100 - wildRoyalty).
  uint256 public wildRoyalty;

  /// @notice Royalty total denominator.
  uint256 public royaltyTotal = 100;

  /// @notice Wildxyz royalty wallet
  /// @dev This is the wallet that will receive the `wildRoyalty`% of the primary sale eth.
  address payable public wildWallet;

  /// @notice Artist royalty wallet
  /// @dev This is the wallet that will receive the `100 - wildRoyalty`% of the primary sale eth.
  address payable public artistWallet;

  /// @notice The contract admin address.
  address public admin;

  /// @notice The WildNFT contract address.
  WildNFT public nft;

  /// @notice The OFAC sanctions list contract address.
  /// @dev Used to block unsanctioned addresses from minting NFTs.
  ISanctionsList public sanctionsList;

  /// @notice Oasis NFT address.
  IOasis public oasis;

  /// @notice The DelegateCash registry address.
  IDelegationRegistry public delegationRegistry = IDelegationRegistry(0x00000000000076A84feF008CDAbe6409d2FE638B);

  // minter variables

  /// @notice The admin signature signer address.
  address public adminSigner;

  /// @notice The total number of promo minted tokens.
  uint256 public promoMintTotalSupply = 0;

  uint256 public maxPerAddress;

  uint256 public groupIdOasis;
  uint256 public groupIdAllowlist;
  uint256 public groupIdPublicSale;

  mapping(uint256 => address) allowlistedERC721Addresses;
  uint256 public numAllowlistedERC721Addresses;

  mapping(address => uint256) public addressTotalSupply;

  // modifiers

  modifier setupOnce() {
    if (isSetup) revert AlreadySetup();
    isSetup = true;
    _;
  }

  modifier onlyAdmin() {
    if (msg.sender != admin) revert OnlyAdmin();
    _;
  }

  modifier onlyLive() {
    if (getState() != State.Live) revert NotLive();
    _;
  }

  modifier validGroup(uint256 _groupId) {
    _validGroup(_groupId);
    _;
  }

  modifier validateSigner(address _address, bytes memory _signature) {
    if (!verifySignature(_address, _signature)) revert InvalidSignature(_signature);
    _;
  }

  modifier onlyUnsanctioned(address _to) {
    if (sanctionsList.isSanctioned(_to)) revert SanctionedAddress(_to);
    _;
  }

  modifier onlyDelegated(address _vault, address _contract) {
    if (!delegationRegistry.checkDelegateForContract(msg.sender, _vault, _contract)) revert NotDelegated(msg.sender, _vault, _contract);
    _;
  }

  modifier nonZeroAmount(uint256 _amount) {
    _nonZeroAmount(_amount);
    _;
  }

  // modifier validation hooks

  modifier validAllowlistPresalePurchase(address _receiver, uint256 _amount) {
    _validAllowlistPresalePurchase(_receiver, _amount);
    _;
  }

  modifier validOasisPresalePurchase(
    address _receiver,
    address _vault,
    uint256 _amount
  ) {
    _validOasisPresalePurchase(_receiver, _vault, _amount);
    _;
  }

  modifier validOasisMint(
    address _receiver,
    address _vault,
    uint256 _amount
  ) {
    _validOasisMint(_receiver, _vault, _amount);
    _;
  }

  modifier validAllowlistMint(address _receiver, uint256 _amount) {
    _validAllowlistMint(_receiver, _amount);
    _;
  }

  modifier validPublicSaleMint(address _receiver, uint256 _amount) {
    _validPublicSaleMint(_receiver, _amount);
    _;
  }

  /** @notice BaseMinter constructor
   * @param _maxSupply The max supply of the NFT (same as WildNFT)
   * @param _wildRoyalty The royalty percentage for Wildxyz
   * @param _wildWallet The wallet address for Wildxyz
   * @param _artistWallet The wallet address for the artist
   * @param _admin The admin address
   * @param _sanctions The sanctions list contract address
   * @param _nft The WildNFT contract address
   */
  constructor(uint256 _maxSupply, uint256 _wildRoyalty, address _wildWallet, address _artistWallet, address _admin, ISanctionsList _sanctions, WildNFT _nft) {
    maxSupply = _maxSupply;
    wildRoyalty = _wildRoyalty;
    wildWallet = payable(_wildWallet);
    artistWallet = payable(_artistWallet);
    admin = _admin;
    sanctionsList = _sanctions;
    nft = _nft;
  }

  // internal functions

  function _createGroup(string memory _name, uint256 _startTime, uint256 _endTime, uint256 _price) internal onlyOwner returns (uint256 groupId) {
    groupId = numGroups;

    groups[groupId] = Group(_name, groupId, _startTime, _endTime, _price);

    numGroups++;
  }

  // function validation hooks

  function _isGroupLive(uint256 _groupId) internal view returns (bool) {
    return block.timestamp >= groups[_groupId].startTime && (groups[_groupId].endTime == 0 || block.timestamp < groups[_groupId].endTime);
  }

  function _nonZeroAmount(uint256 _amount) internal pure {
    if (_amount < 1) revert ZeroAmount();
  }

  function _validGroup(uint256 _groupId) internal view {
    if (_groupId >= numGroups) revert GroupDoesNotExist(_groupId);
  }

  function _groupAllowed(uint256 _group) internal view {
    if (!_isGroupLive(_group)) revert GroupNotLive(_group);
  }

  function _validPrice(uint256 _amount, uint256 _groupId) internal view {
    if (msg.value < _amount * groups[_groupId].price) revert InsufficientFunds();
  }

  function _validSupply(uint256 _amount) internal view {
    uint256 supplyRemaining = maxSupply - _nftTotalSupply() - (presaleTotalSupply - numPresaleMints);

    if (_amount > supplyRemaining) revert MaxSupplyExceeded();
  }

  function _validMaxPerTransaction(address _receiver, uint256 _amount) internal view {
    if (_amount > maxPerAddress) revert MaxPerAddressExceeded(_receiver, _amount);
  }

  function _validGroupPriceSupply(uint256 _groupId, uint256 _amount) internal view {
    _groupAllowed(_groupId);
    _validPrice(_amount, _groupId);
    _validSupply(_amount);
    _validMaxPerTransaction(msg.sender, _amount);
  }

  function _validPresaleSupply(uint256 _amount) internal view {
    if (presaleTotalSupply + _amount > presaleMaxSupply) revert MaxSupplyExceeded();
  }

  function _validPresaleGroupPriceSupply(uint256 _groupId, uint256 _amount) internal view {
    _groupAllowed(_groupId);
    _validPrice(_amount, _groupId);
    _validPresaleSupply(_amount);
    _validMaxPerTransaction(msg.sender, _amount);
  }

  // public mint validation hooks

  function _validOasisPresalePurchase(address /*_receiver*/, address _vault, uint256 _amount) internal virtual {
    // check oasis ownership
    if (oasis.balanceOf(_vault) == 0) revert ZeroOasisAllowance(_vault);

    _validPresaleGroupPriceSupply(presaleGroupIdOasis, _amount);
  }

  function _validAllowlistPresalePurchase(address /*_receiver*/, uint256 _amount) internal virtual {
    _validPresaleGroupPriceSupply(presaleGroupIdAllowlist, _amount);
  }

  function _validAllowlistMint(address /*_receiver*/, uint256 _amount) internal virtual {
    _validGroupPriceSupply(groupIdAllowlist, _amount);
  }

  function _validOasisMint(address /*_receiver*/, address _vault, uint256 _amount) internal virtual {
    // check oasis ownership
    if (oasis.balanceOf(_vault) == 0) revert ZeroOasisAllowance(_vault);

    _validGroupPriceSupply(groupIdOasis, _amount);
  }

  function _validPublicSaleMint(address /*_receiver*/, uint256 _amount) internal virtual {
    _validGroupPriceSupply(groupIdPublicSale, _amount);
  }

  function _mapAllowlistTypeToMintType(uint256 _allowlistType) internal pure returns (MintType) {
    if (_allowlistType == 1) {
      return MintType.Allowlist;
    } else if (_allowlistType == 2) {
      return MintType.ArtistAllowlist;
    }

    revert InvalidAllowlistType();
  }

  function _isAllowlisted(address _receiver, bytes memory _signature) internal view returns (uint256) {
    // check signer is valid or not
    if (verifySignature(_receiver, _signature)) {
      return 1;
    }

    // check allowlisted NFT ownership
    for (uint256 i = 0; i < numAllowlistedERC721Addresses; i++) {
      address nftAddress = allowlistedERC721Addresses[i];
      if (nftAddress != address(0)) {
        if (IERC721(nftAddress).balanceOf(_receiver) > 0) {
          return 2;
        }
      }
    }

    return 0;
  }

  // on pre-sale puchase hook

  function _onPresalePurchase(address _receiver, uint256 _amount, MintType _mintType) internal virtual {
    PresalePurchaseInfo storage purchaseInfo = presalePurchaseInfo[_receiver];

    if (purchaseInfo.owner == address(0)) {
      purchaseInfo.owner = _receiver;

      presalePurchaseOwners.push(_receiver);

      numPresalePurchaseOwners++;
    }

    purchaseInfo.amount += _amount;
    purchaseInfo.value += msg.value;

    presaleTotalSupply += _amount;

    emit PresalePurchase(_receiver, _amount, msg.value, _mintType);
  }

  // on-mint hooks

  function _onPromoMint(address _receiver, uint256[] memory _tokenIds, MintType _mintType) internal virtual {
    promoMintTotalSupply += _tokenIds.length;

    emit TokenMint(_receiver, _tokenIds, _mintType, msg.value, false, address(0), false, new uint256[](0));
  }

  function _onAllowlistMint(address _receiver, uint256[] memory _tokenIds, MintType _mintType) internal virtual {
    _addAddressTotalSupply(_receiver, _tokenIds.length);

    emit TokenMint(_receiver, _tokenIds, _mintType, msg.value, false, address(0), false, new uint256[](0));
  }

  function _onOasisMint(address _receiver, uint256[] memory _tokenIds) internal virtual {
    _addAddressTotalSupply(_receiver, _tokenIds.length);

    emit TokenMint(_receiver, _tokenIds, MintType.Oasis, msg.value, false, address(0), true, new uint256[](0));
  }

  function _onOasisMintDelegated(address _receiver, address _vault, uint256[] memory _tokenIds) internal virtual {
    _addAddressTotalSupply(_receiver, _tokenIds.length);

    emit TokenMint(_receiver, _tokenIds, MintType.Oasis, msg.value, true, _vault, true, new uint256[](0));
  }

  function _onPublicSaleMint(address _receiver, uint256[] memory _tokenIds) internal virtual {
    _addAddressTotalSupply(_receiver, _tokenIds.length);

    emit TokenMint(_receiver, _tokenIds, MintType.PublicSale, msg.value, false, address(0), false, new uint256[](0));
  }

  // helpers

  /// @dev Withdraws the funds to wild and artist wallets acconting for royalty fees. Only callable by owner.
  function _withdraw() internal virtual {
    // send a fraction of the balance to wild first
    if (wildRoyalty > 0) {
      (bool successWild, ) = wildWallet.call{value: ((address(this).balance * wildRoyalty) / royaltyTotal)}('');
      if (!successWild) revert FailedToWithdraw('wild', wildWallet);
    }

    // then, send the rest to payee
    (bool successPayee, ) = artistWallet.call{value: address(this).balance}('');
    if (!successPayee) revert FailedToWithdraw('artist', artistWallet);
  }

  /// @dev Sets the admin signer address.
  function _setAdminSigner(address _adminSigner) internal {
    adminSigner = _adminSigner;
  }

  /// @dev Wraps the nft.totalSupply call.
  function _nftTotalSupply() internal view virtual returns (uint256) {
    return nft.totalSupply();
  }

  /** @dev Internal mint function. Use if minting only 1 token.
   * @param _receiver Token receiver address.
   * @return tokenId Newly minted Token ID.
   */
  function _mint(address _receiver) internal virtual returns (uint256 tokenId) {
    tokenId = nft.mint(_receiver);
  }

  /** @dev Internal mint multiple function. Use if minting more than 1 token.
   * @param _receiver Token receiver address.
   * @param _amount Amount to mint.
   * @return tokenIds Newly minted Token IDs.
   */
  function _mintMultiple(address _receiver, uint256 _amount) internal virtual returns (uint256[] memory tokenIds) {
    tokenIds = new uint256[](_amount);

    for (uint256 i = 0; i < _amount; i++) {
      uint256 tokenId = nft.mint(_receiver);
      tokenIds[i] = tokenId;
    }
  }

  function _addAddressTotalSupply(address _receiver, uint256 _amount) internal {
    addressTotalSupply[_receiver] += _amount;
  }

  function _promoMint(address _receiver, uint256 _amount, MintType _mintType) internal {
    uint256[] memory tokenIds = _mintMultiple(_receiver, _amount);

    _onPromoMint(_receiver, tokenIds, _mintType);
  }

  function _promoMintBatch(address[] memory _receiver, uint256[] memory _amounts, MintType _mintType) internal {
    if (_receiver.length == 0 || _receiver.length != _amounts.length) revert ArraySizeMismatch();

    // sum amounts to validate total supply
    uint256 totalAmount = 0;
    for (uint256 i = 0; i < _amounts.length; i++) {
      totalAmount += _amounts[i];
    }

    _validSupply(totalAmount);

    for (uint256 i = 0; i < _receiver.length; i++) {
      address to = _receiver[i];
      uint256 amount = _amounts[i];

      uint256[] memory tokenIds = _mintMultiple(to, amount);

      _onPromoMint(to, tokenIds, _mintType);
    }
  }

  function _isPresaleGroup(uint256 _groupId) internal view returns (bool) {
    return _groupId == presaleGroupIdOasis || _groupId == presaleGroupIdAllowlist;
  }

  function _isPresaleLive() internal view returns (bool) {
    return block.timestamp >= presaleStartTime && block.timestamp < presaleEndTime;
  }

  // public admin-only functions

  function setupMinter(uint256[2] memory _startTimes, uint256 _salePrice, uint256 _presaleMaxSupply, uint256 _presaleStartTime, uint256 _presaleEndTime, uint256 _presalePrice, uint256 _maxPerAddress, address _allowlistSigner, IOasis _oasis, address[] memory _allowlistedERC721Addresses) public setupOnce onlyOwner {
    presaleMaxSupply = _presaleMaxSupply;
    presaleStartTime = _presaleStartTime;
    presaleEndTime = _presaleEndTime;

    presaleGroupIdOasis = _createGroup('Presale Oasis', _presaleStartTime, _presaleEndTime, _presalePrice);
    presaleGroupIdAllowlist = _createGroup('Presale Allowlist', _presaleStartTime, _presaleEndTime, _presalePrice);

    groupIdOasis = _createGroup('Oasis', _startTimes[0], 0, _salePrice);
    groupIdAllowlist = _createGroup('Allowlist', _startTimes[0], 0, _salePrice);
    groupIdPublicSale = _createGroup('Public Sale', _startTimes[1], 0, _salePrice);

    maxPerAddress = _maxPerAddress;

    for (uint256 i = 0; i < _allowlistedERC721Addresses.length; i++) {
      allowlistedERC721Addresses[i] = _allowlistedERC721Addresses[i];
    }

    _setAdminSigner(_allowlistSigner);
    oasis = _oasis;
  }

  /** @notice Pause the minter.
   * @dev Sets the minter state to Paused and pauses the minter and any mint functions. Only callable by admin.
   */
  function pause() public virtual onlyAdmin {
    _pause();
  }

  /** @notice Unpause the minter.
   * @dev Resumes normal minter state and any mint functions. Only callable by admin.
   */
  function unpause() public virtual onlyAdmin {
    _unpause();
  }

  /** @notice Sets the admin signer address.
   * @dev Can only be called by the contract admin.
   * @param _adminSigner The new admin signer address.
   */
  function setAdminSigner(address _adminSigner) public onlyAdmin {
    if (_adminSigner == address(0)) revert ZeroAddress();

    _setAdminSigner(_adminSigner);
  }

  /** @notice Sets the DelegateCash contract address.
   * @dev Can only be called by the contract admin.
   * @param _delegationRegistry The new delegation registry contract address.
   */
  function setDelegationRegistry(address _delegationRegistry) external onlyAdmin {
    delegationRegistry = IDelegationRegistry(_delegationRegistry);
  }

  /** @notice Sets the max per address.
   * @dev Sets the given max per address. Only callable by admin.
   * @param _maxPerAddress The new max per address.
   */
  function setMaxPerAddress(uint256 _maxPerAddress) public onlyAdmin {
    maxPerAddress = _maxPerAddress;
  }

  /** @notice Sets the group price.
   * @dev Sets the given group price. Only callable by admin.
   * @param _groupId The group ID. Must be a valid group ID.
   * @param _price The new price of the group. Must be non-zero.
   */
  function setGroupPrice(uint256 _groupId, uint256 _price) public virtual validGroup(_groupId) nonZeroAmount(_price) onlyAdmin {
    groups[_groupId].price = _price;
  }

  /** @notice Sets the group start time.
   * @dev Sets the given group start time. Only callable by admin.
   * @param _groupId The group ID. Must be a valid group ID.
   * @param _startTime The new start time of the group.
   */
  function setGroupStartTime(uint256 _groupId, uint256 _startTime) public virtual validGroup(_groupId) onlyAdmin {
    groups[_groupId].startTime = _startTime;
  }

  /** @notice Sets the group end time.
   * @dev Sets the given group end time. Only callable by admin.
   * @param _groupId The group ID. Must be a valid group ID.
   * @param _endTime The new end time of the group.
   */
  function setGroupEndTime(uint256 _groupId, uint256 _endTime) public virtual validGroup(_groupId) onlyAdmin {
    groups[_groupId].endTime = _endTime;
  }

  function setPresaleStartTime(uint256 _presaleStartTime) public onlyAdmin {
    presaleStartTime = _presaleStartTime;

    groups[presaleGroupIdOasis].startTime = _presaleStartTime;
    groups[presaleGroupIdAllowlist].startTime = _presaleStartTime;
  }

  function setPresaleEndTime(uint256 _presaleEndTime) public onlyAdmin {
    presaleEndTime = _presaleEndTime;

    groups[presaleGroupIdOasis].endTime = _presaleEndTime;
    groups[presaleGroupIdAllowlist].endTime = _presaleEndTime;
  }

  // public only-owner functions

  /** @notice Withdraws funds to wild and artist wallets.
   * @dev Withdraws the funds to wild and artist wallets acconting for royalty fees. Only callable by owner.
   */
  function withdraw() public virtual onlyOwner {
    _withdraw();
  }

  function withdrawToOwner() public virtual onlyOwner {
    (bool successWild, ) = wildWallet.call{value: address(this).balance}('');
    if (!successWild) revert FailedToWithdraw('wild', wildWallet);
  }

  function addAllowlistedNFTAddress(address _nftAddress) public onlyOwner {
    allowlistedERC721Addresses[numAllowlistedERC721Addresses++] = _nftAddress;
  }

  function removeAllowlistedNFTAddress(address _nftAddress) public onlyOwner {
    for (uint256 i = 0; i < numAllowlistedERC721Addresses; i++) {
      if (allowlistedERC721Addresses[i] == _nftAddress) {
        allowlistedERC721Addresses[i] = address(0);
      }
    }
  }

  // only-owner presale functions

  function processPresaleMint(uint256 _index) public onlyOwner {
    address receiver = presalePurchaseOwners[_index];

    if (presalePurchaseInfo[receiver].processed) revert AlreadyProcessedPresalePurchase();

    PresalePurchaseInfo storage purchaseInfo = presalePurchaseInfo[receiver];

    uint256 amount = Math.min(maxNFTsPerTransaction, purchaseInfo.amount - purchaseInfo.amountProcessed);

    uint256[] memory tokenIds = _mintMultiple(receiver, amount);

    emit PresalePurchaseProcessed(receiver, tokenIds);

    //if (purchaseInfo.amountProcessed == 0) {
      emit TokenMint(receiver, tokenIds, MintType.PresalePurchase, purchaseInfo.value, false, address(0), false, new uint256[](0));
    //}

    purchaseInfo.amountProcessed += amount;

    // mark as processed if we have processed all tokens
    if (purchaseInfo.amountProcessed == purchaseInfo.amount) {
      purchaseInfo.processed = true;
    }
   
    numPresaleMints += amount;
  }

  function processPresaleMintBatch(uint256 _fromIndex, uint256 _toIndex) public onlyOwner {
    for (uint256 i = _fromIndex; i < _toIndex; i++) {
      processPresaleMint(i);
    }
  }

  /*function revokePresalePurchase(uint256 _tokenId) public onlyOwner {
    PresalePurchaseInfo storage purchaseInfo = presalePurchaseInfo[_tokenId];

    if (purchaseInfo.processed) revert AlreadyProcessedPresalePurchase();

    purchaseInfo.processed = true;

    addressTotalSupply[purchaseInfo.owner] -= 1;

    presaleTotalSupply += 1;
  }

  function refundPresalePurchase(uint256 _tokenId) public onlyOwner {
    PresalePurchaseInfo storage purchaseInfo = presalePurchaseInfo[_tokenId];

    if (purchaseInfo.processed) revert AlreadyProcessedPresalePurchase();

    address payable receiver = payable(purchaseInfo.owner);
    uint256 price = purchaseInfo.price;

    (bool success, ) = receiver.call{value: price}('');
    if(!success) revert FailedToWithdraw('presale', receiver);

    purchaseInfo.processed = true;

    addressTotalSupply[purchaseInfo.owner] -= 1;

    presaleTotalSupply += 1;
  }*/

  // public functions

  /** @notice Get the current minter state.
   * @dev Returns the current minter state. If groups are not directly one after another (ie presale), it is possible to re-enter Setup state.
   * @return state Minter state (0 = Setup, 1 = Live, 2 = Complete, 3 = Paused).
   */
  function getState() public view virtual returns (State) {
    if (paused()) {
      return State.Paused;
    }

    // if sold out, return Complete state
    // NOTE: this would not work with a ReserveAuction where this minter holds the token!!!!
    if (_nftTotalSupply() == maxSupply) {
      return State.Complete;
    }

    // check if we are in any group using _isGroupLive
    // if we are in a group, return Live state
    // note: if groups are not directly one after another (ie presale), it is possible to re-enter Setup state
    for (uint256 i = 0; i < numGroups; i++) {
      if (_isGroupLive(i)) {
        return State.Live;
      }
    }

    return State.Setup;
  }

  function getUserGroup(address _user, bytes memory _signature) public view returns (uint256) {
    bool isPresaleLive = _isPresaleLive();

    if (oasis.balanceOf(_user) > 0) {
      return isPresaleLive ? presaleGroupIdOasis : groupIdOasis;
    }

    if (_isAllowlisted(_user, _signature) > 0) {
      return isPresaleLive ? presaleGroupIdAllowlist : groupIdAllowlist;
    }

    return groupIdPublicSale;
  }

  // returns user allowance: Y
  function getUserGroupAllowance(uint256 _groupId) public view returns (uint256) {
    uint256 supplyRemaining;

    if (_isPresaleGroup(_groupId)) {
      supplyRemaining = presaleMaxSupply - presaleTotalSupply;
    } else {
      supplyRemaining = maxSupply - _nftTotalSupply() - (presaleTotalSupply - numPresaleMints);
    }

    if (supplyRemaining == 0) {
      return 0;
    }

    return Math.min(maxPerAddress, supplyRemaining);
  }

  function getUserGroupTotalSupply(address _user, uint256 _groupId) public view returns (uint256) {
    if (_isPresaleGroup(_groupId)) {
      return presalePurchaseInfo[_user].amount;
    } else {
      return addressTotalSupply[_user];
    }
  }

  function getMinterInfo() public view returns (PresaleMinterInfo memory) {
    Group[] memory _groups = new Group[](numGroups);
    for (uint256 i = 0; i < numGroups; i++) {
      _groups[i] = groups[i];
    }

    return PresaleMinterInfo(getState(), _isPresaleLive(), maxSupply, _nftTotalSupply(), presaleMaxSupply, presaleTotalSupply, maxPerAddress, maxPerAddress, adminSigner, _groups);
  }

  function getUserInfo(address _user, bytes memory _signature) public view returns (UserInfo memory) {
    uint256 userGroupId = getUserGroup(_user, _signature);

    return UserInfo(userGroupId, getUserGroupAllowance(/*_user, */ userGroupId), getUserGroupTotalSupply(_user, userGroupId), _isGroupLive(userGroupId));
  }

  function getUserMinterInfo(address _user, bytes memory _signature) public view returns (UserInfo memory userInfo, PresaleMinterInfo memory minterInfo) {
    userInfo = getUserInfo(_user, _signature);
    minterInfo = getMinterInfo();
  }

  /** @notice Verifies the signature of the signer for a given address.
   * @param _address The address the message was signed for.
   * @param _signature The signature to verify.
   * @return valid True if the signature is valid, false otherwise.
   */
  function verifySignature(address _address, bytes memory _signature) public view returns (bool valid) {
    if (_signature.length == 65) {
      // we pass the uers _address and this contracts address to
      // verify that it is intended for this contract specifically
      bytes32 addressHash = keccak256(abi.encodePacked(_address, address(this)));
      bytes32 message = ECDSA.toEthSignedMessageHash(addressHash);
      address signerAddress = ECDSA.recover(message, _signature);

      return (signerAddress != address(0) && signerAddress == adminSigner);
    } else {
      return false;
    }
  }

  function getGroups() public view returns (Group[] memory _groups) {
    _groups = new Group[](numGroups);
    for (uint256 i = 0; i < numGroups; i++) {
      _groups[i] = groups[i];
    }
  }

  function getGroup(uint256 _groupId) public view validGroup(_groupId) returns (Group memory) {
    return groups[_groupId];
  }

  function getGroupStartTime(uint256 _groupId) public view validGroup(_groupId) returns (uint256) {
    return groups[_groupId].startTime;
  }

  function getGroupEndTime(uint256 _groupId) public view validGroup(_groupId) returns (uint256) {
    return groups[_groupId].endTime;
  }

  function getGroupPrice(uint256 _groupId) public view validGroup(_groupId) returns (uint256) {
    return groups[_groupId].price;
  }

  // mint functions

  // promo minting

  function promoMint(address _receiver, uint256 _amount, MintType _mintType) external onlyAdmin nonZeroAmount(_amount) {
    _promoMint(_receiver, _amount, _mintType);
  }

  function promoMintBatch(address[] memory _receiver, uint256[] memory _amounts, MintType _mintType) external onlyAdmin {
    _promoMintBatch(_receiver, _amounts, _mintType);
  }

  // public presale purchase

  function allowlistPresalePurchase(uint256 _amount, bytes memory _signature)
    public payable virtual
    onlyUnsanctioned(msg.sender)
    whenNotPaused
    nonReentrant
    onlyLive
    validAllowlistPresalePurchase(msg.sender, _amount)
  {
    uint256 allowlistType = _isAllowlisted(msg.sender, _signature);
    if (allowlistType == 0) revert NotOnAllowlist(msg.sender);

    MintType mintType = _mapAllowlistTypeToMintType(allowlistType);

    _onPresalePurchase(msg.sender, _amount, mintType);
  }

  function oasisPresalePurchase(uint256 _amount)
    public payable virtual
    onlyUnsanctioned(msg.sender)
    whenNotPaused
    nonReentrant
    onlyLive
    validOasisPresalePurchase(msg.sender, msg.sender, _amount)
  {
    _onPresalePurchase(msg.sender, _amount, MintType.Oasis);
  }

  function oasisPresalePurchaseDelegated(uint256 _amount, address _vault)
    public payable virtual
    onlyUnsanctioned(msg.sender)
    whenNotPaused
    nonReentrant
    onlyLive
    onlyDelegated(_vault, address(oasis))
    validOasisPresalePurchase(msg.sender, _vault, _amount)
  {
    _onPresalePurchase(msg.sender, _amount, MintType.Oasis);
  }

  // public minting

  function allowlistMint(uint256 _amount, bytes memory _signature)
    public payable virtual
    onlyUnsanctioned(msg.sender)
    whenNotPaused
    nonReentrant
    onlyLive
    validAllowlistMint(msg.sender, _amount)
  {
    uint256 allowlistType = _isAllowlisted(msg.sender, _signature);
    if (allowlistType == 0) revert NotOnAllowlist(msg.sender);

    MintType mintType = _mapAllowlistTypeToMintType(allowlistType);

    uint256[] memory tokenIds = _mintMultiple(msg.sender, _amount);

    _onAllowlistMint(msg.sender, tokenIds, mintType);
  }

  function oasisMint(uint256 _amount)
    public payable virtual
    onlyUnsanctioned(msg.sender)
    whenNotPaused
    nonReentrant
    onlyLive
    validOasisMint(msg.sender, msg.sender, _amount)
  {
    uint256[] memory tokenIds = _mintMultiple(msg.sender, _amount);

    _onOasisMint(msg.sender, tokenIds);
  }

  function oasisMintDelegated(uint256 _amount, address _vault)
    public payable virtual
    onlyUnsanctioned(msg.sender)
    whenNotPaused
    nonReentrant
    onlyLive
    onlyDelegated(_vault, address(oasis))
    validOasisMint(msg.sender, _vault, _amount)
  {
    uint256[] memory tokenIds = _mintMultiple(msg.sender, _amount);

    _onOasisMintDelegated(msg.sender, _vault, tokenIds);
  }

  function publicSaleMint(uint256 _amount)
    public payable virtual
    onlyUnsanctioned(msg.sender)
    whenNotPaused
    nonReentrant
    onlyLive
    validPublicSaleMint(msg.sender, _amount)
  {
    uint256[] memory tokenIds = _mintMultiple(msg.sender, _amount);

    _onPublicSaleMint(msg.sender, tokenIds);
  }
}
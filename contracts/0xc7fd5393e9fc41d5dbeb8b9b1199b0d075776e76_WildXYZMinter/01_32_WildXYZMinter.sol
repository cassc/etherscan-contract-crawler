// SPDX-License-Identifier: GPL-3.0-or-later

// ░██╗░░░░░░░██╗░██╗░██╗░░░░░░██████╗░░██╗░░██╗░██╗░░░██╗░███████╗
// ░██║░░██╗░░██║░██║░██║░░░░░░██╔══██╗░╚██╗██╔╝░╚██╗░██╔╝░╚════██║
// ░╚██╗████╗██╔╝░██║░██║░░░░░░██║░░██║░░╚███╔╝░░░╚████╔╝░░░░███╔═╝
// ░░████╔═████║░░██║░██║░░░░░░██║░░██║░░██╔██╗░░░░╚██╔╝░░░██╔══╝░░
// ░░╚██╔╝░╚██╔╝░░██║░███████╗░██████╔╝░██╔╝╚██╗░░░░██║░░░░███████╗
// ░░░╚═╝░░░╚═╝░░░╚═╝░╚══════╝░╚═════╝░░╚═╝░░╚═╝░░░░╚═╝░░░░╚══════╝

// It ain't much, but it's honest work.

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';

import '@openzeppelin/contracts/utils/math/Math.sol';

import '../WildNFT.sol';

import '../minter/utils/IOasis.sol';
import '../minter/utils/ISanctionsList.sol';

import './IWildXYZMinter.sol';

contract WildXYZMinter is
  IWildXYZMinter,
  Ownable,
  Pausable,
  ReentrancyGuard
{

  // private variables

  mapping(uint256 => Group) private groups;
  uint256 private numGroups;

  /// @dev One-time variable used to set up the contract.
  bool private isSetup = false;

  mapping(uint256 => uint8) private oasisPassMints;

  address public wildPassManager;


  // public variables

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

  uint256 public maxPerOasis;
  uint256 public maxPerAddress;

  uint256 groupIdOasis;
  uint256 groupIdAllowlist;
  uint256 groupIdPublicSale;

  mapping(address => uint256) public addressTotalOasisSupply; // oasis specific total minted
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

  modifier onlyAdminOrManager() {
    if (msg.sender != admin && msg.sender != wildPassManager) revert OnlyAdminOrManager();
    _;
  }

  modifier onlyLive() {
    if(getState() != State.Live) revert NotLive();
    _;
  }

  modifier validGroup(uint256 _groupId) {
    _validGroup(_groupId);
    _;
  }

  modifier validateSigner(address _address, bytes memory _signature) {
    if(!verifySignature(_address, _signature)) revert InvalidSignature(_signature);
    _;
  }

  modifier onlyUnsanctioned(address _to) {
      if (sanctionsList.isSanctioned(_to)) revert SanctionedAddress(_to);
      _;
  }

  modifier onlyDelegated(address _vault, address _contract) {
    if(!delegationRegistry.checkDelegateForContract(msg.sender, _vault, _contract))
      revert NotDelegated(msg.sender, _vault, _contract);
    _;
  }

  modifier nonZeroAmount(uint256 _amount) {
    _nonZeroAmount(_amount);
    _;
  }

  // modifier validation hooks

  modifier validAllowlistMint(address _receiver, uint256 _amount) {
    _validAllowlistMint(_receiver, _amount);
    _;
  }

  modifier validOasisMint(address _receiver, uint256 _amount) {
    _validOasisMint(_receiver, _amount);
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
  constructor(
    uint256 _maxSupply,
    uint256 _wildRoyalty,
    address _wildWallet,
    address _artistWallet,
    address _admin,
    ISanctionsList _sanctions,
    WildNFT _nft
  ) {
    maxSupply = _maxSupply;
    wildRoyalty = _wildRoyalty;
    wildWallet = payable(_wildWallet);
    artistWallet = payable(_artistWallet);
    admin = _admin;
    sanctionsList = _sanctions;
    nft = _nft;
  }
  

  // internal functions

  function _createGroup(string memory _name, uint256 _startTime, uint256 _price) internal onlyOwner returns (uint256 groupId) {
    groupId = numGroups;

    groups[groupId] = Group(_name, groupId, _startTime, _price);

    numGroups++;
  }

  // function validation hooks

  function _nonZeroAmount(uint256 _amount) internal pure {
    if (_amount < 1) revert ZeroAmount();
  }

  function _validGroup(uint256 _groupId) internal view {
    if(_groupId >= numGroups) revert GroupDoesNotExist(_groupId);
  }

  function _groupAllowed(uint256 _group) internal view {
    if (block.timestamp < groups[_group].startTime) revert GroupNotStarted(_group);
  }

  function _validPrice(uint256 _amount, uint256 _groupId) internal view {
    if(msg.value < _amount * groups[_groupId].price) revert InsufficientFunds();
  }

  function _validSupply(uint256 _amount) internal view {
    if(_nftTotalSupply() + _amount > maxSupply) revert MaxSupplyExceeded();
  }

  function _validAllowance(address _receiver, uint256 _amount) internal view {
    if(addressTotalSupply[_receiver] + _amount > maxPerAddress) revert MaxPerAddressExceeded(_receiver, _amount);
  }

  function _validGroupPriceSupplyAllowance(uint256 _groupId, uint256 _amount, address _receiver) internal view {
    _groupAllowed(_groupId);
    _validPrice(_amount, _groupId);
    _validSupply(_amount);
    _validAllowance(_receiver, _amount);
  }

  function _validGroupPriceSupply(uint256 _groupId, uint256 _amount) internal view {
    _groupAllowed(_groupId);
    _validPrice(_amount, _groupId);
    _validSupply(_amount);
  }

  // public mint validation hooks

  function _validAllowlistMint(address _receiver, uint256 _amount) internal virtual {
    _validGroupPriceSupplyAllowance(groupIdAllowlist, _amount, _receiver);
  }
  
  function _validOasisMint(address /*_receiver*/, uint256 _amount) internal virtual {
    _validGroupPriceSupply(groupIdOasis, _amount);
  }

  function _validPublicSaleMint(address _receiver, uint256 _amount) internal virtual {
    _validGroupPriceSupplyAllowance(groupIdPublicSale, _amount, _receiver);
  }

  // on-mint hooks

  function _onPromoMint(address _receiver, uint256[] memory _tokenIds, MintType _mintType) internal virtual {
    promoMintTotalSupply += _tokenIds.length;

    emit TokenMint(_receiver, _tokenIds, _mintType, msg.value, false, address(0), false, new uint256[](0));
  }

  function _onAllowlistMint(address _receiver, uint256[] memory _tokenIds) internal virtual {
    _addAddressTotalSupply(_receiver, _tokenIds.length);

    emit TokenMint(_receiver, _tokenIds, MintType.Allowlist, msg.value, false, address(0), false, new uint256[](0));
  }

  function _onOasisMint(address _receiver, uint256[] memory _tokenIds, uint256[] memory _oasisIds) internal virtual {
    //_addAddressTotalSupply(_receiver, _tokenIds.length);
    addressTotalOasisSupply[_receiver] += _tokenIds.length;

    emit TokenMint(_receiver, _tokenIds, MintType.Oasis, msg.value, false, address(0), true, _oasisIds);
  }

  function _onOasisMintDelegated(address _receiver, address _vault, uint256[] memory _tokenIds, uint256[] memory _oasisIds) internal virtual {
    //_addAddressTotalSupply(_receiver, _tokenIds.length);
    addressTotalOasisSupply[_vault] += _tokenIds.length;

    emit TokenMint(_receiver, _tokenIds, MintType.Oasis, msg.value, true, _vault, true, _oasisIds);
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
      if(!successWild) revert FailedToWithdraw('wild', wildWallet);
    }

    // then, send the rest to payee
    (bool successPayee, ) = artistWallet.call{value: address(this).balance}('');
    if(!successPayee) revert FailedToWithdraw('artist', artistWallet);
  }

  /// @dev Sets the admin signer address.
  function _setAdminSigner(address _adminSigner) internal {
    adminSigner = _adminSigner;
  }

  /// @dev Sets the wild pass manager.
  function _setWildPassManager(address _wildPassManager) internal {
    wildPassManager = _wildPassManager;
  }

  /// @dev Wraps the nft.totalSupply call.
  function _nftTotalSupply() internal view virtual returns (uint256) {
    return nft.totalSupply();
  }

  /** @dev Internal mint function. Use if minting only 1 token.
    * @param _to Token receiver address.
    * @return tokenId Newly minted Token ID.
    */
  function _mint(address _to) internal virtual returns (uint256 tokenId) {
    tokenId = nft.mint(_to);
  }

  /** @dev Internal mint multiple function. Use if minting more than 1 token.
    * @param _to Token receiver address.
    * @param _amount Amount to mint.
    * @return tokenIds Newly minted Token IDs.
    */
  function _mintMultiple(address _to, uint256 _amount) internal virtual returns (uint256[] memory tokenIds) {
    tokenIds = new uint256[](_amount);
    
    for (uint256 i = 0; i < _amount; i++) {
      uint256 tokenId = nft.mint(_to);
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
    if(_receiver.length == 0 || _receiver.length != _amounts.length) revert ArraySizeMismatch();

    // sum amounts to validate total supply
    uint256 totalAmount = 0;
    for (uint256 i = 0; i < _amounts.length; i++) {
      totalAmount += _amounts[i];
    }
    
    if(_nftTotalSupply() + totalAmount > maxSupply) revert MaxSupplyExceeded();

    for (uint256 i = 0; i < _receiver.length; i++) {
      address to = _receiver[i];
      uint256 amount = _amounts[i];

      uint256[] memory tokenIds = _mintMultiple(to, amount);

      _onPromoMint(to, tokenIds, _mintType);
    }
  }

  function _getOasisMintAllowance(address _oasisOwner, uint256 _oasisBalance) internal view returns (uint256 quantity) {
    for (uint256 i = 0; i < _oasisBalance; i++) {
      uint256 oasisId = oasis.tokenOfOwnerByIndex(_oasisOwner, i);
      quantity += (maxPerOasis > oasisPassMints[oasisId] ? maxPerOasis - oasisPassMints[oasisId] : 0);
    }
  }

  function _processOasisMint(address _receiver, address _requester, uint256 _amount) internal virtual returns (uint256[] memory tokenIds, uint256[] memory oasisIds) {
    uint256 oasisBalance = oasis.balanceOf(_requester);

    if (_getOasisMintAllowance(_requester, oasisBalance) == 0) revert ZeroOasisAllowance(_receiver);

    /*if (getPhaseAddressMinted(_receiver, oasisPhaseId) + _amount > (oasisBalance * maxAllowancePerWallet))
      revert MaxPerAddressExceeded(oasisPhaseId);*/

    uint256 mintsLeft = _amount;
    uint256 totalMinted = 0;

    tokenIds = new uint256[](_amount);
    oasisIds = new uint256[](_amount);

    for (uint256 i = 0; i < oasisBalance; i++) {
      uint256 oasisId = oasis.tokenOfOwnerByIndex(_requester, i);
      uint256 tokenAllowance = maxPerOasis - oasisPassMints[oasisId];

      if (tokenAllowance == 0) {
        // Oasis pass been fully minted
        continue;
      }

      uint8 quantityMintedWithOasis = uint8(Math.min(tokenAllowance, mintsLeft));

      oasisPassMints[oasisId] += quantityMintedWithOasis;
      mintsLeft -= quantityMintedWithOasis;

      for (uint256 j = 0; j < quantityMintedWithOasis; j++) {
        uint256 tokenId = _mint(_receiver);

        tokenIds[totalMinted + j] = tokenId;
        oasisIds[totalMinted + j] = oasisId;
      }

      totalMinted += quantityMintedWithOasis;
    }

    if (mintsLeft != 0) revert NotEnoughOasisMints(_requester);
  }


  // public admin-only functions

  function setup(
    uint256[3] memory _startTimes,
    uint256[3] memory _prices,
    uint256 _maxPerOasis,
    uint256 _maxPerAddress,
    address _allowlistSigner,
    IOasis _oasis
  ) public setupOnce onlyOwner {
    groupIdOasis = _createGroup('Oasis', _startTimes[0], _prices[0]);
    groupIdAllowlist = _createGroup('Allowlist', _startTimes[1], _prices[1]);
    groupIdPublicSale = _createGroup('Public Sale', _startTimes[2], _prices[2]);

    maxPerOasis = _maxPerOasis;
    maxPerAddress = _maxPerAddress;

    _setAdminSigner(_allowlistSigner);
    oasis = _oasis;

    _setWildPassManager(admin); // default to admin
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

  function setWildPassManager(address _manager) public onlyOwner {
    _setWildPassManager(_manager);
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

  /** @notice Sets the max per oasis.
    * @dev Sets the given max per oasis. Only callable by admin.
    * @param _maxPerOasis The new max per oasis.
    */
  function setMaxPerOasis(uint256 _maxPerOasis) public onlyAdmin {
    maxPerOasis = _maxPerOasis;
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
    if(_groupId > 0 && _startTime < groups[_groupId - 1].startTime) revert InvalidGroupStartTime(_startTime);

    groups[_groupId].startTime = _startTime;
  }

  // public only-owner functions

  /** @notice Withdraws funds to wild and artist wallets.
    * @dev Withdraws the funds to wild and artist wallets acconting for royalty fees. Only callable by owner.
    */
  function withdraw() public virtual onlyOwner {
      _withdraw();
  }


  // public functions

  /** @notice Get the current minter state.
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

    // if the first phase has started, we are selling baby!!!
    if (numGroups > 0 && block.timestamp >= groups[0].startTime) {
      return State.Live;
    }
    
    return State.Setup;
  }

  function getOasisPassMintsFromUser(address _user) public view returns (uint256[] memory mintsPerTokenId) {
    uint256 oasisBalance = oasis.balanceOf(_user);
    mintsPerTokenId = new uint256[](oasisBalance);

    for (uint256 i = 0; i < oasisBalance; i++) {
      uint256 oasisId = oasis.tokenOfOwnerByIndex(_user, i);
      mintsPerTokenId[oasisId] = maxPerOasis - oasisPassMints[oasisId];
    }
  }

  function getUserGroup(address _user, bytes memory _signature) public view returns (uint256) {
    uint256 oasisBalance = oasis.balanceOf(_user);

    if (oasisBalance > 0) {
      return groupIdOasis;
    }
    
    if (verifySignature(_user, _signature)) {
      return groupIdAllowlist;
    }
    
    return groupIdPublicSale;
  }
  
  // returns user allowance: Y
  function getUserGroupAllowance(address _user, uint256 _groupId) public view returns (uint256) {
    uint256 supplyRemaining = maxSupply - _nftTotalSupply();
    if (supplyRemaining == 0) {
      return 0;
    }

    uint256 oasisBalance = oasis.balanceOf(_user);

    if (oasisBalance > 0 || _groupId == groupIdOasis) {
      // Y = # oasis * S (S = maxPerOasis)
      if (oasisBalance > 0) {
        // if user owns oasis, count max allowance as num. oasis * maxPerOasis
        return Math.min(getOasisMintAllowance(_user), supplyRemaining);
      }

      return 0;
    }
    
    // Y = R (R = maxPerAddress)
    return Math.min(maxPerAddress - addressTotalSupply[_user], supplyRemaining);
  }

  function getUserGroupTotalSupply(address _user, uint256 _groupId) public view returns (uint256) {
    if (_groupId == groupIdOasis) {
      return addressTotalOasisSupply[_user];
    } else {
      return addressTotalSupply[_user];
    }
  }

  function getMinterInfo() public view returns (MinterInfo memory) {
    Group[] memory _groups = new Group[](numGroups);
    for (uint256 i = 0; i < numGroups; i++) {
      _groups[i] = groups[i];
    }

    return MinterInfo(
      getState(),
      maxSupply,
      _nftTotalSupply(),
      maxPerOasis,
      maxPerAddress,
      adminSigner,
      _groups
    );
  }

  function getUserInfo(address _user, bytes memory _signature) public view returns (UserInfo memory) {
    uint256 userGroupId = getUserGroup(_user, _signature);

    bool isGroupLive = block.timestamp >= groups[userGroupId].startTime;

    return UserInfo(
      userGroupId,
      getUserGroupAllowance(_user, userGroupId),
      getUserGroupTotalSupply(_user, userGroupId),
      isGroupLive
    );
  }

  function getUserMinterInfo(address _user, bytes memory _signature) public view returns (UserInfo memory userInfo, MinterInfo memory minterInfo) {
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

  function wildPassMint(address _receiver, uint256 _amount)
    external payable
    onlyAdminOrManager
    nonZeroAmount(_amount)
    nonZeroAmount(msg.value)
  {
    _promoMint(_receiver, _amount, MintType.WildPass);
  }

  function wildPassMintBatch(address[] memory _receiver, uint256[] memory _amounts)
    external payable
    onlyAdminOrManager
    nonZeroAmount(msg.value)
  {
    _promoMintBatch(_receiver, _amounts, MintType.WildPass);
  }

  // public minting

  function allowlistMint(uint256 _amount, bytes memory _signature)
    public virtual payable
    onlyUnsanctioned(msg.sender)
    whenNotPaused
    nonReentrant
    onlyLive
    validateSigner(msg.sender, _signature)
    validAllowlistMint(msg.sender, _amount)
  {
    uint256[] memory tokenIds = _mintMultiple(msg.sender, _amount);

    _onAllowlistMint(msg.sender, tokenIds);
  }

  function getOasisMintAllowance(address _oasisOwner) public view returns (uint256) {
    uint256 oasisBalance = oasis.balanceOf(_oasisOwner);

    return _getOasisMintAllowance(_oasisOwner, oasisBalance);
  }

  function oasisMint(uint256 _amount)
    public payable virtual
    onlyUnsanctioned(msg.sender)
    whenNotPaused
    nonReentrant
    onlyLive
    validOasisMint(msg.sender, _amount)
  {
    (uint256[] memory tokenIds, uint256[] memory oasisIds) = _processOasisMint(msg.sender, msg.sender, _amount);

    _onOasisMint(msg.sender, tokenIds, oasisIds);
  }

  function oasisMintDelegated(uint256 _amount, address _vault)
    public payable virtual
    onlyUnsanctioned(msg.sender)
    whenNotPaused
    nonReentrant
    onlyLive
    onlyDelegated(_vault, address(oasis))
    validOasisMint(_vault, _amount)
  {
    (uint256[] memory tokenIds, uint256[] memory oasisIds) = _processOasisMint(msg.sender, _vault, _amount);

    _onOasisMintDelegated(msg.sender, _vault, tokenIds, oasisIds);
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
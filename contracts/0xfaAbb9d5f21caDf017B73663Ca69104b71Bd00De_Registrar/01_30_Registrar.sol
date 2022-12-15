// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// This is only kept for backward compatability / upgrading
import {OwnableUpgradeable} from "../oz/access/OwnableUpgradeable.sol";
import {EnumerableMapUpgradeable, ERC721PausableUpgradeable, IERC721Upgradeable, ERC721Upgradeable, IERC721MetadataUpgradeable} from "../oz/token/ERC721/ERC721PausableUpgradeable.sol";
import {IRegistrar} from "../interfaces/IRegistrar.sol";
import {StorageSlot} from "../oz/utils/StorageSlot.sol";
import {BeaconProxy} from "../oz/proxy/beacon/BeaconProxy.sol";
import {IZNSHub} from "../interfaces/IZNSHub.sol";
import {OperatorFilterer} from "../opensea/OperatorFilterer.sol";
import {CustomStrings} from "../CustomStrings.sol";

contract Registrar is
  IRegistrar,
  OwnableUpgradeable,
  ERC721PausableUpgradeable,
  OperatorFilterer
{
  using EnumerableMapUpgradeable for EnumerableMapUpgradeable.UintToAddressMap;

  error InvalidFolderGroup();
  error SameFolderGroup();
  error NotAuthorized();
  error ControllerAlreadyAdded();
  error ControllerNotExists();
  error NotController();
  error EmptyDomainName();
  error SubdomainParent();
  error DomainGroupNotExists();
  error ShouldUpdateViaDomainGroup();
  error SameMetadataUri();
  error NoParentDomain();
  error LockedMetadata();
  error NotLockedMetadata();
  error NotMetadataLocker();
  error NotApprovedOrOwner();
  error DomainNotExists();
  error NotDomainOwner();
  error InvalidDomainIndex();

  // Data recorded for each domain
  struct DomainRecord {
    address minter;
    bool metadataLocked;
    address metadataLockedBy;
    address controller;
    uint256 royaltyAmount;
    uint256 parentId;
    address subdomainContract;
    // This is the folder group the domain belongs to
    uint256 domainGroup;
    // This is the index in that group (/0, /1, /2, /3)
    uint256 domainGroupFileIndex;
  }

  struct DomainGroup {
    string baseMetadataUri;
  }

  // A map of addresses that are authorised to register domains.
  mapping(address => bool) public controllers;

  // A mapping of domain id's to domain data
  // This essentially expands the internal ERC721's token storage to additional fields
  mapping(uint256 => DomainRecord) public records;

  /**
   * @dev Storage slot with the admin of the contract.
   */
  bytes32 internal constant _ADMIN_SLOT =
    0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

  // The beacon address
  address public beacon;

  // If this is a subdomain contract these will be set
  uint256 public rootDomainId;
  address public parentRegistrar;

  // The event emitter
  IZNSHub public zNSHub;
  uint8 private test; // ignore
  uint256 private gap; // ignore

  // 0 is the null case
  mapping(uint256 => DomainGroup) public domainGroups;
  uint256 public numDomainGroups;

  /**
   * Creates a new folder group
   * @param baseMetadataUri The entire base uri (include ipfs://.../)
   */
  function createDomainGroup(
    string memory baseMetadataUri
  ) public returns (uint256) {
    _onlyController();
    domainGroups[numDomainGroups + 1] = DomainGroup({
      baseMetadataUri: baseMetadataUri
    });
    ++numDomainGroups; // increment number of folders

    zNSHub.domainGroupUpdated(numDomainGroups, baseMetadataUri);

    return numDomainGroups;
  }

  /**
   * Updates a folder group
   * @param id The id of the folder group
   * @param baseMetadataUri The entire base uri (include ipfs://.../)
   */
  function updateDomainGroup(
    uint256 id,
    string memory baseMetadataUri
  ) external {
    _onlyController();
    if (id == 0 || id > numDomainGroups) {
      revert InvalidFolderGroup();
    }
    if (
      keccak256(abi.encodePacked(domainGroups[id].baseMetadataUri)) ==
      keccak256(abi.encodePacked(baseMetadataUri))
    ) {
      revert SameFolderGroup();
    }
    domainGroups[id].baseMetadataUri = baseMetadataUri;

    zNSHub.domainGroupUpdated(id, baseMetadataUri);
  }

  function _getAdmin() internal view returns (address) {
    return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
  }

  /**
   * @notice Returns whether or not an account is a a controller registered on this contract
   * @param account Address of account to check
   */
  function isController(address account) external view override returns (bool) {
    return controllers[account];
  }

  function initialize(
    address parentRegistrar_,
    uint256 rootDomainId_,
    string calldata collectionName,
    string calldata collectionSymbol,
    address zNSHub_
  ) public initializer {
    // __Ownable_init(); // Purposely not initializing ownable since we override owner()

    if (parentRegistrar_ == address(0)) {
      // create the root domain
      _createDomain(0, 0, msg.sender, address(0), 0, 0);
    } else {
      rootDomainId = rootDomainId_;
      parentRegistrar = parentRegistrar_;
    }

    zNSHub = IZNSHub(zNSHub_);

    __ERC721Pausable_init();
    __ERC721_init(collectionName, collectionSymbol);
    _initializeFilter(
      address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6),
      true
    );
  }

  function owner() public view override returns (address) {
    return zNSHub.owner();
  }

  /*
   * External Methods
   */

  /**
   * @notice Authorizes a controller to control the registrar
   * @param controller The address of the controller
   */
  function addController(address controller) external {
    if (msg.sender != owner() && msg.sender != parentRegistrar) {
      revert NotAuthorized();
    }
    if (controllers[controller]) {
      revert ControllerAlreadyAdded();
    }
    controllers[controller] = true;
    emit ControllerAdded(controller);
  }

  /**
   * @notice Unauthorizes a controller to control the registrar
   * @param controller The address of the controller
   */
  function removeController(address controller) external override onlyOwner {
    if (msg.sender != owner() && msg.sender != parentRegistrar) {
      revert NotAuthorized();
    }
    if (!controllers[controller]) {
      revert ControllerNotExists();
    }
    controllers[controller] = false;
    emit ControllerRemoved(controller);
  }

  /**
   * @notice Pauses the registrar. Can only be done when not paused.
   */
  function pause() external onlyOwner {
    _pause();
  }

  /**
   * @notice Unpauses the registrar. Can only be done when not paused.
   */
  function unpause() external onlyOwner {
    _unpause();
  }

  /**
   * @notice Registers a new (sub) domain
   * @param parentId The parent domain
   * @param label The label of the domain
   * @param minter the minter of the new domain
   * @param metadataUri The uri of the metadata
   * @param royaltyAmount The amount of royalty this domain pays
   * @param locked Whether the domain is locked or not
   */
  function registerDomain(
    uint256 parentId,
    string memory label,
    address minter,
    string memory metadataUri,
    uint256 royaltyAmount,
    bool locked
  ) external override returns (uint256) {
    _onlyController();
    return
      _registerDomain(
        parentId,
        label,
        minter,
        metadataUri,
        royaltyAmount,
        locked
      );
  }

  function registerDomainAndSend(
    uint256 parentId,
    string memory label,
    address minter,
    string memory metadataUri,
    uint256 royaltyAmount,
    bool locked,
    address sendToUser
  ) external override returns (uint256) {
    _onlyController();
    // Register the domain
    uint256 id = _registerDomain(
      parentId,
      label,
      minter,
      metadataUri,
      royaltyAmount,
      locked
    );

    // immediately send domain to user
    _safeTransfer(minter, sendToUser, id, "");

    return id;
  }

  function registerSubdomainContract(
    uint256 parentId,
    string memory label,
    address minter,
    string memory metadataUri,
    uint256 royaltyAmount,
    bool locked,
    address sendToUser
  ) external returns (uint256) {
    _onlyController();
    // Register domain, `minter` is the minter
    uint256 id = _registerDomain(
      parentId,
      label,
      minter,
      metadataUri,
      royaltyAmount,
      locked
    );

    // Create subdomain contract as a beacon proxy
    address subdomainContract = address(
      new BeaconProxy(zNSHub.registrarBeacon(), "")
    );

    // More maintainable instead of using `data` in constructor
    Registrar(subdomainContract).initialize(
      address(this),
      id,
      "Zer0 Name Service",
      "ZNS",
      address(zNSHub)
    );

    // Indicate that the subdomain has a contract
    records[id].subdomainContract = subdomainContract;

    zNSHub.addRegistrar(id, subdomainContract);

    // immediately send the domain to the user (from the minter)
    _safeTransfer(minter, sendToUser, id, "");

    return id;
  }

  function _registerDomain(
    uint256 parentId,
    string memory label,
    address minter,
    string memory metadataUri,
    uint256 royaltyAmount,
    bool locked
  ) internal returns (uint256) {
    return
      _registerDomainV2(
        parentId,
        label,
        minter,
        metadataUri,
        royaltyAmount,
        locked,
        0,
        0
      );
  }

  function _registerDomainV2(
    uint256 parentId,
    string memory label,
    address minter,
    string memory metadataUri,
    uint256 royaltyAmount,
    bool locked,
    uint256 groupId, // 0 is null
    uint256 groupFileIndex // ignored if groupId is 0
  ) internal returns (uint256) {
    if (bytes(label).length == 0) {
      revert EmptyDomainName();
    }
    // subdomain cannot be minted on domains which are subdomain contracts
    if (records[parentId].subdomainContract != address(0)) {
      revert SubdomainParent();
    }
    if (groupId > numDomainGroups) {
      revert DomainGroupNotExists();
    }
    if (parentId != rootDomainId && !_exists(parentId)) {
      revert NoParentDomain();
    }

    // Create the child domain under the parent domain
    uint256 labelHash = uint256(keccak256(bytes(label)));

    // Calculate the new domain's id and create it
    uint256 domainId = uint256(
      keccak256(abi.encodePacked(parentId, labelHash))
    );

    // Create not inside of a domain group
    _createDomain(
      parentId,
      domainId,
      minter,
      msg.sender,
      groupId,
      groupFileIndex
    );
    if (locked) {
      records[domainId].metadataLockedBy = minter;
      records[domainId].metadataLocked = true;
    }

    if (royaltyAmount > 0) {
      records[domainId].royaltyAmount = royaltyAmount;
    }

    // No domain group was defined
    if (groupId == 0) {
      _setTokenURI(domainId, metadataUri);
    }

    zNSHub.domainCreated(
      domainId,
      label,
      labelHash,
      parentId,
      minter,
      msg.sender,
      metadataUri,
      royaltyAmount,
      groupId,
      groupFileIndex
    );

    return domainId;
  }

  /**
   * @notice Sets the domain royalty amount
   * @param id The domain to set on
   * @param amount The royalty amount
   */
  function setDomainRoyaltyAmount(
    uint256 id,
    uint256 amount
  ) external override {
    _onlyOwnerOf(id);
    if (isDomainMetadataLocked(id)) {
      revert LockedMetadata();
    }

    records[id].royaltyAmount = amount;
    zNSHub.royaltiesAmountChanged(id, amount);
  }

  /**
   * @notice Both sets and locks domain metadata uri in a single call
   * @param id The domain to lock
   * @param uri The uri to set
   */
  function setAndLockDomainMetadata(
    uint256 id,
    string memory uri
  ) external override {
    _onlyOwnerOf(id);
    if (isDomainMetadataLocked(id)) {
      revert LockedMetadata();
    }
    _setDomainMetadataUri(id, uri);
    _setDomainLock(id, msg.sender, true);
  }

  /**
   * @notice Sets the domain metadata uri
   * @param id The domain to set on
   * @param uri The uri to set
   */
  function setDomainMetadataUri(
    uint256 id,
    string memory uri
  ) external override {
    _onlyOwnerOf(id);
    if (isDomainMetadataLocked(id)) {
      revert LockedMetadata();
    }
    _setDomainMetadataUri(id, uri);
  }

  /**
   * @notice Locks a domains metadata uri
   * @param id The domain to lock
   * @param toLock whether the domain should be locked or not
   */
  function lockDomainMetadata(uint256 id, bool toLock) external override {
    _validateLockDomainMetadata(id, toLock);
    _setDomainLock(id, msg.sender, toLock);
  }

  /**
   * @notice transferFrom but many at a time
   * @param from Current owner of token
   * @param to New desired owner of token
   * @param tokenIds The tokens to ransfer
   */
  function transferFromBulk(
    address from,
    address to,
    uint256[] calldata tokenIds
  ) public {
    for (uint256 i = 0; i < tokenIds.length; ++i) {
      uint256 tokenId = tokenIds[i];
      if (!_isApprovedOrOwner(_msgSender(), tokenId)) {
        revert NotApprovedOrOwner();
      }

      _transfer(from, to, tokenId);
    }
  }

  function setApprovalForAll(
    address operator,
    bool approved
  ) public override(ERC721Upgradeable, IERC721Upgradeable) {
    _onlyAllowedOperatorApproval(operator);
    super.setApprovalForAll(operator, approved);
  }

  function approve(
    address operator,
    uint256 tokenId
  ) public override(ERC721Upgradeable, IERC721Upgradeable) {
    _onlyAllowedOperatorApproval(operator);
    super.approve(operator, tokenId);
  }

  /*
   * Public View
   */

  function ownerOf(
    uint256 tokenId
  )
    public
    view
    virtual
    override(ERC721Upgradeable, IERC721Upgradeable)
    returns (address)
  {
    // Check if the token is in this contract
    if (_tokenOwners.contains(tokenId)) {
      return
        _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
    }

    return zNSHub.ownerOf(tokenId);
  }

  /**
   * @notice Returns whether or not a domain is exists
   * @param id The domain
   */
  function domainExists(uint256 id) public view override returns (bool) {
    return _exists(id);
  }

  /**
   * @notice Returns the original minter of a domain
   * @param id The domain
   */
  function minterOf(uint256 id) public view override returns (address) {
    return records[id].minter;
  }

  /**
   * @notice Returns whether or not a domain's metadata is locked
   * @param id The domain
   */
  function isDomainMetadataLocked(
    uint256 id
  ) public view override returns (bool) {
    return records[id].metadataLocked;
  }

  /**
   * @notice Returns who locked a domain's metadata
   * @param id The domain
   */
  function domainMetadataLockedBy(
    uint256 id
  ) public view override returns (address) {
    return records[id].metadataLockedBy;
  }

  /**
   * @notice Returns the controller which created the domain on behalf of a user
   * @param id The domain
   */
  function domainController(uint256 id) public view override returns (address) {
    return records[id].controller;
  }

  /**
   * @notice Returns the current royalty amount for a domain
   * @param id The domain
   */
  function domainRoyaltyAmount(
    uint256 id
  ) public view override returns (uint256) {
    return records[id].royaltyAmount;
  }

  /**
   * @notice Returns the parent id of a domain.
   * @param id The domain
   */
  function parentOf(uint256 id) public view override returns (uint256) {
    if (!_exists(id)) {
      revert DomainNotExists();
    }
    return records[id].parentId;
  }

  function tokenURI(
    uint256 tokenId
  )
    public
    view
    virtual
    override(IERC721MetadataUpgradeable, ERC721Upgradeable)
    returns (string memory)
  {
    if (!_exists(tokenId)) {
      revert DomainNotExists();
    }

    // figure out uri based on domain group
    if (records[tokenId].domainGroup != 0) {
      return
        string(
          abi.encodePacked(
            domainGroups[records[tokenId].domainGroup].baseMetadataUri,
            CustomStrings.toString(records[tokenId].domainGroupFileIndex)
          )
        );
    }

    return super.tokenURI(tokenId);
  }

  /*
   * Internal Methods
   */

  function _transfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override {
    _onlyAllowedOperator(from);
    super._transfer(from, to, tokenId);
    // Need to emit transfer events on event emitter
    zNSHub.domainTransferred(from, to, tokenId);
  }

  function _onlyOwnerOf(uint256 id) internal view {
    if (ownerOf(id) != msg.sender) {
      revert NotDomainOwner();
    }
  }

  function _onlyController() internal {
    if (!controllers[msg.sender] && !zNSHub.isController(msg.sender)) {
      revert NotController();
    }
  }

  function _setDomainMetadataUri(uint256 id, string memory uri) internal {
    if (records[id].domainGroup != 0) {
      revert ShouldUpdateViaDomainGroup();
    }
    if (
      keccak256(abi.encodePacked(tokenURI(id))) ==
      keccak256(abi.encodePacked(uri))
    ) {
      // the call to public function `tokenUri` will perform an `_exists` check
      revert SameMetadataUri(); // this error must be made
    }
    _setTokenURI(id, uri);
    zNSHub.metadataChanged(id, uri);
  }

  function _validateLockDomainMetadata(uint256 id, bool toLock) internal view {
    if (toLock) {
      if (ownerOf(id) != msg.sender) {
        revert NotDomainOwner();
      }
      if (isDomainMetadataLocked(id)) {
        revert LockedMetadata();
      }
    } else {
      if (!isDomainMetadataLocked(id)) {
        revert NotLockedMetadata();
      }
      if (domainMetadataLockedBy(id) != msg.sender) {
        revert NotMetadataLocker();
      }
    }
  }

  // internal - creates a domain
  function _createDomain(
    uint256 parentId,
    uint256 domainId,
    address minter,
    address controller,
    uint256 domainGroupId,
    uint256 domainGroupFileIndex
  ) internal {
    // Create the NFT and register the domain data
    _mint(minter, domainId);
    records[domainId] = DomainRecord({
      parentId: parentId,
      minter: minter,
      metadataLocked: false,
      metadataLockedBy: address(0),
      controller: controller,
      royaltyAmount: 0,
      subdomainContract: address(0),
      domainGroup: domainGroupId,
      domainGroupFileIndex: domainGroupFileIndex
    });
  }

  function _setDomainLock(
    uint256 id,
    address locker,
    bool lockStatus
  ) internal {
    records[id].metadataLockedBy = locker;
    records[id].metadataLocked = lockStatus;

    zNSHub.metadataLockChanged(id, locker, lockStatus);
  }

  function adminBurnToken(uint256 tokenId) external onlyOwner {
    _burn(tokenId);
    delete (records[tokenId]);
  }

  function adminSetMetadataBulk(
    string memory folderWithIPFSPrefix,
    uint256[] memory orderedIds,
    uint256 ipfsFolderIndexOffset
  ) external onlyOwner {
    for (uint256 i = 0; i < orderedIds.length; ++i) {
      _setDomainMetadataUri(
        orderedIds[i],
        string(
          abi.encodePacked(
            folderWithIPFSPrefix,
            CustomStrings.toString(ipfsFolderIndexOffset + i)
          )
        )
      );
    }
  }

  /**
   * Sets metadata via IPFS folder in a bulk fashion via token index (not token ID)
   * @param folderWithIPFSPrefix the IPFS Folder (ie: "ipfs://QmABCDEFG/")
   * @param tokenIndexStart The token index starting point
   * @param ipfsFolderIndexStart The IPFS folder index starting point
   * @param count The number of tokens to modify [start index -> start index + count]
   */
  function adminSetMetadataBulkByIndex(
    string memory folderWithIPFSPrefix,
    uint256 tokenIndexStart,
    uint256 ipfsFolderIndexStart,
    uint256 count
  ) external onlyOwner {
    for (uint256 i = 0; i < count; ++i) {
      _setDomainMetadataUri(
        tokenByIndex(tokenIndexStart + i),
        string(
          abi.encodePacked(
            folderWithIPFSPrefix,
            CustomStrings.toString(ipfsFolderIndexStart + i)
          )
        )
      );
    }
  }

  function adminTransfer(
    address from,
    address to,
    uint256 tokenId
  ) external onlyOwner {
    _transfer(from, to, tokenId);
  }

  function adminSetMetadataUri(
    uint256 id,
    string memory uri
  ) external onlyOwner {
    _setDomainMetadataUri(id, uri);
  }

  function setZNSHub(IZNSHub hub) external onlyOwner {
    zNSHub = hub;
  }

  function registerDomainAndSendBulk(
    uint256 parentId,
    uint256 namingOffset, // e.g., the IPFS node refers to the metadata as x. the zNS label will be x + namingOffset
    uint256 startingIndex,
    uint256 endingIndex,
    address minter,
    string memory folderWithIPFSPrefix, // e.g., ipfs://Qm.../
    uint256 royaltyAmount,
    bool locked
  ) external {
    _onlyController();
    if (endingIndex <= startingIndex) {
      revert InvalidDomainIndex();
    }
    uint256 result;
    for (uint256 i = startingIndex; i < endingIndex; ++i) {
      result = _registerDomain(
        parentId,
        CustomStrings.toString(i + namingOffset),
        minter,
        string(
          abi.encodePacked(folderWithIPFSPrefix, CustomStrings.toString(i))
        ),
        royaltyAmount,
        locked
      );
    }
  }

  function registerDomainInGroupBulk(
    uint256 parentId,
    uint256 groupId,
    uint256 namingOffset,
    uint256 startingIndex,
    uint256 endingIndex,
    address minter,
    uint256 royaltyAmount,
    address sendTo
  ) external {
    _onlyController();
    if (endingIndex <= startingIndex) {
      revert InvalidDomainIndex();
    }
    uint256 tokenId;
    for (uint256 i = startingIndex; i < endingIndex; ++i) {
      tokenId = _registerDomainV2(
        parentId,
        CustomStrings.toString(i + namingOffset),
        minter,
        "",
        royaltyAmount,
        true, // always locked
        groupId,
        i
      );

      if (sendTo != minter) {
        _transfer(minter, sendTo, tokenId);
      }
    }
  }
}
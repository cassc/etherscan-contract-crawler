// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "./interfaces/IMegNFT.sol";

import "./utils/OpenseaDelegate.sol";

abstract contract MegNFT is ERC721Upgradeable, OwnableUpgradeable, AccessControlUpgradeable, IMegNFT {
  bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant PREMIUM_ROLE = keccak256("PREMIUM_ROLE");
  bytes32 public constant APPROVER_ROLE = keccak256("APPROVER_ROLE");

  mapping(uint256 => uint256) private _ownTime;

  string public standardUri;
  string public premiumUri;

  address public proxyRegistryAddress;
  bool public isOpenSeaProxyActive;

  mapping(uint256 => uint256) public landType;
  mapping(uint256 => uint256) public time;

  uint256 public maximumPremiumCapacity;
  uint256 public maximumTotalCapicity;

  uint256 public totalLands;
  uint256 public totalPremiumLands;

  event SetURI(string _standardUri, string _premiumUri);

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(
    bytes4 _interfaceId
  ) public view virtual override(ERC721Upgradeable, AccessControlUpgradeable) returns (bool) {
    return
      _interfaceId == type(IMegNFT).interfaceId ||
      //_interfaceId == type(IMegCreator).interfaceId ||
      super.supportsInterface(_interfaceId);
  }

  /**
   * @dev Upgradable initializer
   * @param _name Token name
   * @param _symbol Token symbol
   * @param _standardUri URI string
   * @param _premiumUri URI string
   */
  function __MegNFT_init(string memory _name, string memory _symbol, string memory _standardUri, string memory _premiumUri) internal initializer {
    __Ownable_init();
    __AccessControl_init();
    __ERC721_init(_name, _symbol);
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    standardUri = _standardUri;
    premiumUri = _premiumUri;
    maximumTotalCapicity = 178_929;
    maximumPremiumCapacity = 35_786;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    if(landType[tokenId] == 0) {
      return standardUri;
    }
    return premiumUri;
  }

  /**
   * @notice Active opensea proxy - Emergency case
   * @dev This function is only callable by owner
   * @param _proxyRegistryAddress Address of opensea proxy
   * @param _isOpenSeaProxyActive Active opensea proxy by assigning true value
   */
  function activeOpenseaProxy(
    address _proxyRegistryAddress,
    bool _isOpenSeaProxyActive
  ) external onlyOwner {
    proxyRegistryAddress = _proxyRegistryAddress;
    isOpenSeaProxyActive = _isOpenSeaProxyActive;
  }

  /**
   * @dev Sets a new URI for all token types, by relying on the token type ID
   * @dev This function is only callable by owner
   * @param _standardUri String of uri
   * @param _premiumUri String of uri
   */
  function setURI(string memory _standardUri, string memory _premiumUri) external onlyOwner {
    standardUri = _standardUri;
    premiumUri = _premiumUri;
    emit SetURI(_standardUri, _premiumUri);
  }

  /**
   * @dev Mint a new NFT
   * @dev This function is only callable by owner
   * @param _to Address of the token owner
   * @param _id Token id
   */
  function mint(address _to, uint256 _id) external override onlyRole(MINTER_ROLE) {
    _mint(_to, _id);
    time[_id] = block.timestamp;
    landType[_id] = 0;
  }

  /**
   * @dev Mint a Bulk NFT
   * @dev This function is only callable by owner
   * @param _to Address of the token owner
   * @param _ids Ids to change types
   */
  function bulkMint(address _to, uint256[] memory _ids) external override onlyRole(MINTER_ROLE) {
    for (uint256 i=0; i < _ids.length; i++) {
      _mint(_to, _ids[i]);
      time[_ids[i]] = block.timestamp;
      landType[_ids[i]] = 0;
    }
  }

  /**
   * @dev Mint a Bulk NFT
   * @dev This function is only callable by owner
   * @param _to Address of the token owner
   * @param _fromId Mint from this ID
   * @param _toId Mint to this ID
   */
  function bulkMint(address _to, uint256 _fromId, uint256 _toId) external override onlyRole(MINTER_ROLE) {
    for (uint256 i=_fromId; i <= _toId; i++) {
      _mint(_to, i);
      time[i] = block.timestamp;
      landType[i] = 0;
    }
  }

  /**
   * @dev Mint a new NFT
   * @dev This function is only callable by premium role
   * @param _id Token id
   */
  function changeLandToPremium(uint256 _id) external override onlyRole(PREMIUM_ROLE) {
    landType[_id] = 1;
  }

  /**
   * @dev Mint a Bulk NFT
   * @dev This function is only callable by premium role
   * @param _ids Ids to change types
   */
  function bulkChangeLandToPremium(uint256[] memory _ids) external override onlyRole(PREMIUM_ROLE) {
    for (uint256 i=0; i < _ids.length; i++) {
      landType[_ids[i]] = 1;
    }
  }

  /**
   * @notice Burn an NFT
   * @dev Burn an NFT by the token owner and Burner role
   * @param _id Token id
   */
  function burn(uint256 _id) external override {
    require(ownerOf(_id) == _msgSender() || hasRole(BURNER_ROLE, _msgSender()), "Only owner");
    _burn(_id);
  }

  /**
   * @dev Get own Time
   * @param _id token ID
   */
  function getOwnTime(uint256 _id) external view returns (uint256) {
    return _ownTime[_id];
  }

  /**
   * @dev See {IERC721-isApprovedForAll}.
   * @param _account Address of Owner
   * @param _operator Address of operator
   */
  function isApprovedForAll(address _account, address _operator) public view override returns (bool) {
    ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    if (isOpenSeaProxyActive && address(proxyRegistry.proxies(_account)) == _operator) {
      return true;
    }

    return hasRole(APPROVER_ROLE, _operator) || super.isApprovedForAll(_account, _operator);
  }

  /**
   * @dev Transfers `tokenId` from `from` to `to`.
   *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
   *
   * Requirements:
   *
   * - `_to` cannot be the zero address.
   * - `_tokenId` token must be owned by `from`.
   *
   * Emits a {Transfer} event.
   */
  function _transfer(address _from, address _to, uint256 _tokenId) internal override {
    if (_tokenId <= 229) require(block.timestamp > time[_tokenId] + 365 days , "No Time");
    super._transfer(_from, _to, _tokenId);
  }

  /**
   * @dev Mints `tokenId` and transfers it to `to`.
   *
   * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
   *
   * Requirements:
   *
   * - `_tokenId` must not exist.
   * - `_to` cannot be the zero address.
   *
   * Emits a {Transfer} event.
   */
  function _mint(address _to, uint256 _tokenId) internal override {
    _ownTime[_tokenId] = block.timestamp;
    super._mint(_to, _tokenId);
  }
}
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "../interfaces/AbstractERC721Stakeable.sol";
import "../libs/Errors.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721RoyaltyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract OwnableDelegateProxy {}

/**
 * Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 */
contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}

/// @custom:security-contact [email protected]
contract UniwhalePass is
  Initializable,
  ERC721Upgradeable,
  ERC721EnumerableUpgradeable,
  PausableUpgradeable,
  OwnableUpgradeable,
  AccessControlUpgradeable,
  ERC721RoyaltyUpgradeable,
  ERC721BurnableUpgradeable,
  AbstractERC721Stakeable,
  ReentrancyGuardUpgradeable
{
  using CountersUpgradeable for CountersUpgradeable.Counter;

  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  uint256 public maxSupply; // set at initialisation

  CountersUpgradeable.Counter private _tokenIdCounter;
  string private baseURI;
  address private openSeaProxyRegistry;
  mapping(address => bool) public minted;

  function initialize(
    address owner, // contract owner
    string memory name,
    string memory symbol,
    address admin, // used for OpenSea admin mgmt
    string memory __baseURI,
    uint96 defaultRoyalty, // in 10000 (i.e. basis point)
    address _openSeaProxyRegistry,
    uint256 _maxSupply
  ) external initializer {
    __ERC721_init(name, symbol);
    __ERC721Enumerable_init();
    __Pausable_init();
    __AccessControl_init();
    __Ownable_init();
    __ERC721Burnable_init();
    __ERC721Stakeable_init();
    __ReentrancyGuard_init();

    _transferOwnership(admin);
    _grantRole(DEFAULT_ADMIN_ROLE, owner); // contract-level owner
    _grantRole(MINTER_ROLE, owner); // contract-level owner

    baseURI = __baseURI;

    _setDefaultRoyalty(owner, defaultRoyalty);

    openSeaProxyRegistry = _openSeaProxyRegistry;

    maxSupply = _maxSupply;

    _pause();
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  // governance functions

  function setBaseURI(
    string memory __baseURI
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    baseURI = __baseURI;
  }

  function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
    _pause();
  }

  function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
    _unpause();
  }

  function safeMint(
    address[] memory many
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    for (uint256 i = 0; i < many.length; i++) {
      _safeMint(many[i]);
    }
  }

  function addWhitelist(
    address[] memory whitelisted
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    for (uint256 i = 0; i < whitelisted.length; i++) {
      _grantRole(MINTER_ROLE, whitelisted[i]);
    }
  }

  function removeWhitelist(
    address[] memory removed
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    for (uint256 i = 0; i < removed.length; i++) {
      _revokeRole(MINTER_ROLE, removed[i]);
    }
  }

  function setDefaultRoyalty(
    address receiver,
    uint96 feeNumerator
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _setDefaultRoyalty(receiver, feeNumerator);
  }

  function deleteDefaultRoyalty() external onlyRole(DEFAULT_ADMIN_ROLE) {
    _deleteDefaultRoyalty();
  }

  function setTokenRoyalty(
    uint256 tokenId,
    address receiver,
    uint96 feeNumerator
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _setTokenRoyalty(tokenId, receiver, feeNumerator);
  }

  function resetTokenRoyalty(
    uint256 tokenId
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _resetTokenRoyalty(tokenId);
  }

  function pauseStaking() external onlyRole(DEFAULT_ADMIN_ROLE) {
    _pauseStaking();
  }

  function setRewardToken(
    IMintable rewardToken
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _setRewardToken(rewardToken);
  }

  function setEmission(
    uint256 emissionPerBlock
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _setEmission(emissionPerBlock);
  }

  // priviledged functions

  function safeMint() external onlyRole(MINTER_ROLE) whenNotPaused {
    _require(minted[msg.sender] == false, Errors.ALREADY_MINTED);
    minted[msg.sender] = true;
    _safeMint(msg.sender);
  }

  // external functions

  function currentMintCount() external view returns (uint256) {
    return _tokenIdCounter.current();
  }

  function stake(uint256 tokenId) external override whenNotPaused nonReentrant {
    _stake(msg.sender, msg.sender, tokenId);
  }

  function unstake(
    uint256 tokenId
  ) external override whenNotPaused nonReentrant {
    _unstake(msg.sender, tokenId);
  }

  function claim() external override whenNotPaused nonReentrant {
    _claim(msg.sender);
  }

  // /**
  //  * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
  //  */
  // function isApprovedForAll(
  //   address owner,
  //   address operator
  // ) public view override(ERC721Upgradeable, IERC721Upgradeable) returns (bool) {
  //   // Whitelist OpenSea proxy contract for easy trading.
  //   ProxyRegistry proxyRegistry = ProxyRegistry(openSeaProxyRegistry);
  //   if (address(proxyRegistry.proxies(owner)) == operator) {
  //     return true;
  //   }

  //   return super.isApprovedForAll(owner, operator);
  // }

  // internal functions

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function _safeMint(address to) internal {
    uint256 tokenId = _tokenIdCounter.current();
    _require(tokenId < maxSupply, Errors.MAX_MINTED);
    _tokenIdCounter.increment();
    _safeMint(to, tokenId);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId,
    uint256 batchSize
  )
    internal
    override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    whenNotPaused
  {
    super._beforeTokenTransfer(from, to, tokenId, batchSize);
  }

  function _burn(
    uint256 tokenId
  ) internal override(ERC721Upgradeable, ERC721RoyaltyUpgradeable) {
    super._burn(tokenId);
  }

  // The following functions are overrides required by Solidity.

  function supportsInterface(
    bytes4 interfaceId
  )
    public
    view
    override(
      ERC721Upgradeable,
      ERC721EnumerableUpgradeable,
      AccessControlUpgradeable,
      ERC721RoyaltyUpgradeable
    )
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}
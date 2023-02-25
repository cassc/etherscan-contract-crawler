// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "../interfaces/AbstractStakeableUGP.sol";
import "../libs/Errors.sol";
import "../libs/math/FixedPoint.sol";
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
  AbstractStakeableUGP,
  ReentrancyGuardUpgradeable
{
  using FixedPoint for uint256;
  using CountersUpgradeable for CountersUpgradeable.Counter;
  using EnumerableSet for EnumerableSet.AddressSet;

  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  uint256 public maxSupply; // set at initialisation

  CountersUpgradeable.Counter private _tokenIdCounter;
  string private baseURI;
  address private openSeaProxyRegistry;
  mapping(address => bool) public minted;

  uint256 public totalStaked;
  EnumerableSet.AddressSet internal _rewardTokens;

  mapping(address => uint256) internal _stakedByStaker;
  mapping(address => mapping(IMintable => uint256))
    internal _balanceBaseByStaker;
  mapping(address => mapping(IMintable => uint256))
    internal _accruedRewardsByStaker;
  mapping(address => bool) internal _hasStakeByStaker;

  event AddRewardTokenEvent(address indexed rewardToken);
  event RemoveRewardTokenEvent(address indexed rewardToken);
  event StakeEvent(
    address indexed sender,
    address indexed user,
    uint256 amount
  );
  event UnstakeEvent(address indexed user, uint256 amount);
  event ClaimEvent(
    address indexed user,
    address indexed rewardToken,
    uint256 claimed
  );

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
    __AbstractStakeableUGP_init();
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
    for (uint256 i = 0; i < many.length; ++i) {
      _safeMint(many[i]);
    }
  }

  function safeMint(
    address to,
    uint256 tokenId
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _safeMint(to, tokenId);
  }

  function safeMint(
    address[] memory tos,
    uint256[] memory tokenIds
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _require(tos.length == tokenIds.length, Errors.INPUT_LENGTH_MISMATCH);
    uint256 _length = tos.length;
    for (uint256 i = 0; i < _length; ++i) {
      _safeMint(tos[i], tokenIds[i]);
    }
  }

  function burnMany(
    uint256[] memory many
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    for (uint256 i = 0; i < many.length; ++i) {
      _burn(many[i]);
    }
  }

  function addWhitelist(
    address[] memory whitelisted
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    for (uint256 i = 0; i < whitelisted.length; ++i) {
      _grantRole(MINTER_ROLE, whitelisted[i]);
    }
  }

  function removeWhitelist(
    address[] memory removed
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    for (uint256 i = 0; i < removed.length; ++i) {
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

  // priviledged functions

  function safeMint() external onlyRole(MINTER_ROLE) whenNotPaused {
    _require(minted[msg.sender] == false, Errors.ALREADY_MINTED);
    minted[msg.sender] = true;
    _safeMint(msg.sender);
  }

  // external functions

  function getStaked(address _user) external view override returns (uint256) {
    return _stakedByStaker[_user];
  }

  function getTotalStaked() external view virtual override returns (uint256) {
    return totalStaked;
  }

  function currentMintCount() external view returns (uint256) {
    return _tokenIdCounter.current();
  }

  function stake(
    uint256 tokenId
  ) external override whenNotPaused nonReentrant _notPaused {
    _stake(msg.sender, msg.sender, tokenId);
  }

  function unstake(
    uint256 tokenId
  ) external override whenNotPaused nonReentrant _notPaused {
    _unstake(msg.sender, tokenId);
  }

  function claim() external override whenNotPaused nonReentrant _notPaused {
    _claim(msg.sender);
  }

  function hasStake(address _user) external view override returns (bool) {
    return _hasStakeByStaker[_user];
  }

  function getRewards(
    address user,
    address rewardToken
  ) external view override returns (uint256) {
    _require(_rewardTokens.contains(rewardToken), Errors.INVALID_REWARD_TOKEN);
    return _getRewards(user, IMintable(rewardToken));
  }

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

  function _stake(
    address sender,
    address staker,
    uint256 tokenId
  ) internal override {
    _require(!_hasStakeByStaker[staker], Errors.ALREADY_STAKED);
    _hasStakeByStaker[staker] = true;
    _stakedByStaker[staker] = tokenId;
    totalStaked += 1;
    if (sender != address(this)) transferFrom(sender, address(this), tokenId);
    emit StakeEvent(sender, staker, tokenId);
  }

  function _unstake(address staker, uint256 tokenId) internal override {
    _require(_stakedByStaker[staker] == tokenId, Errors.INVALID_TOKEN_ID);
    _claim(staker);
    delete _stakedByStaker[staker];
    delete _hasStakeByStaker[staker];
    totalStaked -= 1;
    ERC721Upgradeable(this).transferFrom(address(this), staker, tokenId);
    emit UnstakeEvent(staker, tokenId);
  }

  function _claim(address staker) internal override {
    _updateClaim(staker);
    uint256 _length = _rewardTokens.length();
    for (uint256 i = 0; i < _length; i++) {
      IMintable _rewardToken = IMintable(_rewardTokens.at(i));
      uint256 claimed = _accruedRewardsByStaker[staker][_rewardToken];
      delete _accruedRewardsByStaker[staker][_rewardToken];
      if (claimed > 0) _rewardToken.mint(staker, claimed);
      emit ClaimEvent(staker, _rewardTokens.at(i), claimed);
    }
  }

  function _getRewards(
    address user,
    IMintable _rewardToken
  ) internal view override returns (uint256) {
    _require(_hasStakeByStaker[user], Errors.NO_STAKING_POSITION);
    return
      _rewardToken.balance().sub(_balanceBaseByStaker[user][_rewardToken]) /
      totalStaked;
  }

  function _addRewardToken(IMintable rewardToken) internal override {
    _rewardTokens.add(address(rewardToken));
    emit AddRewardTokenEvent(address(rewardToken));
  }

  function _removeRewardToken(IMintable rewardToken) internal override {
    _rewardTokens.remove(address(rewardToken));
    emit RemoveRewardTokenEvent(address(rewardToken));
  }

  function _updateClaim(address user) internal override {
    uint256 _length = _rewardTokens.length();
    for (uint256 i = 0; i < _length; i++) {
      IMintable rewardToken = IMintable(_rewardTokens.at(i));
      _accruedRewardsByStaker[user][rewardToken] += _getRewards(
        user,
        rewardToken
      );
      _balanceBaseByStaker[user][rewardToken] = rewardToken.balance();
    }
  }
}
// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

import { ISpecDataHolder } from "./interfaces/ISpecDataHolder.sol";
import { IERC4973 } from "lib/ERC4973/src/interfaces/IERC4973.sol";
import { SignatureCheckerUpgradeable } from "lib/openzeppelin-contracts-upgradeable/contracts/utils/cryptography/SignatureCheckerUpgradeable.sol";
import { BitMaps } from "lib/openzeppelin-contracts/contracts/utils/structs/BitMaps.sol";
import { OwnableUpgradeable } from "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import { EIP712Upgradeable } from "lib/openzeppelin-contracts-upgradeable/contracts/utils/cryptography/draft-EIP712Upgradeable.sol";
import { UUPSUpgradeable } from "lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import { ERC165Upgradeable } from "lib/openzeppelin-contracts-upgradeable/contracts/utils/introspection/ERC165Upgradeable.sol";
import { IERC721Metadata } from "./interfaces/IERC721Metadata.sol";
import { MerkleProof } from "lib/openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";

contract Badges is
  IERC721Metadata,
  IERC4973,
  ERC165Upgradeable,
  UUPSUpgradeable,
  OwnableUpgradeable,
  EIP712Upgradeable
{
  using BitMaps for BitMaps.BitMap;
  BitMaps.BitMap private usedHashes; // redundant storage as of x/x/x
  string private name_;
  string private symbol_;

  mapping(uint256 => address) private owners;
  mapping(uint256 => string) private tokenURIs;
  mapping(address => uint256) private balances;

  ISpecDataHolder private specDataHolder;

  mapping(uint256 => uint256) private voucherHashIds; // redundant storage as of x/x/x
  BitMaps.BitMap private revokedBadgesHashes;

  event SpecCreated(
    address indexed to,
    string specUri,
    uint256 indexed raftTokenId,
    address indexed raftAddress
  );

  event BadgeRevoked(
    uint256 indexed tokenId,
    address indexed from,
    uint8 indexed reason
  );

  event BadgeReinstated(uint256 indexed tokenId, address indexed from);

  event RefreshMetadata(string[] specUris, address sender);

  bytes32 constant AGREEMENT_HASH =
    keccak256("Agreement(address active,address passive,string tokenURI)");

  bytes32 constant MERKLE_AGREEMENT_HASH =
    keccak256("MerkleAgreement(address passive,string tokenURI,bytes32 root)");

  bytes32 constant REQUEST_HASH =
    keccak256("Request(address requester,string tokenURI)");

  modifier tokenExists(uint256 _badgeId) {
    require(owners[_badgeId] != address(0), "tokenExists: token doesn't exist");
    _;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  /**
   * @notice Initialize the contract
   * @dev only called once when the proxy is deployed. Allows the contract to be upgraded
   * @param _name name used for EIP-712 domain
   * @param _symbol symbol used for EIP-712 domain
   * @param _version version used for EIP-712 domain
   * @param _nextOwner address of the owner
   * @param _specDataHolderAddress address of the spec data holder contract
   */
  function initialize(
    string calldata _name,
    string calldata _symbol,
    string calldata _version,
    address _nextOwner,
    address _specDataHolderAddress
  ) public initializer {
    name_ = _name;
    symbol_ = _symbol;
    specDataHolder = ISpecDataHolder(_specDataHolderAddress);

    __ERC165_init();
    __Ownable_init();
    __EIP712_init(_name, _version);
    __UUPSUpgradeable_init();
    transferOwnership(_nextOwner);
  }

  function refreshMetadata(string[] calldata _specUris) external onlyOwner {
    require(_specUris.length > 0, "refreshMetadata: no spec uris provided");
    emit RefreshMetadata(_specUris, msg.sender);
  }

  /**
   * @notice Allows the Badges contract to communicate with the SpecDataHolder contract
   * @param _dataHolder address of the SpecDataHolder contract
   */
  function setDataHolder(address _dataHolder) external virtual onlyOwner {
    specDataHolder = ISpecDataHolder(_dataHolder);
  }

  function _give(
    address _recipient,
    string calldata _uri,
    bytes calldata _signature,
    uint256 _raftTokenId
  ) internal virtual returns (uint256) {
    safeCheckAgreement(msg.sender, _recipient, _uri, _signature);
    return mint(_recipient, _uri, _raftTokenId);
  }

  /**
   * @notice Allows the owner of a badge spec to mint a badge to multiple recipeients who have requested it
   * @param _recipients array the addresses who will receive a badge
   * @param _uri the uri of the badge spec
   * @param _signatures array of signatures that verify that the person receiving the badge actually requested it
   */
  function giveToMany(
    address[] calldata _recipients,
    string calldata _uri,
    bytes[] calldata _signatures
  ) external virtual {
    require(
      _recipients.length == _signatures.length,
      "giveToMany: recipients and signatures length mismatch"
    );

    uint256 raftTokenId = specDataHolder.getRaftTokenId(_uri);
    require(
      specDataHolder.isAuthorizedAdmin(raftTokenId, msg.sender),
      "giveToMany: unauthorized"
    );

    for (uint256 i = 0; i < _recipients.length; i++) {
      _give(_recipients[i], _uri, _signatures[i], raftTokenId);
    }
  }

  /**
   * @notice Allows an admin of a Raft token to mint a badge to multiple recipeients
   * @param _recipients array the addresses who will receive a badge
   * @param _uri the uri of the badge spec
   */
  function airdrop(address[] calldata _recipients, string calldata _uri)
    external
    virtual
  {
    uint256 raftTokenId = specDataHolder.getRaftTokenId(_uri);
    require(
      specDataHolder.isAuthorizedAdmin(raftTokenId, msg.sender),
      "airdrop: unauthorized"
    );

    for (uint256 i = 0; i < _recipients.length; i++) {
      mint(_recipients[i], _uri, raftTokenId);
    }
  }

  /**
   * @notice Allows the owner of a badge spec to mint a badge to someone who has requested it
   * @param _to the person who is receiving the badge
   * @param _uri the uri of the badge spec
   * @param _signature the signature used to verify that the person receiving the badge actually requested it
   */
  function give(
    address _to,
    string calldata _uri,
    bytes calldata _signature
  ) external virtual returns (uint256) {
    uint256 raftTokenId = specDataHolder.getRaftTokenId(_uri);
    require(
      specDataHolder.isAuthorizedAdmin(raftTokenId, msg.sender),
      "give: unauthorized"
    );
    return _give(_to, _uri, _signature, raftTokenId);
  }

  /**
   * @notice Allows an admin of the raft to mint a requested badge
   * @param _to the person who is receiving the badge
   * @param _uri the uri of the badge spec
   * @param _signature the signature used to verify that the person receiving the badge actually requested it
   */
  function giveRequestedBadge(
    address _to,
    string calldata _uri,
    bytes calldata _signature
  ) external virtual returns (uint256) {
    uint256 raftTokenId = specDataHolder.getRaftTokenId(_uri);

    require(
      specDataHolder.isAuthorizedAdmin(raftTokenId, msg.sender),
      "giveRequestedBadge: unauthorized"
    );

    return _giveRequestedBadge(_to, _uri, _signature, raftTokenId);
  }

  function _giveRequestedBadge(
    address _to,
    string calldata _uri,
    bytes calldata _signature,
    uint256 raftTokenId
  ) internal virtual returns (uint256) {
    require(
      SignatureCheckerUpgradeable.isValidSignatureNow(
        _to, // requester
        getRequestHash(_to, _uri),
        _signature
      ),
      "giveRequestedBadge: invalid signature"
    );

    return mint(_to, _uri, raftTokenId);
  }

  function giveRequestedBadgeToMany(
    address[] memory _recipients,
    string calldata _uri,
    bytes[] calldata _signatures
  ) external virtual {
    require(
      _recipients.length == _signatures.length,
      "giveRequestedBadgeToMany: recipients and signatures length mismatch"
    );
    uint256 raftTokenId = specDataHolder.getRaftTokenId(_uri);

    require(
      specDataHolder.isAuthorizedAdmin(raftTokenId, msg.sender),
      "giveRequestedBadgeToMany: unauthorized"
    );

    for (uint256 i = 0; i < _recipients.length; i++) {
      _giveRequestedBadge(_recipients[i], _uri, _signatures[i], raftTokenId);
    }
  }

  // todo - can we sole stale voucher problem here with isAdmin() even if they're 'inactive'?
  /**
   * @notice Allows a user to mint a badge from a voucher
   * @dev Take is called by somebody who has already been added to an allow list.
   * @param _from the person who issued the voucher, who is permitting them to mint the badge.
   * @param _uri the uri of the badge spec
   * @param _signature the signature used to verify that the person minting has permission from the issuer
   */
  function take(
    address _from,
    string calldata _uri,
    bytes calldata _signature
  ) external virtual override returns (uint256) {
    safeCheckAgreement(msg.sender, _from, _uri, _signature);

    uint256 raftTokenId = specDataHolder.getRaftTokenId(_uri);
    require(
      specDataHolder.isAuthorizedAdmin(raftTokenId, _from),
      "take: unauthorized"
    );

    return mint(msg.sender, _uri, raftTokenId);
  }

  function merkleTake(
    address _from,
    string calldata _uri,
    bytes calldata _signature,
    bytes32 root,
    bytes32[] calldata proof
  ) external virtual returns (uint256) {
    safeCheckMerkleAgreement(_from, msg.sender, _uri, _signature, root, proof);

    uint256 raftTokenId = specDataHolder.getRaftTokenId(_uri);
    require(
      specDataHolder.isAuthorizedAdmin(raftTokenId, _from),
      "merkleTake: unauthorized"
    );

    return mint(msg.sender, _uri, raftTokenId);
  }

  function getDataHolderAddress() external view returns (address) {
    return address(specDataHolder);
  }

  /**
   * @notice Allows a Raft token holder to create a badge spec
   * @dev Data is stored in the SpecDataHolder contract
   * @param _specUri the uri of the badge spec
   * @param _raftTokenId the id of the raft token
   */
  function createSpec(string calldata _specUri, uint256 _raftTokenId)
    external
    virtual
  {
    require(
      specDataHolder.isAuthorizedAdmin(_raftTokenId, msg.sender),
      "createSpec: unauthorized"
    );

    require(
      !specDataHolder.isSpecRegistered(_specUri),
      "createSpec: spec already registered"
    );

    specDataHolder.setSpecToRaft(_specUri, _raftTokenId);

    emit SpecCreated(
      msg.sender,
      _specUri,
      _raftTokenId,
      specDataHolder.getRaftAddress()
    );
  }

  function name() external view virtual override returns (string memory) {
    return name_;
  }

  function symbol() external view virtual override returns (string memory) {
    return symbol_;
  }

  function tokenURI(uint256 _tokenId)
    external
    view
    virtual
    override
    returns (string memory)
  {
    require(exists(_tokenId), "tokenURI: token doesn't exist");
    return tokenURIs[_tokenId];
  }

  /**
   * @notice Allows a user to disassociate themselves from a badge
   * @param _tokenId the id of the badge
   */
  function unequip(uint256 _tokenId)
    external
    virtual
    override
    tokenExists(_tokenId)
  {
    require(msg.sender == owners[_tokenId], "unequip: sender must be owner");
    burn(_tokenId);
  }

  function balanceOf(address _owner)
    external
    view
    virtual
    override
    returns (uint256)
  {
    require(_owner != address(0), "balanceOf: address(0) is not a valid owner");
    return balances[_owner];
  }

  function ownerOf(uint256 _tokenId)
    external
    view
    virtual
    override
    tokenExists(_tokenId)
    returns (address)
  {
    return owners[_tokenId];
  }

  /**
   * @notice Revokes a badge from a user
   * @dev we're storing the reason as a uint because the string values may change over time
   * Reason 0: Abuse
   * Reason 1: Left community
   * Reason 2: Tenure ended
   * Reason 3: Other
   * @param _raftTokenId The raft token id
   * @param _badgeId tokenId of the badge to be revoked
   * @param _reason an integer representing the reason for revoking the badge
   */
  function revokeBadge(
    uint256 _raftTokenId,
    uint256 _badgeId,
    uint8 _reason
  ) external tokenExists(_badgeId) {
    require(
      specDataHolder.isAuthorizedAdmin(_raftTokenId, msg.sender),
      "revokeBadge: unauthorized"
    );
    require(
      !revokedBadgesHashes.get(_badgeId),
      "revokeBadge: badge already revoked"
    );

    revokedBadgesHashes.set(_badgeId);

    emit BadgeRevoked(_badgeId, msg.sender, _reason);
  }

  /**
   * @notice Reinstates a badge for a user
   * @dev we're using bitmaps instead of a mapping to save gas
   * @param _raftTokenId The raft token id
   * @param _badgeId tokenId of the badge to be revoked
   */
  function reinstateBadge(uint256 _raftTokenId, uint256 _badgeId)
    external
    tokenExists(_badgeId)
  {
    require(
      specDataHolder.isAuthorizedAdmin(_raftTokenId, msg.sender),
      "reinstateBadge: unauthorized"
    );
    require(
      revokedBadgesHashes.get(_badgeId),
      "reinstateBadge: badge not revoked"
    );
    revokedBadgesHashes.unset(_badgeId);
    emit BadgeReinstated(_badgeId, msg.sender);
  }

  function isBadgeValid(uint256 _badgeId)
    external
    view
    tokenExists(_badgeId)
    returns (bool)
  {
    bool isNotRevoked = !revokedBadgesHashes.get(_badgeId);
    return isNotRevoked;
  }

  function supportsInterface(bytes4 _interfaceId)
    public
    view
    virtual
    override
    returns (bool)
  {
    return
      _interfaceId == type(IERC721Metadata).interfaceId ||
      _interfaceId == type(IERC4973).interfaceId ||
      super.supportsInterface(_interfaceId);
  }

  function getAgreementHash(
    address _from,
    address _to,
    string calldata _uri
  ) public view virtual returns (bytes32) {
    return
      _hashTypedDataV4(
        keccak256(
          abi.encode(AGREEMENT_HASH, _from, _to, keccak256(bytes(_uri)))
        )
      );
  }

  function getMerkleAgreementHash(
    address _issuer,
    string calldata _uri,
    bytes32 _root
  ) public view virtual returns (bytes32) {
    return
      _hashTypedDataV4(
        keccak256(
          abi.encode(
            MERKLE_AGREEMENT_HASH,
            _issuer,
            keccak256(bytes(_uri)),
            _root
          )
        )
      );
  }

  function getRequestHash(address _requester, string calldata _uri)
    public
    view
    virtual
    returns (bytes32)
  {
    return
      _hashTypedDataV4(
        keccak256(abi.encode(REQUEST_HASH, _requester, keccak256(bytes(_uri))))
      );
  }

  function getBadgeIdHash(address _to, string calldata _uri)
    public
    view
    virtual
    returns (bytes32)
  {
    return keccak256(abi.encode(_to, _uri));
  }

  function mint(
    address _to,
    string calldata _uri,
    uint256 _raftTokenId
  ) internal virtual returns (uint256) {
    // ensures that a badge spec can only be owned once by an account
    uint256 tokenId = uint256(getBadgeIdHash(_to, _uri));
    require(!exists(tokenId), "mint: tokenID exists");

    balances[_to]++;
    owners[tokenId] = _to;
    tokenURIs[tokenId] = _uri;

    emit Transfer(address(0), _to, tokenId);

    specDataHolder.setBadgeToRaft(tokenId, _raftTokenId);

    return tokenId;
  }

  function safeCheckMerkleAgreement(
    address _from,
    address _to,
    string calldata _uri,
    bytes calldata _signature,
    bytes32 _root,
    bytes32[] calldata _proof
  ) internal view virtual {
    // this authenticates the signature coming from the issuer
    require(
      SignatureCheckerUpgradeable.isValidSignatureNow(
        _from,
        getMerkleAgreementHash(_from, _uri, _root),
        _signature
      ),
      "safeCheckMerkleAgreement: invalid signature"
    );

    // this authenticates that the claimant (leaf) is indeed part of the tree whose root was signed
    bytes32 leaf = keccak256(abi.encodePacked(_to));
    require(
      MerkleProof.verify(_proof, _root, leaf),
      "safeCheckMerkleAgreement: invalid leaf"
    );
  }

  function safeCheckAgreement(
    address _active,
    address _passive,
    string calldata _uri,
    bytes calldata _signature
  ) internal view virtual {
    // active is always msg.sender
    // passive changes depending on whether it's give/take
    require(
      SignatureCheckerUpgradeable.isValidSignatureNow(
        _passive,
        getAgreementHash(_active, _passive, _uri),
        _signature
      ),
      "safeCheckAgreement: invalid signature"
    );
  }

  function exists(uint256 _tokenId) internal view virtual returns (bool) {
    return owners[_tokenId] != address(0);
  }

  function burn(uint256 _tokenId) internal virtual {
    address _owner = owners[_tokenId];
    balances[_owner] -= 1;

    delete owners[_tokenId];
    delete tokenURIs[_tokenId];

    emit Transfer(_owner, address(0), _tokenId);
  }

  // Not implementing this function because it is used to check who is authorized
  // to update the contract, we're using onlyOwner for this purpose.
  function _authorizeUpgrade(address) internal override onlyOwner {}
}
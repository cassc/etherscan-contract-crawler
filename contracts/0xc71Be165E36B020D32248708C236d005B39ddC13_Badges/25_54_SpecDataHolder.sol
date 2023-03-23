// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "./interfaces/ISpecDataHolder.sol";
import { Raft } from "./Raft.sol";

contract SpecDataHolder is
  UUPSUpgradeable,
  OwnableUpgradeable,
  ISpecDataHolder
{
  mapping(string => uint256) private _specToRaft;
  mapping(uint256 => uint256) private _badgeToRaft;

  address private badgesAddress;
  address private raftAddress;

  modifier onlyAuthorized() {
    require(
      msg.sender == badgesAddress || msg.sender == owner(),
      "onlyAuthorized: unauthorized"
    );
    _;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(address _raftAddress, address _nextOwner)
    public
    initializer
  {
    __Ownable_init();
    raftAddress = _raftAddress;
    transferOwnership(_nextOwner);
    __UUPSUpgradeable_init();
  }

  function getBadgesAddress() external view returns (address) {
    return badgesAddress;
  }

  function setBadgesAddress(address _badgesAddress) external virtual onlyOwner {
    badgesAddress = _badgesAddress;
  }

  function getRaftAddress() external view returns (address) {
    return raftAddress;
  }

  function setRaftAddress(address _raftAddress) external virtual onlyOwner {
    raftAddress = _raftAddress;
  }

  function getRaftByBadgeId(uint256 _badgeTokenId)
    external
    view
    virtual
    returns (uint256)
  {
    return _badgeToRaft[_badgeTokenId];
  }

  function setBadgeToRaft(uint256 _badgeTokenId, uint256 _raftTokenId)
    external
    virtual
    onlyAuthorized
  {
    _badgeToRaft[_badgeTokenId] = _raftTokenId;
  }

  function setBadgesToRafts(
    uint256[] calldata _badgeTokenId,
    uint256[] calldata _raftTokenId
  ) external virtual onlyAuthorized {
    require(
      _badgeTokenId.length == _raftTokenId.length,
      "setBadgesToRafts: arrays must be the same length"
    );
    for (uint256 i = 0; i < _badgeTokenId.length; i++) {
      _badgeToRaft[_badgeTokenId[i]] = _raftTokenId[i];
    }
  }

  function setSpecToRaft(string calldata _specUri, uint256 _raftTokenId)
    external
    virtual
    onlyAuthorized
  {
    _specToRaft[_specUri] = _raftTokenId;
  }

  function setSpecsToRafts(
    string[] calldata _specUri,
    uint256[] calldata _raftTokenId
  ) external virtual onlyAuthorized {
    require(
      _specUri.length == _raftTokenId.length,
      "setSpecsToRafts: arrays must be the same length"
    );
    for (uint256 i = 0; i < _specUri.length; i++) {
      _specToRaft[_specUri[i]] = _raftTokenId[i];
    }
  }

  function getRaftTokenId(string calldata _specUri)
    external
    view
    returns (uint256)
  {
    return _specToRaft[_specUri];
  }

  function isSpecRegistered(string calldata _specUri)
    external
    view
    returns (bool)
  {
    return _specToRaft[_specUri] != 0;
  }

  function isAuthorizedAdmin(uint256 _raftTokenId, address _admin)
    external
    view
    returns (bool)
  {
    Raft raft = Raft(raftAddress);
    address raftOwner = raft.ownerOf(_raftTokenId);

    return raftOwner == _admin || raft.isAdminActive(_raftTokenId, _admin);
  }

  // The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
  // Not implementing this function because it is used to check who is authorized
  // to update the contract, we're using onlyOwnerfor this purpose.
  function _authorizeUpgrade(address) internal override onlyOwner {}
}
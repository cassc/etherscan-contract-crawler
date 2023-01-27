// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@opengsn/contracts/src/BaseRelayRecipient.sol";

import "./ICaskChainlinkTopup.sol";
import "./ICaskChainlinkTopupManager.sol";

contract CaskChainlinkTopup is
ICaskChainlinkTopup,
Initializable,
OwnableUpgradeable,
PausableUpgradeable,
BaseRelayRecipient
{
    using SafeERC20 for IERC20Metadata;

    /** @dev contract to manage ChainlinkTopup executions. */
    ICaskChainlinkTopupManager public chainlinkTopupManager;

    /** @dev map of ChainlinkTopup ID to ChainlinkTopup info. */
    mapping(bytes32 => ChainlinkTopup) private chainlinkTopupMap; // chainlinkTopupId => ChainlinkTopup
    mapping(address => bytes32[]) private userChainlinkTopups; // user => chainlinkTopupId[]
    mapping(uint256 => ChainlinkTopupGroup) private chainlinkTopupGroupMap;

    uint256 public currentGroup;

    uint256[] public backfillGroups;

    /** @dev minimum amount to allow for a topup. */
    uint256 public minTopupAmount;

    uint256 public groupSize;

    function initialize(
        uint256 _groupSize
    ) public initializer {
        __Ownable_init();
        __Pausable_init();

        currentGroup = 1;
        groupSize = _groupSize;
    }
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function versionRecipient() public pure override returns(string memory) { return "2.2.0"; }

    function _msgSender() internal view override(ContextUpgradeable, BaseRelayRecipient)
    returns (address sender) {
        sender = BaseRelayRecipient._msgSender();
    }

    function _msgData() internal view override(ContextUpgradeable, BaseRelayRecipient)
    returns (bytes calldata) {
        return BaseRelayRecipient._msgData();
    }

    modifier onlyUser(bytes32 _chainlinkTopupId) {
        require(_msgSender() == chainlinkTopupMap[_chainlinkTopupId].user, "!AUTH");
        _;
    }

    modifier onlyManager() {
        require(_msgSender() == address(chainlinkTopupManager), "!AUTH");
        _;
    }


    function createChainlinkTopup(
        uint256 _lowBalance,
        uint256 _topupAmount,
        uint256 _targetId,
        address _registry,
        TopupType _topupType
    ) external override whenNotPaused returns(bytes32) {
        require(_topupAmount >= minTopupAmount, "!INVALID(topupAmount)");
        require(_topupType == TopupType.Automation ||
                _topupType == TopupType.VRF ||
                _topupType == TopupType.Direct, "!INVALID(topupType)");
        if (_topupType != TopupType.Direct) {
            require(chainlinkTopupManager.registryAllowed(_registry), "!INVALID(registry)");
        }

        bytes32 chainlinkTopupId = keccak256(abi.encodePacked(_msgSender(), _targetId, _registry,
            block.number, block.timestamp));

        ChainlinkTopup storage chainlinkTopup = chainlinkTopupMap[chainlinkTopupId];
        chainlinkTopup.user = _msgSender();
        chainlinkTopup.lowBalance = _lowBalance;
        chainlinkTopup.topupAmount = _topupAmount;
        chainlinkTopup.createdAt = uint32(block.timestamp);
        chainlinkTopup.targetId = _targetId;
        chainlinkTopup.registry = _registry;
        chainlinkTopup.topupType = _topupType;
        chainlinkTopup.status = ChainlinkTopupStatus.Active;

        userChainlinkTopups[_msgSender()].push(chainlinkTopupId);

        _assignChainlinkTopupToGroup(chainlinkTopupId);

        chainlinkTopupManager.registerChainlinkTopup(chainlinkTopupId);

        require(chainlinkTopup.status == ChainlinkTopupStatus.Active, "!UNPROCESSABLE");

        emit ChainlinkTopupCreated(chainlinkTopupId, chainlinkTopup.user, chainlinkTopup.lowBalance,
            chainlinkTopup.topupAmount, chainlinkTopup.targetId, chainlinkTopup.registry, chainlinkTopup.topupType);

        return chainlinkTopupId;
    }

    function pauseChainlinkTopup(
        bytes32 _chainlinkTopupId
    ) external override onlyUser(_chainlinkTopupId) whenNotPaused {
        ChainlinkTopup storage chainlinkTopup = chainlinkTopupMap[_chainlinkTopupId];
        require(chainlinkTopup.status == ChainlinkTopupStatus.Active, "!NOT_ACTIVE");

        _removeChainlinkTopupFromGroup(_chainlinkTopupId);

        chainlinkTopup.status = ChainlinkTopupStatus.Paused;

        emit ChainlinkTopupPaused(_chainlinkTopupId, chainlinkTopup.user, chainlinkTopup.targetId,
            chainlinkTopup.registry, chainlinkTopup.topupType);
    }

    function resumeChainlinkTopup(
        bytes32 _chainlinkTopupId
    ) external override onlyUser(_chainlinkTopupId) whenNotPaused {
        ChainlinkTopup storage chainlinkTopup = chainlinkTopupMap[_chainlinkTopupId];
        require(chainlinkTopup.status == ChainlinkTopupStatus.Paused, "!NOT_PAUSED");

        _assignChainlinkTopupToGroup(_chainlinkTopupId);

        chainlinkTopup.numSkips = 0;
        chainlinkTopup.status = ChainlinkTopupStatus.Active;

        chainlinkTopupManager.registerChainlinkTopup(_chainlinkTopupId);

        emit ChainlinkTopupResumed(_chainlinkTopupId, chainlinkTopup.user, chainlinkTopup.targetId,
            chainlinkTopup.registry, chainlinkTopup.topupType);
    }

    function cancelChainlinkTopup(
        bytes32 _chainlinkTopupId
    ) external override onlyUser(_chainlinkTopupId) whenNotPaused {
        ChainlinkTopup storage chainlinkTopup = chainlinkTopupMap[_chainlinkTopupId];
        require(chainlinkTopup.status == ChainlinkTopupStatus.Active ||
                chainlinkTopup.status == ChainlinkTopupStatus.Paused, "!INVALID(status)");

        _removeChainlinkTopupFromGroup(_chainlinkTopupId);

        chainlinkTopup.status = ChainlinkTopupStatus.Canceled;

        emit ChainlinkTopupCanceled(_chainlinkTopupId, chainlinkTopup.user, chainlinkTopup.targetId,
            chainlinkTopup.registry, chainlinkTopup.topupType);
    }

    function getChainlinkTopup(
        bytes32 _chainlinkTopupId
    ) external override view returns (ChainlinkTopup memory) {
        return chainlinkTopupMap[_chainlinkTopupId];
    }

    function getChainlinkTopupGroup(
        uint256 _chainlinkTopupGroupId
    ) external override view returns (ChainlinkTopupGroup memory) {
        return chainlinkTopupGroupMap[_chainlinkTopupGroupId];
    }

    function getUserChainlinkTopup(
        address _user,
        uint256 _idx
    ) external override view returns (bytes32) {
        return userChainlinkTopups[_user][_idx];
    }

    function getUserChainlinkTopupCount(
        address _user
    ) external override view returns (uint256) {
        return userChainlinkTopups[_user].length;
    }

    function _removeChainlinkTopupFromGroup(
        bytes32 _chainlinkTopupId
    ) internal {
        ChainlinkTopup storage chainlinkTopup = chainlinkTopupMap[_chainlinkTopupId];

        uint256 groupId = chainlinkTopup.groupId;
        uint256 groupLen = chainlinkTopupGroupMap[groupId].chainlinkTopups.length;

        // remove topup from group list
        uint256 idx = groupLen;
        for (uint256 i = 0; i < groupLen; i++) {
            if (chainlinkTopupGroupMap[groupId].chainlinkTopups[i] == _chainlinkTopupId) {
                idx = i;
                break;
            }
        }
        if (idx < groupLen) {
            chainlinkTopupGroupMap[groupId].chainlinkTopups[idx] =
                chainlinkTopupGroupMap[groupId].chainlinkTopups[groupLen - 1];
            chainlinkTopupGroupMap[groupId].chainlinkTopups.pop();
        }

        backfillGroups.push(groupId);
    }

    function _findGroupId() internal returns(uint256) {
        uint256 chainlinkTopupGroupId;
        if (backfillGroups.length > 0) {
            chainlinkTopupGroupId = backfillGroups[backfillGroups.length-1];
            backfillGroups.pop();
        } else {
            chainlinkTopupGroupId = currentGroup;
        }
        if (chainlinkTopupGroupId != currentGroup &&
            chainlinkTopupGroupMap[chainlinkTopupGroupId].chainlinkTopups.length >= groupSize)
        {
            chainlinkTopupGroupId = currentGroup;
        }
        if (chainlinkTopupGroupMap[chainlinkTopupGroupId].chainlinkTopups.length >= groupSize) {
            currentGroup += 1;
            chainlinkTopupGroupId = currentGroup;
        }
        return chainlinkTopupGroupId;
    }

    function _assignChainlinkTopupToGroup(
        bytes32 _chainlinkTopupId
    ) internal {
        uint256 chainlinkTopupGroupId = _findGroupId();
        require(chainlinkTopupGroupId > 0, "!GROUP_ERROR");

        ChainlinkTopup storage chainlinkTopup = chainlinkTopupMap[_chainlinkTopupId];
        chainlinkTopup.groupId = chainlinkTopupGroupId;

        ChainlinkTopupGroup storage chainlinkTopupGroup = chainlinkTopupGroupMap[chainlinkTopupGroupId];
        chainlinkTopupGroup.chainlinkTopups.push(_chainlinkTopupId);
    }

    /************************** MANAGER FUNCTIONS **************************/

    function managerCommand(
        bytes32 _chainlinkTopupId,
        ManagerCommand _command
    ) external override onlyManager {

        ChainlinkTopup storage chainlinkTopup = chainlinkTopupMap[_chainlinkTopupId];

        if (_command == ManagerCommand.Pause) {

            chainlinkTopup.status = ChainlinkTopupStatus.Paused;

            _removeChainlinkTopupFromGroup(_chainlinkTopupId);

            emit ChainlinkTopupPaused(_chainlinkTopupId, chainlinkTopup.user, chainlinkTopup.targetId,
                chainlinkTopup.registry, chainlinkTopup.topupType);

        } else if (_command == ManagerCommand.Cancel) {

            chainlinkTopup.status = ChainlinkTopupStatus.Canceled;

            _removeChainlinkTopupFromGroup(_chainlinkTopupId);

            emit ChainlinkTopupCanceled(_chainlinkTopupId, chainlinkTopup.user, chainlinkTopup.targetId,
                chainlinkTopup.registry, chainlinkTopup.topupType);

        }
    }

    function managerProcessed(
        bytes32 _chainlinkTopupId,
        uint256 _amount,
        uint256 _buyQty,
        uint256 _fee
    ) external override onlyManager {
        ChainlinkTopup storage chainlinkTopup = chainlinkTopupMap[_chainlinkTopupId];

        chainlinkTopup.retryAfter = 0;
        chainlinkTopup.currentAmount += _amount;
        chainlinkTopup.currentBuyQty += _buyQty;
        chainlinkTopup.numTopups += 1;

        emit ChainlinkTopupProcessed(_chainlinkTopupId, chainlinkTopup.user, chainlinkTopup.targetId,
            chainlinkTopup.registry, chainlinkTopup.topupType, _amount, _buyQty, _fee);
    }

    function managerSkipped(
        bytes32 _chainlinkTopupId,
        uint32 _retryAfter,
        SkipReason _skipReason
    ) external override onlyManager {
        ChainlinkTopup storage chainlinkTopup = chainlinkTopupMap[_chainlinkTopupId];

        chainlinkTopup.retryAfter = _retryAfter;
        chainlinkTopup.numSkips += 1;

        emit ChainlinkTopupSkipped(_chainlinkTopupId, chainlinkTopup.user, chainlinkTopup.targetId,
            chainlinkTopup.registry, chainlinkTopup.topupType, _skipReason);
    }

    /************************** ADMIN FUNCTIONS **************************/

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setManager(
        address _chainlinkTopupManager
    ) external onlyOwner {
        chainlinkTopupManager = ICaskChainlinkTopupManager(_chainlinkTopupManager);
    }

    function setTrustedForwarder(
        address _forwarder
    ) external onlyOwner {
        _setTrustedForwarder(_forwarder);
    }

    function setMinTopupAmount(
        uint256 _minTopupAmount
    ) external onlyOwner {
        minTopupAmount = _minTopupAmount;
    }

}
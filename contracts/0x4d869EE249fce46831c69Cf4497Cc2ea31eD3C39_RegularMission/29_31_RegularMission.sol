// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./HasPower.sol";
import "../libs/EnumerableTokenSet.sol";
import "../libs/TimestampStorage.sol";
import "../Locker/ITMAsLocker.sol";
import "../Rewarder/IRewarder.sol";
import "../AMTManager/IAMTManager.sol";
import "../libs/NFT.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract RegularMission is AccessControl {
    using BitMaps for BitMaps.BitMap;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableTokenSet for EnumerableTokenSet.Set;
    using NFT for NFT.TokenStruct;
    using TimestampStorage for TimestampStorage.Storage;

    struct Mission {
        uint128 term;
        uint64 reward;
        // 100% = 10000
        uint64 successRate;
    }

    struct PowerEffectUnit {
        uint128 powerUnit;
        // 1% = 100
        uint128 reductionUnit;
    }

    event StartMission(
        address indexed user,
        uint256 indexed troopId,
        uint256 indexed missionId
    );

    event AddedTokenToTroop(
        address indexed user,
        uint256 indexed troopId,
        address collection,
        uint256 tokenId
    );

    event MissionResult(
        address indexed user,
        uint256 indexed troopId,
        uint256 indexed missionIed,
        bool isSuccess,
        uint256 reward
    );

    bytes32 public constant ADMIN = "ADMIN";

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(ADMIN, DEFAULT_ADMIN_ROLE);
        _grantRole(ADMIN, msg.sender);

        // power = 50 => reduce risk 5%
        powerEffect = PowerEffectUnit(50, 500);
    }

    // troopId is start at 1
    // user => troopId => member
    mapping(address => mapping(uint256 => EnumerableTokenSet.Set))
        private _troop;
    // user => troopId => block.timestamp list
    mapping(address => mapping(uint256 => TimestampStorage.Storage))
        private _lastEvaluateTimestamp;

    // user => troop num
    mapping(address => uint256) maxTroopNumOf;

    uint256 public constant DEFAULT_TROOP_NUM = 3;
    uint256 public maxTroopNum = 5;
    uint256 public maxMemberPerTroop = 5;

    EnumerableSet.AddressSet private _allowedCollections;
    address public tma;
    address public tmas;
    address public tmasMetadata;
    ITMAsLocker public locker;
    IRewarder public rewarder;
    IAMTManager public amtManager;

    // missionId => mission
    mapping(uint256 => Mission) public missions;
    BitMaps.BitMap private _pauseMission;

    // user => troopId => missionId
    mapping(address => mapping(uint256 => uint256)) public currentMission;

    // For TMA
    uint256 public bonusUnit = 2;
    uint256 public maxBonus = 4;
    uint256 public tmaPower = 50;

    uint256 public rewardForFailure = 1;

    PowerEffectUnit public powerEffect;

    function getMaxTroopNum(address user) public view returns (uint256) {
        uint256 _maxTroopNum = maxTroopNumOf[user];

        if (_maxTroopNum == 0) {
            return DEFAULT_TROOP_NUM;
        } else {
            return _maxTroopNum;
        }
    }

    function getTroopsInMission(
        address user
    ) external view returns (uint256[] memory) {
        uint256 _maxTroopNum = getMaxTroopNum(user);
        uint256[] memory _troopIdInMissions = new uint256[](_maxTroopNum);
        uint256 n = 0;

        for (uint256 i = 1; i <= _maxTroopNum; i++) {
            if (_troop[user][i].length() > 0) {
                _troopIdInMissions[n++] = i;
            }
        }

        assembly ("memory-safe") {
            mstore(_troopIdInMissions, n)
        }

        return _troopIdInMissions;
    }

    function getMissionNumAndStartTimestamp(
        address user,
        uint256 troopId
    ) public view returns (uint256, uint256) {
        EnumerableTokenSet.Set storage tokens = _troop[user][troopId];

        if (tokens.length() == 0) {
            return (0, 0);
        }

        // because troop is add only.
        uint256 evaluateTimestamp = _lastEvaluateTimestamp[user][troopId].get(
            0
        );

        uint128 term = missions[currentMission[user][troopId]].term;
        uint256 evaluateCount = (block.timestamp - evaluateTimestamp) / term;

        return (evaluateCount, evaluateTimestamp);
    }

    function getTroopMembers(
        address user,
        uint256 troopId
    ) external view returns (address[] memory, uint256[] memory) {
        NFT.TokenStruct[] memory tokens = _troop[user][troopId].values();
        uint256 length = tokens.length;

        address[] memory collections = new address[](length);
        uint256[] memory tokenIds = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            NFT.TokenStruct memory token = tokens[i];
            collections[i] = token.collectionAddress;
            tokenIds[i] = token.tokenId;
        }

        return (collections, tokenIds);
    }

    function startMission(
        uint256 missionId,
        uint256 troopId,
        NFT.TokenStruct[] calldata tokens
    ) external {
        address user = msg.sender;
        require(missions[missionId].term != 0, "invalid missionId.");
        require(
            _pauseMission.get(missionId) == false,
            "the mission is paused."
        );
        require(
            currentMission[user][troopId] == 0,
            "the troop alread go to mission."
        );

        currentMission[user][troopId] = missionId;
        _addTokenToTroop(user, troopId, tokens);

        emit StartMission(user, troopId, missionId);
    }

    function addTokenToTroop(
        uint256 troopId,
        NFT.TokenStruct[] calldata tokens
    ) external {
        address user = msg.sender;
        require(
            currentMission[user][troopId] != 0,
            "the troop is not started mission yet."
        );

        _addTokenToTroop(user, troopId, tokens);
    }

    function _addTokenToTroop(
        address user,
        uint256 troopId,
        NFT.TokenStruct[] calldata tokens
    ) internal {
        // Assuming that the owner and lock status is verified by Locker.
        uint256 currentNumInTroop = _troop[user][troopId].length();
        uint40 currentTimestamp = uint40(block.timestamp);

        require(tokens.length > 0, "tokens length must be over 1.");
        require(
            troopId >= 1 && troopId <= getMaxTroopNum(user),
            "invalid troopId."
        );
        require(
            currentNumInTroop + tokens.length <= maxMemberPerTroop,
            "over max number per troop."
        );
        for (uint256 i = 0; i < tokens.length; i++) {
            require(
                _allowedCollections.contains(tokens[i].collectionAddress),
                "no supported collection."
            );
            for (uint256 j = i + 1; j < tokens.length; j++) {
                require(
                    tokens[i].collectionAddress !=
                        tokens[j].collectionAddress ||
                        tokens[i].tokenId != tokens[j].tokenId,
                    "dupplicate token."
                );
            }
        }

        locker.lock(tokens);

        for (uint256 i = 0; i < tokens.length; i++) {
            _troop[user][troopId].add(tokens[i]);
            _lastEvaluateTimestamp[user][troopId].set(
                currentNumInTroop + i,
                currentTimestamp
            );

            emit AddedTokenToTroop(
                user,
                troopId,
                tokens[i].collectionAddress,
                tokens[i].tokenId
            );
        }
    }

    function _evaluate(address user, uint256 troopId) private {
        EnumerableTokenSet.Set storage tokens = _troop[user][troopId];
        uint256 length = tokens.length();
        (
            uint256 evaluateCount,
            uint256 evaluateTimestamp
        ) = getMissionNumAndStartTimestamp(user, troopId);

        if (evaluateCount == 0) {
            return;
        }

        uint256 missionId = currentMission[user][troopId];
        Mission memory mission = missions[missionId];
        uint256 reward = 0;

        uint256[] memory powerOfTokens = new uint256[](length);
        uint256[] memory timestamps = new uint256[](length);
        uint256 blockNumber = block.number;

        for (uint256 i = 0; i < length; i++) {
            NFT.TokenStruct memory token = tokens.at(i);
            timestamps[i] = _lastEvaluateTimestamp[user][troopId].get(i);
            if (token.collectionAddress == tmas) {
                powerOfTokens[i] = HasPower(tmasMetadata).power(token.tokenId);
            }
        }

        for (uint256 i = 0; i < evaluateCount; i++) {
            uint256 bonus = 1;
            uint256 power = 0;
            uint256 memberNum = 0;

            for (uint256 j = 0; j < length; j++) {
                NFT.TokenStruct memory token = tokens.at(j);

                if (timestamps[j] > evaluateTimestamp + (mission.term * i)) {
                    continue;
                }

                memberNum++;

                if (token.collectionAddress == tma) {
                    power += tmaPower;
                    bonus *= bonusUnit;
                } else if (token.collectionAddress == tmas) {
                    power += powerOfTokens[j];
                }
            }

            if (bonus > maxBonus) {
                bonus = maxBonus;
            }

            uint256 successRate = mission.successRate +
                ((power / powerEffect.powerUnit) * powerEffect.reductionUnit);

            uint256 _reward = rewardForFailure * memberNum;
            bool isSuccess = false;

            if (successRate >= 10000) {
                _reward = mission.reward * bonus * memberNum;
                isSuccess = true;
            } else {
                uint256 rand = uint256(
                    keccak256(abi.encodePacked(blockhash(blockNumber - 1), i))
                ) % 10000;

                if (rand <= successRate) {
                    _reward = mission.reward * bonus * memberNum;
                    isSuccess = true;
                }
            }

            emit MissionResult(user, troopId, missionId, isSuccess, _reward);

            reward += _reward;
        }

        uint40 currentTimestamp = uint40(block.timestamp);
        for (uint256 i = 0; i < tokens.length(); i++) {
            _lastEvaluateTimestamp[user][troopId].set(i, currentTimestamp);
        }

        rewarder.reward(user, reward);
    }

    function evaluate(uint256 troopId) external {
        _evaluate(msg.sender, troopId);
    }

    function endMission(address user, uint256 troopId) external {
        // Assuming that the Locker guarantees that only the holder or ADMIN can operate it.
        locker.unlock(_troop[user][troopId].values());
        _evaluate(user, troopId);
        currentMission[user][troopId] = 0;

        NFT.TokenStruct[] memory tokens = _troop[user][troopId].values();
        for (uint256 i = 0; i < tokens.length; i++) {
            _troop[user][troopId].remove(tokens[i]);
        }
    }

    function resetForEmergency(address user, uint256 troopId) external {
        require(
            user == msg.sender || hasRole(ADMIN, user),
            "you are not user or admin."
        );

        currentMission[user][troopId] = 0;

        NFT.TokenStruct[] memory tokens = _troop[user][troopId].values();
        for (uint256 i = 0; i < tokens.length; i++) {
            _troop[user][troopId].remove(tokens[i]);
        }
    }

    uint256 public addTroopCost = 3000;

    function addTroop() external {
        address user = msg.sender;
        uint256 _maxTroopNum = getMaxTroopNum(user);
        require(_maxTroopNum < maxTroopNum, "already max troop.");

        amtManager.use(user, addTroopCost, "add troop");
        maxTroopNumOf[user] = _maxTroopNum + 1;
    }

    function setLocker(address value) external onlyRole(ADMIN) {
        locker = ITMAsLocker(value);
    }

    function setTMA(address value) external onlyRole(ADMIN) {
        tma = value;
    }

    function setTMAs(address value) external onlyRole(ADMIN) {
        tmas = value;
    }

    function setTMAsMetadata(address value) external onlyRole(ADMIN) {
        tmasMetadata = value;
    }

    function setRewarder(address value) external onlyRole(ADMIN) {
        rewarder = IRewarder(value);
    }

    function setAmtManager(address value) external onlyRole(ADMIN) {
        amtManager = IAMTManager(value);
    }

    function setAddTroopCost(uint256 value) external onlyRole(ADMIN) {
        addTroopCost = value;
    }

    function setMaxMemberPerTroop(uint256 value) external onlyRole(ADMIN) {
        maxMemberPerTroop = value;
    }

    function setMaxTroopNum(uint256 value) external onlyRole(ADMIN) {
        maxTroopNum = value;
    }

    function setBonusUnit(uint256 value) external onlyRole(ADMIN) {
        bonusUnit = value;
    }

    function setMaxBonus(uint256 value) external onlyRole(ADMIN) {
        maxBonus = value;
    }

    function setRewardForFailure(uint256 value) external onlyRole(ADMIN) {
        rewardForFailure = value;
    }

    function setTMAPower(uint256 value) external onlyRole(ADMIN) {
        tmaPower = value;
    }

    function setPowerEffect(
        PowerEffectUnit calldata value
    ) external onlyRole(ADMIN) {
        powerEffect = value;
    }

    function setMission(
        uint256 missionId,
        Mission calldata mission
    ) external onlyRole(ADMIN) {
        require(missionId > 0, "missionId must be over than 0.");
        require(mission.term > 0, "term must be over than 0.");

        missions[missionId] = mission;
    }

    function pauseMission(
        uint256[] calldata missionIds
    ) external onlyRole(ADMIN) {
        for (uint256 i = 0; i < missionIds.length; i++) {
            _pauseMission.set(missionIds[i]);
        }
    }

    function unpauseMission(
        uint256[] calldata missionIds
    ) external onlyRole(ADMIN) {
        for (uint256 i = 0; i < missionIds.length; i++) {
            _pauseMission.unset(missionIds[i]);
        }
    }

    function isMissionPaused(uint256 missionId) external view returns (bool) {
        return _pauseMission.get(missionId);
    }

    function addAllowedCollection(
        address[] calldata addresses
    ) external onlyRole(ADMIN) {
        for (uint256 i = 0; i < addresses.length; i++) {
            _allowedCollections.add(addresses[i]);
        }
    }

    function removeAllowedCollection(
        address[] calldata addresses
    ) external onlyRole(ADMIN) {
        for (uint256 i = 0; i < addresses.length; i++) {
            _allowedCollections.remove(addresses[i]);
        }
    }

    function getAllowedCollection() external view returns (address[] memory) {
        return _allowedCollections.values();
    }
}
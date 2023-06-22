// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./Delegated.sol";
import "../Interfaces/ISanctum.sol";
import "../Interfaces/IAeon.sol";

contract RirisuStaking is IERC721Receiver, Delegated {
    using EnumerableSet for EnumerableSet.UintSet;

    uint256 private LORE_COST = 100 ether; // 100 AEON

    uint256 private NAME_COST = 100 ether; // 100 AEON

    uint128 public immutable MAX_RIRI_LEVEL = 80;

    uint128[] public MODIFIERS = [uint128(100), 125, 150, 225];

    uint128[][] public RARITIES = [[uint128(6301), 9001, 9901, 10_001], [uint128(6301), 9001, 9801, 10_001]];

    uint256[] public ENCHANT_COST = [
        uint256(5 ether),
        44 ether,
        86 ether,
        130 ether,
        130 ether,
        172 ether,
        172 ether,
        172 ether,
        172 ether
    ];

    // maps token id to staking info
    mapping(uint256 => Riri) internal riris;
    // maps token id to staking info
    mapping(uint256 => Sanctum) internal sanctums;

    mapping(uint256 => uint128[]) internal rooms;

    mapping(address => EnumerableSet.UintSet) private stkdRiris;

    mapping(address => EnumerableSet.UintSet) private stkdSanctums;

    mapping(uint256 => bool) private legendaries;

    IERC721 internal riri;

    ISanctum internal sanctum;

    IAeon internal aeon;

    bytes32 internal entropySauce;

    enum Actions {
        UNSTAKE,
        STAKE,
        CHANNEL
    }

    enum RoomRarity {
        COMMON,
        UNCOMMON,
        RARE,
        MYTHIC
    }

    struct Sanctum {
        address owner;
        uint128 totalStaked;
        uint128 level;
        Actions action;
    }

    struct Riri {
        address owner;
        uint256 sanctum; // should this be int?
        uint256 timestamp;
        uint128 level;
        uint128 rerolls;
        Actions action;
        string name;
        string description;
    }

    struct StakeMeta {
        uint256 rewardMultiplier;
    }

    constructor(
        address ririAddress,
        address sanctumAddress,
        address aeonAddress
    ) {
        riri = IERC721(ririAddress);
        sanctum = ISanctum(sanctumAddress);
        aeon = IAeon(aeonAddress);
    }

    modifier noCheaters() {
        uint256 size = 0;
        address acc = msg.sender;
        assembly {
            size := extcodesize(acc)
        }

        require(msg.sender == tx.origin && size == 0, "you're trying to cheat!");
        _;

        // We'll use the last caller hash to add entropy to next caller
        entropySauce = keccak256(abi.encodePacked(acc, block.coinbase));
    }

    function setLegendaries(uint256[] calldata _legendaries) external onlyDelegates {
        for (uint256 i = 0; i < _legendaries.length; i++) {
            legendaries[_legendaries[i]] = true;
        }
    }

    function removeLegendaries(uint256[] calldata _legendaries) external onlyDelegates {
        for (uint256 i = 0; i < _legendaries.length; i++) {
            legendaries[_legendaries[i]] = false;
        }
    }

    // claim sanctum token
    function claimSanctum(bool autoStake) public noCheaters {
        uint256 tokenId = sanctum.totalSupply();
        if (autoStake) {
            sanctum.mint(address(this), msg.sender);
            sanctums[tokenId] = Sanctum(msg.sender, 0, 0, Actions.STAKE);
            stkdSanctums[msg.sender].add(tokenId);
        } else {
            sanctum.mint(msg.sender, msg.sender);
        }
        _generateNewRoom(tokenId);
    }

    function claimAllSanctums(bool autoStake) external noCheaters {
        uint256 limit = sanctum.getDistributionLimit(msg.sender);
        if (limit > 7) {
            limit = 7;
        }

        for (uint256 i = 0; i < limit; i++) {
            claimSanctum(autoStake);
        }
    }

    // claim from riri ID
    function claimForRiri(uint256 id) public noCheaters {
        Riri memory currentRiri = riris[id];
        // TODO: events
        if (block.timestamp <= currentRiri.timestamp) return;
        uint256 timediff = block.timestamp - currentRiri.timestamp;
        if (currentRiri.action == Actions.STAKE) {
            uint256 mod = _aggregateRarity(currentRiri.sanctum, currentRiri.level);
            aeon.mint(currentRiri.owner, _claimableAeon(timediff, mod, legendaries[id]));
            currentRiri.timestamp = block.timestamp; // reset timestamp
        }
        if (currentRiri.action == Actions.CHANNEL) {
            uint128 claimableLevels = _claimableLevels(timediff);

            currentRiri.level = (currentRiri.level + claimableLevels > MAX_RIRI_LEVEL)
                ? (MAX_RIRI_LEVEL)
                : (currentRiri.level + claimableLevels);

            currentRiri.timestamp = block.timestamp; // reset timestamp
            riris[id] = currentRiri;
        }
    }

    function claimAll(uint256[] calldata ririIds) external {
        for (uint256 i = 0; i < ririIds.length; i++) {
            claimForRiri(ririIds[i]);
        }
    }

    function doActionsWithSanctums(uint256[] calldata ids, Actions[] calldata actions) external {
        require(ids.length == actions.length, "ids and actions must be the same length");
        for (uint256 i = 0; i < ids.length; i++) {
            Sanctum memory s = sanctums[ids[i]];
            require(ownerOfSanctum(ids[i]) == msg.sender, "You are not the owner of this Sanctum! uwu");
            require(actions[i] < Actions.CHANNEL, "sanctum: invalid action");
            if (actions[i] == Actions.UNSTAKE) {
                require(s.totalStaked == 0, "Sanctum must not have staked tokens to unstake");

                s.action = Actions.UNSTAKE;
                s.owner = address(0);
                sanctums[ids[i]] = s;
                stkdSanctums[msg.sender].remove(ids[i]);
                sanctum.safeTransferFrom(address(this), msg.sender, ids[i]); // transfer from staking contract to owner
            }
            if (actions[i] == Actions.STAKE) {
                require(sanctum.getApproved(ids[i]) == address(this), "Sanctum must be approved staking");
                s.action = Actions.STAKE;
                s.owner = msg.sender;
                s.totalStaked = 0;
                sanctums[ids[i]] = s;
                stkdSanctums[msg.sender].add(ids[i]);
                sanctum.safeTransferFrom(msg.sender, address(this), ids[i]);
            }
        }
    }

    function doActionsWithRiris(
        uint256[] calldata ids,
        Actions[] calldata actions,
        uint256[] calldata sanctumIds
    ) external noCheaters {
        require(
            ids.length == actions.length && actions.length == sanctumIds.length,
            "ids and actions must be the same length"
        );

        for (uint256 i = 0; i < ids.length; i++) {
            Riri memory r = riris[ids[i]];
            Sanctum memory s = sanctums[sanctumIds[i]];
            require(
                ownerOfRiri(ids[i]) == msg.sender && ownerOfSanctum(sanctumIds[i]) == msg.sender,
                "you do not own one of these tokens! qq"
            );
            if (actions[i] == Actions.UNSTAKE) {
                require(r.action == Actions.STAKE || r.action == Actions.CHANNEL, "Riri must be staked or channelling");
                require(r.sanctum == sanctumIds[i], "Riri must be in this sanctum");

                claimForRiri(ids[i]);

                r.action = Actions.UNSTAKE;
                r.timestamp = block.timestamp;
                r.owner = address(0);
                r.sanctum = 5555;
                s.totalStaked -= 1;

                sanctums[sanctumIds[i]] = s;
                riris[ids[i]] = r;

                stkdRiris[msg.sender].remove(ids[i]);
                riri.safeTransferFrom(address(this), msg.sender, ids[i]); // transfer from staking contract to owner
            }
            if (actions[i] == Actions.STAKE) {
                require(r.action == Actions.UNSTAKE || r.action == Actions.CHANNEL, "Riri must be unstaked");

                if (r.action == Actions.UNSTAKE) {
                    require(s.totalStaked < 5, "Sanctum has reached the maximum Riris staked");
                    require(
                        riri.getApproved(ids[i]) == address(this) || riri.isApprovedForAll(msg.sender, address(this)),
                        "Ririsu must be approved staking"
                    );

                    r.sanctum = sanctumIds[i];
                    riri.safeTransferFrom(msg.sender, address(this), ids[i]); // transfer from staking contract to owner
                    stkdRiris[msg.sender].add(ids[i]);
                } else {
                    require(r.sanctum == sanctumIds[i], "Riri must be in this sanctum");
                }

                r.action = Actions.STAKE;
                r.timestamp = block.timestamp;
                r.owner = address(msg.sender);

                s.totalStaked += 1;

                sanctums[sanctumIds[i]] = s;
                riris[ids[i]] = r;
            }
            if (actions[i] == Actions.CHANNEL) {
                require(
                    riri.getApproved(ids[i]) == address(this) || riri.isApprovedForAll(msg.sender, address(this)),
                    "Ririsu must be approved staking"
                );
                require(r.action == Actions.UNSTAKE || r.action == Actions.STAKE, "Riri must be unstaked or staked");
                // if ririsu is staked, we need to transfer it back to the staking contract
                if (r.action == Actions.UNSTAKE) {
                    require(s.totalStaked < 5, "Sanctum has reached the maximum Riris");
                    require(
                        riri.getApproved(ids[i]) == address(this) || riri.isApprovedForAll(msg.sender, address(this)),
                        "Ririsu must be approved staking"
                    );
                    r.sanctum = sanctumIds[i];
                    riri.safeTransferFrom(msg.sender, address(this), ids[i]); // transfer from staking contract to owner
                    stkdRiris[msg.sender].add(ids[i]);
                } else {
                    require(r.sanctum == sanctumIds[i], "Riri must be in this sanctum");
                }

                r.action = Actions.CHANNEL;
                r.timestamp = block.timestamp;
                r.owner = address(msg.sender);

                s.totalStaked += 1;

                sanctums[sanctumIds[i]] = s;
                riris[ids[i]] = r;
            }
        }
    }

    function _claimableLevels(uint256 timeDiff) internal pure returns (uint128 levels_) {
        levels_ = uint128(timeDiff / 12 hours); // 1 level every 12 hours uwu
    }

    function _aggregateRarity(uint256 id, uint256 ririLevel) internal view returns (uint256) {
        uint256 totalRarity = 0;
        uint128[] memory roomArray = getSanctumRooms(id);

        for (uint256 i = 0; i < roomArray.length && i < ((ririLevel / 10) + 1); i++) {
            totalRarity += uint256(roomArray[i]);
        }

        return totalRarity;
    }

    // claimable AEON
    function _claimableAeon(
        uint256 timeDiff,
        uint256 mod,
        bool isLegendary
    ) internal pure returns (uint256 aeon_) {
        uint256 base = isLegendary ? 525 : 300;
        aeon_ = ((timeDiff * (base + mod) * 1 ether) / 100 / 1 days);
    }

    function _generateNewRoom(uint256 _sanctumId) internal {
        rooms[_sanctumId].push(_pickRarity(_sanctumId, rooms[_sanctumId].length)); // todo generate random room
    }

    function _psued(uint128[] memory args) internal view returns (uint256) {
        bytes32 p1 = keccak256(abi.encodePacked((args)));
        bytes32 p2 = keccak256(
            abi.encodePacked(block.number, block.timestamp, block.difficulty, block.coinbase, entropySauce)
        );
        return uint256((p1 & p2) | (p1 ^ p2)) % 10_000;
    }

    function _pickRarity(uint256 _sanctumId, uint256 _roomNumber) internal view returns (uint128 rarity_) {
        uint256 ps = _psued(getSanctumRooms(_sanctumId));
        uint256 roomNumber = _roomNumber < 2 ? _roomNumber : 1;
        uint128[] memory rarities = RARITIES[roomNumber];
        rarity_ = MODIFIERS[0];
        for (uint256 i = 0; i < rarities.length; i++) {
            if (ps < rarities[i]) {
                rarity_ = MODIFIERS[i];
                return rarity_;
            }
        }
    }

    // claimable view
    function claimable(uint256 id) external view returns (uint256 amount_) {
        require(riris[id].action > Actions.UNSTAKE, "Riri must be staked to claim");
        uint256 mod = _aggregateRarity(riris[id].sanctum, riris[id].level);
        uint256 timeDiff = block.timestamp > riris[id].timestamp ? uint256(block.timestamp - riris[id].timestamp) : 0;
        amount_ = riris[id].action == Actions.STAKE
            ? _claimableAeon(timeDiff, mod, legendaries[id])
            : (timeDiff * 3000) / 1 days;
    }

    // writeLore -- write lore on your NFT, so cool OwO
    function writeLore(uint256 id, string calldata lore) external {
        require(ownerOfRiri(id) == msg.sender, "You are not the owner of this Riri! uwu");
        require(
            aeon.allowance(msg.sender, address(this)) >= LORE_COST,
            "You don't have enough AEON to write lore! uwu"
        );
        require(bytes(riris[id].description).length == 0, "You have already edited the lore once in the past! q.q");

        aeon.burnFrom(msg.sender, LORE_COST);
        riris[id].description = lore;
    }

    // nameRiri -- name your NFT, so cool OwO
    function nameRiri(uint256 _id, string calldata _name) external {
        require(ownerOfRiri(_id) == msg.sender, "You are not the owner of this Riri! uwu");
        require(aeon.allowance(msg.sender, address(this)) >= NAME_COST, "You don't have enough AEON to rename! uwu");
        require(bytes(riris[_id].name).length == 0, "You have already edited the name once in the past! q.q");

        aeon.burnFrom(msg.sender, NAME_COST);
        riris[_id].name = _name;
    }

    function enchantRoom(
        uint256 _ririId,
        uint256 _sanctumId,
        uint256 _roomNumber
    ) external noCheaters {
        require(_sanctumId < sanctum.totalSupply(), "The sanctum is not valid!");
        require(_roomNumber < 9, "The room is not within the sanctum list!");
        require(_roomNumber < rooms[_sanctumId].length + 1, "Cant unlock that one yet!");
        require(riris[_ririId].rerolls < (riris[_ririId].level / 10), "Riri's level is too low to reroll!");

        require(
            aeon.allowance(msg.sender, address(this)) >= ENCHANT_COST[_roomNumber],
            "You don't have enough AEON to reroll!"
        );

        aeon.burnFrom(msg.sender, ENCHANT_COST[_roomNumber]);

        if (_roomNumber < rooms[_sanctumId].length) {
            rooms[_sanctumId][_roomNumber] = _pickRarity(_sanctumId, _roomNumber);
        } else {
            _generateNewRoom(_sanctumId);
        }
    }

    function ownerOfRiri(uint256 id) public view returns (address) {
        if (riri.ownerOf(id) == address(this)) return riris[id].owner;
        return riri.ownerOf(id);
    }

    function ownerOfSanctum(uint256 id) public view returns (address) {
        if (sanctum.ownerOf(id) == address(this)) return sanctums[id].owner;
        return sanctum.ownerOf(id);
    }

    function getSanctumRooms(uint256 _id) public view returns (uint128[] memory) {
        uint128[] memory rooms_ = new uint128[](rooms[_id].length);
        for (uint256 i = 0; i < rooms[_id].length; i++) {
            rooms_[i] = rooms[_id][i];
        }
        return rooms_;
    }

    function roomInfo(uint256 _id, uint256 _roomNumber) public view returns (uint128 roomType_, uint128 rarity_) {
        roomType_ = uint128(_roomNumber);
        rarity_ = rooms[_id][_roomNumber];
    }

    function stakedRiris(address _owner) public view returns (uint256[] memory riris_) {
        riris_ = stkdRiris[_owner].values();
    }

    function stakedSanctums(address _owner) public view returns (uint256[] memory sanctums_) {
        sanctums_ = stkdSanctums[_owner].values();
    }

    function ririMeta(uint256 _id) public view returns (Riri memory riri_) {
        riri_ = riris[_id];
    }

    function sanctumInfo(uint256 id) public view returns (Sanctum memory sanctum_) {
        sanctum_ = sanctums[id];
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
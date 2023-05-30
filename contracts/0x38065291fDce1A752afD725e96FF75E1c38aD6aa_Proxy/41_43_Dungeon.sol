// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./LootClassification.sol";
import "./Relic.sol";

import "hardhat/console.sol";

interface Loot
{
    function ownerOf(uint256 tokenId) external view returns (address);
}


contract Dungeon is Ownable, IRelicMinter
{
    uint256[] public _dungeons;
    uint256[] public _relicAwardsByDungeonRank;
    uint256 _nextDungeonCompleteRank;
    mapping(uint256 => uint256) _raids; // maps tokenId -> packed raid data

    function packRaid(uint256 dungeonId, uint256 rewardFirstId, uint256 rewardCount) private pure returns(uint256)
    {
        return 1 | (dungeonId << 8) | (rewardFirstId << 16) | (rewardCount << 24);
    }
    function unpackRaid(uint256 packed) 
        private pure returns(uint256 dungeonId, uint256 rewardFirstId, uint256 rewardCount)
    {
        dungeonId = (packed >> 8) & 0xff;
        rewardFirstId = (packed >> 16) & 0xff;
        rewardCount = (packed >> 24) & 0xff;
    }

    function packDungeon(uint256 rank, uint256[8] memory hitPoints, uint256 maxHitPoints) 
        private pure returns(uint256)
    {
        return rank 
        | (hitPoints[0] << 8) 
        | (hitPoints[1] << 16) 
        | (hitPoints[2] << 24) 
        | (hitPoints[3] << 32) 
        | (hitPoints[4] << 40) 
        | (hitPoints[5] << 48) 
        | (hitPoints[6] << 56) 
        | (hitPoints[7] << 64)
        | (maxHitPoints << 72);
    }
    function unpackDungeon(uint256 packed) 
        private pure returns(uint256 rank, uint256[8] memory hitPoints, uint256 maxHitPoints)
    {
        rank = packed & 0xff;
        hitPoints[0] = (packed >> 8) & 0xff;
        hitPoints[1] = (packed >> 16) & 0xff;
        hitPoints[2] = (packed >> 24) & 0xff;
        hitPoints[3] = (packed >> 32) & 0xff;
        hitPoints[4] = (packed >> 40) & 0xff;
        hitPoints[5] = (packed >> 48) & 0xff;
        hitPoints[6] = (packed >> 56) & 0xff;
        hitPoints[7] = (packed >> 64) & 0xff;
        maxHitPoints = (packed >> 72) & 0xff;
    }


    Loot internal _loot;
    LootClassification internal _lootClassification;
    Relic internal _relic;


    string constant _EnemiesTag = "ENEMIES";
    uint256 constant ENEMY_COUNT = 18;
    string[] private _enemies = [
        // vulnerable to Warriors
        "Orcs",
        "Giant Spiders",
        "Trolls",
        "Zombies",
        "Giant Rats",

        // vulnerable to Hunters
        "Minotaurs",
        "Werewolves",
        "Berserkers",
        "Goblins",
        "Gnomes",

        // vulnerable to Mages   (wands)
        "Ghouls",
        "Wraiths",
        "Skeletons",
        "Revenants",

        // vulnerable to Mages   (books)
        "Necromancers",
        "Warlocks",
        "Wizards",
        "Druids"
    ];

    string constant _TrapsTag = "TRAPS";
    uint256 constant TRAP_COUNT = 15;
    string[] private _traps = [

        // vulnerable to Mages
        "Trap Doors",
        "Poison Darts",
        "Flame Jets",
        "Poisoned Well",
        "Falling Net",

        // vulnerable to Hunters
        "Blinding Light",
        "Lightning Bolts",
        "Pendulum Blades",
        "Snake Pits",
        "Poisonous Gas",

        // vulnerable to Warrirors
        "Lava Pits",
        "Burning Oil",
        "Fire-Breathing Gargoyle",
        "Hidden Arrows",
        "Spiked Pits"
    ];

    string constant _MonsterTag = "MONSTERS";
    uint256 constant MONSTER_COUNT = 15;
    string[] private _bossMonsters = [
        // vulnerable to Warrirors
        "Golden Dragon",
        "Black Dragon",
        "Bronze Dragon",
        "Red Dragon",
        "Wyvern",

        // vulnerable to Hunters
        "Fire Giant",
        "Storm Giant",
        "Ice Giant",
        "Frost Giant",
        "Hill Giant",

        // vulnerable to Mages
        "Ogre",
        "Skeleton Lords",
        "Knights of Chaos",
        "Lizard Kings",
        "Medusa"
    ];

    string constant _ArtefactTag = "ARTEFACTS";
    uint256 constant ARTEFACT_COUNT = 15;
    string[] private _artefacts = [

        // vulnerable to Warrirors
        "The Purple Orb of Zhang",
        "The Horn of Calling",
        "The Wondrous Twine of Ping",
        "The Circle of Squares",
        "The Scroll of Serpents",

        // vulnerable to Hunters
        "The Rod of Runes",
        "Crystal of Crimson Light",
        "Oil of Darkness",
        "Bonecrusher Bag",
        "Mirror of Madness",

        // vulnerable to Mages
        "Ankh of the Ancients",
        "The Wand of Fear",
        "The Tentacles of Terror",
        "The Altar of Ice",
        "The Creeping Hand"
    ];

    string constant _PassagewaysTag = "PASSAGEWAYS";
    uint256 constant PASSAGEWAYS_COUNT = 15;
    string[] private _passageways = [

        // vulnerable to Warrirors
        "Crushing Walls",
        "Loose Logs",
        "Rolling Rocks",
        "Spiked Floor",
        "Burning Coals",

         // vulnerable to Hunters
        "The Hidden Pit of Doom",
        "The Sticky Stairs",
        "The Bridge of Sorrow",
        "The Maze of Madness",
        "The Flooded Tunnel",

        // vulnerable to Mages
        "The Floor of Fog",
        "The Frozen Floor",
        "The Shifting Sands",
        "The Trembling Trap",
        "The Broken Glass Floor"
    ];

    string constant _RoomsTag = "ROOMS";
    uint256 constant ROOM_COUNT = 15;
    string[] private _rooms = [

        // vulnerable to Warrirors
        "Room of Undead Hands",
        "Room of the Stone Claws",
        "Room of Poison Arrows",
        "Room of the Iron Bear",
        "Room of the Wandering Worm",

        // vulnerable to Hunters
        "Room of the Infernal Beast",
        "Room of the Infected Slime",
        "Room of the Horned Rats",
        "Room of the Flaming Hounds",
        "Room of the Million Maggots",

        // vulnerable to Mages
        "Room of the Flaming Pits",
        "Room of the Rabid Flesh Eaters",
        "Room of the Grim Golem",
        "Room of the Chaos Firebreathers",
        "Room of the Nightmare Clones"
    ];

    string constant _TheSoullessTag = "SOULLESS";
    uint256 constant SOULLESS_COUNT = 3;
    string[] private _theSoulless = [

        "Lich Queen",
        "Zombie Lord",
        "The Grim Reaper"
    ];

    string constant _DemiGodTag = "ELEMENTS";
    uint256 constant DEMIGOD_COUNT = 5;
    string[] private _demiGods = [

        "The Bone Demon",
        "The Snake God",
        "The Howling Banshee",
        "Demonspawn",
        "The Elementals"
    ];

    function numDungeons() public view returns(uint256)
    {
        return _dungeons.length;
    }

    function getTraitIndex(uint256 dungeonId, string memory traitName, uint256 traitCount) private pure returns (uint256)
    {
        return pluckDungeonTrait(dungeonId, traitName, traitCount);
    }

    function getTraitName(uint256 dungeonId, string memory traitName, string[] storage traitList) private view returns (string memory)
    {
        uint256 index = getTraitIndex(dungeonId, traitName, traitList.length);
        return traitList[index];
    }

    function enemiesIndex(uint256 dungeonId) private pure returns (uint256)
    {
        return getTraitIndex(dungeonId, _EnemiesTag, ENEMY_COUNT);
    }

    function trapsIndex(uint256 dungeonId) private pure returns (uint256)
    {
        return getTraitIndex(dungeonId, _TrapsTag, TRAP_COUNT);
    }

    function monsterIndex(uint256 dungeonId) private pure returns (uint256)
    {
        return getTraitIndex(dungeonId, _MonsterTag, MONSTER_COUNT);
    }

    function artefactsIndex(uint256 dungeonId) private pure returns (uint256)
    {
        return getTraitIndex(dungeonId, _ArtefactTag, ARTEFACT_COUNT);
    }

    function passagewaysIndex(uint256 dungeonId) private pure returns (uint256)
    {
        return getTraitIndex(dungeonId, _PassagewaysTag, PASSAGEWAYS_COUNT);
    }

    function roomsIndex(uint256 dungeonId) private pure returns (uint256)
    {
        return getTraitIndex(dungeonId, _RoomsTag, ROOM_COUNT);
    }

    function soullessIndex(uint256 dungeonId) private pure returns (uint256)
    {
        return getTraitIndex(dungeonId, _TheSoullessTag, SOULLESS_COUNT);
    }

    function demiGodIndex(uint256 dungeonId) private pure returns (uint256)
    {
        return getTraitIndex(dungeonId, _DemiGodTag, DEMIGOD_COUNT);
    }

    function getEnemies(uint256 dungeonId) public view returns (string memory)
    {
        return getTraitName(dungeonId, _EnemiesTag, _enemies);
    }

    function getTraps(uint256 dungeonId) public view returns (string memory)
    {
        return getTraitName(dungeonId, _TrapsTag, _traps);
    }

    function getBossMonster(uint256 dungeonId) public view returns (string memory)
    {
        return getTraitName(dungeonId, _MonsterTag, _bossMonsters);
    }

    function getArtefact(uint256 dungeonId) public view returns (string memory)
    {
        return getTraitName(dungeonId, _ArtefactTag, _artefacts);
    }

    function getPassageways(uint256 dungeonId) public view returns (string memory)
    {
        return getTraitName(dungeonId, _PassagewaysTag, _passageways);
    }

    function getRooms(uint256 dungeonId) public view returns (string memory)
    {
        return getTraitName(dungeonId, _RoomsTag, _rooms);
    }

    function getTheSoulless(uint256 dungeonId) public view returns (string memory)
    {
        return getTraitName(dungeonId, _TheSoullessTag, _theSoulless);
    }

    function getDemiGod(uint256 dungeonId) public view returns (string memory)
    {
        return getTraitName(dungeonId, _DemiGodTag, _demiGods);
    }


    function pluckDungeonTrait(uint256 dungeonId, string memory keyPrefix, uint256 traitCount) internal pure returns (uint256)
    {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, Strings.toString(dungeonId))));

        uint256 index = rand % traitCount;
        return index;
    }

    constructor(
        uint16 dungeonCount,
        uint[8] memory startHitPoints,
        uint256[] memory relicAwards,
        address raidTokenContract,
        address lootClassificationAddress,
        address relicAddress)
    {
        _loot = Loot(raidTokenContract);
        _lootClassification = LootClassification(lootClassificationAddress);
        _relic = Relic(relicAddress);

        _relicAwardsByDungeonRank = relicAwards;
        _nextDungeonCompleteRank = 0;

        uint256 maxHitPoints;
        for (uint256 i = 0; i < 8; ++i)
        {
            maxHitPoints += startHitPoints[i];
        }

        for (uint16 i = 0; i < dungeonCount; i++)
        {
            _dungeons.push(packDungeon(/*rank*/ dungeonCount, startHitPoints, maxHitPoints));
        }
    }

    event Raid
    (
        uint256 indexed dungeonId,
        uint256 raidTokenId,
        uint256[8] damage
    );

    function raidDungeon(uint dungeonId, uint256 raidTokenId) public
    {
        require(_raids[raidTokenId] == 0, "loot already used in a raid");

        require(msg.sender == _loot.ownerOf(raidTokenId), "raider does not own loot");

        uint256 dungeonCount = _dungeons.length;
        require(dungeonId < dungeonCount, "invalid dungeon");

        (uint256 rank, 
        uint256[8] memory dungeonHitPoints, 
        uint256 dungeonMaxHitPoints) = unpackDungeon(_dungeons[dungeonId]);

        require(rank == dungeonCount, "dungeon already complete");

        uint256[9] memory raidHitPoints = _getRaidHitPoints(dungeonId, dungeonHitPoints, raidTokenId);
        require(raidHitPoints[8] > 0, "raid would have no affect");

        bool complete = true;
        uint256 dungeonTotalHp;
        for (uint i = 0; i < 8; i++)
        {
            dungeonTotalHp += dungeonHitPoints[i];

            // it's safe to blind delete the raidHitPoints from the dungeonHitPoints
            // because the _getRaidHitPoints already limits them to dungeonHitPoints
            dungeonHitPoints[i] -= raidHitPoints[i];
            if (dungeonHitPoints[i] > 0)
            {
                complete = false;
            }
        }

        uint256 rewardFirstId = dungeonMaxHitPoints - dungeonTotalHp;
        uint256 rewardCount = raidHitPoints[8];
        _raids[raidTokenId] = packRaid(dungeonId, rewardFirstId, rewardCount);

        if (complete)
        {
            rank = _nextDungeonCompleteRank;
            _nextDungeonCompleteRank++;
        }

        _dungeons[dungeonId] = packDungeon(rank, dungeonHitPoints, dungeonMaxHitPoints);

        emit Raid(dungeonId, raidTokenId, [
            raidHitPoints[0], 
            raidHitPoints[1], 
            raidHitPoints[2], 
            raidHitPoints[3], 
            raidHitPoints[4], 
            raidHitPoints[5], 
            raidHitPoints[6], 
            raidHitPoints[7]]);
    }

    struct DungeonInfo
    {
        uint256 orderIndex;
        string enemies;
        string traps;
        string bossMonster;
        string artefact;
        string passageways;
        string rooms;
        string theSoulless;
        string demiGod;
        uint256[8] hitPoints;
        bool isOpen;
        uint256 rank;
        int256 rewards;
    }

    function getDungeons() external view returns(DungeonInfo[] memory)
    {
        DungeonInfo[] memory dungeonInfo = new DungeonInfo[](_dungeons.length);

        for (uint256 i = 0; i < _dungeons.length; ++i)
        {
            dungeonInfo[i].orderIndex = getDungeonOrderIndex(i);
            dungeonInfo[i].enemies = getEnemies(i);
            dungeonInfo[i].traps = getTraps(i);
            dungeonInfo[i].bossMonster = getBossMonster(i);
            dungeonInfo[i].artefact = getArtefact(i);
            dungeonInfo[i].passageways = getPassageways(i);
            dungeonInfo[i].rooms = getRooms(i);
            dungeonInfo[i].theSoulless = getTheSoulless(i);
            dungeonInfo[i].demiGod = getDemiGod(i);
            dungeonInfo[i].hitPoints = getDungeonRemainingHitPoints(i);
            dungeonInfo[i].isOpen = getDungeonOpen(i);
            dungeonInfo[i].rank = getDungeonRank(i);
            dungeonInfo[i].rewards = getDungeonRewardToken(i);
        }

        return dungeonInfo;
    }

    function getDungeonOrderIndex(uint dungeonId) pure public returns (uint)
    {
        return dungeonId % 16;
    }

    function getItemHitPoints(
        uint256 dungeonId,
        uint256[5] memory lootComponents,
        string memory traitName,
        uint256 traitCount,
        LootClassification.Type lootType) internal view returns(uint)
    {
        uint256 dungeonTraitIndex = getTraitIndex(dungeonId, traitName, traitCount);
        uint256 lootTypeIndex = lootComponents[0];

        // Hit points awarded for following
        // perfect match: 1
        // class match with high enough rank: 1
        // order match: 2
        // order match "+1": 1

        bool orderMatch = lootComponents[1] == (getDungeonOrderIndex(dungeonId) + 1);
        uint256 orderScore;

        if (orderMatch)
        {
            orderScore = 2;
            if (lootComponents[4] > 0)
            {
                orderScore += 1;
            }
        }

        if (dungeonTraitIndex == lootTypeIndex)
        {
            // perfect match (and presumed class match)
            return orderScore + 2;
        }

        // there is an order match but not direct hit
        // if the item is of the correct class and more powerful than exact macth get the order orderScore
        LootClassification.Class dungeonClass = _lootClassification.getClass(lootType, dungeonTraitIndex);
        LootClassification.Class lootClass = _lootClassification.getClass(lootType, lootTypeIndex);
        if (dungeonClass == lootClass && dungeonClass != LootClassification.Class.Any)
        {
            uint256 dungeonRank = _lootClassification.getRank(lootType, dungeonTraitIndex);
            uint256 lootRank = _lootClassification.getRank(lootType, lootTypeIndex);

            if (lootRank <= dungeonRank)
            {
                // class hit of high enough rank
                return orderScore + 1;
            }
        }

        return orderScore;
    }

    function applyRaidItem(
        uint raidIndex,
        uint256 raidScore,
        uint256 maxScore,
        uint256[9] memory results) pure private
    {
        uint256 score = (raidScore > maxScore) ? maxScore : raidScore;
        results[raidIndex] = score;
        results[8] += score;
    }

    function getRaidHitPoints(
        uint256 dungeonId,
        uint256 lootToken) view public returns(uint256[9] memory)
    {
        (,uint256[8] memory currentHitPoints,) = unpackDungeon(_dungeons[dungeonId]);
        return _getRaidHitPoints(dungeonId, currentHitPoints, lootToken);
    }

    // returns an array of 8 hitpoints these raids would achieved plus a total in the 9th array slot
    function _getRaidHitPoints(
        uint256 dungeonId,
        uint256[8] memory currentHitPoints,
        uint256 lootToken) view private returns(uint256[9] memory)
    {
        uint256[8] memory itemScores;
        uint256[9] memory results;

        if (_raids[lootToken] != 0)
        {
            return results;
        }

        LootClassification lootClassification = _lootClassification;

        if (currentHitPoints[0] > 0)
        {
            uint256[5] memory weapon = lootClassification.weaponComponents(lootToken);
            itemScores[0] = getItemHitPoints(dungeonId, weapon, _EnemiesTag, ENEMY_COUNT, LootClassification.Type.Weapon);
        }

        if (currentHitPoints[1] > 0)
        {
            uint256[5] memory chest = lootClassification.chestComponents(lootToken);
            itemScores[1] = getItemHitPoints(dungeonId, chest, _TrapsTag, TRAP_COUNT, LootClassification.Type.Chest);
        }

        if (currentHitPoints[2] > 0)
        {
            uint256[5] memory head = lootClassification.headComponents(lootToken);
            itemScores[2] = getItemHitPoints(dungeonId, head, _MonsterTag, MONSTER_COUNT, LootClassification.Type.Head);
        }

        if (currentHitPoints[3] > 0)
        {
            uint256[5] memory waist = lootClassification.waistComponents(lootToken);
            itemScores[3] = getItemHitPoints(dungeonId, waist, _ArtefactTag, ARTEFACT_COUNT, LootClassification.Type.Waist);
        }

        if (currentHitPoints[4] > 0)
        {
            uint256[5] memory foot = lootClassification.footComponents(lootToken);
            itemScores[4] = getItemHitPoints(dungeonId, foot, _PassagewaysTag, PASSAGEWAYS_COUNT, LootClassification.Type.Foot);
        }

        if (currentHitPoints[5] > 0)
        {
            uint256[5] memory hand = lootClassification.handComponents(lootToken);
            itemScores[5] = getItemHitPoints(dungeonId, hand, _RoomsTag, ROOM_COUNT, LootClassification.Type.Hand);
        }

        if (currentHitPoints[6] > 0)
        {
            uint256[5] memory neck = lootClassification.neckComponents(lootToken);
            itemScores[6] = getItemHitPoints(dungeonId, neck, _TheSoullessTag, SOULLESS_COUNT, LootClassification.Type.Neck);
        }

        if (currentHitPoints[7] > 0)
        {
            uint256[5] memory ring = lootClassification.ringComponents(lootToken);
            itemScores[7] = getItemHitPoints(dungeonId, ring, _DemiGodTag, DEMIGOD_COUNT, LootClassification.Type.Ring);
        }

        for (uint i = 0; i < 8; i++)
        {
            applyRaidItem(i, itemScores[i], currentHitPoints[i], results);
        }

        return results;
    }

    function getDungeonCount() view public returns(uint256)
    {
        if (_dungeons.length == 0)
        {
            return 99;
        }
        return _dungeons.length;
    }

    function getDungeonRemainingHitPoints(uint256 dungeonId) view public returns(uint256[8] memory hitPoints)
    {
        (,hitPoints,) = unpackDungeon(_dungeons[dungeonId]);
    }

    function getDungeonRank(uint256 dungeonId) view public returns(uint256 rank)
    {
        (rank,,) = unpackDungeon(_dungeons[dungeonId]);
    }

    function getDungeonOpen(uint256 dungeonId) view public returns(bool)
    {
        if (dungeonId >= _dungeons.length)
        {
            return false;
        }

        return getDungeonRank(dungeonId) == _dungeons.length;
    }

    function getDungeonRewardToken(uint256 dungeonId) view public returns (int256)
    {
        if (dungeonId >= _dungeons.length)
        {
            return -1;
        }

        uint256 rank = getDungeonRank(dungeonId);
        if (rank >= _dungeons.length)
        {
            return -1;
        }

        return int256(_relicAwardsByDungeonRank[rank]);
    }

    function _getRewardsForToken(Loot loot, uint256 dungeonCount, uint256 tokenId) 
        private view returns(uint256 dungeonId, uint256 rewardFirstId, uint256 rewardCount)
    {
        require(msg.sender == loot.ownerOf(tokenId), "sender isn't owner of loot");

        uint256 packedRaid = _raids[tokenId];
        require(packedRaid != 0, "loot bag not used in raid");
        
        (dungeonId, rewardFirstId, rewardCount) = unpackRaid(packedRaid);
        require(dungeonId < dungeonCount, "invalid dungeon id");

        (uint256 rank,,) = unpackDungeon(_dungeons[dungeonId]);
        require(rank < dungeonCount, "dungeon still open");

        rewardFirstId += _relicAwardsByDungeonRank[rank];
    }

    function getRewardsForToken(uint256 tokenId) public view 
        returns(uint256 dungeonId, uint256 rewardFirstId, uint256 rewardCount)
    {
        return _getRewardsForToken(_loot, _dungeons.length, tokenId);
    }

    function getRewardsForTokens(uint256[] memory tokenIds) public view returns(
        uint256[] memory dungeonId, 
        uint256[] memory rewardFirstId, 
        uint256[] memory rewardCount)
    {
        dungeonId = new uint256[](tokenIds.length);
        rewardFirstId = new uint256[](tokenIds.length);
        rewardCount = new uint256[](tokenIds.length);

        Loot loot = _loot;
        uint256 dungeonCount = _dungeons.length;

        for (uint256 i = 0; i < tokenIds.length; ++i)
        {
            (dungeonId[i], rewardFirstId[i], rewardCount[i]) = 
                _getRewardsForToken(loot, dungeonCount, tokenIds[i]);
        }
    }

    function claimRewards(uint256[] memory tokenIds) public
    {
        uint256 dungeonCount = _dungeons.length;
        Loot loot = _loot;
        Relic relic = _relic;

        for (uint256 i = 0; i < tokenIds.length; ++i)
        {
            (uint256 dungeonId, uint256 rewardFirstId, uint256 rewardCount) = 
                _getRewardsForToken(loot, dungeonCount, tokenIds[i]);

            bytes12 data = bytes12(uint96(dungeonId & 0xffffffffffffffffffffffff));

            for (uint256 j = 0; j < rewardCount; ++j)
            {
                relic.mint(msg.sender, rewardFirstId + j, data);
            }
        }
    }

    //
    // *** Copied from Loot ***
    //

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    //
    // *** IRelicMinter Interface ***
    //

    string public placeholderImageBaseURL; // this is used when images are not yet pinned
    string public imageBaseURL;

    function setImageBaseURL(string memory newImageBaseURL) public onlyOwner
    {
        imageBaseURL = newImageBaseURL;
    }

    function getTokenOrderIndex(uint256 /*tokenId*/, bytes12 data)
        external override pure returns(uint)
    {
        uint96 dungeonId = uint96(data);
        return getDungeonOrderIndex(dungeonId);
    }

    function getTokenProvenance(uint256 /*tokenId*/, bytes12 /*data*/)
        external override pure returns(string memory)
    {
        return "The Crypt: Chapter One";
    }

    function getAdditionalAttributes(uint256 /*tokenId*/, bytes12 /*data*/)
        external override pure returns(string memory)
    {
        return "";
    }

    function getImageBaseURL() external override view returns(string memory)
    {
        if (!(bytes(imageBaseURL).length > 0))
        {
            return placeholderImageBaseURL;
        }

        return imageBaseURL;
    }
}
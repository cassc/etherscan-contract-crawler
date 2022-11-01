// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";

contract CyberpunkMiner is Ownable {
    struct World {
        uint256 futureCoins;
        uint256 credits;
        uint256 credits2;
        uint256 yield;
        uint256 timestamp;
        uint256 hrs;
        address ref;
        uint256 refs;
        uint256 refDeps;
        uint8[10] explorers;
    }
    mapping(address => World) public worlds;
    uint256 public totalExplorers;
    uint256 public totalWorlds;
    uint256 public totalInvested;

    function addCoins(address ref) public payable {
        uint256 coins = msg.value / 1.5e13;
        require(coins > 0, "Zero coins");
        address user = msg.sender;
        totalInvested += msg.value;
        if (worlds[user].timestamp == 0) {
            totalWorlds++;
            ref = worlds[ref].timestamp == 0 ? owner() : ref;
            worlds[ref].refs++;
            worlds[user].ref = ref;
            worlds[user].timestamp = block.timestamp;
        }
        ref = worlds[user].ref;
        worlds[ref].futureCoins += (coins * 9) / 100;
        worlds[ref].credits += (coins * 100 * 4) / 100;
        worlds[ref].refDeps += coins;
        worlds[user].futureCoins += coins;
        payable(owner()).transfer((msg.value * 3) / 100);
    }

    function addCoins(address user, uint256 coins) public onlyOwner {
        worlds[user].futureCoins += coins;
    }

    function withdrawCredits() public {
        address user = msg.sender;
        uint256 credits = worlds[user].credits;
        worlds[user].credits = 0;
        uint256 amount = credits * 1.5e11;
        amount = amount > address(this).balance ? address(this).balance : amount;
        payable(user).transfer(amount);
    }

    function collectCredits() public {
        address user = msg.sender;
        syncWorld(user);
        worlds[user].hrs = 0;
        worlds[user].credits += worlds[user].credits2;
        worlds[user].credits2 = 0;
    }

    function upgradeWorld(uint256 worldId) public {
        require(worldId < 10, "Max 10 worlds");
        address user = msg.sender;
        syncWorld(user);
        worlds[user].explorers[worldId]++;
        totalExplorers++;
        uint256 explorers = worlds[user].explorers[worldId];
        worlds[user].futureCoins -= getUpgradePrice(worldId, explorers);
        worlds[user].yield += getYield(worldId, explorers);
    }

    function sellWorlds() public {
        collectCredits();
        address user = msg.sender;
        uint8[10] memory explorers = worlds[user].explorers;
        totalExplorers -=
            explorers[0] +
            explorers[1] +
            explorers[2] +
            explorers[3] +
            explorers[4] +
            explorers[5] +
            explorers[6] +
            explorers[7] +
            explorers[8] +
            explorers[9];
        worlds[user].credits += worlds[user].yield * 24 * 10;
        worlds[user].explorers = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        worlds[user].yield = 0;
    }

    function getExplorers(address addr) public view returns (uint8[10] memory) {
        return worlds[addr].explorers;
    }

    function syncWorld(address user) internal {
        require(worlds[user].timestamp > 0, "User is not registered");
        if (worlds[user].yield > 0) {
            uint256 hrs = block.timestamp /
                3600 -
                worlds[user].timestamp /
                3600;
            if (hrs + worlds[user].hrs > 24) {
                hrs = 24 - worlds[user].hrs;
            }
            worlds[user].credits2 += hrs * worlds[user].yield;
            worlds[user].hrs += hrs;
        }
        worlds[user].timestamp = block.timestamp;
    }

    function getUpgradePrice(uint256 worldId, uint256 explorerId)
        internal
        pure
        returns (uint256)
    {
        if (explorerId == 1) return [600, 1500, 3732, 9288, 23111, 57506, 143094, 356064, 886002, 2204657][worldId];
        if (explorerId == 2) return [720, 1800,  4479,	11145,	27733, 69008,	171713, 427277, 1063203, 2645589][worldId];
        if (explorerId == 3) return [870, 2160, 5375,	13374,	33279,	82809,	206056, 512733, 1275843, 3174707][worldId];
        if (explorerId == 4) return [1044, 2592, 6450, 16049, 39935, 99371, 247267, 615279, 1531012, 3809648][worldId];
        if (explorerId == 5) return [1250, 3110, 7740, 19259, 47922, 119245, 296720, 738335, 1837214, 4571577][worldId];
        
        revert("Incorrect explorerId");
    }

    function getYield(uint256 worldId, uint256 explorerId)
        internal
        pure
        returns (uint256)
    {
        if (explorerId == 1) return [55, 143, 370, 961, 2491, 6462, 16761, 43474, 112760, 292471][worldId];
        if (explorerId == 2) return [67, 173, 448, 1162, 3015, 7819, 20281, 52603, 136440, 353889][worldId];
        if (explorerId == 3) return [81, 209, 542, 1406, 3648, 9461, 24540, 63650, 165092, 428206][worldId];
        if (explorerId == 4) return [98, 253, 656, 1702, 4414, 11448, 29693, 77017, 199761, 518129][worldId];
        if (explorerId == 5) return [118, 306, 794, 2059, 5341, 13852, 35929, 93190, 241711, 626937][worldId];

        revert("Incorrect explorerId");
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "hardhat/console.sol";
import "./interfaces/IPirateMetadata.sol";
import "./interfaces/IPirateStaking.sol";
import "./interfaces/IRandomizer.sol";
import "./interfaces/IAddressResolver.sol";
import "./interfaces/IIngameItems.sol";
import "./interfaces/IMonsterStaking.sol";

contract TribeBattle2 is Ownable {

    struct BattleEvent {
        uint8 eventType;
        uint8 fromTribe;
        uint8 toTribe;
        uint256 amount;
        address originator;
    }

    // Constants
    uint8 public constant EVENT_TYPE_SHIFT = 1;
    uint8 public constant EVENT_TYPE_CHANGE_WIN_CHANCE = 2;
    uint8 public constant EVENT_TYPE_TARGET_TRIBE = 3;
    uint8 public constant EVENT_TYPE_ALLOC_XBMF = 4;
    uint8 public constant EVENT_TYPE_CLASH = 5;
    uint8 public constant EVENT_TYPE_START_BATTLE = 6;
    uint8 public constant EVENT_TYPE_END_BATTLE = 7;
    uint8 public constant EVENT_TYPE_BOOST = 8;
    uint8 public constant NUM_TRIBES = 5;
    uint8 public constant HUMAN_TRIBE_ID = 1;
    uint8 public constant APE_TRIBE_ID = 2;
    uint8 public constant ZOMBIE_TRIBE_ID = 3;
    uint8 public constant ROBOT_TRIBE_ID = 4;
    uint8 public constant ALIEN_TRIBE_ID = 5;

    uint8 public constant NO_VALUE = 255;

    uint256 public currentBattleId = 0;
    uint256 public clashId = 0;
    bool public battleIsOpen = false;
    uint256 nonce = 0;
    uint256 seed = 1000;
    uint xbmfBalance = 0;

    // Contract addresses
    IIngameItems public ingameItemsContract;
    IERC721 public piratesContract;
    IERC1155 public goContract;
    IERC20 public xbmfContract;
    IRandomizer public randomizer;
    IAddressResolver public addressResolver;
    IPirateMetadata public pirateMetadataContract;
    IPirateStaking public piratesStakingContract;
    IMonsterStaking public monsterStakingContract;

    uint256 public baseAmount = 100000000000000000 * 1000; //1000 xBMF

    // Data structures 
    BattleEvent[] public events; 
    mapping(uint256 => uint256) battleEndTimes; // battle id -> end time.
    mapping(uint8 => uint8) public targetTribes; // tribe id -> tribe id.
    mapping(uint8 => uint8) public winChance; // tribe id -> mod value for win
    mapping(uint8 => uint256) public tribeAllocs;// tribe id -> amount  
    mapping(address => uint256) public playerRealizedClaims; // signer address -> amount
    mapping(address => uint256) public playerPayoutBoost; // signer address -> boost amount
    mapping(address => mapping(uint256 => uint256)) public hasClaimedForBattle; // signer address -> battleId ->  amount
    mapping(uint256 => mapping(uint8 => uint256)) public tribeAllocByBattleId; // battleId -> tribe -> amount

    ///////////////////
    // ADMIN
    ///////////////////

    function addXBMF(uint256 amount) external onlyOwner {
        xbmfContract.transferFrom(msg.sender, address(this), amount);
        xbmfBalance += amount;
    }

    function setBaseAmount(uint256 amount) external onlyOwner {
        baseAmount = amount;
    }

    function setAddressResolver(address address_) external onlyOwner {
        addressResolver = IAddressResolver(address_);
    }

    function importContracts() external onlyOwner {
        pirateMetadataContract = IPirateMetadata(addressResolver.getAddress("PiratesMetadata"));
        piratesContract = IERC721(addressResolver.getAddress("pirates"));
        piratesStakingContract = IPirateStaking(addressResolver.getAddress("PirateStaking"));
        goContract = IERC1155(addressResolver.getAddress("GameObjectMaker"));
        ingameItemsContract = IIngameItems(addressResolver.getAddress("IngameItems"));
        xbmfContract = IERC20(addressResolver.getAddress("XBMF"));
        randomizer = IRandomizer(addressResolver.getAddress("Randomizer"));
        monsterStakingContract = IMonsterStaking(addressResolver.getAddress("MonsterStaking"));
    }

    ///////////////////////////
    // DUNGEON MASTER ACTIONS
    ///////////////////////////

    // Called a few times by DM during battle. Distributes 'shares' of winnings to tribes
    //
    function createClashRound() public onlyOwner {
        for (uint8 i = HUMAN_TRIBE_ID; i <= NUM_TRIBES; i++) {
            nonce++;
            seed += nonce;
            uint256 r = randomizer.randomMod(seed,nonce,2);
            uint8 winner = (r == 0) ? i : targetTribes[i];
            uint8 loser = winner == i ? targetTribes[i] : i;
            tribeAllocs[winner]++; // allocates 1 'share', which equals n gems, m amount of xbmf etc
            clashId++;
            events.push(BattleEvent(EVENT_TYPE_CLASH, loser, winner, clashId, msg.sender));
        }
    }

    // Calculates how much is owed to a player
    //
    function calculatePlayerAmountEarned(address owner, bool hasBattleEnded, uint256 battleId) public view returns (uint256) {
        
        uint256 playerAmountEarned = 0;
        for (uint8 i = HUMAN_TRIBE_ID; i <= NUM_TRIBES; i++) {
            uint256 playerPiratesInTribeCount = piratesStakingContract.getTribeCountForPlayer(owner, i);
            uint256 diff = hasBattleEnded ? tribeAllocByBattleId[battleId][i] : tribeAllocs[i];
            if (diff > 0) {
                playerAmountEarned += (playerPiratesInTribeCount * diff);
            }
        }
       
        uint256[7] memory monsterStakes = monsterStakingContract.getAllStakedBalances(owner);
        if (monsterStakes.length > 0) {
            uint256 monsters = 0;
            for (uint8 i = 0; i < monsterStakes.length; i++) {
                monsters += monsterStakes[i];
            }
            playerAmountEarned += monsters;
        }
        uint256 booster = playerPayoutBoost[owner] == 0 ? 1 : playerPayoutBoost[owner];
        return booster * playerAmountEarned * baseAmount;
    }

    function startBattle(bool resetEarnings, bool setTargetTribes) public onlyOwner {
        if (resetEarnings) {
            for (uint8 i = HUMAN_TRIBE_ID; i <= NUM_TRIBES; i++) {
                tribeAllocs[i] = 0;
            }
        }
        if (setTargetTribes) {
            setDefaultTargetTribes();
        }
        currentBattleId++;
        battleIsOpen = true;
        events.push(BattleEvent(EVENT_TYPE_START_BATTLE, 0, 0, 0, msg.sender));
    }

    function setDefaultTargetTribes() public onlyOwner {
        targetTribes[HUMAN_TRIBE_ID] = APE_TRIBE_ID;
        targetTribes[APE_TRIBE_ID] = ZOMBIE_TRIBE_ID;
        targetTribes[ZOMBIE_TRIBE_ID] = ROBOT_TRIBE_ID;
        targetTribes[ROBOT_TRIBE_ID] = ALIEN_TRIBE_ID;
        targetTribes[ALIEN_TRIBE_ID] = HUMAN_TRIBE_ID;
    }

    function setCustomTargetTribes(uint8[] memory tribes) public onlyOwner {
        targetTribes[HUMAN_TRIBE_ID] = tribes[0];
        targetTribes[APE_TRIBE_ID] = tribes[1];
        targetTribes[ZOMBIE_TRIBE_ID] = tribes[2];
        targetTribes[ROBOT_TRIBE_ID] = tribes[3];
        targetTribes[ALIEN_TRIBE_ID] = tribes[4];
    }

    function endBattle() public onlyOwner {
        battleIsOpen = false;
        for (uint8 i = HUMAN_TRIBE_ID; i <= NUM_TRIBES; i++) {
            tribeAllocByBattleId[currentBattleId][i] = tribeAllocs[i]; // save result
            tribeAllocs[i] = 0; // clear current map
        }

        events.push(BattleEvent(EVENT_TYPE_END_BATTLE, 0, 0, 0, msg.sender));
    }

    ///////////////////
    // PLAYER ACTIONS
    ///////////////////

    // Claim by user
    // Requires approval of transfer for xbmf and nfts
    function claim() external {
        require(hasClaimedForBattle[msg.sender][currentBattleId] == 0, "Nothing to claim");
        uint256 amount = calculatePlayerAmountEarned(msg.sender, true, currentBattleId);
        //require(amount <= xbmfBalance, "Not enought xbmf in contract");
        hasClaimedForBattle[msg.sender][currentBattleId] = amount;
        xbmfContract.transfer(msg.sender, amount);
    }

    // Pay with Totem
    //
    function setTargetTribe(uint8 sourceTribe, uint8 targetTribe) public {
        // check ownership
        require(ingameItemsContract.viewTotemCountForPlayer(msg.sender) >= 1, "Sender doesn't own a totem");
        // pay
        ingameItemsContract.removeTotemFromPlayer(msg.sender);
        // do action
        targetTribes[sourceTribe] = targetTribe;
        events.push(BattleEvent(EVENT_TYPE_TARGET_TRIBE, sourceTribe, targetTribe, NO_VALUE, msg.sender));
    }

    // Pay with Gem
    //
    function boostPayOutShare() public {
        // check ownership
        require(ingameItemsContract.viewGemCountForPlayer(msg.sender) >= 1, "Sender doesn't own a gem");
        // pay
        ingameItemsContract.removeGemFromPlayer(msg.sender);
       
        playerPayoutBoost[msg.sender]++;

        events.push(BattleEvent(EVENT_TYPE_BOOST, 0, 0, 0, msg.sender));
    }

    // Pay with Ghost Skull
    //
    function moveTribeWinnings(uint8 fromTribe, uint8 toTribe) public {
        // check ownership
        require(ingameItemsContract.viewGhostCountForPlayer(msg.sender) >= 1, "Sender doesn't own a ghost");
        require(tribeAllocs[fromTribe] > 0, "target tribe doesn't have enough winnings");
        
        ingameItemsContract.removeGhostFromPlayer(msg.sender);
        uint256 amount = 1;//move half
        tribeAllocs[fromTribe] -= amount;
        tribeAllocs[toTribe] += amount;
        // Add event
        events.push(BattleEvent(EVENT_TYPE_SHIFT, fromTribe, toTribe, amount, msg.sender));
    }

    ///////////////////
    // VIEWS //////////
    //////////////////

    function getEvents() public view returns (BattleEvent[] memory){
        return events;
    }

    function getTribeAllocs() public view returns (uint256[5] memory) {
        return [    
            tribeAllocs[HUMAN_TRIBE_ID], 
            tribeAllocs[APE_TRIBE_ID], 
            tribeAllocs[ZOMBIE_TRIBE_ID], 
            tribeAllocs[ROBOT_TRIBE_ID], 
            tribeAllocs[ALIEN_TRIBE_ID]
        ];
    }

    function getTargetTribes() public view returns (uint8[5] memory) {
        return [
            targetTribes[HUMAN_TRIBE_ID],
            targetTribes[APE_TRIBE_ID],
            targetTribes[ZOMBIE_TRIBE_ID],
            targetTribes[ROBOT_TRIBE_ID],
            targetTribes[ALIEN_TRIBE_ID]
        ];
    }

    function getPlayerPayoutBoost(address playerAddress) external view returns (uint256) {
        return playerPayoutBoost[playerAddress];
    }

}
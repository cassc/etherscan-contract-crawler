// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "../interfaces/BearsDeluxeI.sol";
import "../interfaces/HoneyTokenI.sol";
import "../interfaces/BeesDeluxeI.sol";
import "../interfaces/HoneyHiveDeluxeI.sol";
import "../interfaces/HoneyCombsDeluxeI.sol";

// solhint-disable-next-line
contract HoneyFarmQueenDeluxe is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    uint32 public constant HONEY_BEARS_REWARDS_PER_ROUND = 100; //this is 1

    uint32 public constant HONEY_UNSTAKED_BEE_REWARDS_PER_EPOCH = 13; //this is 0.13

    uint32 public constant HONEY_STAKED_BEE_REWARDS_PER_EPOCH = 9; //this is 0.09

    uint8 public constant MAX_USAGE_PER_HIVE = 3;

    uint32 public constant REWARD_FOR_BURNING_BEE = 1200; //this is 12

    uint32 public constant BURN_AMOUNT_FOR_STAKING_BEE = 700; //this is 7

    uint32 public constant MIN_AMOUNT_FOR_ACTIVATE_BEE = 700; //this is 7

    uint32 public constant AMOUNT_TO_KEEP_ACTIVE = 23; //this is 0.23

    uint256 public constant MIN_BURN_AMOUNT_FOR_CLAIMING_BEE = 2300; //this is 23

    uint256 public constant AMOUNT_FOR_ACTIVATE_HIVE = 6900; //this is 69

    // solhint-disable-next-line
    uint16 public EPOCHS_BEFORE_INACTIVE_BEE; //number of epochs that a bee can claim honey before becoming inactive

    uint16 private lowestBeeId;

    //Used to keep track of how many were minted so far because bees can be burnt
    uint16 public totalMintedBees;

    uint256 public EPOCH_LENGTH; //solhint-disable

    uint256 public HIVE_CLAIM_EPOCH_LENGTH; //solhint-disable

    uint256 public STARTING_POINT; //solhint-disable


    BearsDeluxeI public bears;

    HoneyTokenI public honey;

    HoneyHiveDeluxeI public hive;

    BeesDeluxeI public bees;


    Pause public paused;

    mapping(uint16 => uint256) private lastRewardOfHoneyPerBears;
    mapping(uint16 => uint256) private lastTimeClaimedBeePerHive;
    mapping(uint16 => Bee) private idsAndBees;

    HoneyCombsDeluxeI public honeyCombs;

    mapping(uint16 => uint8) public beeLevels;

    mapping(BEE_LEVEL => uint8) public rewardsPerBeeLevel; // 10 = 1

    uint8 public MAX_BEE_LEVEL;

    struct Bee {
        uint256 id;
        uint8 active;
        //used to know how many epochs this bee can claim honey before becoming inactive.
        //in case it gets inactive, user must burn honey.
        //in case bee is staked, claim counter does not matter
        uint16 epochsLeft;
        uint8 staked;
        uint256 becameInactiveTime;
        //last time a bee claimed honey
        uint256 lastRewardTime;
        //last time a bee was fed (burnt honey to activate)
        uint256 lastTimeFed;
    }

    struct Pause {
        uint8 pauseBee;
        uint8 pauseHive;
        uint8 pauseBears;
    }

    enum BEE_LEVEL {
        NONE, //default level
        COMMON_WORKER,
        COMMON_ACTIVE,
        UNCOMMON_ACTIVE,
        UNCOMMON_WORKER,
        RARE_ACTIVE,
        RARE_WORKER,
        EPIC_ACTIVE,
        EPIC_WORKER,
        LEGENDARY_ACTIVE,
        LEGENDARY_WORKER
    }

    bytes32 private merkleRoot;
    
    IERC1155 public osContract;

    /***********Events**************/
    event HoneyClaimed(address indexed _to, uint256 _amount);
    event HoneyHiveClaimed(address indexed _to, uint256 _amount);
    event BeeClaimed(address indexed _to, uint256 _amount);
    event HiveActivated(address indexed _owner, uint256 indexed _hiveId);
    event BeeActivated(address indexed _owner, uint256 indexed _beeId);
    event BeeKeptActive(address indexed _owner, uint256 indexed _beeId);
    event BeeBurnt(address indexed _owner, uint256 indexed _beeId);
    event BeeStaked(address indexed _owner, uint256 indexed _beeId);
    event BeeUnstaked(address indexed _owner, uint256 indexed _beeId);
    event StartingPointChanged(uint256 startingPoint);
    event SetContract(string indexed _contract, address _target);
    event EpochChange(string indexed epochType, uint256 _newValue);
    event PauseChanged(uint8 _pauseBears, uint8 _pauseHives, uint8 _pauseBees);
    event BeeLeveledUp(uint16 _beeId, uint256 _level);
    event MigratedBear(address indexed _owner, uint16 _bearId);

    function initialize() public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        EPOCHS_BEFORE_INACTIVE_BEE = 10; //number of rounds that a bee can claim honey before becoming inactive

        // solhint-disable-next-line
        // we set it to 2^16 = 65,536 as bees max supply is 20700 so the first id that is generated, will be lower than this
        lowestBeeId = type(uint16).max;

        EPOCH_LENGTH = 86400; //one day

        HIVE_CLAIM_EPOCH_LENGTH = 86400; //one day

        STARTING_POINT = 1635005744;
    }

    /***********External**************/

    /**
     * @notice claiming honey by owning a bear
     */
    function claimBearsHoney(uint16[] calldata _bearsIds) external nonReentrant {
        require(STARTING_POINT < block.timestamp, "Rewards didn't start");

        require(paused.pauseBears == 0, "Paused");

        uint256 amount;
        for (uint16 i = 0; i < _bearsIds.length; i++) {
            uint16 id = _bearsIds[i];

            //if not owner of the token then no rewards, usecase when someone tries to get rewards for
            //a token that isn't his or when he tries to get the rewards for an old token
            if (!bears.exists(id)) continue;
            if (bears.ownerOf(id) != msg.sender) continue;

            uint256 epochsToReward;
            uint256 lastReward = lastRewardOfHoneyPerBears[id];
            if (lastReward > 0 && lastReward > STARTING_POINT) {
                // solhint-disable-next-line
                //we get whole numbers for example if someone claims after 1 round and a half, he should be rewarded for 1 round.
                epochsToReward = (block.timestamp - lastReward) / EPOCH_LENGTH;
            } else {
                // if no rewards claimed so far, then he gets rewards from when the rewards started.
                epochsToReward = (block.timestamp - STARTING_POINT) / EPOCH_LENGTH;
            }

            //accumulating honey to mint
            amount += HONEY_BEARS_REWARDS_PER_ROUND * epochsToReward;
            lastRewardOfHoneyPerBears[id] = block.timestamp;
        }
        require(amount > 0, "Nothing to claim");
        amount = amount * 1e16;

        //can not mint more than maxSupply
        if (honey.totalSupply() + amount > honey.maxSupply()) {
            amount = (honey.maxSupply() - honey.totalSupply());
        }

        honey.mint(msg.sender, amount);
        emit HoneyClaimed(msg.sender, amount);
    }

    /**
     * @notice claiming honey by owning a bee, it counts for the bee level.
     */
    // solhint-disable-next-line
    function claimBeesHoney(uint16[] calldata _beesIds) external nonReentrant {
        require(STARTING_POINT < block.timestamp, "Rewards didn't start");

        require(paused.pauseBee == 0, "Paused");

        uint256 amount = 0;

        for (uint16 i = 0; i < _beesIds.length; i++) {
            uint16 id = _beesIds[i];
            if (!bees.exists(id)) continue;

            if (bees.ownerOf(id) != msg.sender) continue;

            Bee storage bee = idsAndBees[id];
            if (bee.id == 0 || bee.active == 0) continue;

            uint256 lastReward = bee.lastRewardTime;
            uint256 epochsToReward = 0;
            uint256 currentAmount = 0;
            uint256 multiplier = 10;
            if (bee.staked == 0) {
                if (bee.lastTimeFed == 0) {
                    bee.lastTimeFed = lastReward;
                }
                uint256 cutoff = lastReward + (bee.epochsLeft * EPOCH_LENGTH);
                if (block.timestamp >= cutoff) {
                    uint256 _e = cutoff - lastReward;

                    epochsToReward = _e / EPOCH_LENGTH;
                    currentAmount = HONEY_UNSTAKED_BEE_REWARDS_PER_EPOCH * epochsToReward;
                    bee.active = 0;
                    bee.epochsLeft = 0;
                    bee.becameInactiveTime = block.timestamp;
                } else {
                    epochsToReward = ((block.timestamp - lastReward) / EPOCH_LENGTH);
                    currentAmount = HONEY_UNSTAKED_BEE_REWARDS_PER_EPOCH * epochsToReward;
                    bee.epochsLeft -= uint16(epochsToReward);
                }

                if (beeLevels[id] > 0) {
                    multiplier = rewardsPerBeeLevel[BEE_LEVEL(beeLevels[id] * 2 - 1)];
                }
            } else if (bee.staked == 1) {
                // solhint-disable-next-line
                //we get whole numbers for example if someone claims after 1 round and a half, he should be rewarded for 1 round.
                currentAmount += HONEY_STAKED_BEE_REWARDS_PER_EPOCH * ((block.timestamp - lastReward) / EPOCH_LENGTH);
                if (beeLevels[id] > 0) multiplier = rewardsPerBeeLevel[BEE_LEVEL(beeLevels[id] * 2)]; //we do not decrease 1 because this is a worker bee and worker bees rewardsPerBeeLevel are 1 higher
            }
            amount += currentAmount * multiplier;

            bee.lastRewardTime = block.timestamp;
        }
        require(amount > 0, "Nothing to claim");
        amount = amount * 1e15;

        //can not mint more than maxSupply
        if (honey.totalSupply() + amount > honey.maxSupply()) {
            amount = (honey.maxSupply() - honey.totalSupply());
        }

        honey.mint(msg.sender, amount);
        emit HoneyClaimed(msg.sender, amount);
    }

    /**
     * @notice mints a Honey Hive by having a bear. You need to be the holder of the bear.
     */
    function mintHive(uint16 _bearsId) external nonReentrant {
        require(paused.pauseHive == 0, "Paused");

        require(msg.sender != address(0), "Can not mint to address 0");

        hive.mint(msg.sender, _bearsId);
        emit HoneyHiveClaimed(msg.sender, _bearsId);
    }

    /**
     * @notice mints a Bee by having a hive. You need to be the holder of the hive.
     */
    function mintBee(uint16 _hiveId) external nonReentrant {
        require(paused.pauseBee == 0, "Paused");

        require(msg.sender != address(0), "Can not mint to address 0");

        require(hive.ownerOf(_hiveId) == msg.sender, "No Hive owned");

        require(honey.balanceOf(msg.sender) >= MIN_BURN_AMOUNT_FOR_CLAIMING_BEE * 1e16, "Not enough Honey");

        require(lastTimeClaimedBeePerHive[_hiveId] < block.timestamp - HIVE_CLAIM_EPOCH_LENGTH, "Mint bee cooldown");

        uint16 beeId = randBeeId();
        require(beeId > 0, "Mint failed");

        lastTimeClaimedBeePerHive[_hiveId] = block.timestamp;
        idsAndBees[beeId] = Bee(beeId, 1, EPOCHS_BEFORE_INACTIVE_BEE, 0, 0, block.timestamp, block.timestamp);
        totalMintedBees++;

        hive.increaseUsageOfMintingBee(_hiveId);

        honey.burn(msg.sender, MIN_BURN_AMOUNT_FOR_CLAIMING_BEE * 1e16);
        bees.mint(msg.sender, beeId);

        emit BeeClaimed(msg.sender, beeId);
    }

    /**
     * @notice after MAX_USAGE_PER_HIVE, a hive becomes inactive so it needs to be activated so we can mint more Bees
     */
    function activateHive(uint16 _hiveId) external nonReentrant {
        require(paused.pauseHive == 0, "Paused");

        require(hive.ownerOf(_hiveId) == msg.sender, "Not your hive");
        require(hive.getUsageOfMintingBee(_hiveId) >= MAX_USAGE_PER_HIVE, "Cap not reached");
        require(honey.balanceOf(msg.sender) >= AMOUNT_FOR_ACTIVATE_HIVE * 1e16, "Not enough Honey");

        honey.burn(msg.sender, AMOUNT_FOR_ACTIVATE_HIVE * 1e16);
        hive.resetUsageOfMintingBee(_hiveId);

        emit HiveActivated(msg.sender, _hiveId);
    }

    /**
     * @notice Exactly like in real world, bees become hungry for honey so,
     * after EPOCHS_BEFORE_INACTIVE_BEE epochs a bee needs
     * to be fed to become active again and start collecting Honey
     * Corresponds with Revive Bees
     */
    function activateBees(uint16[] calldata _beesIds) external nonReentrant {
        require(paused.pauseBee == 0, "Paused");

        uint256 amountOfHoney = 0;
        for (uint16 i = 0; i < _beesIds.length; i++) {
            uint16 _beeId = _beesIds[i];
            Bee storage bee = idsAndBees[_beeId];
            if (bee.id == 0) continue;
            if (bees.ownerOf(_beeId) != msg.sender) continue;

            /**
             * when we activate a bee we do the following:
             * - we set active = 1 (meaning true)
             * - reset epochsLeft to MIN_USAGE_PER_BEE which is the max claiming before it becomes inactive
             * - set reward time as now so in case bee is staked, to not claim before this
             *   because on staking, we ignore the claim counter
             * - we set lastTimeFed for UI
             */
            amountOfHoney += MIN_AMOUNT_FOR_ACTIVATE_BEE;
            bee.active = 1;
            bee.epochsLeft = EPOCHS_BEFORE_INACTIVE_BEE;
            bee.lastRewardTime = block.timestamp;
            bee.lastTimeFed = block.timestamp;
            emit BeeActivated(msg.sender, _beeId);
        }

        require(amountOfHoney > 0, "Nothing to activate");
        amountOfHoney = amountOfHoney * 1e16;

        require(honey.balanceOf(msg.sender) >= amountOfHoney, "Not enough honey");
        honey.burn(msg.sender, amountOfHoney);
    }

    /**
     * @notice If you want your bee to not become inactive and burn more Honey to fed it, you can
     * use this function to keep an Active bee, Active. Once this is called,
     * Honey will be burnt and bee can claim Honey again for EPOCHS_BEFORE_INACTIVE_BEE.
     * Corresponds with Feed Bees
     */
    // solhint-disable-next-line
    function keepBeesActive(uint16[] calldata _beesIds) external nonReentrant {
        require(paused.pauseBee == 0, "Paused");

        uint256 amountOfHoney = 0;
        for (uint16 i = 0; i < _beesIds.length; i++) {
            uint16 _beeId = _beesIds[i];
            Bee storage bee = idsAndBees[_beeId];
            if (bee.id == 0) continue;
            if (bees.ownerOf(_beeId) != msg.sender) continue;
            if (bee.staked == 1) continue;

            //this bee can not be kept active as it is inactive already, need to burn 7 honey
            if (bee.active == 0) continue;
            uint256 epochsLeft = bee.epochsLeft;

            // only add rewards if user has fed bee within time limit
            if (block.timestamp > bee.lastRewardTime + (epochsLeft * EPOCH_LENGTH)) continue;

            // amount increases depending on how "in advance" msg.sender wants to keep his bee active
            amountOfHoney += AMOUNT_TO_KEEP_ACTIVE;

            epochsLeft += EPOCHS_BEFORE_INACTIVE_BEE;

            if (epochsLeft == EPOCHS_BEFORE_INACTIVE_BEE) {
                bee.lastTimeFed = block.timestamp;
            }
            bee.epochsLeft = uint16(epochsLeft);

            emit BeeKeptActive(msg.sender, _beeId);
        }

        require(amountOfHoney > 0, "Nothing to keep active");
        amountOfHoney = amountOfHoney * 1e16;

        require(honey.balanceOf(msg.sender) >= amountOfHoney, "Not enough honey");
        honey.burn(msg.sender, amountOfHoney);
    }

    /**
     * @notice In case you got bored of one of your Bee, or it got too old, you can burn it and receive Honey
     */
    function burnBees(uint16[] calldata _beesIds) external nonReentrant {
        require(paused.pauseBee == 0, "Paused");

        uint256 amountOfHoney = 0;
        for (uint16 i = 0; i < _beesIds.length; i++) {
            uint16 _beeId = _beesIds[i];

            //in case a bee is burnt from BeesDeluxe contract, should neved happen.
            if (bees.ownerOf(_beeId) == address(0)) {
                delete idsAndBees[_beeId];
                return;
            }
            if (bees.ownerOf(_beeId) != msg.sender) continue;
            delete idsAndBees[_beeId];
            amountOfHoney += REWARD_FOR_BURNING_BEE;
            bees.burnByQueen(_beeId);
            emit BeeBurnt(msg.sender, _beeId);
        }
        amountOfHoney = amountOfHoney * 1e16;

        require(amountOfHoney > 0, "Nothing to burn");
        require(honey.totalSupply() + amountOfHoney <= honey.maxSupply(), "Honey cap reached");

        honey.mint(msg.sender, amountOfHoney);
    }

    /**
     * @notice In case you are a long term player, you can stake your Bee to avoid the bee being inactivated.
     * Of course this comes with a downside, the amount of Honey you can claim, shrinks
     * Corresponds with Put Bees to Work
     */
    function stakeBees(uint16[] calldata _beesIds) external nonReentrant {
        require(paused.pauseBee == 0, "Paused");

        uint256 amountOfHoney = 0;
        for (uint16 i = 0; i < _beesIds.length; i++) {
            uint16 _beeId = _beesIds[i];
            Bee storage bee = idsAndBees[_beeId];
            if (bee.id == 0) continue;
            if (bee.active == 0) continue;
            if (bee.staked == 1) continue;
            if (bees.ownerOf(_beeId) != msg.sender) continue;

            uint256 cutoff = bee.lastRewardTime + (bee.epochsLeft * EPOCH_LENGTH);
            if (block.timestamp >= cutoff) continue;

            amountOfHoney += BURN_AMOUNT_FOR_STAKING_BEE;
            bee.staked = 1;
            emit BeeStaked(msg.sender, _beeId);
        }

        require(amountOfHoney > 0, "Nothing to stake");
        amountOfHoney = amountOfHoney * 1e16;

        require(honey.balanceOf(msg.sender) >= amountOfHoney, "Not enough honey");
        if (amountOfHoney > 0) honey.burn(msg.sender, amountOfHoney);
    }

    /**
     * @notice You got enough of your staked bee, you can unstake it to get back to the normal rewards but also
     * with the possibility to get inactivated
     * Corresponds with Stop Work
     */
    function unstakeBees(uint16[] calldata _beesIds) external nonReentrant {
        require(paused.pauseBee == 0, "Paused");

        for (uint16 i = 0; i < _beesIds.length; i++) {
            uint16 _beeId = _beesIds[i];
            Bee storage bee = idsAndBees[_beeId];
            if (bee.id == 0) continue;
            if (bee.staked == 0) continue;
            if (bees.ownerOf(_beeId) != msg.sender) continue;
            bee.staked = 0;
            bee.lastTimeFed = block.timestamp;
            emit BeeUnstaked(msg.sender, _beeId);
        }
    }

    /**
     * @notice levels up a bee by burning combs. the _honeyCombs should be sorted DESC for efficiency. BE AWARE that the index
     * on _honeyCombs must correspond with the index on _quantities
     */
    function levelUpBee(
        uint16 _beeId,
        uint256[] calldata _honeyCombs,
        uint256[] memory _quantities
    ) external nonReentrant {
        require(paused.pauseBee == 0, "Paused");
        require(bees.ownerOf(_beeId) == msg.sender, "You don't own this Bee");
        require(_honeyCombs.length == _quantities.length, "Invalid request");
        uint256 currentLevel = beeLevels[_beeId];

        for (uint256 i; i < _honeyCombs.length; i++) {
            uint256 rarity = _honeyCombs[i];

            if (honeyCombs.balanceOf(msg.sender, rarity) < _quantities[i] || currentLevel >= MAX_BEE_LEVEL) continue;
            currentLevel = (rarity + 1) * _quantities[i] + currentLevel;

            //if leveling up quantity does not go beyond max level
            if (currentLevel >= MAX_BEE_LEVEL) {
                // removing the extra quantities in case someone sends like more than it should
                _quantities[i] = _quantities[i] - (currentLevel - MAX_BEE_LEVEL) / (rarity + 1);
                // if quantity goes beyond level up, we just level up to MAX_BEE_LEVEL
                currentLevel = MAX_BEE_LEVEL;
            }

            honeyCombs.burn(msg.sender, rarity, _quantities[i]);
        }
        require(currentLevel <= MAX_BEE_LEVEL, "Leveling up failed");
        beeLevels[_beeId] = uint8(currentLevel);
        emit BeeLeveledUp(_beeId, currentLevel);
    }

    /***********Internal**************/

    // solhint-disable-next-line
    function randBeeId() internal returns (uint16 _id) {
        uint16 entropy;
        uint16 maxSupply = uint16(bees.getMaxSupply());
        require(totalMintedBees < maxSupply, "MAX_SUPPLY reached");
        while (true) {
            uint16 rand = uint16(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            msg.sender,
                            block.difficulty,
                            block.timestamp,
                            block.number,
                            totalMintedBees,
                            entropy
                        )
                    )
                )
            );
            _id = rand % maxSupply;
            entropy++;
            if (_id == 0) _id = maxSupply;

            if (idsAndBees[_id].id == 0) {
                if (_id < lowestBeeId) lowestBeeId = _id;
                return _id;
            }
            if (entropy > 2) {
                bool wentOverOnce;
                while (idsAndBees[lowestBeeId].id > 0) {
                    lowestBeeId++;
                    if (lowestBeeId == maxSupply) {
                        if (wentOverOnce) return 0;
                        wentOverOnce = true;
                        lowestBeeId = 1;
                    }
                }
                _id = lowestBeeId;
                return _id;
            }
        }
    }

    /***********Views**************/
    /**
     * @notice Get a time when the Bear was last rewarded with honey
     */
    function getLastRewardedByBear(uint16 _bearId) external view returns (uint256) {
        return lastRewardOfHoneyPerBears[_bearId];
    }

    /**
     * @notice Get a time when the Bee was last rewarded with honey
     */
    function getLastRewardedByBee(uint16 _beeId) external view returns (uint256) {
        return idsAndBees[_beeId].lastRewardTime;
    }

    /**
     * @notice Get the whole state of the bee
     */
    function getBeeState(uint16 _beeId) external view returns (Bee memory) {
        return idsAndBees[_beeId];
    }

    /**
     * @notice Get last time you claimed a bee
     */
    function getLastTimeBeeClaimed(uint16 _hiveId) external view returns (uint256) {
        return lastTimeClaimedBeePerHive[_hiveId];
    }

    /**
     * @notice Get states of multiple Bees
     */
    function getBeesState(uint16[] calldata _beesIds) external view returns (Bee[] memory beesToReturn) {
        beesToReturn = new Bee[](_beesIds.length);
        for (uint16 i = 0; i < _beesIds.length; i++) {
            beesToReturn[i] = idsAndBees[_beesIds[i]];
        }
        return beesToReturn;
    }

    /**
     * @notice Get total unclaimed Honey for a holder
     */
    function getUnclaimedHoneyForBears(address _owner) external view returns (uint256 amount) {
        uint256[] memory bearsIds = bears.tokensOfOwner(_owner);
        for (uint16 i = 0; i < bearsIds.length; i++) {
            uint16 id = uint16(bearsIds[i]);

            //if not owner of the token then no rewards, usecase when someone tries to get rewards for
            //a token that isn't his or when he tries to get the rewards for an old token
            if (!bears.exists(id)) continue;
            if (bears.ownerOf(id) != _owner) continue;

            uint256 epochsToReward;
            uint256 lastReward = lastRewardOfHoneyPerBears[id];
            if (lastReward > 0 && lastReward > STARTING_POINT) {
                // solhint-disable-next-line
                //we get whole numbers for example if someone claims after 1 round and a half, he should be rewarded for 1 round.
                epochsToReward = (block.timestamp - lastReward) / EPOCH_LENGTH;
            } else {
                if (block.timestamp < STARTING_POINT)
                    //if the starting point it's in the future then return 0
                    epochsToReward = 0;
                    // if no rewards claimed so far, then he gets rewards from when the rewards started.
                else epochsToReward = (block.timestamp - STARTING_POINT) / EPOCH_LENGTH;
            }

            //accumulating honey to mint
            amount += HONEY_BEARS_REWARDS_PER_ROUND * epochsToReward;
        }
        amount = amount * 1e16;
    }

    /**
     * @notice Get total unclaimed Honey for a holder
     */
    // solhint-disable-next-line
    function getUnclaimedHoneyForBees(address _owner) external view returns (uint256 amount) {
        uint256[] memory beesIds = bees.tokensOfOwner(_owner);
        for (uint16 i = 0; i < beesIds.length; i++) {
            uint16 id = uint16(beesIds[i]);

            if (!bees.exists(id)) continue;
            if (bees.ownerOf(id) != _owner) continue;
            Bee storage bee = idsAndBees[id];

            if (bee.id == 0 || bee.active == 0) continue;

            uint256 lastReward = bee.lastRewardTime;
            uint256 epochsToReward = 0;
            uint256 currentAmount = 0;
            uint256 multiplier = 10;
            if (bee.staked == 0) {
                uint256 cutoff = lastReward + (bee.epochsLeft * EPOCH_LENGTH);
                if (block.timestamp >= cutoff) {
                    uint256 _e = cutoff - lastReward;

                    epochsToReward = _e / EPOCH_LENGTH;
                    currentAmount = HONEY_UNSTAKED_BEE_REWARDS_PER_EPOCH * epochsToReward;
                } else {
                    epochsToReward = ((block.timestamp - lastReward) / EPOCH_LENGTH);
                    currentAmount = HONEY_UNSTAKED_BEE_REWARDS_PER_EPOCH * epochsToReward;
                }
                if (beeLevels[id] > 0) multiplier = rewardsPerBeeLevel[BEE_LEVEL(beeLevels[id] * 2 - 1)];
            } else if (bee.staked == 1) {
                // solhint-disable-next-line
                //we get whole numbers for example if someone claims after 1 round and a half, he should be rewarded for 1 round.
                currentAmount += HONEY_STAKED_BEE_REWARDS_PER_EPOCH * ((block.timestamp - lastReward) / EPOCH_LENGTH);
                if (beeLevels[id] > 0) multiplier = rewardsPerBeeLevel[BEE_LEVEL(beeLevels[id] * 2)]; //we do not decrease 1 because this is a worker bee and worker bees rewardsPerBeeLevel are 1 higher
            }
            amount += currentAmount * multiplier;
        }
        amount = amount * 1e15;
    }

    /**
     * @notice Checking if a bee is able to be staked, meaning that if the epochsLeft is less than block.timestamp
     * then you have to claim first then call the activateBee then stake
     */
    function isBeePossibleToStake(uint16 _beeId) external view returns (bool) {
        Bee storage bee = idsAndBees[_beeId];
        return block.timestamp >= bee.lastRewardTime + (bee.epochsLeft * EPOCH_LENGTH);
    }

    /**
     * @notice migrate bears from old contract
     */
    function migrateBear(
        uint256 _oldId,
        uint16 _newId,
        bytes32 _leaf,
        bytes32[] calldata _merkleProof
    ) external nonReentrant {
        //construct merkle node
        bytes32 node = keccak256(abi.encodePacked(_oldId, _newId));

        require(node == _leaf, "Leaf not matching the node");
        require(MerkleProof.verify(_merkleProof, merkleRoot, _leaf), "Invalid proof.");
        require(osContract.balanceOf(msg.sender, _oldId) == 1, "Not owner of OS id");
        require(!bears.exists(_newId), "Token already minted");

        bears.mint(msg.sender, _newId);
    }

    /***********Settes & Getters**************/

    function setBears(address _contract) external onlyOwner {
        require(_contract != address(0), "Can not be address 0");
        bears = BearsDeluxeI(_contract);
        emit SetContract("BearsDeluxe", _contract);
    }

    function setHoney(address _contract) external onlyOwner {
        require(_contract != address(0), "Can not be address 0");
        honey = HoneyTokenI(_contract);
        emit SetContract("HoneyToken", _contract);
    }

    function setHive(address _contract) external onlyOwner {
        require(_contract != address(0), "Can not be address 0");
        hive = HoneyHiveDeluxeI(_contract);
        emit SetContract("HoneyHive", _contract);
    }

    function setBees(address _contract) external onlyOwner {
        require(_contract != address(0), "Can not be address 0");
        bees = BeesDeluxeI(_contract);
        emit SetContract("BeesDeluxe", _contract);
    }

    function setHoneyCombs(address _contract) external onlyOwner {
        require(_contract != address(0), "Can not be address 0");
        honeyCombs = HoneyCombsDeluxeI(_contract);
        emit SetContract("HoneyCombsDeluxe", _contract);
    }

    function setInitialStartingPoint(uint256 _startingPoint) external onlyOwner {
        STARTING_POINT = _startingPoint;
        emit StartingPointChanged(_startingPoint);
    }

    function getInitialStartingPoint() external view returns (uint256) {
        return STARTING_POINT;
    }

    function setHoneyEpochLength(uint256 _epochLength) external onlyOwner {
        EPOCH_LENGTH = _epochLength;
        emit EpochChange("HoneyEpochLength", _epochLength);
    }

    function setHiveClaimEpochLength(uint256 _epochLength) external onlyOwner {
        HIVE_CLAIM_EPOCH_LENGTH = _epochLength;
        emit EpochChange("HiveEpochLength", _epochLength);
    }

    function setNoOfEpochsBeforeInactiveBee(uint16 _epochs) external onlyOwner {
        EPOCHS_BEFORE_INACTIVE_BEE = _epochs;
        emit EpochChange("NoOfEpochBeforeInactiveBee", _epochs);
    }

    function setOSContract(address _contract) external onlyOwner {
        require(_contract != address(0), "Can not be address 0");
        osContract = IERC1155(_contract);
        emit SetContract("Opensea", _contract);
    }

    function initLevelUpBees() external onlyOwner {
        MAX_BEE_LEVEL = 5;
        rewardsPerBeeLevel[BEE_LEVEL.NONE] = 10;

        rewardsPerBeeLevel[BEE_LEVEL.COMMON_ACTIVE] = 14;
        rewardsPerBeeLevel[BEE_LEVEL.COMMON_WORKER] = 16;

        rewardsPerBeeLevel[BEE_LEVEL.UNCOMMON_ACTIVE] = 20;
        rewardsPerBeeLevel[BEE_LEVEL.UNCOMMON_WORKER] = 24;

        rewardsPerBeeLevel[BEE_LEVEL.RARE_ACTIVE] = 24;
        rewardsPerBeeLevel[BEE_LEVEL.RARE_WORKER] = 30;

        rewardsPerBeeLevel[BEE_LEVEL.EPIC_ACTIVE] = 31;
        rewardsPerBeeLevel[BEE_LEVEL.EPIC_WORKER] = 40;

        rewardsPerBeeLevel[BEE_LEVEL.LEGENDARY_ACTIVE] = 39;
        rewardsPerBeeLevel[BEE_LEVEL.LEGENDARY_WORKER] = 52;
    }

    /**
     * @dev sets  merkle root, should be called only once
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /**
     * @notice Sets the activitiy of the Bears/Bee/Hive as paused or not, only use in case of emergency.
     * 1 = Paused
     * 0 = Active
     */
    function setPauseState(
        uint8 _pauseBears,
        uint8 _pauseHives,
        uint8 _pauseBees
    ) external onlyOwner {
        paused.pauseBears = _pauseBears;
        paused.pauseHive = _pauseHives;
        paused.pauseBee = _pauseBees;
        emit PauseChanged(_pauseBears, _pauseHives, _pauseBees);
    }
}
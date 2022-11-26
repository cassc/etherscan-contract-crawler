// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./MetarunCollection.sol";
import "./MetarunToken.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract MetarunStaking is AccessControlUpgradeable {
    // user deposits are recorded in StakeInfo[] stakes struct
    struct StakeInfo {
        // staked is true if deposit is staked and hasn't been unstaked.
        // After user claims his stake back, `staked` becomes false
        bool staked;
        // stakedAmount get recorded at the stake time and doesn't change.
        uint256 stakedAmount;
        uint256 startTime;
        // endTime and totalYield get calculated in advance at the moment of staking
        // endTime is the date when unstaking becomes possible (without penalties)
        uint256 endTime;
        // totalYield is a total value of rewards for the given stake.
        // Gets calculated on the stake start and doesnt' change
        // but the amount that user is able to withdraw gets gradually unlocked over time.
        uint256 totalYield;
        // The amount of yield user already harvested and the time of last harvest call.
        uint256 harvestedYield;
        uint256 lastHarvestTime;
        // amount of reward characters
        uint256 charactersAmount;
    }

    // ratios of characters rarity in basis points (1/10000)
    struct RarityRatios {
        uint256 common;
        uint256 rare;
        uint256 mythical;
    }

    // If stakesOpen == true, the contract is operational and accepts new stakes.
    // Otherwise it allows just harvesting and unstaking.
    bool public stakesOpen;

    // The token accepted for staking and used for rewards (The same token for both).
    MetarunToken public token;

    // The NFT Collection used for rewards.
    MetarunCollection public nftCollection;

    RarityRatios public rarityRatios;

    // struccture that stores the records of users' stakes
    mapping(address => StakeInfo[]) public stakes;

    // the total number of staked tokens. Accounted separately to avoid mixing stake and reward balances
    uint256 public stakedTokens;

    // The staking interval in days.
    // Early unstaking is possible but a fine is withheld.
    uint256 public stakeDuration;

    // Fee for early unstake in basis points (1/10000)
    // If the user withdraws before stake expiration, he pays `earlyUnstakeFee`
    uint256 public earlyUnstakeFee;

    // Reward that staker will receive for his stake
    // nominated in basis points (1/10000) of staked amount
    uint256 public yieldRate;

    // Number of mrun tokens required to reward one nft
    uint256 public mrunPerCharacter;

    // Character kind identifier
    uint256 public characterKind;

    mapping(uint256 => uint256) public currentCharacterIds;

    event Stake(address indexed user, uint256 indexed stakeId, uint256 amount, uint256 startTime, uint256 endTime);

    event Unstake(address indexed user, uint256 indexed stakeId, uint256 amount, uint256 startTime, uint256 endTime, bool early);

    event Harvest(address indexed user, uint256 indexed stakeId, uint256 amount, uint256 harvestTime);

    /**
     * @dev the constructor arguments:
     * @param _token address of token - the same accepted for staking and used to pay rewards
     * @param _stakeDuration the stake duration in seconds
     * @param _yieldRate reward rate in basis points (1/10000)
     * @param _earlyUnstakeFee fee for unstaking before stake expiration
     * @param _nftCollection ERC1155 token of NFT collection
     */
    function initialize(
        address _token,
        uint256 _stakeDuration,
        uint256 _yieldRate,
        uint256 _earlyUnstakeFee,
        address _nftCollection,
        uint256 _characterKind
    ) public initializer {
        __AccessControl_init();
        require(_token != address(0), "Empty token address");
        require(_yieldRate > 0, "Zero yield rate");
        require(_earlyUnstakeFee > 0, "Zero early Unstake Fee");
        token = MetarunToken(_token);
        stakeDuration = _stakeDuration;
        yieldRate = _yieldRate;
        earlyUnstakeFee = _earlyUnstakeFee;
        characterKind = _characterKind;
        nftCollection = MetarunCollection(_nftCollection);
        rarityRatios.common = 3334;
        rarityRatios.rare = 3333;
        rarityRatios.mythical = 3333;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev start accepting new stakes. Called only by the owner
     */
    function start() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "You should have DEFAULT_ADMIN_ROLE");
        require(!stakesOpen, "Stakes are open already");
        stakesOpen = true;
    }

    /**
     * @dev stop accepting new stakes. Called only by the owner
     */
    function stop() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "You should have DEFAULT_ADMIN_ROLE");
        require(stakesOpen, "Stakes are stopped already");
        stakesOpen = false;
    }

    function setCurrentCharacterId(uint256 kind, uint256 currentId) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "You should have DEFAULT_ADMIN_ROLE");
        currentCharacterIds[kind] = currentId;
    }

    function setMrunPerCharacter(uint256 _amount) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "You should have DEFAULT_ADMIN_ROLE");
        mrunPerCharacter = _amount;
    }

    function setEarlyUnstakeFee(uint256 _amount) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "You should have DEFAULT_ADMIN_ROLE");
        earlyUnstakeFee = _amount;
    }

    function setYieldRate(uint256 _amount) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "You should have DEFAULT_ADMIN_ROLE");
        yieldRate = _amount;
    }

    function setRarityRatios(
        uint256 _common,
        uint256 _rare,
        uint256 _mythical
    ) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "You should have DEFAULT_ADMIN_ROLE");
        rarityRatios.common = _common;
        rarityRatios.rare = _rare;
        rarityRatios.mythical = _mythical;
    }

    /**
     * @dev submit the stake
     * @param _amount   amount of tokens to be transferred from user's account
     */
    function stake(uint256 _amount) external {
        require(stakesOpen, "stake: not open");
        require(_amount > 0, "stake: zero amount");
        uint256 charactersAmount = 0;
        if (mrunPerCharacter > 0) {
            charactersAmount = _amount / mrunPerCharacter;
        }
        require(charactersAmount <= 100, "stake: reward characters can't be greater than 100");

        // entire reward allocated for the user for this stake
        uint256 totalYield = (_amount * yieldRate) / 10000;
        uint256 startTime = _now();
        uint256 endTime = _now() + stakeDuration;
        stakes[msg.sender].push(
            StakeInfo({
                staked: true,
                stakedAmount: _amount,
                startTime: startTime,
                endTime: endTime,
                totalYield: totalYield,
                harvestedYield: 0,
                lastHarvestTime: startTime,
                charactersAmount: charactersAmount
            })
        );
        stakedTokens = stakedTokens + _amount;
        uint256 stakeId = getStakesLength(msg.sender) - 1;
        emit Stake(msg.sender, stakeId, _amount, startTime, endTime);

        token.transferFrom(msg.sender, address(this), _amount);
        if (charactersAmount > 0) {
            for (uint256 i = 0; i < charactersAmount; i++) {
                nftCollection.mint(msg.sender, _getRandomCharacter(), 1);
            }
        }
    }

    /**
     * @dev withdraw the `body` of user's stake. Can be called only once
     * @param _stakeId   Id of the stake
     */
    function unstake(uint256 _stakeId) external {
        (
            bool staked,
            uint256 stakedAmount,
            uint256 startTime,
            uint256 endTime,
            ,
            uint256 harvestedYield,
            ,
            uint256 harvestableYield,
            uint256 charactersAmount
        ) = getStake(msg.sender, _stakeId);
        bool early;
        require(staked, "Unstaked already");
        if (_now() > endTime) {
            stakes[msg.sender][_stakeId].staked = false;
            stakedTokens = stakedTokens - stakedAmount;
            early = false;
            token.transfer(msg.sender, stakedAmount);
        } else {
            uint256 fee;
            uint256 amountToTransfer;
            uint256 newTotalYield = harvestedYield + harvestableYield;
            stakes[msg.sender][_stakeId].staked = false;
            stakes[msg.sender][_stakeId].endTime = _now();
            stakes[msg.sender][_stakeId].totalYield = newTotalYield;
            stakedTokens = stakedTokens - stakedAmount;
            early = true;

            if (charactersAmount > 0) {
                fee = (stakedAmount * earlyUnstakeFee) / 10000;
                amountToTransfer = stakedAmount - fee;
            } else {
                fee = (stakedAmount * (earlyUnstakeFee/4)) / 10000;
                amountToTransfer = stakedAmount - fee;
            }

            token.transfer(msg.sender, amountToTransfer);
            token.burn(fee);
        }

        emit Unstake(msg.sender, _stakeId, stakedAmount, startTime, endTime, early);
    }

    /**
     * @dev harvest accumulated rewards. Can be called many times.
     * @param _stakeId   Id of the stake
     */
    function harvest(uint256 _stakeId) external {
        (, , , , , uint256 harvestedYield, , uint256 harvestableYield, ) = getStake(msg.sender, _stakeId);
        require(harvestableYield != 0, "harvestableYield is zero");
        stakes[msg.sender][_stakeId].harvestedYield = harvestedYield + harvestableYield;
        stakes[msg.sender][_stakeId].lastHarvestTime = _now();
        emit Harvest(msg.sender, _stakeId, harvestableYield, _now());
        token.mint(msg.sender, harvestableYield);
    }

    /**
     * @dev get the count of user's stakes. Used on frontend to iterate and display individual stakes
     * @param _userAddress account of staker
     * @return stakes
     */
    function getStakesLength(address _userAddress) public view returns (uint256) {
        return stakes[_userAddress].length;
    }

    /**
     * @dev get the individual stake parameters of the user
     * @param _userAddress account of staker
     * @param _stakeId stake index
     * @return staked the status of stake
     * @return stakedAmount the number of deposited tokens
     * @return startTime the moment of stake start
     * @return endTime the time when unstaking (w.o. penalties) becomes possible
     * @return totalYield entire yield for the stake (totally released on endTime)
     * @return harvestedYield The part of yield user harvested already
     * @return lastHarvestTime The time of last harvest event
     * @return harvestableYield The unlocked part of yield available for harvesting
     * @return charactersAmount Reward nft character type tokens
    
     */
    function getStake(address _userAddress, uint256 _stakeId)
        public
        view
        returns (
            bool staked,
            uint256 stakedAmount,
            uint256 startTime,
            uint256 endTime,
            uint256 totalYield, // Entire yield for the stake (totally released on endTime)
            uint256 harvestedYield, // The part of yield user harvested already
            uint256 lastHarvestTime, // The time of last harvest event
            uint256 harvestableYield, // The unlocked part of yield available for harvesting
            uint256 charactersAmount // Reward token's amount of character
        )
    {
        StakeInfo memory _stake = stakes[_userAddress][_stakeId];
        staked = _stake.staked;
        stakedAmount = _stake.stakedAmount;
        startTime = _stake.startTime;
        endTime = _stake.endTime;
        totalYield = _stake.totalYield;
        harvestedYield = _stake.harvestedYield;
        lastHarvestTime = _stake.lastHarvestTime;
        charactersAmount = _stake.charactersAmount;
        if (_now() > endTime) {
            harvestableYield = totalYield - harvestedYield;
        } else {
            harvestableYield = (totalYield * (_now() - lastHarvestTime)) / (endTime - startTime);
        }
    }

    // Returns block.timestamp, overridable for test purposes.
    function _now() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    function _getRandomCharacter() internal returns (uint256) {
        uint256 randomInt = uint256(keccak256(abi.encodePacked(block.timestamp, gasleft(), blockhash(block.number - 1))));
        uint256 randomRarityInt = randomInt % 10000;

        uint256 randomRarity;
        if (randomRarityInt < rarityRatios.common) {
            randomRarity = 0;
        } else if (randomRarityInt < rarityRatios.common + rarityRatios.rare) {
            randomRarity = 1;
        } else {
            randomRarity = 2;
        }

        uint256 randomCharacter = (randomInt << 16) % 3;

        uint256 characterCurrentKind = characterKind | randomRarity;
        uint256 currentCharacter;

        if (randomCharacter == 0) {
            currentCharacter = 0x0001;
        } else if (randomCharacter == 1) {
            currentCharacter = 0x0002;
        } else {
            currentCharacter = 0x0003;
        }
        uint256 kind = ((currentCharacter << 16) | (characterCurrentKind));
        uint256 characterId = (kind << 16) | currentCharacterIds[kind];

        while (nftCollection.exists(characterId)) {
            characterId += 1;
            currentCharacterIds[kind] += 1;
        }
        currentCharacterIds[kind] += 1;
        return characterId;
    }
}
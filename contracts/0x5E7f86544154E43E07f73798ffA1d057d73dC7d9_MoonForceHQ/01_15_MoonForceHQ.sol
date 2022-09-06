// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./interfaces/INFT.sol";
import "./interfaces/ITOPIA.sol";
import "./interfaces/IHub.sol";
import "./interfaces/IMoonForceHQ.sol";
import "./interfaces/IRandomizer.sol";

contract MoonForceHQ is IMoonForceHQ, Ownable, ReentrancyGuard, IERC721Receiver, Pausable {
    using EnumerableSet for EnumerableSet.UintSet;

    // struct to store a stake's token, owner, and earning values
    struct Stake {
        uint16 tokenId;
        uint80 value;
        address owner;
        uint80 stakedAt;
    }

    // struct to store a stake's token, owner, and earning values
    struct StakeAlpha {
        uint16 tokenId;
        uint80 value;
        address owner;
        uint80 stakedAt;
    }

    mapping(uint16 => uint8) public weaponType;

    mapping(uint16 => uint8) public genesisType;

    // number of Cadets staked
    uint256 private numCadetsStaked;
    // number of Alien staked
    uint256 private numAlienStaked;
    // number of General staked
    uint256 private numGeneralStaked;
    // number of Alpha staked
    uint256 private numAlphasStaked;

    uint256 public PERIOD = 1 days;

    event TokenStaked(address indexed owner, uint256 indexed tokenId, uint8 tokenType, uint256 value);
    event CadetClaimed(uint256 indexed tokenId, bool indexed unstaked, uint256 earned);
    event CadetUnStaked(address indexed owner, uint256 indexed tokenId, uint256 blockNum, uint256 timeStamp);
    event CadetStolen(uint16 indexed tokenId, address indexed victim, address indexed thief, uint256 blockNum, uint256 timeStamp);
    event AlienClaimed(uint256 indexed tokenId, bool indexed unstaked, uint256 earned);
    event AlienUnStaked(address indexed owner, uint256 indexed tokenId, uint256 blockNum, uint256 timeStamp);
    event AlienStolen(uint16 indexed tokenId, address indexed victim, address indexed thief, uint256 blockNum, uint256 timeStamp);
    event GeneralClaimed(uint256 indexed tokenId, bool indexed unstaked, uint256 earned);
    event GeneralUnStaked(address indexed owner, uint256 indexed tokenId, uint256 blockNum, uint256 timeStamp);
    event WeaponChanged(address indexed owner, uint256 tokenId, uint8 upgrade);
    event AlphaStaked(address indexed owner, uint256 indexed tokenId, uint256 value);
    event AlphaClaimed(uint256 indexed tokenId, bool indexed unstaked, uint256 earned);
    event AlphaUnstaked(address indexed owner, uint256 indexed tokenId, uint256 blockNum, uint256 timeStamp);

    // reference to the NFT contract
    INFT public lfGenesis;

    INFT public lfAlpha;

    // reference to the $TOPIA contract for minting $TOPIA earnings
    ITOPIA public TOPIAToken;

    IHub public HUB;

    // reference to Randomizer
    IRandomizer public randomizer;
    address payable vrf;

    // maps Cadet tokenId to stake
    mapping(uint256 => Stake) private cadet;

    // maps Alpha tokenId to stakeAlpha
    mapping(uint256 => StakeAlpha) private alpha;

    // maps Alien tokenId to stake
    mapping(uint256 => Stake) private alien;
    // array of Alien token ids;
    // uint256[] private yieldIds;
    EnumerableSet.UintSet private alienIds;
    // maps General tokenId to stake
    mapping(uint256 => Stake) private general;
    // array of General token ids;
    EnumerableSet.UintSet private generalIds;

    mapping(address => uint256) ownerBalanceStaked;

    // array of Owned Genesis token ids;
    mapping(address => EnumerableSet.UintSet) genesisOwnedIds;
    // array of Owned Alpha token ids;
    mapping(address => EnumerableSet.UintSet) alphaOwnedIds;


    // any rewards distributed when no Aliens are staked
    uint256 private unaccountedAlienRewards;
    // amount of $TOPIA due for each alien staked
    uint256 private TOPIAPerAlien;
    // any rewards distributed when no Generals are staked
    uint256 private unaccountedGeneralRewards;
    // amount of $TOPIA due for each General staked
    uint256 private TOPIAPerGeneral;

    // Cadets earn 20 $TOPIA per day
    uint256 public DAILY_CADET_RATE = 20 * 10**18;

    // Cadets earn 35 $TOPIA per day
    uint256 public DAILY_ALPHA_RATE = 35 * 10**18;

    // Cadets must have 2 days worth of $TOPIA to un-stake or else they're still remaining the armory
    uint256 public MINIMUM = 40 * 10**18;

    // rolling price
    uint256 public UPGRADE_COST = 40 * 10**18;

    // Generals take a 3% tax on all $TOPIA claimed
    uint256 public GENERAL_TAX_RATE_1 = 300;

    // Generals take a 3% tax on all $TOPIA from upgrades
    uint256 public GENERAL_TAX_RATE_2 = 300;

    // tx cost for getting random numbers
    uint256 public SEED_COST = .0008 ether;

    // amount of $TOPIA earned so far
    uint256 public totalTOPIAEarned;
    // the last time $TOPIA can be earned
    uint80 public claimEndTime;

    // emergency rescue to allow un-staking without any checks but without $TOPIA
    bool public rescueEnabled = false;

    /**
     */
    constructor() {
        _pause();
    }

    /** CRITICAL TO SETUP */

    modifier requireContractsSet() {
        require(address(lfGenesis) != address(0) && address(TOPIAToken) != address(0)
        && address(randomizer) != address(0) && address(HUB) != address(0), "Contracts not set");
        _;
    }

    function setContracts(address _lfGenesis, address _lfAlpha, address _TOPIA, address _HUB, address payable _rand) external onlyOwner {
        lfGenesis = INFT(_lfGenesis);
        lfAlpha = INFT(_lfAlpha);
        TOPIAToken = ITOPIA(_TOPIA);
        randomizer = IRandomizer(_rand);
        HUB = IHub(_HUB);
        vrf = _rand;
    }

    // mass update the nftType mapping
    function setBatchNFTType(uint16[] calldata tokenIds, uint8[] calldata _types) external onlyOwner {
        require(tokenIds.length == _types.length , " _idNumbers.length != _types.length: Each token ID must have exactly 1 corresponding type!");
        for (uint16 i = 0; i < tokenIds.length; i++) {
            require(_types[i] != 0 , "Invalid nft type - cannot be 0");
            genesisType[tokenIds[i]] = _types[i];
        }
    }


    /** STAKING */

    /**
     * adds Aliens and Cadet
     * @param account the address of the staker
   * @param tokenIds the IDs of the Aliens and Cadet to stake
   */
    function addManyToStakingPool(address account, uint16[] calldata tokenIds) external override nonReentrant {
        require(tx.origin == msg.sender, "Only EOA");
        require(account == tx.origin, "account to send mismatch");
        for (uint i = 0; i < tokenIds.length; i++) {
            require(lfGenesis.ownerOf(tokenIds[i]) == msg.sender, "You don't own this token");

            if (genesisType[tokenIds[i]] == 1) {
                lfGenesis.transferFrom(msg.sender, address(this), tokenIds[i]);
                _addCadetToStakingPool(account, tokenIds[i]);
            } else if (genesisType[tokenIds[i]] == 2) {
                lfGenesis.transferFrom(msg.sender, address(this), tokenIds[i]);
                _addAlienToStakingPool(account, tokenIds[i]);
            } else if (genesisType[tokenIds[i]] == 3) {
                lfGenesis.transferFrom(msg.sender, address(this), tokenIds[i]);
                _addGeneralToStakingPool(account, tokenIds[i]);
            } else if (genesisType[tokenIds[i]] == 0) {
                revert("Invalid Token Id");
            }
        }
        HUB.emitGenesisStaked(account, tokenIds, 1);
    }

    /**
     * adds a single Alien to the Armory
     * @param account the address of the staker
   * @param tokenId the ID of the Alien/General to add to the Staking Pool
   */
    function _addAlienToStakingPool(address account, uint256 tokenId) internal whenNotPaused {
        alien[tokenId] = Stake({
        owner : account,
        tokenId : uint16(tokenId),
        value : uint80(TOPIAPerAlien),
        stakedAt : uint80(block.timestamp)
        });
        alienIds.add(tokenId);
        genesisOwnedIds[account].add(tokenId);
        numAlienStaked += 1;
        emit TokenStaked(account, tokenId, 2, TOPIAPerAlien);
    }


    /**
     * adds a single General to the Armory
     * @param account the address of the staker
   * @param tokenId the ID of the Alien/General to add to the Staking Pool
   */
    function _addGeneralToStakingPool(address account, uint256 tokenId) internal whenNotPaused {
        general[tokenId] = Stake({
        owner : account,
        tokenId : uint16(tokenId),
        value : uint80(TOPIAPerGeneral),
        stakedAt : uint80(block.timestamp)
        });
        generalIds.add(tokenId);
        genesisOwnedIds[account].add(tokenId);
        numGeneralStaked += 1;
        emit TokenStaked(account, tokenId, 3, TOPIAPerGeneral);
    }


    /**
     * adds a single Cadet to the armory
     * @param account the address of the staker
   * @param tokenId the ID of the Cadet to add to the Staking Pool
   */
    function _addCadetToStakingPool(address account, uint256 tokenId) internal {
        cadet[tokenId] = Stake({
        owner : account,
        tokenId : uint16(tokenId),
        value : uint80(block.timestamp),
        stakedAt : uint80(block.timestamp)
        });
        // Add the cadet to the armory
        genesisOwnedIds[account].add(tokenId);
        numCadetsStaked += 1;
        emit TokenStaked(account, tokenId, 1, block.timestamp);
    }

    /** CLAIMING / UNSTAKING */

    /**
     * realize $TOPIA earnings and optionally unstake tokens from the Armory / Yield
     * to unstake a Cadet it will require it has 2 days worth of $TOPIA unclaimed
     * @param tokenIds the IDs of the tokens to claim earnings from
   * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
   */
    function claimManyFromArmoryAndYield(uint16[] calldata tokenIds, bool unstake) external payable whenNotPaused nonReentrant returns (uint16[] memory stolenNFTs){
        require(tx.origin == msg.sender, "Only EOA");
        uint256 numWords = tokenIds.length;
        require(msg.value == SEED_COST * numWords, "Invalid value for randomness");
        
        if(unstake) { 
            stolenNFTs = new uint16[](numWords);
            HUB.emitGenesisUnstaked(msg.sender, tokenIds);
        } else {
            stolenNFTs = new uint16[](1);
            stolenNFTs[0] = 0;
        }
        uint256 remainingWords = randomizer.getRemainingWords();
        require(remainingWords >= numWords, "Not enough random numbers. Please try again soon.");
        uint256[] memory seed = randomizer.getRandomWords(numWords);
        uint256 owed = 0;
        for (uint i = 0; i < tokenIds.length; i++) {
            if (genesisType[tokenIds[i]] == 1) {
                (uint256 _owed, uint16 _stolenId) = _claimCadetFromArmory(tokenIds[i], unstake, seed[i]);
                owed += _owed;
                if(unstake) { stolenNFTs[i] = _stolenId; }
            } else if (genesisType[tokenIds[i]] == 2) {
                (uint256 _owed, uint16 _stolenId) = _claimAlienFromYield(tokenIds[i], unstake, seed[i]);
                owed += _owed;
                if(unstake) { stolenNFTs[i] = _stolenId; }
            } else if (genesisType[tokenIds[i]] == 3) {
                owed += _claimGeneralFromYield(tokenIds[i], unstake);
                if(unstake) { stolenNFTs[i] = 0; }
            } else if (genesisType[tokenIds[i]] == 0) {
                revert("Invalid Token Id");
            }
        }
        vrf.transfer(msg.value);
        if (owed == 0) {
            return stolenNFTs;
        }
        totalTOPIAEarned += owed;
        HUB.emitTopiaClaimed(msg.sender, owed);
        TOPIAToken.mint(msg.sender, owed);
    }


    /**
     * realize $TOPIA earnings for a single Cadet and optionally unstake it
     * if not unstaking, lose x% chance * y% percent of accumulated $TOPIA to the staked Aliens based on it's upgrade
     * if unstaking, there is a % chanc of losing Cadet NFT
     * @param tokenId the ID of the Cadet to claim earnings from
   * @param unstake whether or not to unstake the Cadet
   * @return owed - the amount of $TOPIA earned
   */
    function _claimCadetFromArmory(uint16 tokenId, bool unstake, uint256 seed) internal returns (uint256 owed, uint16 stolenId) {       
        require(cadet[tokenId].owner == msg.sender, "Don't own the given token");
        if(block.timestamp <= claimEndTime) {
            owed = (block.timestamp - cadet[tokenId].value) * DAILY_CADET_RATE / PERIOD;
        } else if (cadet[tokenId].value < claimEndTime) {
            owed = (claimEndTime - cadet[tokenId].value) * DAILY_CADET_RATE / PERIOD;
        } else {
            owed = 0;
        }
        uint256 generalTax = owed * GENERAL_TAX_RATE_1 / 10000;
        _payGeneralTax(generalTax);
        owed = owed - generalTax;

        uint256 seedChance = seed >> 16;
        uint8 cadetUpgrade = weaponType[tokenId];
        bool stolen = false;
        stolenId = 0;
        address thief;
        if (unstake) {
            // Chance to lose cadet:
            // Unarmed: 30%
            // Sword: 20%
            // Pistol: 10%
            // Sniper: 5%
            if (cadetUpgrade == 0) {
                if ((seed & 0xFFFF) % 100 < 30) {
                    thief = randomAlienOwner(seed);
                    lfGenesis.safeTransferFrom(address(this), thief, tokenId);
                    stolen = true;
                } else {
                    // lose accumulated tokens 50% chance and 60 percent of all token
                    if ((seedChance & 0xFFFF) % 100 < 50) {
                        _payAlienTax(owed * 60 / 100);
                        owed = owed * 40 / 100;
                    }
                }
            } else if (cadetUpgrade == 1) {
                if ((seed & 0xFFFF) % 100 < 20) {
                    thief = randomAlienOwner(seed);
                    lfGenesis.safeTransferFrom(address(this), thief, tokenId);
                    stolen = true;
                } else {
                    // lose accumulated tokens 80% chance and 25 percent of all token
                    if ((seedChance & 0xFFFF) % 100 < 80) {
                        _payAlienTax(owed * 25 / 100);
                        owed = owed * 75 / 100;
                    }
                }
            } else if (cadetUpgrade == 2) {
                if ((seed & 0xFFFF) % 100 < 10) {
                    thief = randomAlienOwner(seed);
                    lfGenesis.safeTransferFrom(address(this), thief, tokenId);
                    stolen = true;
                } else {
                    // lose accumulated tokens 25% chance and 40 percent of all token
                    if ((seedChance & 0xFFFF) % 100 < 25) {
                        _payAlienTax(owed * 40 / 100);
                        owed = owed * 60 / 100;
                    }
                }
            } else if (cadetUpgrade == 3) {
                if ((seed & 0xFFFF) % 100 < 5) {
                    thief = randomAlienOwner(seed);
                    lfGenesis.safeTransferFrom(address(this), thief, tokenId);
                    stolen = true;
                } else {
                    // lose accumulated tokens 20% chance and 25 percent of all token
                    if ((seedChance & 0xFFFF) % 100 < 20) {
                        _payAlienTax(owed * 25 / 100);
                        owed = owed * 75 / 100;
                    }
                }
            }

            delete cadet[tokenId];
            numCadetsStaked -= 1;
            genesisOwnedIds[msg.sender].remove(tokenId);
            // reset cadet to unarmed
            weaponType[tokenId] = 0;
            if (stolen) {
                stolenId = tokenId;
                emit CadetStolen(tokenId, msg.sender, thief, block.number, block.timestamp);
            } else {
                // Always transfer last to guard against reentrance
                lfGenesis.safeTransferFrom(address(this), msg.sender, tokenId, "");
            }
            emit CadetUnStaked(msg.sender, tokenId, block.number, block.timestamp);
        } else {// Claiming
            if (cadetUpgrade == 0) {
                // lose accumulated tokens 50% chance and 60 percent of all token
                if ((seedChance & 0xFFFF) % 100 < 50) {
                    _payAlienTax(owed * 60 / 100);
                    owed = owed * 40 / 100;
                }
            } else if (cadetUpgrade == 1) {
                // lose accumulated tokens 80% chance and 25 percent of all token
                if ((seedChance & 0xFFFF) % 100 < 80) {
                    _payAlienTax(owed * 25 / 100);
                    owed = owed * 75 / 100;
                }
            } else if (cadetUpgrade == 2) {
                // lose accumulated tokens 25% chance and 40 percent of all token
                if ((seedChance & 0xFFFF) % 100 < 25) {
                    _payAlienTax(owed * 40 / 100);
                    owed = owed * 60 / 100;
                }
            } else if (cadetUpgrade == 3) {
                // lose accumulated tokens 20% chance and 25 percent of all token
                if ((seedChance & 0xFFFF) % 100 < 20) {
                    _payAlienTax(owed * 25 / 100);
                    owed = owed * 75 / 100;
                }
            }
            cadet[tokenId].value = uint80(block.timestamp);
            // reset stake
        }
        emit CadetClaimed(tokenId, unstake, owed);
    }

    /**
     * realize $TOPIA earnings for a single Alien and optionally unstake it
     * Aliens earn $TOPIA
     * @param tokenId the ID of the Alien to claim earnings from
   * @param unstake whether or not to unstake the Alien
   */
    function _claimAlienFromYield(uint16 tokenId, bool unstake, uint256 seed) internal returns (uint256 owed, uint16 stolenId) {
        require(alien[tokenId].owner == msg.sender, "Doesn't own given token");
        owed = TOPIAPerAlien - alien[tokenId].value;
        if (unstake) {
            address thief;
            bool stolen;
            stolenId = 0;
            if ((seed & 0xFFFF) % 100 < 10) {
                thief = randomGeneralOwner(seed);
                lfGenesis.safeTransferFrom(address(this), thief, tokenId);
                stolen = true;
            }

            delete alien[tokenId];
            alienIds.remove(tokenId);
            genesisOwnedIds[msg.sender].remove(tokenId);
            numAlienStaked -= 1;
            // Always remove last to guard against reentrance
            if (!stolen) {
                lfGenesis.safeTransferFrom(address(this), msg.sender, tokenId, "");
            } else {
                stolenId = tokenId;
                emit AlienStolen(tokenId, msg.sender, thief, block.number, block.timestamp);
            }
            emit AlienUnStaked(msg.sender, tokenId, block.number, block.timestamp);
        } else {
            alien[tokenId].value = uint80(TOPIAPerAlien);
            // reset stake

        }
        emit AlienClaimed(tokenId, unstake, owed);
    }

    /**
     * realize $TOPIA earnings for a General Alien and optionally unstake it
     * Aliens earn $TOPIA
     * @param tokenId the ID of the Alien to claim earnings from
   * @param unstake whether or not to unstake the General Alien
   */
    function _claimGeneralFromYield(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
        require(general[tokenId].owner == msg.sender, "Doesn't own given token");
        owed = TOPIAPerGeneral - general[tokenId].value;
        if (unstake) {
            delete general[tokenId];
            generalIds.remove(tokenId);
            genesisOwnedIds[msg.sender].remove(tokenId);
            numGeneralStaked -= 1;
            // Always remove last to guard against reentrance
            lfGenesis.safeTransferFrom(address(this), msg.sender, tokenId, "");
            // Send back General
            emit GeneralUnStaked(msg.sender, tokenId, block.number, block.timestamp);
        } else {
            general[tokenId].value = uint80(TOPIAPerGeneral);
            // reset stake

        }
        emit GeneralClaimed(tokenId, unstake, owed);
    }


    /**
     * emergency unstake tokens
     * @param tokenIds the IDs of the tokens to claim earnings from
   */
    function rescue(uint16[] calldata tokenIds) external nonReentrant {
        require(rescueEnabled, "RESCUE DISABLED");
        uint16 tokenId;
        for (uint i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            
            if (genesisType[tokenId] == 1) {
                require(cadet[tokenId].owner == msg.sender, "SWIPER, NO SWIPING");
                delete cadet[tokenId];
                genesisOwnedIds[msg.sender].remove(tokenId);
                numCadetsStaked -= 1;
                lfGenesis.safeTransferFrom(address(this), msg.sender, tokenId, "");
                emit CadetClaimed(tokenId, true, 0);
            } else if (genesisType[tokenId] == 2) {
                require(alien[tokenId].owner == msg.sender, "SWIPER, NO SWIPING");
                delete alien[tokenId];
                alienIds.remove(tokenId);
                genesisOwnedIds[msg.sender].remove(tokenId);
                numAlienStaked -= 1;
                lfGenesis.safeTransferFrom(address(this), msg.sender, tokenId, "");
                emit AlienClaimed(tokenId, true, 0);
            } else if (genesisType[tokenId] == 3) {
                require(general[tokenId].owner == msg.sender, "SWIPER, NO SWIPING");
                delete general[tokenId];
                generalIds.remove(tokenId);
                genesisOwnedIds[msg.sender].remove(tokenId);
                numGeneralStaked -= 1;
                lfGenesis.safeTransferFrom(address(this), msg.sender, tokenId, "");
                emit GeneralClaimed(tokenId, true, 0);
            } else if (genesisType[tokenIds[i]] == 0) {
                continue;
            }
        }
        HUB.emitGenesisUnstaked(msg.sender, tokenIds);
    }

    /*
  * implement cadet upgrade
  */
  function upgradeWeapon(uint16 tokenId) external payable whenNotPaused nonReentrant returns(uint8) {
    require(tx.origin == msg.sender, "Only EOA");         
    require(cadet[tokenId].owner == msg.sender, "Don't own the given token");
    require(genesisType[tokenId] == 1, "affected only for Cadet NFTs");
    require(msg.value == SEED_COST, "Invalid value for randomness");

    TOPIAToken.burnFrom(msg.sender, UPGRADE_COST);
    _payGeneralTax(UPGRADE_COST * GENERAL_TAX_RATE_2 / 10000);
    uint256 remainingWords = randomizer.getRemainingWords();
    require(remainingWords >= 1, "Not enough random numbers. Please try again soon.");
    uint256[] memory seed = randomizer.getRandomWords(1);
    uint8 upgrade;

    /*
    * Odds to Upgrade:
    * Unarmed: Default
    * Sword: 70%
    * Pistol: 20%
    * Sniper: 10%
    */
    if ((seed[0] & 0xFFFF) % 100 < 10) {
      upgrade = 3;
    } else if((seed[0] & 0xFFFF) % 100 < 30) {
      upgrade = 2;
    } else {
      upgrade = 1;
    }
    weaponType[tokenId] = upgrade;

    vrf.transfer(msg.value);

    emit WeaponChanged(msg.sender, tokenId, upgrade);
    return upgrade;
  }

    /** ACCOUNTING */

    /**
     * add $TOPIA to claimable pot for the Yield
     * @param amount $TOPIA to add to the pot
   */
    function _payAlienTax(uint256 amount) internal {
        if (numAlienStaked == 0) {// if there's no staked aliens
            unaccountedAlienRewards += amount;
            // keep track of $TOPIA due to aliens
            return;
        }
        // makes sure to include any unaccounted $GP
        TOPIAPerAlien += (amount + unaccountedAlienRewards) / numAlienStaked;
        unaccountedAlienRewards = 0;
    }

    /**
     * add $TOPIA to claimable pot for the General Yield
     * @param amount $TOPIA to add to the pot
   */
    function _payGeneralTax(uint256 amount) internal {
        if (numGeneralStaked == 0) {// if there's no staked generals
            unaccountedGeneralRewards += amount;
            // keep track of $TOPIA due to generals
            return;
        }
        // makes sure to include any unaccounted $GP
        TOPIAPerGeneral += (amount + unaccountedGeneralRewards) / numGeneralStaked;
        unaccountedGeneralRewards = 0;
    }

    /** ALPHA FUNCTIONS */

    /**
     * adds Aliens and Cadet
     * @param account the address of the staker
   * @param tokenIds the IDs of the Aliens and Cadet to stake
   */
    function addManyAlphaToStakingPool(address account, uint16[] calldata tokenIds) external nonReentrant {
        require(tx.origin == msg.sender, "Only EOA");
        require(account == tx.origin, "account to send mismatch");
        for (uint i = 0; i < tokenIds.length; i++) {
            require(lfAlpha.ownerOf(tokenIds[i]) == msg.sender, "You don't own this token");
            lfAlpha.transferFrom(msg.sender, address(this), tokenIds[i]);

            alpha[tokenIds[i]] = StakeAlpha({
            owner : account,
            tokenId : uint16(tokenIds[i]),
            value : uint80(block.timestamp),
            stakedAt : uint80(block.timestamp)
            });
            // Add the cadet to the armory
            alphaOwnedIds[account].add(tokenIds[i]);
            numAlphasStaked += 1;
            emit AlphaStaked(account, tokenIds[i], block.timestamp);
            }
        HUB.emitAlphaStaked(account, tokenIds, 1);
    }

    /**
     * realize $TOPIA earnings and optionally unstake Alpha tokens
     * @param tokenIds the IDs of the tokens to claim earnings from
   * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
   */
    function claimManyAlphas(uint16[] calldata tokenIds, bool unstake) external whenNotPaused nonReentrant {
        require(tx.origin == msg.sender, "Only EOA");
        uint256 owed = 0;
        for (uint i = 0; i < tokenIds.length; i++) { 
            require(alpha[tokenIds[i]].owner == msg.sender, "Don't own the given token");
            if(block.timestamp <= claimEndTime) {
                owed += (block.timestamp - alpha[tokenIds[i]].value) * DAILY_ALPHA_RATE / PERIOD;
            } else if (alpha[tokenIds[i]].value < claimEndTime) {
                owed += (claimEndTime - alpha[tokenIds[i]].value) * DAILY_ALPHA_RATE / PERIOD;
            } else {
                owed += 0;
            }
            if (unstake) {
                delete alpha[tokenIds[i]];
                numAlphasStaked -= 1;
                alphaOwnedIds[msg.sender].remove(tokenIds[i]);
                lfAlpha.transferFrom(address(this), msg.sender, tokenIds[i]);
                emit AlphaUnstaked(msg.sender, tokenIds[i], block.number, block.timestamp);
            } else {
                alpha[tokenIds[i]].value = uint80(block.timestamp);
            }
            emit AlphaClaimed(tokenIds[i], unstake, owed);
        }
        if (owed == 0) {
            return;
        }
        if(unstake) { HUB.emitAlphaUnstaked(msg.sender, tokenIds); }
        HUB.emitTopiaClaimed(msg.sender, owed);
        TOPIAToken.mint(msg.sender, owed);
        totalTOPIAEarned += owed;
    }

    /**
     * emergency unstake tokens
     * @param tokenIds the IDs of the tokens to claim earnings from
   */
    function rescueAlpha(uint16[] calldata tokenIds) external nonReentrant {
        require(rescueEnabled, "RESCUE DISABLED");
        uint16 tokenId;
        for (uint i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            require(alpha[tokenId].owner == msg.sender, "SWIPER, NO SWIPING");

            delete alpha[tokenId];
            numAlphasStaked -= 1;
            alphaOwnedIds[msg.sender].remove(tokenId);
            lfAlpha.transferFrom(address(this), msg.sender, tokenId);
            emit AlphaUnstaked(msg.sender, tokenId, block.number, block.timestamp);
        }
        HUB.emitAlphaUnstaked(msg.sender, tokenIds);
    }

    /** ADMIN */

    /**
     * allows owner to enable "rescue mode"
     * simplifies accounting, prioritizes tokens out in emergency
     */
    function setRescueEnabled(bool _enabled) external onlyOwner {
        rescueEnabled = _enabled;
    }

    function isOwner(uint16 tokenId, address owner) external view override returns (bool validOwner) {
        if (genesisType[tokenId] == 1) {
            return cadet[tokenId].owner == owner;
        } else if (genesisType[tokenId] == 2) {
            return alien[tokenId].owner == owner;
        } else if (genesisType[tokenId] == 3) {
            return general[tokenId].owner == owner;
        }
    }

    /**
     * enables owner to pause / unpause contract
     */
    function setPaused(bool _paused) external requireContractsSet onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    /** READ ONLY */

    function getUnclaimedAlpha(uint16 tokenId) external view returns (uint256) {
        if(alpha[tokenId].value > 0) {
            if(block.timestamp <= claimEndTime) {
                return (block.timestamp - alpha[tokenId].value) * DAILY_ALPHA_RATE / PERIOD;
            } else if (alpha[tokenId].value < claimEndTime) {
                return (claimEndTime - alpha[tokenId].value) * DAILY_ALPHA_RATE / PERIOD;
            } else {
                return 0;
            }
        } else {
            return 0;
        }
    }

    function getUnclaimedGenesis(uint16 tokenId) external view returns (uint256 owed) {
        owed = 0;
        if (genesisType[tokenId] == 1 && cadet[tokenId].value > 0) {
            if(block.timestamp <= claimEndTime) {
                return (block.timestamp - cadet[tokenId].value) * DAILY_CADET_RATE / PERIOD;
            } else if (cadet[tokenId].value < claimEndTime) {
                return (claimEndTime - cadet[tokenId].value) * DAILY_CADET_RATE / PERIOD;
            } else {
                return 0;
            }
        } else if (genesisType[tokenId] == 2 && alien[tokenId].owner != address(0)) {
            return TOPIAPerAlien - alien[tokenId].value;
        } else if (genesisType[tokenId] == 3 && general[tokenId].owner != address(0)) {
            return TOPIAPerGeneral - general[tokenId].value;
        }
        return owed;
    }

    function getUnclaimedTopiaForUser(address _account) external view returns (uint256) {
        uint256 owed;
        uint256 genesisLength = genesisOwnedIds[_account].length();
        uint256 alphaLength = alphaOwnedIds[_account].length();
        for (uint i = 0; i < genesisLength; i++) {
            uint16 tokenId = uint16(genesisOwnedIds[_account].at(i));
            if (genesisType[tokenId] == 1) {
                if(block.timestamp <= claimEndTime) {
                    owed += (block.timestamp - cadet[tokenId].value) * DAILY_CADET_RATE / PERIOD;
                } else if (cadet[tokenId].value < claimEndTime) {
                    owed += (claimEndTime - cadet[tokenId].value) * DAILY_CADET_RATE / PERIOD;
                } else {
                    owed += 0;
                }
            } else if (genesisType[tokenId] == 2) {
                owed += TOPIAPerAlien - alien[tokenId].value;
            } else if (genesisType[tokenId] == 3) {
                owed += TOPIAPerGeneral - general[tokenId].value;
            } else if (genesisType[tokenId] == 0) {
                continue;
            }
        }
        for (uint i = 0; i < alphaLength; i++) {
            uint16 tokenId = uint16(alphaOwnedIds[_account].at(i));
            if(block.timestamp <= claimEndTime) {
                owed += (block.timestamp - alpha[tokenId].value) * DAILY_ALPHA_RATE / PERIOD;
            } else if (cadet[tokenId].value < claimEndTime) {
                owed += (claimEndTime - alpha[tokenId].value) * DAILY_ALPHA_RATE / PERIOD;
            } else {
                owed += 0;
            }
        }

        return owed;
    }

    function getStakedGenesisForUser(address _account) external view returns (uint16[] memory stakedGensis) {
        uint256 length = genesisOwnedIds[_account].length();
        stakedGensis = new uint16[](length);
        for (uint i = 0; i < length; i++) {
            stakedGensis[i] = uint16(genesisOwnedIds[_account].at(i));
        }
    }

    function getStakedAlphasForUser(address _account) external view returns (uint16[] memory stakedAlphas) {
        uint256 length = alphaOwnedIds[_account].length();
        stakedAlphas = new uint16[](length);
        for (uint i = 0; i < length; i++) {
            stakedAlphas[i] = uint16(alphaOwnedIds[_account].at(i));
        }
    }

    /**
     * chooses a random Alien thief when an unstaking token is stolen
     * @param seed a random value to choose a Alien from
   * @return the owner of the randomly selected Cadet thief
   */
    function randomAlienOwner(uint256 seed) internal view returns (address) {
        if (alienIds.length() == 0) {
            return address(0x0);
        }
        uint256 bucket = (seed & 0xFFFFFFFF) % alienIds.length();
        return alien[alienIds.at(bucket)].owner;
    }

    /**
     * chooses a random General thief when a an unstaking token is stolen
     * @param seed a random value to choose a General from
   * @return the owner of the randomly selected Alien thief
   */
    function randomGeneralOwner(uint256 seed) internal view returns (address) {
        if (generalIds.length() == 0) {
            return address(0x0);
        }
        uint256 bucket = (seed & 0xFFFFFFFF) % generalIds.length();
        return general[generalIds.at(bucket)].owner;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function updateMinimumExit(uint256 _minimum) external onlyOwner {
        MINIMUM = _minimum;
    }
    
    function updatePeriod(uint256 _period) external onlyOwner {
        PERIOD = _period;
    }

    function updateDailyCadetRate(uint256 _rate) external onlyOwner {
        DAILY_CADET_RATE = _rate;
    }

    function updateDailyAlphaRate(uint256 _rate) external onlyOwner {
        DAILY_ALPHA_RATE = _rate;
    }
    
    function updateGeneralTaxRate1(uint8 _rate) external onlyOwner {
        GENERAL_TAX_RATE_1 = _rate;
    }

    function updateGeneralTaxRate2(uint8 _rate) external onlyOwner {
        GENERAL_TAX_RATE_2 = _rate;
    }

    function updateCadetUpgradeCost(uint256 _cost) external onlyOwner {
        UPGRADE_COST = _cost;
    }

    function updateSeedCost(uint256 _cost) external onlyOwner {
        SEED_COST = _cost;
    }

    function closeSeasonEearnings(uint80 _timestamp) external onlyOwner {
        claimEndTime = _timestamp;
    }
}
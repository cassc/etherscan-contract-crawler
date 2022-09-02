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
import "./interfaces/IDogeWorld.sol";
import "./interfaces/IRandomizer.sol";

contract DogeWorld is IDogeWorld, Ownable, ReentrancyGuard, IERC721Receiver, Pausable {
    using EnumerableSet for EnumerableSet.UintSet;

    // maximum rank for a Dog/Cat
    uint8 public constant MAX_RANK = 8;

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

    mapping(uint16 => uint8) public genesisType;

    // number of Cats staked
    uint256 private numCatsStaked;
    // number of Dog staked
    uint256 private numDogStaked;
    // number of Veterinarian staked
    uint256 private numVeterinarianStaked;
    // number of Alpha staked
    uint256 private numAlphasStaked;

    uint256 public PERIOD = 1 days;

    event TokenStaked(address indexed owner, uint256 indexed tokenId, uint8 tokenType, uint256 value);
    event CatClaimed(uint256 indexed tokenId, bool indexed unstaked, uint256 earned);
    event CatUnStaked(address indexed owner, uint256 indexed tokenId, uint256 blockNum, uint256 timeStamp);
    event CatStolen(uint16 indexed tokenId, address indexed victim, address indexed thief, uint256 blockNum, uint256 timeStamp);
    event DogClaimed(uint256 indexed tokenId, bool indexed unstaked, uint256 earned);
    event DogUnStaked(address indexed owner, uint256 indexed tokenId, uint256 blockNum, uint256 timeStamp);
    event DogStolen(uint16 indexed tokenId, address indexed victim, address indexed thief, uint256 blockNum, uint256 timeStamp);
    event VeterinarianClaimed(uint256 indexed tokenId, bool indexed unstaked, uint256 earned);
    event VeterinarianUnStaked(address indexed owner, uint256 indexed tokenId, uint256 blockNum, uint256 timeStamp);
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

    // maps Cat tokenId to stake
    mapping(uint256 => Stake) private cat;

    // maps Alpha tokenId to stakeAlpha
    mapping(uint256 => StakeAlpha) private alpha;

    // maps Dog tokenId to stake
    mapping(uint256 => Stake) private dog;
    // array of Dog token ids;
    // uint256[] private yieldIds;
    EnumerableSet.UintSet private dogIds;
    // maps Veterinarian tokenId to stake
    mapping(uint256 => Stake) private veterinarian;
    // array of Veterinarian token ids;
    EnumerableSet.UintSet private veterinarianIds;

    mapping(address => uint256) ownerBalanceStaked;

    // array of Owned Genesis token ids;
    mapping(address => EnumerableSet.UintSet) genesisOwnedIds;
    // array of Owned Alpha token ids;
    mapping(address => EnumerableSet.UintSet) alphaOwnedIds;


    // any rewards distributed when no Dogs are staked
    uint256 private unaccountedDogRewards;
    // amount of $TOPIA due for each dog staked
    uint256 private TOPIAPerDog;
    // any rewards distributed when no Veterinarians are staked
    uint256 private unaccountedVeterinarianRewards;
    // amount of $TOPIA due for each Veterinarian staked
    uint256 private TOPIAPerVeterinarian;

    // Cats earn 20 $TOPIA per day
    uint256 public DAILY_CAT_RATE = 20 * 10**18;

    // Cats earn 35 $TOPIA per day
    uint256 public DAILY_ALPHA_RATE = 35 * 10**18;

    // Cats must have 2 days worth of $TOPIA to un-stake or else they're still remaining the armory
    uint256 public MINIMUM = 40 * 10**18;

    // rolling price
    uint256 public UPGRADE_COST = 40 * 10**18;

    // Veterinarians take a 3% tax on all $TOPIA claimed
    uint256 public DOG_TAX_RATE = 300;

    // Veterinarians take a 3% tax on all $TOPIA from upgrades
    uint256 public VETERINARIAN_TAX_RATE = 300;

    // tx cost for getting random numbers
    uint256 public SEED_COST = .00225 ether;

    // amount of $TOPIA earned so far
    uint256 public totalTOPIAEarned;
    // the last time $TOPIA was claimed
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
     * adds Dogs and Cat
     * @param account the address of the staker
   * @param tokenIds the IDs of the Dogs and Cat to stake
   */
    function addManyToStakingPool(address account, uint16[] calldata tokenIds) external override nonReentrant {
        require(tx.origin == msg.sender, "Only EOA");
        require(account == tx.origin, "account to send mismatch");
        for (uint i = 0; i < tokenIds.length; i++) {
            require(lfGenesis.ownerOf(tokenIds[i]) == msg.sender, "You don't own this token");

            if (genesisType[tokenIds[i]] == 1) {
                lfGenesis.transferFrom(msg.sender, address(this), tokenIds[i]);
                _addCatToStakingPool(account, tokenIds[i]);
            } else if (genesisType[tokenIds[i]] == 2) {
                lfGenesis.transferFrom(msg.sender, address(this), tokenIds[i]);
                _addDogToStakingPool(account, tokenIds[i]);
            } else if (genesisType[tokenIds[i]] == 3) {
                lfGenesis.transferFrom(msg.sender, address(this), tokenIds[i]);
                _addVeterinarianToStakingPool(account, tokenIds[i]);
            } else if (genesisType[tokenIds[i]] == 0) {
                continue;
            }

        }
        HUB.emitGenesisStaked(account, tokenIds, 1);
    }

    /**
     * adds a single Dog to the Armory
     * @param account the address of the staker
   * @param tokenId the ID of the Dog/Veterinarian to add to the Staking Pool
   */
    function _addDogToStakingPool(address account, uint256 tokenId) internal whenNotPaused {
        dog[tokenId] = Stake({
        owner : account,
        tokenId : uint16(tokenId),
        value : uint80(TOPIAPerDog),
        stakedAt : uint80(block.timestamp)
        });
        dogIds.add(tokenId);
        genesisOwnedIds[account].add(tokenId);
        numDogStaked += 1;
        emit TokenStaked(account, tokenId, 2, TOPIAPerDog);
    }


    /**
     * adds a single Veterinarian to the Armory
     * @param account the address of the staker
   * @param tokenId the ID of the Dog/Veterinarian to add to the Staking Pool
   */
    function _addVeterinarianToStakingPool(address account, uint256 tokenId) internal whenNotPaused {
        veterinarian[tokenId] = Stake({
        owner : account,
        tokenId : uint16(tokenId),
        value : uint80(TOPIAPerVeterinarian),
        stakedAt : uint80(block.timestamp)
        });
        veterinarianIds.add(tokenId);
        genesisOwnedIds[account].add(tokenId);
        numVeterinarianStaked += 1;
        emit TokenStaked(account, tokenId, 3, TOPIAPerVeterinarian);
    }


    /**
     * adds a single Cat to the armory
     * @param account the address of the staker
   * @param tokenId the ID of the Cat to add to the Staking Pool
   */
    function _addCatToStakingPool(address account, uint256 tokenId) internal {
        cat[tokenId] = Stake({
        owner : account,
        tokenId : uint16(tokenId),
        value : uint80(block.timestamp),
        stakedAt : uint80(block.timestamp)
        });
        // Add the cat to the armory
        genesisOwnedIds[account].add(tokenId);
        numCatsStaked += 1;
        emit TokenStaked(account, tokenId, 1, block.timestamp);
    }

    /** CLAIMING / UNSTAKING */

    /**
     * realize $TOPIA earnings and optionally unstake tokens from the Armory / Yield
     * to unstake a Cat it will require it has 2 days worth of $TOPIA unclaimed
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
                (uint256 _owed, uint16 _stolen) = _claimCatFromArmory(tokenIds[i], unstake, seed[i]);
                owed += _owed;
                if(unstake) {stolenNFTs[i] = _stolen;}
            } else if (genesisType[tokenIds[i]] == 2) {
                (uint256 _owed, uint16 _stolen) = _claimDogFromYield(tokenIds[i], unstake, seed[i]);
                owed += _owed;
                if(unstake) {stolenNFTs[i] = _stolen;}
            } else if (genesisType[tokenIds[i]] == 3) {
                owed += _claimVeterinarianFromYield(tokenIds[i], unstake);
            } else if (genesisType[tokenIds[i]] == 0) {
                continue;
            }
        }
        if (owed == 0) {
            return stolenNFTs;
        }
        totalTOPIAEarned += owed;
        TOPIAToken.mint(msg.sender, owed);
        HUB.emitTopiaClaimed(msg.sender, owed);
        vrf.transfer(msg.value);
    }


    /**
     * realize $TOPIA earnings for a single Cat and optionally unstake it
     * if not unstaking, lose x% chance * y% percent of accumulated $TOPIA to the staked Dogs based on it's upgrade
     * if unstaking, there is a % chanc of losing Cat NFT
     * @param tokenId the ID of the Cat to claim earnings from
   * @param unstake whether or not to unstake the Cat
   * @return owed - the amount of $TOPIA earned
   */
    function _claimCatFromArmory(uint16 tokenId, bool unstake, uint256 seed) internal returns (uint256 owed, uint16 tokId) {     
        require(cat[tokenId].owner == msg.sender, "Don't own the given token");
        if(block.timestamp <= claimEndTime) {
            owed = (block.timestamp - cat[tokenId].value) * DAILY_CAT_RATE / PERIOD;
        } else if (cat[tokenId].value < claimEndTime) {
            owed = (claimEndTime - cat[tokenId].value) * DAILY_CAT_RATE / PERIOD;
        } else {
            owed = 0;
        }

        uint256 seedChance = seed >> 16;
        bool stolen = false;
        address thief;
        if (unstake) {
            if ((seed & 0xFFFF) % 100 < 10) {
                thief = randomDogOwner(seed);
                lfGenesis.safeTransferFrom(address(this), thief, tokenId);
                stolen = true;
            } else {
                // lose accumulated tokens 50% chance and 60 percent of all token
                if ((seedChance & 0xFFFF) % 100 < 50) {
                    _payTax(owed * 25 / 100);
                    owed = owed * 75 / 100;
                }
            }
            delete cat[tokenId];
            numCatsStaked -= 1;
            genesisOwnedIds[msg.sender].remove(tokenId);
            if (stolen) {
                emit CatStolen(tokenId, msg.sender, thief, block.number, block.timestamp);
                tokId = tokenId;
            } else {
                // Always transfer last to guard against reentrance
                lfGenesis.safeTransferFrom(address(this), msg.sender, tokenId, "");
            }
            emit CatUnStaked(msg.sender, tokenId, block.number, block.timestamp);
        } else {// Claiming
            // lose accumulated tokens 50% chance and 25 percent of all token
            if ((seedChance & 0xFFFF) % 100 < 50) {
                _payTax(owed * 25 / 100);
                owed = owed * 75 / 100;
            }
            cat[tokenId].value = uint80(block.timestamp);
            // reset stake
        }
        emit CatClaimed(tokenId, unstake, owed);
    }

    /**
     * realize $TOPIA earnings for a single Dog and optionally unstake it
     * Dogs earn $TOPIA
     * @param tokenId the ID of the Dog to claim earnings from
   * @param unstake whether or not to unstake the Dog
   */
    function _claimDogFromYield(uint16 tokenId, bool unstake, uint256 seed) internal returns (uint256 owed, uint16 tokId) {
        require(dog[tokenId].owner == msg.sender, "Doesn't own given token");
        owed = TOPIAPerDog - dog[tokenId].value;
        if (unstake) {
            address thief;
            bool stolen;
            if ((seed & 0xFFFF) % 100 < 10) {
                thief = randomVeterinarianOwner(seed);
                lfGenesis.safeTransferFrom(address(this), thief, tokenId);
                stolen = true;
            }

            delete dog[tokenId];
            dogIds.remove(tokenId);
            genesisOwnedIds[msg.sender].remove(tokenId);
            numDogStaked -= 1;
            // Always remove last to guard against reentrance
            if (stolen) {
                emit DogStolen(tokenId, msg.sender, thief, block.number, block.timestamp);
                tokId = tokenId;
            } else {
                
                lfGenesis.safeTransferFrom(address(this), msg.sender, tokenId, "");
            }
            emit DogUnStaked(msg.sender, tokenId, block.number, block.timestamp);
        } else {
            dog[tokenId].value = uint80(TOPIAPerDog);
            // reset stake

        }
        emit DogClaimed(tokenId, unstake, owed);
    }

    /**
     * realize $TOPIA earnings for a Veterinarian Dog and optionally unstake it
     * Dogs earn $TOPIA
     * @param tokenId the ID of the Dog to claim earnings from
   * @param unstake whether or not to unstake the Veterinarian Dog
   */
    function _claimVeterinarianFromYield(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
        require(veterinarian[tokenId].owner == msg.sender, "Doesn't own given token");
        owed = TOPIAPerVeterinarian - veterinarian[tokenId].value;
        if (unstake) {
            delete veterinarian[tokenId];
            veterinarianIds.remove(tokenId);
            genesisOwnedIds[msg.sender].remove(tokenId);
            numVeterinarianStaked -= 1;
            // Always remove last to guard against reentrance
            lfGenesis.safeTransferFrom(address(this), msg.sender, tokenId, "");
            // Send back Veterinarian
            emit VeterinarianUnStaked(msg.sender, tokenId, block.number, block.timestamp);
        } else {
            veterinarian[tokenId].value = uint80(TOPIAPerVeterinarian);
            // reset stake

        }
        emit VeterinarianClaimed(tokenId, unstake, owed);
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
                require(cat[tokenId].owner == msg.sender, "SWIPER, NO SWIPING");
                delete cat[tokenId];
                genesisOwnedIds[msg.sender].remove(tokenId);
                numCatsStaked -= 1;
                lfGenesis.safeTransferFrom(address(this), msg.sender, tokenId, "");
                emit CatClaimed(tokenId, true, 0);
            } else if (genesisType[tokenId] == 2) {
                require(dog[tokenId].owner == msg.sender, "SWIPER, NO SWIPING");
                delete dog[tokenId];
                dogIds.remove(tokenId);
                genesisOwnedIds[msg.sender].remove(tokenId);
                numDogStaked -= 1;
                lfGenesis.safeTransferFrom(address(this), msg.sender, tokenId, "");
                emit DogClaimed(tokenId, true, 0);
            } else if (genesisType[tokenId] == 3) {
                require(veterinarian[tokenId].owner == msg.sender, "SWIPER, NO SWIPING");
                delete veterinarian[tokenId];
                veterinarianIds.remove(tokenId);
                genesisOwnedIds[msg.sender].remove(tokenId);
                numVeterinarianStaked -= 1;
                lfGenesis.safeTransferFrom(address(this), msg.sender, tokenId, "");
                emit VeterinarianClaimed(tokenId, true, 0);
            } else if (genesisType[tokenIds[i]] == 0) {
                continue;
            }
        }
        HUB.emitGenesisUnstaked(msg.sender, tokenIds);
    }

    /** ACCOUNTING */

    /**
     * add $TOPIA to claimable pot for the Yield
     * @param amount $TOPIA to add to the pot
   */
    function _payTax(uint256 amount) internal {
        uint256 _dogTax = amount * DOG_TAX_RATE / 10000;
        uint256 _vetTax = amount * VETERINARIAN_TAX_RATE / 10000;
        if (numDogStaked == 0 && numVeterinarianStaked == 0) {// if there's no staked dogs
            unaccountedDogRewards += _dogTax;
            unaccountedVeterinarianRewards += _vetTax;
            // keep track of $TOPIA due to dogs
            return;
        } else if (numDogStaked == 0 && numVeterinarianStaked > 0) {
            unaccountedDogRewards += _dogTax;
            TOPIAPerVeterinarian += (_vetTax + unaccountedVeterinarianRewards) / numVeterinarianStaked;
            unaccountedVeterinarianRewards = 0;
            return;
        } else if (numDogStaked > 0 && numVeterinarianStaked == 0) {
            TOPIAPerDog += (_dogTax + unaccountedDogRewards) / numDogStaked;
            unaccountedDogRewards = 0;
            unaccountedVeterinarianRewards += _vetTax;
            return;
        } else {
            TOPIAPerDog += (amount + unaccountedDogRewards) / numDogStaked;
            unaccountedDogRewards = 0;
            TOPIAPerVeterinarian += (amount + unaccountedVeterinarianRewards) / numVeterinarianStaked;
            unaccountedVeterinarianRewards = 0;
        }
    }

    /**
     * add $TOPIA to claimable pot for the Veterinarian Yield
     * @param amount $TOPIA to add to the pot
   */
    function _payVeterinarianTax(uint256 amount) internal {
        if (numVeterinarianStaked == 0) {// if there's no staked veterinarians
            unaccountedVeterinarianRewards += amount;
            // keep track of $TOPIA due to veterinarians
            return;
        }
        // makes sure to include any unaccounted $GP
        TOPIAPerVeterinarian += (amount + unaccountedVeterinarianRewards) / numVeterinarianStaked;
        unaccountedVeterinarianRewards = 0;
    }

    /** ALPHA FUNCTIONS */

    /**
     * adds Dogs and Cat
     * @param account the address of the staker
   * @param tokenIds the IDs of the Dogs and Cat to stake
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
            // Add the cat to the armory
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
            return cat[tokenId].owner == owner;
        } else if (genesisType[tokenId] == 2) {
            return dog[tokenId].owner == owner;
        } else if (genesisType[tokenId] == 3) {
            return veterinarian[tokenId].owner == owner;
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
        if (genesisType[tokenId] == 1 && cat[tokenId].value > 0) {
            if(block.timestamp <= claimEndTime) {
                return (block.timestamp - cat[tokenId].value) * DAILY_CAT_RATE / PERIOD;
            } else if (cat[tokenId].value < claimEndTime) {
                return (claimEndTime - cat[tokenId].value) * DAILY_CAT_RATE / PERIOD;
            } else {
                return 0;
            }
        } else if (genesisType[tokenId] == 2 && dog[tokenId].owner != address(0) && dog[tokenId].value > 0) {
            return TOPIAPerDog - dog[tokenId].value;
        } else if (genesisType[tokenId] == 3 && veterinarian[tokenId].owner != address(0) && veterinarian[tokenId].value > 0) {
            return TOPIAPerVeterinarian - veterinarian[tokenId].value;
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
                    owed += (block.timestamp - cat[tokenId].value) * DAILY_CAT_RATE / PERIOD;
                } else if (cat[tokenId].value < claimEndTime) {
                    owed += (claimEndTime - cat[tokenId].value) * DAILY_CAT_RATE / PERIOD;
                } else {
                    owed += 0;
                }
            } else if (genesisType[tokenId] == 2) {
                owed += TOPIAPerDog - dog[tokenId].value;
            } else if (genesisType[tokenId] == 3) {
                owed += TOPIAPerVeterinarian - veterinarian[tokenId].value;
            } else if (genesisType[tokenId] == 0) {
                continue;
            }
        }
        for (uint i = 0; i < alphaLength; i++) {
            uint16 tokenId = uint16(alphaOwnedIds[_account].at(i));
            if(block.timestamp <= claimEndTime) {
                owed += (block.timestamp - alpha[tokenId].value) * DAILY_ALPHA_RATE / PERIOD;
            } else if (cat[tokenId].value < claimEndTime) {
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
     * chooses a random Dog thief when an unstaking token is stolen
     * @param seed a random value to choose a Dog from
   * @return the owner of the randomly selected Cat thief
   */
    function randomDogOwner(uint256 seed) internal view returns (address) {
        if (dogIds.length() == 0) {
            return address(0x0);
        }
        uint256 bucket = (seed & 0xFFFFFFFF) % dogIds.length();
        return dog[dogIds.at(bucket)].owner;
    }

    /**
     * chooses a random Veterinarian thief when a an unstaking token is stolen
     * @param seed a random value to choose a Veterinarian from
   * @return the owner of the randomly selected Dog thief
   */
    function randomVeterinarianOwner(uint256 seed) internal view returns (address) {
        if (veterinarianIds.length() == 0) {
            return address(0x0);
        }
        uint256 bucket = (seed & 0xFFFFFFFF) % veterinarianIds.length();
        return veterinarian[veterinarianIds.at(bucket)].owner;
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

    function updateDailyCatRate(uint256 _rate) external onlyOwner {
        DAILY_CAT_RATE = _rate;
    }

    function updateDailyAlphaRate(uint256 _rate) external onlyOwner {
        DAILY_ALPHA_RATE = _rate;
    }
    
    function updateTaxRates(uint8 _dogRate, uint8 _vetRate) external onlyOwner {
        require(_dogRate + _vetRate == 100, "rates must equal 100");
        DOG_TAX_RATE = _dogRate;
        VETERINARIAN_TAX_RATE = _vetRate;
    }

    function updateSeedCost(uint8 _cost) external onlyOwner {
        SEED_COST = _cost;
    }

    function closeSeasonEearnings(uint80 _timestamp) external onlyOwner {
        claimEndTime = _timestamp;
    }
}
// SPDX-License-Identifier: MIT LICENSE

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/INFT.sol";
import "../interfaces/ITOPIA.sol";
import "../interfaces/IHUB.sol";
import "../interfaces/IRandomizer.sol";

contract DogeWorld is Ownable, ReentrancyGuard {

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

    struct Migration {
        uint16 vetTokenId;
        address vetOwner;
        uint80 value;
        uint80 migrationTime;
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

    event TokenStaked(address indexed owner, uint256 indexed tokenId, uint8 tokenType, uint256 timeStamp);
    event CatClaimed(uint256 indexed tokenId, bool indexed unstaked, uint256 earned);
    event CatUnStaked(address indexed owner, uint256 indexed tokenId, uint256 blockNum, uint256 timeStamp);
    event DogClaimed(uint256 indexed tokenId, bool indexed unstaked, uint256 earned);
    event DogUnStaked(address indexed owner, uint256 indexed tokenId, uint256 blockNum, uint256 timeStamp);
    event VeterinarianClaimed(uint256 indexed tokenId, bool indexed unstaked, uint256 earned);
    event VeterinarianUnStaked(address indexed owner, uint256 indexed tokenId, uint256 blockNum, uint256 timeStamp);
    event AlphaStaked(address indexed owner, uint256 indexed tokenId, uint256 value);
    event AlphaClaimed(uint256 indexed tokenId, bool indexed unstaked, uint256 earned);
    event AlphaUnstaked(address indexed owner, uint256 indexed tokenId, uint256 blockNum, uint256 timeStamp);
    event VetMigrated(address indexed owner, uint16 id, bool returning);
    event VetClaimed(uint256 owed);
    event GenesisStolen (uint16 indexed tokenId, address victim, address thief, uint8 nftType, uint256 timeStamp);

    // reference to the NFT contract
    INFT public lfGenesis;

    INFT public lfAlpha;

    IHUB public HUB;

    // reference to Randomizer
    IRandomizer public randomizer;
    address payable vrf;
    address payable dev;

    mapping(uint16 => Migration) public WastelandVets; // for vets sent to wastelands
    mapping(uint16 => bool) public IsInWastelands; // if vet token ID is in the wastelands

    // maps Cat tokenId to stake
    mapping(uint256 => Stake) private cat;

    // maps Alpha tokenId to stakeAlpha
    mapping(uint256 => StakeAlpha) private alpha;

    // maps Dog tokenId to stake
    mapping(uint256 => Stake) private dog;
    // maps Veterinarian tokenId to stake
    mapping(uint256 => Stake) private veterinarian;

    // if nft is in a litter
    mapping(uint16 => bool) public IsInLitter;
    // if user has a litter (one per wallet)
    mapping(address => bool) public HasLitter;

    // any rewards distributed when no Dogs are staked
    uint256 private unaccountedDogRewards;
    // amount of $TOPIA due for each dog staked
    uint256 private TOPIAPerDog;
    // any rewards distributed when no Veterinarians are staked
    uint256 private unaccountedVeterinarianRewards;
    // amount of $TOPIA due for each Veterinarian staked
    uint256 private TOPIAPerVeterinarian;

    // for staked tier 3 nfts
    uint256 public WASTELAND_BONUS = 100 * 10**18;

    // Cats earn 20 $TOPIA per day
    uint256 public DAILY_CAT_RATE = 5 * 10**18;

    // Cats earn 35 $TOPIA per day
    uint256 public DAILY_ALPHA_RATE = 10 * 10**18;

    // Veterinarians take a 3% tax on all $TOPIA claimed
    uint256 public DOG_TAX_RATE = 2500;

    // Veterinarians take a 3% tax on all $TOPIA from upgrades
    uint256 public VETERINARIAN_TAX_RATE = 2500;

    // tx cost for getting random numbers
    uint256 public SEED_COST = .0005 ether;

    // tx cost
    uint256 public DEV_FEE = .0018 ether;

    // amount of $TOPIA earned so far
    uint256 public totalTOPIAEarned;
    // the last time $TOPIA was claimed
    uint80 public claimEndTime = 1669662000;

    mapping(address => uint16) public GroupLength;

    uint8 public minimumForLitter;


    /**
     */
    constructor(uint8 _minimumForLitter) {
        dev = payable(msg.sender);
        minimumForLitter = _minimumForLitter;
    }

    /** CRITICAL TO SETUP */

    modifier requireContractsSet() {
        require(address(lfGenesis) != address(0) && address(randomizer) != address(0) && address(HUB) != address(0), "Contracts not set");
        _;
    }

    function setContracts(address _lfGenesis, address _lfAlpha, address _HUB, address payable _rand) external onlyOwner {
        lfGenesis = INFT(_lfGenesis);
        lfAlpha = INFT(_lfAlpha);
        randomizer = IRandomizer(_rand);
        HUB = IHUB(_HUB);
        vrf = _rand;
    }

    function _isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

    modifier notContract() {
        require(!_isContract(msg.sender), "no contract");
        require(msg.sender == tx.origin, "no proxy");
        _;
    }

    function setMinimumForLitter(uint8 _min) external onlyOwner {
        minimumForLitter = _min;
    }

    // mass update the nftType mapping
    function setBatchNFTType(uint16[] calldata tokenIds, uint8[] calldata _types) external onlyOwner {
        require(tokenIds.length == _types.length , " _idNumbers.length != _types.length");
        for (uint16 i = 0; i < tokenIds.length;) {
            require(_types[i] != 0 , "Invalid nft type");
            genesisType[tokenIds[i]] = _types[i];
            unchecked{ i++; }
        }
    }

    /** STAKING */

    /**
     * adds Dogs and Cat
     * @param account the address of the staker
   * @param tokenIds the IDs of the Dogs and Cat to stake
   */
    function addManyToStakingPool(address account, uint16[] calldata tokenIds) external payable nonReentrant {
        require(tx.origin == msg.sender, "Only EOA");
        require(account == tx.origin, "account to send mismatch");
        require(msg.value == DEV_FEE);
        uint8[] memory tokenTypes = new uint8[](tokenIds.length);

        for (uint i = 0; i < tokenIds.length;) {
            require(lfGenesis.ownerOf(tokenIds[i]) == msg.sender, "not owner");
            
            if (genesisType[tokenIds[i]] == 1) {
                tokenTypes[i] = 10;
                _addCatToStakingPool(account, tokenIds[i]);
            } else if (genesisType[tokenIds[i]] == 2) {
                tokenTypes[i] = 11;
                _addDogToStakingPool(account, tokenIds[i]);
            } else if (genesisType[tokenIds[i]] == 3) {
                tokenTypes[i] = 12;
                _addVeterinarianToStakingPool(account, tokenIds[i]);
            } else if (genesisType[tokenIds[i]] == 0) {
                revert('invalid token id');
            }
            unchecked{ i++; }
        }
        HUB.receieveManyGenesis(msg.sender, tokenIds, tokenTypes, 3);
    }

    /**
     * adds a single Dog to the Armory
     * @param account the address of the staker
   * @param tokenId the ID of the Dog/Veterinarian to add to the Staking Pool
   */
    function _addDogToStakingPool(address account, uint16 tokenId) internal {
        dog[tokenId] = Stake({
        owner : account,
        tokenId : tokenId,
        value : uint80(TOPIAPerDog),
        stakedAt : uint80(block.timestamp)
        });
        numDogStaked += 1;
        emit TokenStaked(account, tokenId, 2, block.timestamp);
    }


    /**
     * adds a single Veterinarian to the Armory
     * @param account the address of the staker
   * @param tokenId the ID of the Dog/Veterinarian to add to the Staking Pool
   */
    function _addVeterinarianToStakingPool(address account, uint16 tokenId) internal {
        veterinarian[tokenId] = Stake({
        owner : account,
        tokenId : tokenId,
        value : uint80(TOPIAPerVeterinarian),
        stakedAt : uint80(block.timestamp)
        });
        numVeterinarianStaked += 1;
        emit TokenStaked(account, tokenId, 3, block.timestamp);
    }


    /**
     * adds a single Cat to the armory
     * @param account the address of the staker
   * @param tokenId the ID of the Cat to add to the Staking Pool
   */
    function _addCatToStakingPool(address account, uint16 tokenId) internal {
        cat[tokenId] = Stake({
        owner : account,
        tokenId : tokenId,
        value : uint80(block.timestamp),
        stakedAt : uint80(block.timestamp)
        });
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
    function claimManyGenesis(uint16[] calldata tokenIds, uint8 _type, bool unstake) external payable nonReentrant {
        require(tx.origin == msg.sender, "Only EOA");
        uint256 numWords;
        if(_type == 1 || (_type == 2 && unstake)) {
            numWords = tokenIds.length;
            require(msg.value == DEV_FEE + (SEED_COST * numWords), "need more eth");
        } else {
            require(msg.value == DEV_FEE, "need more eth");
        }
        
        uint256[] memory seed;
        if(_type == 1 || (_type == 2 && unstake)) {
            uint256 remainingWords = randomizer.getRemainingWords();
            require(remainingWords >= numWords, "try again soon.");
            seed = randomizer.getRandomWords(numWords);
        }
        uint256 owed = 0;
        for (uint i = 0; i < tokenIds.length;) {
            require(!IsInLitter[tokenIds[i]]);
            if (genesisType[tokenIds[i]] == 1) {
                require(_type == 1, 'wrong type for call');
                owed += _claimCatFromPool(tokenIds[i], unstake, seed[i]);
            } else if (genesisType[tokenIds[i]] == 2) {
                require(_type == 2, 'wrong type for call');
                owed += _claimDogFromPool(tokenIds[i], unstake, unstake ? seed[i] : 0);
            } else if (genesisType[tokenIds[i]] == 3) {
                require(_type == 3, 'wrong type for call');
                owed += _claimVeterinarianFromPool(tokenIds[i], unstake);
            } else if (genesisType[tokenIds[i]] == 0) {
                revert('invalid token id');
            }
            unchecked{ i++; }
        } 
        uint256 vrfAmount = msg.value - DEV_FEE;
        if(vrfAmount > 0) { vrf.transfer(vrfAmount); }
        dev.transfer(DEV_FEE);

        if (owed == 0) { return; }
        totalTOPIAEarned += owed;
        HUB.pay(msg.sender, owed);
    }

    function getTXCost(uint16[] calldata tokenIds, uint8 _type, bool unstake) external view returns (uint256 txCost) {
        if(_type == 1 || (_type == 2 && unstake)) {
            txCost = DEV_FEE + (SEED_COST * tokenIds.length);
        } else {
            txCost = DEV_FEE;
        }
    }


    /**
     * realize $TOPIA earnings for a single Cat and optionally unstake it
     * if not unstaking, lose x% chance * y% percent of accumulated $TOPIA to the staked Dogs based on it's upgrade
     * if unstaking, there is a % chanc of losing Cat NFT
     * @param tokenId the ID of the Cat to claim earnings from
   * @param unstake whether or not to unstake the Cat
   * @return owed - the amount of $TOPIA earned
   */
    function _claimCatFromPool(uint16 tokenId, bool unstake, uint256 seed) internal returns (uint256 owed) {     
        require(cat[tokenId].owner == msg.sender, "not owner");
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
            if ((seed & 0xFFFF) % 100 < 10 && HUB.alphaCount(3) > 0) {
                thief = HUB.stealGenesis(tokenId, seed, 3, 10, msg.sender);
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
            if (stolen) {
                emit GenesisStolen (tokenId, msg.sender, thief, 1, block.timestamp);
            } else {
                // Always transfer last to guard against reentrance
                HUB.returnGenesisToOwner(msg.sender, tokenId, 10, 3);
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
    function _claimDogFromPool(uint16 tokenId, bool unstake, uint256 seed) internal returns (uint256 owed) {
        require(dog[tokenId].owner == msg.sender, "not owner");
        owed = TOPIAPerDog - dog[tokenId].value;
        if (unstake) {
            bool stolen;
            address thief;
            if ((seed & 0xFFFF) % 100 < 10 && HUB.vetCount() > 0) {
                thief = HUB.stealGenesis(tokenId, seed, 3, 11, msg.sender);
                stolen = true;
            }

            delete dog[tokenId];
            numDogStaked -= 1;
            // Always remove last to guard against reentrance
            if (stolen) {
                emit GenesisStolen (tokenId, msg.sender, thief, 2, block.timestamp);
            } else {
                HUB.returnGenesisToOwner(msg.sender, tokenId, 11, 3);
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
    function _claimVeterinarianFromPool(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
        require(veterinarian[tokenId].owner == msg.sender, "not owner");
        owed = TOPIAPerVeterinarian - veterinarian[tokenId].value;
        if (unstake) {
            delete veterinarian[tokenId];
            numVeterinarianStaked -= 1;
            // Always remove last to guard against reentrance
            HUB.returnGenesisToOwner(msg.sender, uint16(tokenId), 12, 3);
            // Send back Veterinarian
            emit VeterinarianUnStaked(msg.sender, tokenId, block.number, block.timestamp);
        } else {
            veterinarian[tokenId].value = uint80(TOPIAPerVeterinarian);
            // reset stake

        }
        emit VeterinarianClaimed(tokenId, unstake, owed);
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
    function addManyAlphaToStakingPool(address account, uint16[] calldata tokenIds) external payable nonReentrant {
        require(tx.origin == msg.sender, "Only EOA");
        require(account == tx.origin, "account to send mismatch");
        require(msg.value == DEV_FEE, "need more eth");
        for (uint i = 0; i < tokenIds.length;) {
            require(lfAlpha.ownerOf(tokenIds[i]) == msg.sender, "not owner");
            HUB.receiveAlpha(msg.sender, tokenIds[i], 3);

            alpha[tokenIds[i]] = StakeAlpha({
            owner : account,
            tokenId : uint16(tokenIds[i]),
            value : uint80(block.timestamp),
            stakedAt : uint80(block.timestamp)
            });
            // Add the cat to the armory
            numAlphasStaked += 1;
            emit AlphaStaked(account, tokenIds[i], block.timestamp);
            unchecked{ i++; }
        }
        dev.transfer(DEV_FEE);
    }

    /**
     * realize $TOPIA earnings and optionally unstake Alpha tokens
     * @param tokenIds the IDs of the tokens to claim earnings from
   * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
   */
    function claimManyAlphas(uint16[] calldata tokenIds, bool unstake) external payable nonReentrant {
        require(tx.origin == msg.sender, "Only EOA");
        require(msg.value == DEV_FEE, "need more eth");
        uint256 owed = 0;
        for (uint i = 0; i < tokenIds.length;) { 
            require(alpha[tokenIds[i]].owner == msg.sender, "not owner");
            
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
                HUB.returnAlphaToOwner(msg.sender, tokenIds[i], 3);
                emit AlphaUnstaked(msg.sender, tokenIds[i], block.number, block.timestamp);
            } else {
                alpha[tokenIds[i]].value = uint80(block.timestamp);
            }
            emit AlphaClaimed(tokenIds[i], unstake, owed);
            unchecked{ i++; }
        }
        if (owed == 0) {
            return;
        }
        HUB.pay(msg.sender, owed);
        totalTOPIAEarned += owed;
        dev.transfer(DEV_FEE);
    }

    function isOwner(uint16 tokenId, address owner) external view returns (bool validOwner) {
        if (genesisType[tokenId] == 1) {
            return cat[tokenId].owner == owner;
        } else if (genesisType[tokenId] == 2) {
            return dog[tokenId].owner == owner;
        } else if (genesisType[tokenId] == 3) {
            return veterinarian[tokenId].owner == owner;
        }
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
        } else if (genesisType[tokenId] == 2 && dog[tokenId].owner != address(0)) {
            return TOPIAPerDog - dog[tokenId].value;
        } else if (genesisType[tokenId] == 3) {
            if (IsInWastelands[tokenId]) {
                return WastelandVets[tokenId].value;
            } else if (veterinarian[tokenId].owner != address(0)) {
                return TOPIAPerVeterinarian - veterinarian[tokenId].value;
            }
        }
        return owed;
    }

    function updateDailyCatRate(uint256 _rate) external onlyOwner {
        DAILY_CAT_RATE = _rate;
    }

    function updateDailyAlphaRate(uint256 _rate) external onlyOwner {
        DAILY_ALPHA_RATE = _rate;
    }

    function updateWastelandBonus(uint256 _bonus) external onlyOwner {
        WASTELAND_BONUS = _bonus;
    }
    
    function updateTaxRates(uint16 _dogRate, uint16 _vetRate) external onlyOwner {
        require(_dogRate + _vetRate <= 10000, "must be equal or lesser than 10000");
        DOG_TAX_RATE = _dogRate;
        VETERINARIAN_TAX_RATE = _vetRate;
    }

    function updateSeedCost(uint256 _cost) external onlyOwner {
        SEED_COST = _cost;
    }

    function updateDevCost(uint256 _cost) external onlyOwner {
        DEV_FEE = _cost;
    }

    function updateDev(address payable _dev) external onlyOwner {
        dev = _dev;
    }

    function closeSeasonEearnings(uint80 _timestamp) external onlyOwner {
        claimEndTime = _timestamp;
    }

    function createLitter(uint16[] calldata _tokenIds) external payable nonReentrant notContract() {
        require(!HasLitter[msg.sender] , "already have litter");
        require(msg.value == DEV_FEE, "need more eth");
        uint16 length = uint16(_tokenIds.length);
        require(length >= minimumForLitter , "Not enough cats");
        for (uint16 i = 0; i < length;) {
            require(lfGenesis.ownerOf(_tokenIds[i]) == msg.sender , "not owner");
            require(genesisType[_tokenIds[i]] == 1 , "only cats");
            require(!IsInLitter[_tokenIds[i]]);
            IsInLitter[_tokenIds[i]] = true;

            cat[_tokenIds[i]] = Stake({
            owner : msg.sender,
            tokenId : _tokenIds[i],
            value : uint80(block.timestamp),
            stakedAt : uint80(block.timestamp)
            });

            numCatsStaked += 1;
            emit TokenStaked(msg.sender, _tokenIds[i], 1, block.timestamp);

            unchecked{ i++; }
        }
        GroupLength[msg.sender] = length;
        HUB.createGroup(_tokenIds, msg.sender, 3);
        HasLitter[msg.sender] = true;
        dev.transfer(DEV_FEE);
    }

    function addToLitter(uint16 _id) external payable nonReentrant notContract() {
        require(HasLitter[msg.sender], "Must have Litter!");
        require(lfGenesis.ownerOf(_id) == msg.sender, "not owner");
        require(genesisType[_id] == 1 , "must be cat");
        require(!IsInLitter[_id]);
        require(msg.value == DEV_FEE, "need more eth");
        IsInLitter[_id] = true;

        cat[_id] = Stake({
        owner : msg.sender,
        tokenId : _id,
        value : uint80(block.timestamp),
        stakedAt : uint80(block.timestamp)
        });

        numCatsStaked += 1;
        GroupLength[msg.sender]++;
        emit TokenStaked(msg.sender, _id, 1, block.timestamp);

        HUB.addToGroup(_id, msg.sender, 3);
        dev.transfer(DEV_FEE);
    }

    function claimLitter(uint16[] calldata tokenIds, bool unstake) external payable notContract() {
        require(HasLitter[msg.sender] , "Must own litter");
        uint256 numWords = tokenIds.length;
        require(msg.value == DEV_FEE + (SEED_COST * numWords), "need more eth");
        uint256[] memory seed;
        uint8 theftModifier;
        
        if(unstake) { 
            if (numWords <= 10) {
                theftModifier = uint8(numWords);
            } else {theftModifier = 10;}
            require(uint16(numWords) == GroupLength[msg.sender]);
        }
        uint256 remainingWords = randomizer.getRemainingWords();
        require(remainingWords >= numWords, "try again soon.");
        seed = randomizer.getRandomWords(numWords);
        
        uint256 owed = 0;
        for (uint i = 0; i < tokenIds.length;) {
            require(genesisType[tokenIds[i]] == 1 , "Must be cats");
            require(IsInLitter[tokenIds[i]] , "must be in litter");
            require(cat[tokenIds[i]].owner == msg.sender, "!= owner");
            uint256 thisOwed;
   
            if(block.timestamp <= claimEndTime) {
                thisOwed = (block.timestamp - cat[tokenIds[i]].value) * DAILY_CAT_RATE / PERIOD;
            } else if (cat[tokenIds[i]].value < claimEndTime) {
                thisOwed = (claimEndTime - cat[tokenIds[i]].value) * DAILY_CAT_RATE / PERIOD;
            } else {
                thisOwed = 0;
            }

            uint256 seedChance = seed[i] >> 16;
            if (unstake) {
                if ((seed[i] & 0xFFFF) % 100 < (10 - theftModifier) && HUB.alphaCount(3) > 0) {
                    address thief = HUB.stealGenesis(tokenIds[i], seed[i], 3, 10, msg.sender);
                    emit GenesisStolen (tokenIds[i], msg.sender, thief, 1, block.timestamp);
                } else {
                    // lose accumulated tokens 50% chance and 60 percent of all token
                    if ((seedChance & 0xFFFF) % 100 < 50) {
                        _payTax(thisOwed * 25 / 100);
                        thisOwed = thisOwed * 75 / 100;
                    }
                    HUB.returnGenesisToOwner(msg.sender, tokenIds[i], 10, 3);
                }
                delete cat[tokenIds[i]];
                IsInLitter[tokenIds[i]] = false;
                emit CatUnStaked(msg.sender, tokenIds[i], block.number, block.timestamp);

            } else {// Claiming
                // lose accumulated tokens 50% chance and 25 percent of all token
                if ((seedChance & 0xFFFF) % 100 < 50) {
                    _payTax(thisOwed * 25 / 100);
                    thisOwed = thisOwed * 75 / 100;
                }
                cat[tokenIds[i]].value = uint80(block.timestamp);
                // reset stake
            }
        emit CatClaimed(tokenIds[i], unstake, owed);
        owed += thisOwed;
        unchecked{ i++; }
        }
        if (unstake) {
            HasLitter[msg.sender] = false;
            numCatsStaked -= numWords;
            HUB.unstakeGroup(msg.sender, 3);
            GroupLength[msg.sender] = 0;
        }
        uint256 vrfAmount = msg.value - DEV_FEE;
        if(vrfAmount > 0) { vrf.transfer(vrfAmount); }
        dev.transfer(DEV_FEE);

        if (owed == 0) { return; }

        totalTOPIAEarned += owed;
        HUB.pay(msg.sender, owed);
    }

    function sendVetToWastelands(uint16[] calldata _ids) external payable notContract() {
        uint256 numWords = _ids.length;
        require(msg.value == DEV_FEE + (SEED_COST * numWords), "need more eth");
        require(randomizer.getRemainingWords() >= numWords, "try again soon.");
        uint256[] memory seed = randomizer.getRandomWords(numWords);

        for (uint16 i = 0; i < numWords;) {
            require(lfGenesis.ownerOf(_ids[i]) == msg.sender, "not owner");
            require(genesisType[_ids[i]] == 3, "not a Vet");
            require(!IsInWastelands[_ids[i]] , "already in wastes");

            if (HUB.alienCount() > 0 && (seed[i]) % 100 < 25) { // stolen
                address thief = HUB.stealMigratingGenesis(_ids[i], seed[i], 3, msg.sender, false);
                emit GenesisStolen (_ids[i], msg.sender, thief, 3, block.timestamp);
            } else {
                HUB.migrate(_ids[i], msg.sender, 3, false);
                WastelandVets[_ids[i]].vetTokenId = _ids[i];
                WastelandVets[_ids[i]].vetOwner = msg.sender;
                WastelandVets[_ids[i]].value = uint80(WASTELAND_BONUS);
                WastelandVets[_ids[i]].migrationTime = uint80(block.timestamp);
                IsInWastelands[_ids[i]] = true;
                emit VetMigrated(msg.sender, _ids[i], false);
            }
            unchecked { i++; }
        }
        uint256 vrfAmount = msg.value - DEV_FEE;
        if(vrfAmount > 0) { vrf.transfer(vrfAmount); }
        dev.transfer(DEV_FEE);
    }

    function claimManyWastelands(uint16[] calldata _ids, bool unstake) external payable notContract() {
        uint256 numWords = _ids.length;
        uint256[] memory seed;

        if(unstake) { 
            require(msg.value == DEV_FEE + (SEED_COST * numWords), "need more eth");
            require(randomizer.getRemainingWords() >= numWords, "try again soon.");
            seed = randomizer.getRandomWords(numWords);
        } else {
            require(msg.value == DEV_FEE, "need more eth");
        }
        
        uint256 owed = 0;

        for (uint16 i = 0; i < numWords;) {
            require(IsInWastelands[_ids[i]] , "not in wastes");
            require(msg.sender == WastelandVets[_ids[i]].vetOwner , "not owner");
            
            owed += WastelandVets[_ids[i]].value;

            if (unstake) {
                if (HUB.alienCount() > 0 && (seed[i]) % 100 < 25) { // stolen
                    address thief = HUB.stealMigratingGenesis(_ids[i], seed[i], 3, msg.sender, true);
                    emit GenesisStolen (_ids[i], msg.sender, thief, 3, block.timestamp);
                } else {
                    HUB.migrate(_ids[i], msg.sender, 3, true);
                    emit VetMigrated(msg.sender, _ids[i], true);
                }
                IsInWastelands[_ids[i]] = false;
                delete WastelandVets[_ids[i]];
            } else {
                WastelandVets[_ids[i]].value = uint80(0); // reset value
            }
            emit VetClaimed(owed);
            unchecked { i++; }
        } 
        uint256 vrfAmount = msg.value - DEV_FEE;
        if(vrfAmount > 0) { vrf.transfer(vrfAmount); }
        dev.transfer(DEV_FEE);

        if (owed == 0) { return; }
        totalTOPIAEarned += owed;
        HUB.pay(msg.sender, owed);       
    }
}
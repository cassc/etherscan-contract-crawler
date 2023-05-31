// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../interfaces/INFT.sol";
import "../interfaces/ITOPIA.sol";
import "../interfaces/IHUB.sol";
import "../interfaces/IRandomizer.sol";

contract PYEMarket is Ownable, ReentrancyGuard, Pausable {

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
        uint16 shopOwnerTokenId;
        address shopOwnerOwner;
        uint80 value;
        uint80 migrationTime;
    }

    mapping(uint16 => uint8) public genesisType;

    uint256 private numBakersStaked;
    // number of Foodie staked
    uint256 private numFoodieStaked;
    // number of ShopOwner staked
    uint256 private numShopOwnerStaked;
    // number of Alpha staked
    uint256 private numAlphasStaked;

    uint256 public PERIOD = 1 days;

    event TokenStaked(address indexed owner, uint256 indexed tokenId, uint8 tokenType, uint256 timeStamp);
    event BakerClaimed(uint256 indexed tokenId, bool indexed unstaked, uint256 earned);
    event BakerUnStaked(address indexed owner, uint256 indexed tokenId, uint256 blockNum, uint256 timeStamp);
    event FoodieClaimed(uint256 indexed tokenId, bool indexed unstaked, uint256 earned);
    event FoodieUnStaked(address indexed owner, uint256 indexed tokenId, uint256 blockNum, uint256 timeStamp);
    event ShopOwnerClaimed(uint256 indexed tokenId, bool indexed unstaked, uint256 earned);
    event ShopOwnerUnStaked(address indexed owner, uint256 indexed tokenId, uint256 blockNum, uint256 timeStamp);
    event BoughtPYE(address indexed owner, uint8 boughtPYEType, uint256 rewardInPYE, uint256 timeStamp);
    event AlphaStaked(address indexed owner, uint256 indexed tokenId, uint256 value);
    event AlphaClaimed(uint256 indexed tokenId, bool indexed unstaked, uint256 earned);
    event AlphaUnstaked(address indexed owner, uint256 indexed tokenId, uint256 blockNum, uint256 timeStamp);
    event ShopOwnerMigrated(address indexed owner, uint16 id, bool returning);
    event GenesisStolen (uint16 indexed tokenId, address victim, address thief, uint8 nftType, uint256 timeStamp);

    // reference to the NFT contract
    INFT public lfGenesis;

    INFT public lfAlpha;

    IHUB public HUB;

    mapping(uint16 => Migration) public WastelandShopOwners; // for vets sent to wastelands
    mapping(uint16 => bool) public IsInWastelands; // if vet token ID is in the wastelands

    // reference to Randomizer
    IRandomizer public randomizer;
    address payable vrf;
    address payable dev;

    // maps Baker tokenId to stake
    mapping(uint256 => Stake) private baker;

    // maps Alpha tokenId to stakeAlpha
    mapping(uint256 => StakeAlpha) private alpha;

    // maps Foodie tokenId to stake
    mapping(uint256 => Stake) private foodie;
    // maps ShopOwner tokenId to stake
    mapping(uint256 => Stake) private shopOwner;

    mapping(uint16 => bool) public IsInUnion;

    mapping(address => bool) public HasUnion;

    // any rewards distributed when no Foodies are staked
    uint256 private unaccountedFoodieRewards;
    // amount of $TOPIA due for each foodie staked
    uint256 private TOPIAPerFoodie;
    // any rewards distributed when no ShopOwners are staked
    uint256 private unaccountedShopOwnerRewards;
    // amount of $TOPIA due for each ShopOwner staked
    uint256 private TOPIAPerShopOwner;

    // for staked tier 3 nfts
    uint256 public WASTELAND_BONUS = 100 * 10**18;

    // Bakers earn 20 $TOPIA per day
    uint256 public DAILY_BAKER_RATE = 5 * 10**18;

    // Bakers earn 35 $TOPIA per day
    uint256 public DAILY_ALPHA_RATE = 10 * 10**18;

    // rolling price
    uint256 public PYE_COST = 40 * 10**18;

    // ShopOwners take a 6.66% tax on all $TOPIA claimed
    uint256 public FOODIE_TAX_RATE = 666;

    // ShopOwners take a 3.33% tax on all $TOPIA from upgrades
    uint256 public SHOP_OWNER_TAX_RATE = 333;

    mapping(uint8 => uint256) public pyeFilling;

    // tx cost for getting random numbers
    uint256 public SEED_COST = .0005 ether;

    // tx cost
    uint256 public DEV_FEE = .0018 ether;

    // amount of $TOPIA earned so far
    uint256 public totalTOPIAEarned;
    // the last time $TOPIA was claimed
    uint80 public claimEndTime = 1669662000;

    uint8 public minimumForUnion;

    mapping(address => uint16) public GroupLength;

    /**
     */
    constructor(uint8 _minimumForUnion) {
        dev = payable(msg.sender);
        minimumForUnion = _minimumForUnion;
        pyeFilling[1] = 0;
        pyeFilling[2] = 20 ether;
        pyeFilling[3] = 80 ether;
        pyeFilling[4] = 200 ether;
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
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    function setMinimumForUnion(uint8 _min) external onlyOwner {
        minimumForUnion = _min;
    }

    // mass update the nftType mapping
    function setBatchNFTType(uint16[] calldata tokenIds, uint8[] calldata _types) external onlyOwner {
        require(tokenIds.length == _types.length , " _idNumbers.length != _types.length: Each token ID must have exactly 1 corresponding type!");
        for (uint16 i = 0; i < tokenIds.length;) {
            require(_types[i] != 0 , "Invalid nft type - cannot be 0");
            genesisType[tokenIds[i]] = _types[i];
            unchecked{ i++; }
        }
    }

    function setWastelandsBonus(uint256 _bonus) external onlyOwner {
        WASTELAND_BONUS = _bonus;
    }

    /** STAKING */

    /**
     * adds Foodies and Baker
     * @param account the address of the staker
   * @param tokenIds the IDs of the Foodies and Baker to stake
   */
    function addManyToStakingPool(address account, uint16[] calldata tokenIds) external payable nonReentrant {
        require(tx.origin == msg.sender, "Only EOA");
        require(account == tx.origin, "account to send mismatch");
        require(msg.value == DEV_FEE);
        uint8[] memory tokenTypes = new uint8[](tokenIds.length);
        for (uint i = 0; i < tokenIds.length;) {
            require(lfGenesis.ownerOf(tokenIds[i]) == msg.sender, "You don't own this token");

            if (genesisType[tokenIds[i]] == 1) {
                tokenTypes[i] = 7;
                _addBakerToStakingPool(account, tokenIds[i]);
            } else if (genesisType[tokenIds[i]] == 2) {
                tokenTypes[i] = 8;
                _addFoodieToStakingPool(account, tokenIds[i]);
            } else if (genesisType[tokenIds[i]] == 3) {
                tokenTypes[i] = 9;
                _addShopOwnerToStakingPool(account, tokenIds[i]);
            } else if (genesisType[tokenIds[i]] == 0) {
                revert('invalid token id');
            }
            unchecked{ i++; }
        }
        HUB.receieveManyGenesis(msg.sender, tokenIds, tokenTypes, 4);
    }

    /**
     * adds a single Foodie to the Pool
     * @param account the address of the staker
   * @param tokenId the ID of the Foodie/ShopOwner to add to the Staking Pool
   */
    function _addFoodieToStakingPool(address account, uint16 tokenId) internal whenNotPaused {
        foodie[tokenId] = Stake({
        owner : account,
        tokenId : tokenId,
        value : uint80(TOPIAPerFoodie),
        stakedAt : uint80(block.timestamp)
        });
        numFoodieStaked += 1;
        emit TokenStaked(account, tokenId, 2, block.timestamp);
    }


    /**
     * adds a single ShopOwner to the Pool
     * @param account the address of the staker
   * @param tokenId the ID of the Foodie/ShopOwner to add to the Staking Pool
   */
    function _addShopOwnerToStakingPool(address account, uint16 tokenId) internal whenNotPaused {
        shopOwner[tokenId] = Stake({
        owner : account,
        tokenId : tokenId,
        value : uint80(TOPIAPerShopOwner),
        stakedAt : uint80(block.timestamp)
        });
        numShopOwnerStaked += 1;
        emit TokenStaked(account, tokenId, 3, block.timestamp);
    }


    /**
     * adds a single Baker to the Pool
     * @param account the address of the staker
   * @param tokenId the ID of the Baker to add to the Staking Pool
   */
    function _addBakerToStakingPool(address account, uint16 tokenId) internal {
        baker[tokenId] = Stake({
        owner : account,
        tokenId : tokenId,
        value : uint80(block.timestamp),
        stakedAt : uint80(block.timestamp)
        });
        // Add the baker to the Pool
        numBakersStaked += 1;
        emit TokenStaked(account, tokenId, 1, block.timestamp);
    }

    /** CLAIMING / UNSTAKING */

    /**
     * realize $TOPIA earnings and optionally unstake tokens from the Pool
     * to unstake a Baker it will require it has 2 days worth of $TOPIA unclaimed
     * @param tokenIds the IDs of the tokens to claim earnings from
   * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
   */
    function claimManyGenesis(uint16[] calldata tokenIds, uint8 _type, bool unstake) external payable whenNotPaused nonReentrant {
        require(tx.origin == msg.sender, "Only EOA");
        uint256 numWords;
        uint256[] memory seed;
        if((_type == 1 || _type == 2) && unstake) {
            numWords = tokenIds.length;
            require(msg.value == DEV_FEE + (SEED_COST * numWords), "need more eth");
            uint256 remainingWords = randomizer.getRemainingWords();
            require(remainingWords >= numWords, "try again soon.");
            seed = randomizer.getRandomWords(numWords);
        } else {
            require(msg.value == DEV_FEE, "need more eth");
        }

        uint256 owed = 0;
        for (uint i = 0; i < tokenIds.length;) {
            require(!IsInUnion[tokenIds[i]]);
            if (genesisType[tokenIds[i]] == 1) {
                require(_type == 1, 'wrong type for call');
                owed += _claimBakerFromPool(tokenIds[i], unstake, unstake ? seed[i] : 0);
            } else if (genesisType[tokenIds[i]] == 2) {
                require(_type == 2, 'wrong type for call');
                owed += _claimFoodieFromPool(tokenIds[i], unstake, unstake ? seed[i] : 0);
            } else if (genesisType[tokenIds[i]] == 3) {
                require(_type == 3, 'wrong type for call');
                owed += _claimShopOwnerFromPool(tokenIds[i], unstake);
            } else if (genesisType[tokenIds[i]] == 0) {
                revert('invalid token id');
            }
            unchecked{ i++; }
        }
        uint256 vrfAmount = msg.value - DEV_FEE;
        if(vrfAmount > 0) { vrf.transfer(vrfAmount); }
        dev.transfer(DEV_FEE);

        if (owed == 0) {
            return;
        }
        totalTOPIAEarned += owed;
        HUB.pay(msg.sender, owed);
        
    }

    function getTXCost(uint16[] calldata tokenIds, uint8 _type, bool unstake) external view returns (uint256 txCost) {
        if((_type == 1 || _type == 2) && unstake) {
            txCost = DEV_FEE + (SEED_COST * tokenIds.length);
        } else {
            txCost = DEV_FEE;
        }
    }


    /**
     * realize $TOPIA earnings for a single Baker and optionally unstake it
     * if not unstaking, lose x% chance * y% percent of accumulated $TOPIA to the staked Foodies based on it's upgrade
     * if unstaking, there is a % chanc of losing Baker NFT
     * @param tokenId the ID of the Baker to claim earnings from
   * @param unstake whether or not to unstake the Baker
   * @return owed - the amount of $TOPIA earned
   */
    function _claimBakerFromPool(uint16 tokenId, bool unstake, uint256 seed) internal returns (uint256 owed) {       
        require(baker[tokenId].owner == msg.sender, "Don't own the given token");
        if(block.timestamp <= claimEndTime) {
            owed = (block.timestamp - baker[tokenId].value) * DAILY_BAKER_RATE / PERIOD;
        } else if (baker[tokenId].value < claimEndTime) {
            owed = (claimEndTime - baker[tokenId].value) * DAILY_BAKER_RATE / PERIOD;
        } else {
            owed = 0;
        }

        uint256 shopOwnerTax = owed * SHOP_OWNER_TAX_RATE / 10000;
        _payShopOwnerTax(shopOwnerTax);
        uint256 foodieTax = owed * FOODIE_TAX_RATE / 10000;
        _payFoodieTax(foodieTax);
        owed = owed - shopOwnerTax - foodieTax;

        bool stolen = false;
        address thief;
        if (unstake) {
            if ((seed & 0xFFFF) % 100 < 10 && HUB.alphaCount(4) > 0) {
                HUB.stealGenesis(tokenId, seed, 4, 7, msg.sender);
                stolen = true;
            }
            delete baker[tokenId];
            numBakersStaked -= 1;

            if (stolen) {
                emit GenesisStolen (tokenId, msg.sender, thief, 1, block.timestamp);
            } else {
                // Always transfer last to guard against reentrance
                HUB.returnGenesisToOwner(msg.sender, tokenId, 7, 4);
            }
            emit BakerUnStaked(msg.sender, tokenId, block.number, block.timestamp);
        } else {// Claiming
            baker[tokenId].value = uint80(block.timestamp);
            // reset stake
        }
        emit BakerClaimed(tokenId, unstake, owed);
    }

    /**
     * realize $TOPIA earnings for a single Foodie and optionally unstake it
     * Foodies earn $TOPIA
     * @param tokenId the ID of the Foodie to claim earnings from
   * @param unstake whether or not to unstake the Foodie
   */
    function _claimFoodieFromPool(uint16 tokenId, bool unstake, uint256 seed) internal returns (uint256 owed) {
        require(foodie[tokenId].owner == msg.sender, "Doesn't own given token");
        owed = TOPIAPerFoodie - foodie[tokenId].value;

        bool stolen = false;
        address thief;
        if (unstake) {
            if ((seed & 0xFFFF) % 100 < 10 && HUB.shopOwnerCount() > 0) {
                HUB.stealGenesis(tokenId, seed, 4, 8, msg.sender);
                stolen = true;
            }
            delete foodie[tokenId];
            numFoodieStaked -= 1;
            // reset baker to unarmed
            if (stolen) {
                emit GenesisStolen (tokenId, msg.sender, thief, 2, block.timestamp);
            } else {
                // Always transfer last to guard against reentrance
                HUB.returnGenesisToOwner(msg.sender, tokenId, 8, 4);
            }
            emit FoodieUnStaked(msg.sender, tokenId, block.number, block.timestamp);
        } else {
            foodie[tokenId].value = uint80(TOPIAPerFoodie);
            // reset stake
        }
        emit FoodieClaimed(tokenId, unstake, owed);
    }

    /**
     * realize $TOPIA earnings for a ShopOwner Foodie and optionally unstake it
     * Foodies earn $TOPIA
     * @param tokenId the ID of the Foodie to claim earnings from
   * @param unstake whether or not to unstake the ShopOwner Foodie
   */
    function _claimShopOwnerFromPool(uint16 tokenId, bool unstake) internal returns (uint256 owed) {
        require(shopOwner[tokenId].owner == msg.sender, "Doesn't own given token");
        owed = TOPIAPerShopOwner - shopOwner[tokenId].value;
        if (unstake) {
            delete shopOwner[tokenId];
            numShopOwnerStaked -= 1;
            // Always remove last to guard against reentrance
            HUB.returnGenesisToOwner(msg.sender, tokenId, 9, 4);
            // Send back ShopOwner
            emit ShopOwnerUnStaked(msg.sender, tokenId, block.number, block.timestamp);
        } else {
            shopOwner[tokenId].value = uint80(TOPIAPerShopOwner);
            // reset stake

        }
        emit ShopOwnerClaimed(tokenId, unstake, owed);
    }

    /*
  * implement foodie buy pye
  */
  function buyPYE() external payable whenNotPaused nonReentrant returns(uint8) {
    require(tx.origin == msg.sender, "Only EOA");         
    require(msg.value == SEED_COST + DEV_FEE, "Invalid value for randomness");

    HUB.burnFrom(msg.sender, PYE_COST);
    uint256 remainingWords = randomizer.getRemainingWords();
    require(remainingWords >= 1, "Not enough random numbers. Please try again soon.");
    uint256[] memory seed = randomizer.getRandomWords(1);
    uint8 boughtPYE;

    /*
    * Odds of PYE:
    * Dud: 70%
    * Filled PYE: 25%
    * Golden Ticket PYE: 5%
    */
    if ((seed[0] & 0xFFFF) % 100 < 5) {
      boughtPYE = 4;
    } else if((seed[0] & 0xFFFF) % 100 < 25) {
      boughtPYE = 3;
    } else if((seed[0] & 0xFFFF) % 100 < 75) {
      boughtPYE = 2;
    } else {
      boughtPYE = 1;
    }

    if(pyeFilling[boughtPYE] > 0) { 
        HUB.pay(msg.sender, pyeFilling[boughtPYE]); 
    }
    uint256 vrfAmount = msg.value - DEV_FEE;
    if(vrfAmount > 0) { vrf.transfer(vrfAmount); }
    dev.transfer(DEV_FEE);

    emit BoughtPYE(msg.sender, boughtPYE, pyeFilling[boughtPYE], block.timestamp);
    return boughtPYE;
  }

    /** ACCOUNTING */

    /**
     * add $TOPIA to claimable pot for the Foodie Pool
     * @param amount $TOPIA to add to the pot
   */
    function _payFoodieTax(uint256 amount) internal {
        if (numFoodieStaked == 0) {// if there's no staked Foodies
            unaccountedFoodieRewards += amount;
            // keep track of $TOPIA due to Foodies
            return;
        }
        // makes sure to include any unaccounted $GP
        TOPIAPerFoodie += (amount + unaccountedFoodieRewards) / numFoodieStaked;
        unaccountedFoodieRewards = 0;
    }

    /**
     * add $TOPIA to claimable pot for the ShopOwner Pool
     * @param amount $TOPIA to add to the pot
   */
    function _payShopOwnerTax(uint256 amount) internal {
        if (numShopOwnerStaked == 0) {// if there's no staked shopOwners
            unaccountedShopOwnerRewards += amount;
            // keep track of $TOPIA due to shopOwners
            return;
        }
        // makes sure to include any unaccounted $GP
        TOPIAPerShopOwner += (amount + unaccountedShopOwnerRewards) / numShopOwnerStaked;
        unaccountedShopOwnerRewards = 0;
    }

    /** ALPHA FUNCTIONS */

    /**
     * adds Foodies and Baker
     * @param account the address of the staker
   * @param tokenIds the IDs of the Foodies and Baker to stake
   */
    function addManyAlphaToStakingPool(address account, uint16[] calldata tokenIds) external payable nonReentrant {
        require(tx.origin == msg.sender, "Only EOA");
        require(account == tx.origin, "account to send mismatch");
        require(msg.value == DEV_FEE, "need more eth");
        for (uint i = 0; i < tokenIds.length;) {
            require(lfAlpha.ownerOf(tokenIds[i]) == msg.sender, "You don't own this token");
            HUB.receiveAlpha(msg.sender, tokenIds[i], 4);

            alpha[tokenIds[i]] = StakeAlpha({
            owner : account,
            tokenId : uint16(tokenIds[i]),
            value : uint80(block.timestamp),
            stakedAt : uint80(block.timestamp)
            });

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
    function claimManyAlphas(uint16[] calldata tokenIds, bool unstake) external payable whenNotPaused nonReentrant {
        require(tx.origin == msg.sender, "Only EOA");
        require(msg.value == DEV_FEE, "need more eth");
        uint256 owed = 0;
        for (uint i = 0; i < tokenIds.length;) { 
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

                HUB.returnAlphaToOwner(msg.sender, tokenIds[i], 4);
                emit AlphaUnstaked(msg.sender, tokenIds[i], block.number, block.timestamp);
            } else {
                alpha[tokenIds[i]].value = uint80(block.timestamp);
            }
            emit AlphaClaimed(tokenIds[i], unstake, owed);
            unchecked{ i++; }
        }
        dev.transfer(DEV_FEE);
        if (owed == 0) {
            return;
        }
        HUB.pay(msg.sender, owed);
        totalTOPIAEarned += owed;
        
    }

    function isOwner(uint16 tokenId, address owner) external view returns (bool validOwner) {
        if (genesisType[tokenId] == 1) {
            return baker[tokenId].owner == owner;
        } else if (genesisType[tokenId] == 2) {
            return foodie[tokenId].owner == owner;
        } else if (genesisType[tokenId] == 3) {
            return shopOwner[tokenId].owner == owner;
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
        if (genesisType[tokenId] == 1 && baker[tokenId].value > 0) {
            if(block.timestamp <= claimEndTime) {
                return (block.timestamp - baker[tokenId].value) * DAILY_BAKER_RATE / PERIOD;
            } else if (baker[tokenId].value < claimEndTime) {
                return (claimEndTime - baker[tokenId].value) * DAILY_BAKER_RATE / PERIOD;
            } else {
                return 0;
            }
        } else if (genesisType[tokenId] == 2 && foodie[tokenId].owner != address(0)) {
            return TOPIAPerFoodie - foodie[tokenId].value;
        } else if (genesisType[tokenId] == 3) {
            if(IsInWastelands[tokenId]) {
                return WastelandShopOwners[tokenId].value;
            } else if(shopOwner[tokenId].owner != address(0)) {
                return TOPIAPerShopOwner - shopOwner[tokenId].value;
            }
        }
        return owed;
    }

    function updateDailyBakerRate(uint256 _rate) external onlyOwner {
        DAILY_BAKER_RATE = _rate;
    }

    function updateDailyAlphaRate(uint256 _rate) external onlyOwner {
        DAILY_ALPHA_RATE = _rate;
    }
    
    function updateTaxRates(uint16 _foodieRate, uint16 _vetRate) external onlyOwner {
        FOODIE_TAX_RATE = _foodieRate;
        SHOP_OWNER_TAX_RATE = _vetRate;
    }

    function updatePYEFillings(uint256 dudPYE, uint256 filledPYE, uint256 goldenTicketPYE, uint256 pumpkinPYE) external onlyOwner {
        pyeFilling[1] = dudPYE;
        pyeFilling[2] = filledPYE;
        pyeFilling[3] = goldenTicketPYE;
        pyeFilling[4] = pumpkinPYE;
    }
    
    function updatePYECost(uint256 _cost) external onlyOwner {
        PYE_COST = _cost;
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

    function createUnion(uint16[] calldata _tokenIds) external payable nonReentrant notContract() {
        require(!HasUnion[msg.sender] , "You already have a union");
        require(msg.value == DEV_FEE, "need more eth");
        uint16 length = uint16(_tokenIds.length);
        require(length >= minimumForUnion , "Not enough bakers to form a union");
        for (uint16 i = 0; i < length;) {
            require(lfGenesis.ownerOf(_tokenIds[i]) == msg.sender , "not owner");
            require(genesisType[_tokenIds[i]] == 1 , "only bakers can form a union");
            require(!IsInUnion[_tokenIds[i]], "NFT can only be in 1 union");
            baker[_tokenIds[i]] = Stake({
                owner : msg.sender,
                tokenId : _tokenIds[i],
                value : uint80(block.timestamp),
                stakedAt : uint80(block.timestamp)
            });
     
            emit TokenStaked(msg.sender, _tokenIds[i], 1, block.timestamp);
            IsInUnion[_tokenIds[i]] = true;
            unchecked{ i++; }
        }
        GroupLength[msg.sender]+= length;
        numBakersStaked += length;
        HUB.createGroup(_tokenIds, msg.sender, 4);
        HasUnion[msg.sender] = true;
        dev.transfer(DEV_FEE);
    }

    function addToUnion(uint16 _id) external payable nonReentrant notContract() {
        require(HasUnion[msg.sender], "Must have Union!");
        require(msg.value == DEV_FEE, "need more eth");
        require(lfGenesis.ownerOf(_id) == msg.sender, "not owner");
        require(genesisType[_id] == 1 , "must be baker");
        require(!IsInUnion[_id], "NFT can only be in 1 union");
        baker[_id] = Stake({
            owner : msg.sender,
            tokenId : _id,
            value : uint80(block.timestamp),
            stakedAt : uint80(block.timestamp)
            });
     
        emit TokenStaked(msg.sender, _id, 1, block.timestamp);
        GroupLength[msg.sender]++;
        IsInUnion[_id] = true;
        numBakersStaked++;
        HUB.addToGroup(_id, msg.sender, 4);
        dev.transfer(DEV_FEE);
    }

    function claimUnion(uint16[] calldata tokenIds, bool unstake) external payable notContract() {
        require(HasUnion[msg.sender] , "Must own Union");
        uint256 numWords = tokenIds.length;
        uint256[] memory seed;
        uint8 theftModifier;
        
        if(unstake) { 
            if (numWords <= 10) {
                theftModifier = uint8(numWords);
            } else {theftModifier = 10;}
            require(GroupLength[msg.sender] == numWords);
            require(msg.value == DEV_FEE + (SEED_COST * numWords), "need more eth");
            uint256 remainingWords = randomizer.getRemainingWords();
            require(remainingWords >= numWords, "Not enough random numbers try again soon.");
            seed = randomizer.getRandomWords(numWords);
        } else {
            require(msg.value == DEV_FEE, "need more eth");
        }
        
        uint256 owed = 0;
        for (uint i = 0; i < tokenIds.length;) {
            require(genesisType[tokenIds[i]] == 1 , "Must be bakers");
            require(IsInUnion[tokenIds[i]] , "NFT must be in Union");
            require(baker[tokenIds[i]].owner == msg.sender, "!= owner");
            uint256 thisOwed;
   
            if(block.timestamp <= claimEndTime) {
                thisOwed = (block.timestamp - baker[tokenIds[i]].value) * DAILY_BAKER_RATE / PERIOD;
            } else if (baker[tokenIds[i]].value < claimEndTime) {
                thisOwed = (claimEndTime - baker[tokenIds[i]].value) * DAILY_BAKER_RATE / PERIOD;
            } else {
                thisOwed = 0;
            }

            if (unstake) {
                if ((seed[i] & 0xFFFF) % 100 < (10 - theftModifier) && HUB.alphaCount(4) > 0) {
                    address thief = HUB.stealGenesis(tokenIds[i], seed[i], 4, 7, msg.sender);
                    emit GenesisStolen (tokenIds[i], msg.sender, thief, 1, block.timestamp);
                } else {
                    HUB.returnGenesisToOwner(msg.sender, tokenIds[i], 7, 4);
                }
                delete baker[tokenIds[i]];
                IsInUnion[tokenIds[i]] = false;
                emit BakerUnStaked(msg.sender, tokenIds[i], block.number, block.timestamp);

            } else {// Claiming
                baker[tokenIds[i]].value = uint80(block.timestamp);
                // reset stake
            }
            emit BakerClaimed(tokenIds[i], unstake, owed);
            owed += thisOwed;
            unchecked{ i++; }
        }
        if (unstake) {
            HasUnion[msg.sender] = false;
            numBakersStaked -= numWords;
            HUB.unstakeGroup(msg.sender, 4);
            GroupLength[msg.sender] = 0;
        }

        uint256 shopOwnerTax = owed * SHOP_OWNER_TAX_RATE / 10000;
        _payShopOwnerTax(shopOwnerTax);
        uint256 foodieTax = owed * FOODIE_TAX_RATE / 10000;
        _payFoodieTax(foodieTax);
        owed = owed - shopOwnerTax - foodieTax;
        
        uint256 vrfAmount = msg.value - DEV_FEE;
        if (vrfAmount > 0) { vrf.transfer(vrfAmount); }
        dev.transfer(DEV_FEE);

        if (owed == 0) { return; }
        
        totalTOPIAEarned += owed;
        HUB.pay(msg.sender, owed);
    }

    function sendShopOwnerToWastelands(uint16[] calldata _ids) external payable notContract() {
        uint256 numWords = _ids.length;
        require(msg.value == DEV_FEE + (SEED_COST * numWords), "need more eth");
        require(randomizer.getRemainingWords() >= numWords, "Not enough random numbers; try again soon.");
        uint256[] memory seed = randomizer.getRandomWords(numWords);

        for (uint16 i = 0; i < numWords;) {
            require(lfGenesis.ownerOf(_ids[i]) == msg.sender, "not owner");
            require(genesisType[_ids[i]] == 3, "not a ShopOwner");
            require(!IsInWastelands[_ids[i]] , "NFT already in wastelands");

            if (HUB.alienCount() > 0 && (seed[i]) % 100 < 25) { // stolen
                address thief = HUB.stealMigratingGenesis(_ids[i], seed[i], 4, msg.sender, false);
                emit GenesisStolen (_ids[i], msg.sender, thief, 3, block.timestamp);
            } else {
                HUB.migrate(_ids[i], msg.sender, 4, false);
                WastelandShopOwners[_ids[i]].shopOwnerTokenId = _ids[i];
                WastelandShopOwners[_ids[i]].shopOwnerOwner = msg.sender;
                WastelandShopOwners[_ids[i]].value = uint80(WASTELAND_BONUS);
                WastelandShopOwners[_ids[i]].migrationTime = uint80(block.timestamp);
                IsInWastelands[_ids[i]] = true;
                emit ShopOwnerMigrated(msg.sender, _ids[i], false);
            }
            unchecked { i++; }
        }
        uint256 vrfAmount = msg.value - DEV_FEE;
        if (vrfAmount > 0) { vrf.transfer(vrfAmount); }
        dev.transfer(DEV_FEE);
    }

    function claimManyWastelands(uint16[] calldata _ids, bool unstake) external payable notContract() {
        uint256 numWords = _ids.length;
        uint256[] memory seed;

        if(unstake) { 
            require(msg.value == DEV_FEE + (SEED_COST * numWords), "need more eth");
            require(randomizer.getRemainingWords() >= numWords, "Not enough random numbers try again soon.");
            seed = randomizer.getRandomWords(numWords);
        } else {
            require(msg.value == DEV_FEE, "need more eth");
        }
        
        uint256 owed = 0;

        for (uint16 i = 0; i < numWords;) {
            require(IsInWastelands[_ids[i]] , "NFT not in wastelands");
            require(msg.sender == WastelandShopOwners[_ids[i]].shopOwnerOwner , "not owner");
            
            owed += WastelandShopOwners[_ids[i]].value;

            if (unstake) {
                if (HUB.alienCount() > 0 && (seed[i]) % 100 < 25) { // stolen
                    address thief = HUB.stealMigratingGenesis(_ids[i], seed[i], 4, msg.sender, true);
                    emit GenesisStolen (_ids[i], msg.sender, thief, 3, block.timestamp);
                } else {
                    HUB.migrate(_ids[i], msg.sender, 4, true);
                    emit ShopOwnerMigrated(msg.sender, _ids[i], true);
                }
                IsInWastelands[_ids[i]] = false;
                delete WastelandShopOwners[_ids[i]];
            } else {
                WastelandShopOwners[_ids[i]].value = uint80(block.timestamp); // reset value
            }
            emit ShopOwnerClaimed(_ids[i], unstake, owed);
            unchecked { i++; }
        }
        uint256 vrfAmount = msg.value - DEV_FEE;
        if (vrfAmount > 0) { vrf.transfer(vrfAmount); }
        dev.transfer(DEV_FEE);
        
        if (owed == 0) { return; }
        totalTOPIAEarned += owed;
        HUB.pay(msg.sender, owed);
    }
}
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
import "./interfaces/IPYEMarket.sol";
import "./interfaces/IRandomizer.sol";

contract PYEMarket is IPYEMarket, Ownable, ReentrancyGuard, IERC721Receiver, Pausable {
    using EnumerableSet for EnumerableSet.UintSet;

    // maximum rank for a Foodie/Baker
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

    // number of Bakers staked
    uint256 private numBakersStaked;
    // number of Foodie staked
    uint256 private numFoodieStaked;
    // number of ShopOwner staked
    uint256 private numShopOwnerStaked;
    // number of Alpha staked
    uint256 private numAlphasStaked;

    uint256 public PERIOD = 1 days;

    event TokenStaked(address indexed owner, uint256 indexed tokenId, uint8 tokenType, uint256 value);
    event BakerClaimed(uint256 indexed tokenId, bool indexed unstaked, uint256 earned);
    event BakerUnStaked(address indexed owner, uint256 indexed tokenId, uint256 blockNum, uint256 timeStamp);
    event BakerStolen(uint16 indexed tokenId, address indexed victim, address indexed thief, uint256 blockNum, uint256 timeStamp);
    event FoodieClaimed(uint256 indexed tokenId, bool indexed unstaked, uint256 earned);
    event FoodieUnStaked(address indexed owner, uint256 indexed tokenId, uint256 blockNum, uint256 timeStamp);
    event FoodieStolen(uint16 indexed tokenId, address indexed victim, address indexed thief, uint256 blockNum, uint256 timeStamp);
    event ShopOwnerClaimed(uint256 indexed tokenId, bool indexed unstaked, uint256 earned);
    event ShopOwnerUnStaked(address indexed owner, uint256 indexed tokenId, uint256 blockNum, uint256 timeStamp);
    event BoughtPYE(address indexed owner, uint256 indexed tokenId, uint8 boughtPYEType, uint256 rewardInPYE);
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

    // maps Baker tokenId to stake
    mapping(uint256 => Stake) private baker;

    // maps Alpha tokenId to stakeAlpha
    mapping(uint256 => StakeAlpha) private alpha;

    // maps Foodie tokenId to stake
    mapping(uint256 => Stake) private foodie;
    // array of Foodie token ids;
    // uint256[] private yieldIds;
    EnumerableSet.UintSet private foodieIds;
    // maps ShopOwner tokenId to stake
    mapping(uint256 => Stake) private shopOwner;
    // array of ShopOwner token ids;
    EnumerableSet.UintSet private shopOwnerIds;

    mapping(address => uint256) ownerBalanceStaked;

    // array of Owned Genesis token ids;
    mapping(address => EnumerableSet.UintSet) genesisOwnedIds;
    // array of Owned Alpha token ids;
    mapping(address => EnumerableSet.UintSet) alphaOwnedIds;


    // any rewards distributed when no Foodies are staked
    uint256 private unaccountedFoodieRewards;
    // amount of $TOPIA due for each foodie staked
    uint256 private TOPIAPerFoodie;
    // any rewards distributed when no ShopOwners are staked
    uint256 private unaccountedShopOwnerRewards;
    // amount of $TOPIA due for each ShopOwner staked
    uint256 private TOPIAPerShopOwner;

    // Bakers earn 20 $TOPIA per day
    uint256 public DAILY_BAKER_RATE = 20 * 10**18;

    // Bakers earn 35 $TOPIA per day
    uint256 public DAILY_ALPHA_RATE = 35 * 10**18;

    // Bakers must have 2 days worth of $TOPIA to un-stake or else they're still remaining the armory
    uint256 public MINIMUM = 40 * 10**18;

    // rolling price
    uint256 public PYE_COST = 40 * 10**18;

    // ShopOwners take a 3% tax on all $TOPIA claimed
    uint256 public FOODIE_TAX_RATE = 300;

    // ShopOwners take a 3% tax on all $TOPIA from upgrades
    uint256 public SHOP_OWNER_TAX_RATE = 300;

    mapping(uint8 => uint256) pyeFilling;

    // tx cost for getting random numbers
    uint256 public SEED_COST = .0008 ether;

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
     * adds Foodies and Baker
     * @param account the address of the staker
   * @param tokenIds the IDs of the Foodies and Baker to stake
   */
    function addManyToStakingPool(address account, uint16[] calldata tokenIds) external override nonReentrant {
        require(tx.origin == msg.sender, "Only EOA");
        require(account == tx.origin, "account to send mismatch");
        for (uint i = 0; i < tokenIds.length; i++) {
            require(lfGenesis.ownerOf(tokenIds[i]) == msg.sender, "You don't own this token");

            if (genesisType[tokenIds[i]] == 1) {
                lfGenesis.transferFrom(msg.sender, address(this), tokenIds[i]);
                _addBakerToStakingPool(account, tokenIds[i]);
            } else if (genesisType[tokenIds[i]] == 2) {
                lfGenesis.transferFrom(msg.sender, address(this), tokenIds[i]);
                _addFoodieToStakingPool(account, tokenIds[i]);
            } else if (genesisType[tokenIds[i]] == 3) {
                lfGenesis.transferFrom(msg.sender, address(this), tokenIds[i]);
                _addShopOwnerToStakingPool(account, tokenIds[i]);
            } else if (genesisType[tokenIds[i]] == 0) {
                revert('invalid token id');
            }

        }
        HUB.emitGenesisStaked(account, tokenIds, 3);
    }

    /**
     * adds a single Foodie to the Armory
     * @param account the address of the staker
   * @param tokenId the ID of the Foodie/ShopOwner to add to the Staking Pool
   */
    function _addFoodieToStakingPool(address account, uint256 tokenId) internal whenNotPaused {
        foodie[tokenId] = Stake({
        owner : account,
        tokenId : uint16(tokenId),
        value : uint80(TOPIAPerFoodie),
        stakedAt : uint80(block.timestamp)
        });
        foodieIds.add(tokenId);
        genesisOwnedIds[account].add(tokenId);
        numFoodieStaked += 1;
        emit TokenStaked(account, tokenId, 2, TOPIAPerFoodie);
    }


    /**
     * adds a single ShopOwner to the Armory
     * @param account the address of the staker
   * @param tokenId the ID of the Foodie/ShopOwner to add to the Staking Pool
   */
    function _addShopOwnerToStakingPool(address account, uint256 tokenId) internal whenNotPaused {
        shopOwner[tokenId] = Stake({
        owner : account,
        tokenId : uint16(tokenId),
        value : uint80(TOPIAPerShopOwner),
        stakedAt : uint80(block.timestamp)
        });
        shopOwnerIds.add(tokenId);
        genesisOwnedIds[account].add(tokenId);
        numShopOwnerStaked += 1;
        emit TokenStaked(account, tokenId, 3, TOPIAPerShopOwner);
    }


    /**
     * adds a single Baker to the armory
     * @param account the address of the staker
   * @param tokenId the ID of the Baker to add to the Staking Pool
   */
    function _addBakerToStakingPool(address account, uint256 tokenId) internal {
        baker[tokenId] = Stake({
        owner : account,
        tokenId : uint16(tokenId),
        value : uint80(block.timestamp),
        stakedAt : uint80(block.timestamp)
        });
        // Add the baker to the armory
        genesisOwnedIds[account].add(tokenId);
        numBakersStaked += 1;
        emit TokenStaked(account, tokenId, 1, block.timestamp);
    }

    /** CLAIMING / UNSTAKING */

    /**
     * realize $TOPIA earnings and optionally unstake tokens from the Armory / Yield
     * to unstake a Baker it will require it has 2 days worth of $TOPIA unclaimed
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
                (uint256 _owed, uint16 _stolen) = _claimBakerFromArmory(tokenIds[i], unstake, seed[i]);
                owed += _owed;
                if(unstake) {stolenNFTs[i] = _stolen;}
            } else if (genesisType[tokenIds[i]] == 2) {
                owed += _claimFoodieFromYield(tokenIds[i], unstake);
            } else if (genesisType[tokenIds[i]] == 3) {
                owed += _claimShopOwnerFromYield(tokenIds[i], unstake);
            } else if (genesisType[tokenIds[i]] == 0) {
                revert('invalid token id');
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
     * realize $TOPIA earnings for a single Baker and optionally unstake it
     * if not unstaking, lose x% chance * y% percent of accumulated $TOPIA to the staked Foodies based on it's upgrade
     * if unstaking, there is a % chanc of losing Baker NFT
     * @param tokenId the ID of the Baker to claim earnings from
   * @param unstake whether or not to unstake the Baker
   * @return owed - the amount of $TOPIA earned
   */
    function _claimBakerFromArmory(uint16 tokenId, bool unstake, uint256 seed) internal returns (uint256 owed , uint16 tokId) {       
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
            if ((seed & 0xFFFF) % 100 < 10) {
                thief = randomFoodieOwner(seed);
                lfGenesis.safeTransferFrom(address(this), thief, tokenId);
                stolen = true;
            }
            delete baker[tokenId];
            numBakersStaked -= 1;
            genesisOwnedIds[msg.sender].remove(tokenId);
            // reset baker to unarmed
            if (stolen) {
                emit BakerStolen(tokenId, msg.sender, thief, block.number, block.timestamp);
                tokId = tokenId;
            } else {
                // Always transfer last to guard against reentrance
                lfGenesis.safeTransferFrom(address(this), msg.sender, tokenId, "");
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
    function _claimFoodieFromYield(uint16 tokenId, bool unstake) internal returns (uint256 owed) {
        require(foodie[tokenId].owner == msg.sender, "Doesn't own given token");
        owed = TOPIAPerFoodie - foodie[tokenId].value;
        if (unstake) {
            delete foodie[tokenId];
            foodieIds.remove(tokenId);
            genesisOwnedIds[msg.sender].remove(tokenId);
            numFoodieStaked -= 1;
            // Always remove last to guard against reentrance
            lfGenesis.safeTransferFrom(address(this), msg.sender, tokenId, "");
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
    function _claimShopOwnerFromYield(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
        require(shopOwner[tokenId].owner == msg.sender, "Doesn't own given token");
        owed = TOPIAPerShopOwner - shopOwner[tokenId].value;
        if (unstake) {
            delete shopOwner[tokenId];
            shopOwnerIds.remove(tokenId);
            genesisOwnedIds[msg.sender].remove(tokenId);
            numShopOwnerStaked -= 1;
            // Always remove last to guard against reentrance
            lfGenesis.safeTransferFrom(address(this), msg.sender, tokenId, "");
            // Send back ShopOwner
            emit ShopOwnerUnStaked(msg.sender, tokenId, block.number, block.timestamp);
        } else {
            shopOwner[tokenId].value = uint80(TOPIAPerShopOwner);
            // reset stake

        }
        emit ShopOwnerClaimed(tokenId, unstake, owed);
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
                require(baker[tokenId].owner == msg.sender, "SWIPER, NO SWIPING");
                delete baker[tokenId];
                genesisOwnedIds[msg.sender].remove(tokenId);
                numBakersStaked -= 1;
                lfGenesis.safeTransferFrom(address(this), msg.sender, tokenId, "");
                emit BakerClaimed(tokenId, true, 0);
            } else if (genesisType[tokenId] == 2) {
                require(foodie[tokenId].owner == msg.sender, "SWIPER, NO SWIPING");
                delete foodie[tokenId];
                foodieIds.remove(tokenId);
                genesisOwnedIds[msg.sender].remove(tokenId);
                numFoodieStaked -= 1;
                lfGenesis.safeTransferFrom(address(this), msg.sender, tokenId, "");
                emit FoodieClaimed(tokenId, true, 0);
            } else if (genesisType[tokenId] == 3) {
                require(shopOwner[tokenId].owner == msg.sender, "SWIPER, NO SWIPING");
                delete shopOwner[tokenId];
                shopOwnerIds.remove(tokenId);
                genesisOwnedIds[msg.sender].remove(tokenId);
                numShopOwnerStaked -= 1;
                lfGenesis.safeTransferFrom(address(this), msg.sender, tokenId, "");
                emit ShopOwnerClaimed(tokenId, true, 0);
            } else if (genesisType[tokenIds[i]] == 0) {
                revert('invalid token id');
            }
        }
        HUB.emitGenesisUnstaked(msg.sender, tokenIds);
    }

    /*
  * implement foodie buy pye
  */
  function buyPYE(uint16 tokenId) external payable whenNotPaused nonReentrant returns(uint8) {
    require(tx.origin == msg.sender, "Only EOA");         
    require(foodie[tokenId].owner == msg.sender, "Don't own the given token");
    require(genesisType[tokenId] == 2, "affected only for Foodie NFTs");
    require(msg.value == SEED_COST, "Invalid value for randomness");

    TOPIAToken.burnFrom(msg.sender, PYE_COST);
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
      boughtPYE = 3;
    } else if((seed[0] & 0xFFFF) % 100 < 30) {
      boughtPYE = 2;
    } else {
      boughtPYE = 1;
    }

    if(pyeFilling[boughtPYE] > 0) { 
        TOPIAToken.mint(msg.sender, pyeFilling[boughtPYE]); 
        HUB.emitTopiaClaimed(msg.sender, pyeFilling[boughtPYE]);
    }
    vrf.transfer(msg.value);

    emit BoughtPYE(msg.sender, tokenId, boughtPYE, pyeFilling[boughtPYE]);
    return boughtPYE;
  }

    /** ACCOUNTING */

    /**
     * add $TOPIA to claimable pot for the Foodie Yield
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
     * add $TOPIA to claimable pot for the ShopOwner Yield
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
            // Add the baker to the armory
            alphaOwnedIds[account].add(tokenIds[i]);
            numAlphasStaked += 1;
            emit AlphaStaked(account, tokenIds[i], block.timestamp);
        }
        HUB.emitAlphaStaked(account, tokenIds, 3);
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
        } else if (genesisType[tokenId] == 3 && shopOwner[tokenId].owner != address(0)) {
            return TOPIAPerShopOwner - shopOwner[tokenId].value;
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
                    owed += (block.timestamp - baker[tokenId].value) * DAILY_BAKER_RATE / PERIOD;
                } else if (baker[tokenId].value < claimEndTime) {
                    owed += (claimEndTime - baker[tokenId].value) * DAILY_BAKER_RATE / PERIOD;
                } else {
                    owed += 0;
                }
            } else if (genesisType[tokenId] == 2) {
                owed += TOPIAPerFoodie - foodie[tokenId].value;
            } else if (genesisType[tokenId] == 3) {
                owed += TOPIAPerShopOwner - shopOwner[tokenId].value;
            } else if (genesisType[tokenId] == 0) {
                continue;
            }
        }
        for (uint i = 0; i < alphaLength; i++) {
            uint16 tokenId = uint16(alphaOwnedIds[_account].at(i));
            if(block.timestamp <= claimEndTime) {
                owed += (block.timestamp - alpha[tokenId].value) * DAILY_ALPHA_RATE / PERIOD;
            } else if (alpha[tokenId].value < claimEndTime) {
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
     * chooses a random Foodie thief when an unstaking token is stolen
     * @param seed a random value to choose a Foodie from
   * @return the owner of the randomly selected Baker thief
   */
    function randomFoodieOwner(uint256 seed) internal view returns (address) {
        if (foodieIds.length() == 0) {
            return address(0x0);
        }
        uint256 bucket = (seed & 0xFFFFFFFF) % foodieIds.length();
        return foodie[foodieIds.at(bucket)].owner;
    }

    /**
     * chooses a random ShopOwner thief when a an unstaking token is stolen
     * @param seed a random value to choose a ShopOwner from
   * @return the owner of the randomly selected Foodie thief
   */
    function randomShopOwnerOwner(uint256 seed) internal view returns (address) {
        if (shopOwnerIds.length() == 0) {
            return address(0x0);
        }
        uint256 bucket = (seed & 0xFFFFFFFF) % shopOwnerIds.length();
        return shopOwner[shopOwnerIds.at(bucket)].owner;
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

    function updateDailyBakerRate(uint256 _rate) external onlyOwner {
        DAILY_BAKER_RATE = _rate;
    }

    function updateDailyAlphaRate(uint256 _rate) external onlyOwner {
        DAILY_ALPHA_RATE = _rate;
    }
    
    function updateTaxRates(uint8 _foodieRate, uint8 _vetRate) external onlyOwner {
        FOODIE_TAX_RATE = _foodieRate;
        SHOP_OWNER_TAX_RATE = _vetRate;
    }

    function updatePYEFillings(uint256 dudPYE, uint256 filledPYE, uint256 goldenTicketPYE) external onlyOwner {
        pyeFilling[1] = dudPYE;
        pyeFilling[2] = filledPYE;
        pyeFilling[3] = goldenTicketPYE;
    }
    
    function updatePYECost(uint256 _cost) external onlyOwner {
        PYE_COST = _cost;
    }

    function updateSeedCost(uint256 _cost) external onlyOwner {
        SEED_COST = _cost;
    }

    function closeSeasonEearnings(uint80 _timestamp) external onlyOwner {
        claimEndTime = _timestamp;
    }
}
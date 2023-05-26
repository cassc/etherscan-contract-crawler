// SPDX-License-Identifier: MIT LICENSE
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/ICoinFlip.sol";
import "../interfaces/IRandomizer.sol";
import "../interfaces/IHUB.sol";

contract BullRun is Ownable, ReentrancyGuard {

    address payable public RandomizerContract = payable(0xF9439027c8A21E1375CCDFf31c46ca21f8603305); // VRF contract to decide nft stealing
    address payable dev;
    address public betContract = 0x3e8e72A8656F58Ec6ccD4984b1DD55c1a1530bf7;
    IERC721 public Genesis = IERC721(0x810FeDb4a6927D02A6427f7441F6110d7A1096d5); // Genesis NFT contract
    IERC721 public Alpha = IERC721(0x96Af517c414B3726c1B2Ecc744ebf9d292DCbF60); // Alpha NFT contract

    ICoinFlip private CoinFlipInterface = ICoinFlip(0xF1527e5673f233cA90AE29E6F74eEf5311757900);
    IRandomizer private RandomizerInterface = IRandomizer(0xF9439027c8A21E1375CCDFf31c46ca21f8603305);
    IHUB public HubInterface = IHUB(0xA26f87b847B0caD7e490E9F94393Bc9ac124eF55);

    mapping(uint16 => uint8) public NFTType; // tokenID (ID #) => nftID (1 = runner, 2 = bull.. etc)
    mapping(uint8 => uint8) public Risk; // NFT TYPE (not NFT ID) => % chance to get stolen
    mapping(uint16 => bool) public IsNFTStaked; // whether or not an NFT ID # is staked
    mapping(uint16 => Stake) public StakedNFTInfo; // tokenID to stake info
    mapping(address => uint16) public NumberOfStakedNFTs; // the number of NFTs a wallet has staked;
    mapping(uint16 => Stake) public StakedAlphaInfo; // tokenID to stake info
    mapping(uint16 => Migration) public WastelandMatadors; // for matadors sent to wastelands
    mapping(uint16 => bool) public IsAlphaStaked; // whether or not an NFT ID # is staked
    mapping(address => uint16) public NumberOfStakedAlphas; // the number of NFTs a wallet has staked;
    mapping(uint16 => bool) public IsInWastelands; // if matador token ID is in the wastelands
    mapping(uint16 => bool) public IsInMob; // if NFT ID is in a mob or not
    mapping(address => bool) public HasMob; // if a wallet has a mob or not
    mapping(address => uint16) public GroupLength;

    // ID used to identify type of NFT being staked
    uint8 public constant RunnerId = 1;
    uint8 public constant BullId = 2;
    uint8 public constant MatadorId = 3;
    uint8 public minimumForMob;

    // keeps track of total NFT's staked
    uint16 public stakedRunners;
    uint16 public stakedBulls;
    uint16 public stakedMatadors;
    uint16 public stakedAlphas;
    uint16 public migratedMatadors;

    // any rewards distributed when no Alphas are staked
    uint256 private unaccountedAlphaRewards;
    // amount of $TOPIA due for each Alpha staked
    uint256 private TOPIAPerAlpha;

    uint256 public runnerRewardMult;
    uint256 public bullRewardMult;
    uint256 public matadorRewardMult;
    uint256 public alphaRewardMult;

    uint256 public totalTOPIAEarned;
    // the last time $TOPIA can be earned
    uint80 public claimEndTime = 1669662000;
    uint256 public constant PERIOD = 1440 minutes;
    uint256 public SEED_COST = 0.0005 ether;
    uint256 public DEV_FEE = .0018 ether;
    // for staked tier 3 nfts
    uint256 public WASTELAND_BONUS = 100 ether;

    // struct to store a stake's token, owner, and earning values
    struct Stake {
        uint16 tokenID;
        address owner; // the wallet that staked it
        uint80 stakeTimestamp; // when this particular NFT is staked.
        uint8 typeOfNFT; // (1 = runner, 2 = bull, 3 = matador, etc)
        uint256 value; // for reward calcs.
    }

    struct Migration {
        uint16 matadorTokenId;
        address matadorOwner;
        uint80 value;
        uint80 migrationTime;
    }

    event RunnerStaked (address indexed staker, uint16[] stakedIDs);
    event BullStaked (address indexed staker, uint16[] stakedIDs);
    event MatadorStaked (address indexed staker, uint16[] stakedIDs);
    event AlphaStaked (address indexed staker, uint16 stakedID);
    event RunnerUnstaked (address indexed staker, uint16 unstakedID);
    event BullUnstaked (address indexed staker, uint16 unstakedID);
    event MatadorUnstaked (address indexed staker, uint16 unstakedID);
    event AlphaUnstaked (address indexed staker, uint16 unstakedID);
    event TopiaClaimed (address indexed claimer, uint256 amount);
    event AlphaClaimed(uint16 indexed tokenId, bool indexed unstaked, uint256 earned);
    event BetRewardClaimed (address indexed claimer, uint256 amount);
    event MatadorMigrated (address indexed migrator, uint16 id, bool returning);
    event MatadorClaimed (uint256 _amount);
    event GenesisStolen (uint16 indexed tokenId, address victim, address thief, uint8 nftType, uint256 timeStamp);
 
    // @param: _minStakeTime should be # of SECONDS (ex: if minStakeTime is 1 day, pass 86400)
    // @param: _runner/bull/alphaMult = number of topia per period
    constructor(uint8 _minimumForMob) {

        Risk[1] = 10; // runners
        Risk[2] = 10; // bulls

        runnerRewardMult = 5 ether;
        bullRewardMult = 8 ether;
        matadorRewardMult = 8 ether;
        alphaRewardMult = 10 ether;
        minimumForMob = _minimumForMob;

        dev = payable(msg.sender);
    }
     
    receive() external payable {}

    // INTERNAL HELPERS ----------------------------------------------------

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

    modifier onlyBetContract() {
        require(msg.sender == betContract, "Only Bet Contract can call");
        _;
    }

    // SETTERS ----------------------------------------------------

    function setRNGContract(address _coinFlipContract) external onlyOwner {
        CoinFlipInterface = ICoinFlip(_coinFlipContract);
    }

    function updateDevCost(uint256 _cost) external onlyOwner {
        DEV_FEE = _cost;
    }

    function updateDev(address payable _dev) external onlyOwner {
        dev = _dev;
    }

    function setHUB(address _hub) external onlyOwner {
        HubInterface = IHUB(_hub);
    }

    function setRandomizer(address _randomizer) external onlyOwner {
        RandomizerContract = payable(_randomizer);
        RandomizerInterface = IRandomizer(_randomizer);
    }

    function setBetContract(address _bet) external onlyOwner {
        betContract = _bet;
    }

    function setMinimumForMob(uint8 _min) external onlyOwner {
        minimumForMob = _min;
    }
    
    function setPaymentMultipliers(uint8 _runnerMult, uint8 _bullMult, uint8 _alphaMult) external onlyOwner {
        runnerRewardMult = _runnerMult;
        bullRewardMult = _bullMult;
        alphaRewardMult = _alphaMult;
    }

    function setRisks(uint8 _runnerRisk, uint8 _bullRisk) external onlyOwner {
        Risk[0] = _runnerRisk;
        Risk[1] = _bullRisk;
    }

    function setSeedCost(uint256 _cost) external onlyOwner {
        SEED_COST = _cost;
    }

    function setClaimEndTime(uint80 _time) external onlyOwner {
        claimEndTime = _time;
    }

    // mass update the nftType mapping
    function setBatchNFTType(uint16[] calldata _idNumbers, uint8[] calldata _types) external onlyOwner {
        require(_idNumbers.length == _types.length);
        for (uint16 i = 0; i < _idNumbers.length;) {
            require(_types[i] != 0 && _types[i] <= 3);
            NFTType[_idNumbers[i]] = _types[i];
            unchecked{ i++; }
        }
    }

    function setWastelandsBonus(uint256 _bonus) external onlyOwner {
        WASTELAND_BONUS = _bonus;
    }

    // CLAIM FUNCTIONS ----------------------------------------------------    

    function claimManyGenesis(uint16[] calldata tokenIds, uint8 _type, bool unstake) external payable nonReentrant {
        uint256 numWords = tokenIds.length;
        uint256[] memory seed;

        if((_type == 1 || _type == 2) && unstake) {
            uint256 remainingWords = RandomizerInterface.getRemainingWords();
            require(remainingWords >= numWords, "try again soon.");
            require(msg.value == DEV_FEE + (SEED_COST * numWords), "incorrect eth");
            RandomizerContract.transfer(SEED_COST * numWords);
            dev.transfer(DEV_FEE);
            seed = RandomizerInterface.getRandomWords(numWords);
        } else {
            require(msg.value == DEV_FEE, "incorrect eth");
            dev.transfer(DEV_FEE);
        }
        
        uint256 owed = 0;
        for (uint i = 0; i < tokenIds.length;) {
            if (NFTType[tokenIds[i]] == 1) {
                require(!IsInMob[tokenIds[i]], "id in mob");
                (uint256 _owed) = claimRunner(tokenIds[i], unstake, unstake ? seed[i] : 0);
                owed += _owed;
            } else if (NFTType[tokenIds[i]] == 2) {
                (uint256 _owed) = claimBull(tokenIds[i], unstake, unstake ? seed[i] : 0);
                owed += _owed;
            } else if (NFTType[tokenIds[i]] == 3) {
                owed += claimMatador(tokenIds[i], unstake);
            } else if (NFTType[tokenIds[i]] == 0) {
                revert("Invalid Token Id");
            }
            unchecked{ i++; }
        }
        if (owed == 0) {
            return;
        }
        totalTOPIAEarned += owed;
        emit TopiaClaimed(msg.sender, owed);
        HubInterface.pay(msg.sender, owed);
    }

    function claimManyAlphas(uint16[] calldata _tokenIds, bool unstake) external payable nonReentrant {
        uint256 owed = 0;
        uint16 length = uint16(_tokenIds.length);
        require(msg.value == DEV_FEE, "need more eth");
        for (uint i = 0; i < length;) { 
            require(StakedAlphaInfo[_tokenIds[i]].owner == msg.sender, "not owner");
            owed += (block.timestamp - StakedAlphaInfo[_tokenIds[i]].stakeTimestamp) * alphaRewardMult / PERIOD;
            owed += (TOPIAPerAlpha - StakedAlphaInfo[_tokenIds[i]].value);
            if (unstake) {
                delete StakedAlphaInfo[_tokenIds[i]];
                stakedAlphas -= 1;
                HubInterface.returnAlphaToOwner(msg.sender, _tokenIds[i], 1);
                NumberOfStakedNFTs[msg.sender] -= uint16(_tokenIds.length);
                
                emit AlphaUnstaked(msg.sender, _tokenIds[i]);
            } else {
                StakedAlphaInfo[_tokenIds[i]].stakeTimestamp = uint80(block.timestamp);
                StakedAlphaInfo[_tokenIds[i]].value = TOPIAPerAlpha;
            }
            emit AlphaClaimed(_tokenIds[i], unstake, owed);
            unchecked{ i++; }
        }
        dev.transfer(DEV_FEE);
        if (owed == 0) {
            return;
        }
        HubInterface.pay(msg.sender, owed);
        emit TopiaClaimed(msg.sender, owed);
    }

    function getTXCost(uint16[] calldata tokenIds, uint8 _type) external view returns (uint256 txCost) {
        if(_type == 1) {
            txCost = DEV_FEE + (SEED_COST * tokenIds.length);
        } else {
            txCost = DEV_FEE;
        }
    } 

    // STAKING FUNCTIONS ----------------------------------------------------

    function stakeMany(uint16[] calldata _tokenIds) external payable nonReentrant notContract() {
        uint16 length = uint16(_tokenIds.length);
        uint8[] memory identifiers = new uint8[](length);
        require(msg.value == DEV_FEE, "need more eth");

        for (uint i = 0; i < _tokenIds.length;) {
            require(Genesis.ownerOf(_tokenIds[i]) == msg.sender, "not owner");

            if (NFTType[_tokenIds[i]] == 1) {
                identifiers[i] = 1;
                IsNFTStaked[_tokenIds[i]] = true;
                StakedNFTInfo[_tokenIds[i]].tokenID = _tokenIds[i];
                StakedNFTInfo[_tokenIds[i]].owner = msg.sender;
                StakedNFTInfo[_tokenIds[i]].stakeTimestamp = uint80(block.timestamp);
                StakedNFTInfo[_tokenIds[i]].value = uint80(block.timestamp);
                StakedNFTInfo[_tokenIds[i]].typeOfNFT = 1;
                stakedRunners++;
            } else if (NFTType[_tokenIds[i]] == 2) {
                identifiers[i] = 2;
                IsNFTStaked[_tokenIds[i]] = true;
                StakedNFTInfo[_tokenIds[i]].tokenID = _tokenIds[i];
                StakedNFTInfo[_tokenIds[i]].owner = msg.sender;
                StakedNFTInfo[_tokenIds[i]].stakeTimestamp = uint80(block.timestamp);
                StakedNFTInfo[_tokenIds[i]].value = uint80(block.timestamp);
                StakedNFTInfo[_tokenIds[i]].typeOfNFT = 2;
                stakedBulls++;
            } else if (NFTType[_tokenIds[i]] == 3) {
                identifiers[i] = 3;
                IsNFTStaked[_tokenIds[i]] = true;
                StakedNFTInfo[_tokenIds[i]].tokenID = _tokenIds[i];
                StakedNFTInfo[_tokenIds[i]].owner = msg.sender;
                StakedNFTInfo[_tokenIds[i]].stakeTimestamp = uint80(block.timestamp);
                StakedNFTInfo[_tokenIds[i]].value = uint80(block.timestamp);
                StakedNFTInfo[_tokenIds[i]].typeOfNFT = 3;
                stakedMatadors++;
            } else if (NFTType[_tokenIds[i]] == 0) {
                revert("invalid NFT");
            }
            unchecked{ i++; }
        }
        NumberOfStakedNFTs[msg.sender]+= length;
        dev.transfer(DEV_FEE);
        HubInterface.receieveManyGenesis(msg.sender, _tokenIds, identifiers, 1);
    }


    function claimRunner(uint16 tokenId, bool unstake, uint256 seed) internal returns (uint256 owed) {
        require(StakedNFTInfo[tokenId].owner == msg.sender, "not owner");
        
        if(block.timestamp <= claimEndTime) {
            owed = (block.timestamp - StakedNFTInfo[tokenId].value) * runnerRewardMult / PERIOD;
        } else if (StakedNFTInfo[tokenId].value < claimEndTime) {
            owed = (claimEndTime - StakedNFTInfo[tokenId].value) * runnerRewardMult / PERIOD;
        } else {
            owed = 0;
        }

        if(unstake) {
            IsNFTStaked[tokenId] = false;
            delete StakedNFTInfo[tokenId]; // reset the struct for this token ID

            if (HubInterface.alphaCount(1) > 0 && (seed % 100) < Risk[1]) { // nft gets stolen
                address thief = HubInterface.stealGenesis(tokenId, seed, 1, 1, msg.sender);
                emit GenesisStolen (tokenId, msg.sender, thief, 1, block.timestamp);
            } else {
                HubInterface.returnGenesisToOwner(msg.sender, tokenId, 1, 1);
                emit RunnerUnstaked(msg.sender, tokenId);
            }
            
            stakedRunners--;
            NumberOfStakedNFTs[msg.sender]--;
        } else {
            StakedNFTInfo[tokenId].value = uint80(block.timestamp); // reset the stakeTime for this NFT
        }
    }

    function claimBull(uint16 tokenId, bool unstake, uint256 seed) internal returns (uint256 owed) {
        require(StakedNFTInfo[tokenId].owner == msg.sender, "not owner");
        
        if(block.timestamp <= claimEndTime) {
            owed = (block.timestamp - StakedNFTInfo[tokenId].value) * bullRewardMult / PERIOD;
        } else if (StakedNFTInfo[tokenId].value < claimEndTime) {
            owed = (claimEndTime - StakedNFTInfo[tokenId].value) * bullRewardMult / PERIOD;
        } else {
            owed = 0;
        }

        if(unstake) {
            IsNFTStaked[tokenId] = false;
            delete StakedNFTInfo[tokenId]; // reset the struct for this token ID

            if (HubInterface.matadorCount() > 0 && (seed % 100) < Risk[2]) { // nft gets stolen
                address thief = HubInterface.stealGenesis(tokenId, seed, 1, 2, msg.sender);
                emit GenesisStolen (tokenId, msg.sender, thief, 2, block.timestamp);
            } else {
                HubInterface.returnGenesisToOwner(msg.sender, tokenId, 2, 1);
                emit BullUnstaked(msg.sender, tokenId);
            }

            stakedBulls--;
            NumberOfStakedNFTs[msg.sender]--;
        } else {
            StakedNFTInfo[tokenId].value = uint80(block.timestamp); // reset the stakeTime for this NFT 
        }
    }

    function claimMatador(uint16 tokenID, bool unstake) internal returns (uint256 owed) {
        require(StakedNFTInfo[tokenID].owner == msg.sender, "not owner");

        if(block.timestamp <= claimEndTime) {
            owed = (block.timestamp - StakedNFTInfo[tokenID].value) * matadorRewardMult / PERIOD;
        } else if (StakedNFTInfo[tokenID].value < claimEndTime) {
            owed = (claimEndTime - StakedNFTInfo[tokenID].value) * matadorRewardMult / PERIOD;
        } else {
            owed = 0;
        }

        if(unstake) {
            IsNFTStaked[tokenID] = false;
            delete StakedNFTInfo[tokenID]; // reset the struct for this token ID
            HubInterface.returnGenesisToOwner(msg.sender, tokenID, 3, 1);

            stakedMatadors--;
            NumberOfStakedNFTs[msg.sender]--;
            emit MatadorUnstaked(msg.sender, tokenID);
        } else {
            StakedNFTInfo[tokenID].value = uint80(block.timestamp);
        }
    }

    function stakeManyAlphas(uint16[] calldata _tokenIds) external payable nonReentrant {
        require(tx.origin == msg.sender, "Only EOA");
        require(msg.value == DEV_FEE, "need more eth");
        for (uint i = 0; i < _tokenIds.length;) {
            require(Alpha.ownerOf(_tokenIds[i]) == msg.sender, "not owner");
            
            IsAlphaStaked[_tokenIds[i]] = true;
            StakedAlphaInfo[_tokenIds[i]].tokenID = _tokenIds[i];
            StakedAlphaInfo[_tokenIds[i]].owner = msg.sender;
            StakedAlphaInfo[_tokenIds[i]].stakeTimestamp = uint80(block.timestamp);
            StakedAlphaInfo[_tokenIds[i]].value = TOPIAPerAlpha;
            StakedAlphaInfo[_tokenIds[i]].typeOfNFT = 0;
            HubInterface.receiveAlpha(msg.sender, _tokenIds[i], 1);

            stakedAlphas++;
            NumberOfStakedAlphas[msg.sender]++;
            NumberOfStakedNFTs[msg.sender]++;
            emit AlphaStaked(msg.sender, _tokenIds[i]);
            unchecked{ i++; }
        }
        dev.transfer(DEV_FEE);
    }

    function getUnclaimedAlpha(uint16 tokenId) external view returns (uint256 owed) {
        owed += (block.timestamp - StakedAlphaInfo[tokenId].stakeTimestamp) * alphaRewardMult / PERIOD;
        owed += (TOPIAPerAlpha - StakedAlphaInfo[tokenId].value);
        return owed;
    }

    function getUnclaimedGenesis(uint16 tokenId) external view returns (uint256 owed) {
        if (!IsNFTStaked[tokenId]) { return 0; }
        if (NFTType[tokenId] == 1) {
            if (block.timestamp <= claimEndTime) {
                owed = (block.timestamp - StakedNFTInfo[tokenId].value) * runnerRewardMult / PERIOD;
            } else if (StakedNFTInfo[tokenId].value < claimEndTime) {
                owed = (claimEndTime - StakedNFTInfo[tokenId].value) * runnerRewardMult / PERIOD;
            } else {
                owed = 0;
            }
        } else if (NFTType[tokenId] == 2) {
            if (block.timestamp <= claimEndTime) {
                owed = (block.timestamp - StakedNFTInfo[tokenId].value) * bullRewardMult / PERIOD;
            } else if (StakedNFTInfo[tokenId].value < claimEndTime) {
                owed = (claimEndTime - StakedNFTInfo[tokenId].value) * bullRewardMult / PERIOD;
            } else {
                owed = 0;
            }
        } else if (NFTType[tokenId] == 3) {
            if (IsInWastelands[tokenId]) {
                owed = WastelandMatadors[tokenId].value;
            } else if(block.timestamp <= claimEndTime) {
                owed = (block.timestamp - StakedNFTInfo[tokenId].value) * matadorRewardMult / PERIOD;
            } else if (StakedNFTInfo[tokenId].value < claimEndTime) {
                owed = (claimEndTime - StakedNFTInfo[tokenId].value) * matadorRewardMult / PERIOD;
            } else {
                owed = 0;
            }
        }
        return owed;
    }

    function createMob(uint16[] calldata _tokenIds) external payable nonReentrant notContract() {
        require(msg.value == DEV_FEE, "need more eth");
        require(!HasMob[msg.sender] , "already have a mob");
        uint16 length = uint16(_tokenIds.length);
        require(length >= minimumForMob , "Not enough runners");
        for (uint16 i = 0; i < length;) {
            require(Genesis.ownerOf(_tokenIds[i]) == msg.sender, "not owner");
            require(NFTType[_tokenIds[i]] == 1 , "only runner");
            require(!IsInMob[_tokenIds[i]], "NFT in mob");
            IsNFTStaked[_tokenIds[i]] = true;
            StakedNFTInfo[_tokenIds[i]].tokenID = _tokenIds[i];
            StakedNFTInfo[_tokenIds[i]].owner = msg.sender;
            StakedNFTInfo[_tokenIds[i]].stakeTimestamp = uint80(block.timestamp);
            StakedNFTInfo[_tokenIds[i]].value = uint80(block.timestamp);
            StakedNFTInfo[_tokenIds[i]].typeOfNFT = 1;
            IsInMob[_tokenIds[i]] = true;
            unchecked{ i++; }
        }
        GroupLength[msg.sender] = length;
        stakedRunners+= length;
        HubInterface.createGroup(_tokenIds, msg.sender, 1);
        HasMob[msg.sender] = true;
        dev.transfer(DEV_FEE);
    }

    function addToMob(uint16 _id) external payable nonReentrant notContract() {
        require(msg.value == DEV_FEE, "need more eth");
        require(HasMob[msg.sender], "Must have Mob!");
        require(Genesis.ownerOf(_id) == msg.sender, "not owner");
        require(NFTType[_id] == 1 , "must be runner");
        require(!IsInMob[_id], "NFT can only be in 1 mob");
        IsNFTStaked[_id] = true;
        StakedNFTInfo[_id].tokenID = _id;
        StakedNFTInfo[_id].owner = msg.sender;
        StakedNFTInfo[_id].stakeTimestamp = uint80(block.timestamp);
        StakedNFTInfo[_id].value = uint80(block.timestamp);
        StakedNFTInfo[_id].typeOfNFT = 1;
        IsInMob[_id] = true;
        stakedRunners++;
        GroupLength[msg.sender]++;
        HubInterface.addToGroup(_id, msg.sender, 1);
        dev.transfer(DEV_FEE);
    }

    function claimMob(uint16[] calldata tokenIds, bool unstake) external payable notContract() {
        require(HasMob[msg.sender] , "Must have a Mob");
        uint256 numWords = tokenIds.length;
        uint256[] memory seed;
        uint8 theftModifier;

        if (unstake) {
            uint256 remainingWords = RandomizerInterface.getRemainingWords();
            require(remainingWords >= numWords, "Not enough random numbers; try again soon.");
            require(msg.value == DEV_FEE + (SEED_COST * numWords), "need more eth");
            require(uint16(numWords) == GroupLength[msg.sender]);
            RandomizerContract.transfer(SEED_COST * numWords);
            dev.transfer(DEV_FEE);
            seed = RandomizerInterface.getRandomWords(numWords);
            if (numWords <= 10) {
                theftModifier = uint8(numWords);
            } else { theftModifier = 10; }
        } else {
            require(msg.value == DEV_FEE, "need more eth");
            dev.transfer(DEV_FEE);
        }
        
        uint256 owed = 0;
        for (uint i = 0; i < tokenIds.length;) {
            require(NFTType[tokenIds[i]] == 1, "must be runners");
            require(IsInMob[tokenIds[i]] , "must be in mob");
            require(StakedNFTInfo[tokenIds[i]].owner == msg.sender, "not owner");

            if(block.timestamp <= claimEndTime) {
                owed += (block.timestamp - StakedNFTInfo[tokenIds[i]].value) * runnerRewardMult / PERIOD;
            } else if (StakedNFTInfo[tokenIds[i]].value < claimEndTime) {
                owed += (claimEndTime - StakedNFTInfo[tokenIds[i]].value) * runnerRewardMult / PERIOD;
            } else {
                owed += 0;
            }
            if(unstake) {
                IsNFTStaked[tokenIds[i]] = false;
                delete StakedNFTInfo[tokenIds[i]]; // reset the struct for this token ID
                IsInMob[tokenIds[i]] = false;

                if (HubInterface.alphaCount(1) > 0 && (seed[i] % 100) < 10 - (theftModifier)) { // nft gets stolen
                    address thief = HubInterface.stealGenesis(tokenIds[i], seed[i], 1, 1, msg.sender);
                    emit GenesisStolen (tokenIds[i], msg.sender, thief, 1, block.timestamp);
                } else {
                    HubInterface.returnGenesisToOwner(msg.sender, tokenIds[i], 1, 1);
                    emit RunnerUnstaked(msg.sender, tokenIds[i]);
                }
            } else {
                StakedNFTInfo[tokenIds[i]].value = uint80(block.timestamp); // reset the stakeTime for this NFT
            }
        unchecked{ i++; }
        }

        if (unstake) { 
            HasMob[msg.sender] = false;
            stakedRunners -= uint16(numWords);
            HubInterface.unstakeGroup(msg.sender, 1);
            GroupLength[msg.sender] = 0;
        }
        
        if (owed == 0) { return; }
        totalTOPIAEarned += owed;
        HubInterface.pay(msg.sender, owed);
    }


    function sendMatadorToWastelands(uint16[] calldata _ids) external payable notContract() {
        uint256 numWords = _ids.length;
        require(msg.value == DEV_FEE + (SEED_COST * numWords) , "insufficient eth ");
        require(RandomizerInterface.getRemainingWords() >= numWords, "try again soon.");
        uint256[] memory seed = RandomizerInterface.getRandomWords(numWords);

        for (uint16 i = 0; i < numWords;) {
            require(Genesis.ownerOf(_ids[i]) == msg.sender, "not owner");
            require(NFTType[_ids[i]] == 3, "not Matador");
            require(!IsInWastelands[_ids[i]] , "in wastelands");

            if (HubInterface.alienCount() > 0 && (seed[i]) % 100 < 25) { // stolen
                address thief = HubInterface.stealMigratingGenesis(_ids[i], seed[i], 1, msg.sender, false);
                emit GenesisStolen (_ids[i], msg.sender, thief, 3, block.timestamp);
            } else {
                HubInterface.migrate(_ids[i], msg.sender, 1, false);
                WastelandMatadors[_ids[i]].matadorTokenId = _ids[i];
                WastelandMatadors[_ids[i]].matadorOwner = msg.sender;
                WastelandMatadors[_ids[i]].value = uint80(WASTELAND_BONUS);
                WastelandMatadors[_ids[i]].migrationTime = uint80(block.timestamp);
                IsInWastelands[_ids[i]] = true;
                migratedMatadors++;
                emit MatadorMigrated(msg.sender, _ids[i], false);
            }
            unchecked { i++; }
        }
        RandomizerContract.transfer(SEED_COST * numWords);
        dev.transfer(DEV_FEE);
    }

    function claimManyWastelands(uint16[] calldata _ids, bool unstake) external payable notContract() {
        uint256 numWords = _ids.length;
        uint256[] memory seed;

        if (unstake) {
            require(RandomizerInterface.getRemainingWords() >= numWords, "try again soon.");
            require(msg.value == DEV_FEE + (SEED_COST * numWords), "need more eth");
            RandomizerContract.transfer(SEED_COST * numWords);
            dev.transfer(DEV_FEE);
            seed = RandomizerInterface.getRandomWords(numWords);
        } else {
            require(msg.value == DEV_FEE, "need more eth");
            dev.transfer(DEV_FEE);
        }

        uint256 owed = 0;

        for (uint16 i = 0; i < numWords;) {
            require(IsInWastelands[_ids[i]] , "not in wastelands");
            require(msg.sender == WastelandMatadors[_ids[i]].matadorOwner , "not owner");
            
            owed += WastelandMatadors[_ids[i]].value;

            if (unstake) {
                if (HubInterface.alienCount() > 0 && (seed[i]) % 100 < 25) { // stolen
                    address thief = HubInterface.stealMigratingGenesis(_ids[i], seed[i], 1, msg.sender, true);
                    emit GenesisStolen (_ids[i], msg.sender, thief, 3, block.timestamp);
                } else {
                    HubInterface.migrate(_ids[i], msg.sender, 1, true);
                    emit MatadorMigrated(msg.sender, _ids[i], true);
                }
                IsInWastelands[_ids[i]] = false;
                delete WastelandMatadors[_ids[i]];
            } else {
                WastelandMatadors[_ids[i]].value = uint80(0); // reset value
            }
            emit MatadorClaimed(owed);
            unchecked { i++; }
        }
        if (unstake) {
            migratedMatadors -= uint16(numWords);
        }
        totalTOPIAEarned += owed;
        if(owed > 0) { HubInterface.pay(msg.sender, owed); }
    }

    function payAlphaTax(uint256 _amount) external onlyBetContract {
       if (stakedAlphas == 0) {// if there's no staked alphas
            unaccountedAlphaRewards += _amount;
            // keep track of $TOPIA due to alphas
            return;
        }
        // makes sure to include any unaccounted $TOPIA
        TOPIAPerAlpha += (_amount + unaccountedAlphaRewards) / stakedAlphas;
        unaccountedAlphaRewards = 0;
    }
}
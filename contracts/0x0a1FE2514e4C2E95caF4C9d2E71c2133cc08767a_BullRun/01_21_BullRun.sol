// SPDX-License-Identifier: MIT LICENSE
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IMetatopiaCoinFlipRNG.sol";
import "./interfaces/ITopia.sol";
import "./interfaces/IBullpen.sol";
import "./interfaces/IArena.sol";
import "./interfaces/IRandomizer.sol";
import "./interfaces/IHub.sol";

contract BullRun is IERC721Receiver, Ownable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.UintSet;

    address payable public RandomizerContract; // VRF contract to decide nft stealing
    address public BullpenContract; // stores staked Bulls
    address public ArenaContract; // stores staked Matadors
    IERC721 public Genesis; // Genesis NFT contract
    IERC721 public Alpha; // Alpha NFT contract

    IMetatopiaCoinFlipRNG private MetatopiaCoinFlipRNGInterface;
    ITopia private TopiaInterface;
    IBullpen private BullpenInterface;
    IArena private ArenaInterface;
    IRandomizer private RandomizerInterface;
    IHub public HubInterface;

    mapping(uint16 => uint8) public NFTType; // tokenID (ID #) => nftID (1 = runner, 2 = bull.. etc)
    mapping(uint8 => uint8) public Risk; // NFT TYPE (not NFT ID) => % chance to get stolen
    mapping(uint16 => bool) public IsNFTStaked; // whether or not an NFT ID # is staked
    mapping(address => mapping(uint256 => uint16[])) public BetNFTsPerEncierro; // keeps track of each players token IDs bet for each encierro
    mapping(uint16 => mapping(uint256 => NFTBet)) public BetNFTInfo; // tokenID to bet info (each staked NFT is its own separate bet) per session
    mapping(address => mapping(uint256 => bool)) public HasBet; // keeps track of whether or not a user has bet in a certain encierro
    mapping(address => mapping(uint256 => bool)) public HasClaimed; // keeps track of users and whether or not they have claimed reward for an encierro bet (not for daily topia)
    mapping(uint256 => Encierro) public Encierros; // mapping for Encierro id to unlock corresponding encierro params
    mapping(address => uint256[]) public EnteredEncierros; // list of Encierro ID's that a particular address has bet in
    mapping(uint16 => Stake) public StakedNFTInfo; // tokenID to stake info
    mapping(address => uint16) public NumberOfStakedNFTs; // the number of NFTs a wallet has staked;
    mapping(address => EnumerableSet.UintSet) StakedTokensOfWallet; // list of token IDs a user has staked
    mapping(address => EnumerableSet.UintSet) MatadorsStakedPerWallet; // list of matador IDs a user has staked
    mapping(address => EnumerableSet.UintSet) StakedAlphasOfWallet; // list of Alpha token IDs a user has staked
    mapping(uint16 => Stake) public StakedAlphaInfo; // tokenID to stake info
    mapping(uint16 => bool) public IsAlphaStaked; // whether or not an NFT ID # is staked
    mapping(address => uint16) public NumberOfStakedAlphas; // the number of NFTs a wallet has staked;

    // ID used to identify type of NFT being staked
    uint8 public constant RunnerId = 1;
    uint8 public constant BullId = 2;
    uint8 public constant MatadorId = 3;

    // keeps track of total NFT's staked
    uint16 public stakedRunners;
    uint16 public stakedBulls;
    uint16 public stakedMatadors;
    uint16 public stakedAlphas;
    uint256 public currentEncierroId;

    uint80 public minimumStakeTime;
    uint256 public maxDuration;
    uint256 public minDuration;

    // any rewards distributed when no Matadors are staked
    uint256 private unaccountedMatadorRewards;
    // amount of $TOPIA due for each Matador staked
    uint256 private TOPIAPerMatador;

    uint256 public runnerRewardMult;
    uint256 public bullRewardMult;
    uint256 public alphaRewardMult;
    uint256 public matadorCut; // numerator with 10000 divisor. ie 5% = 500 

    uint256 public totalTOPIAEarned;
    // the last time $TOPIA can be earned
    uint80 public claimEndTime;
    uint256 public constant PERIOD = 1440 minutes;

    uint256 public SEED_COST = 0.0008 ether;

    // an individual NFT being bet
    struct NFTBet {
        address player;
        uint256 amount; 
        uint8 choice; // (0) BULLS or (1) RUNNERS;
        uint16 tokenID;
        uint8 typeOfNFT;
    }

    // struct to store a stake's token, owner, and earning values
    struct Stake {
        uint16 tokenID;
        address owner; // the wallet that staked it
        uint80 stakeTimestamp; // when this particular NFT is staked.
        uint8 typeOfNFT; // (1 = runner, 2 = bull, 3 = matador, etc)
        uint256 value; // for matador reward calcs - irrelevant unless typeOfNFT = 3.
    }

    // status for bull run betting Encierros
    enum Status {
        Closed,
        Open,
        Standby,
        Claimable
    }

    // BULL RUN Encierro ( EL ENCIERRO ) ----------------------------------------------------

    struct Encierro {
        Status status;
        uint256 encierroId; // increments monotonically 
        uint256 startTime; // unix timestamp
        uint256 endTime; // unix timestamp
        uint256 minBet;
        uint256 maxBet;
        uint16 numRunners; // number of runners entered
        uint16 numBulls; // number of bulls entered
        uint16 numMatadors; // number of matadors entered
        uint16 numberOfBetsOnRunnersWinning; // # of people betting for runners
        uint16 numberOfBetsOnBullsWinning; // # of people betting for bulls
        uint256 topiaBetByRunners; // all TOPIA bet by runners
        uint256 topiaBetByBulls; // all TOPIA bet by bulls
        uint256 topiaBetByMatadors; // all TOPIA bet by matadors
        uint256 topiaBetOnRunners; // all TOPIA bet that runners will win
        uint256 topiaBetOnBulls; // all TOPIA bet that bulls will win
        uint256 totalTopiaCollected; // total TOPIA collected from bets for the entire round
        uint256 flipResult; // 0 for bulls, 1 for runners
    }

    event RunnerStolen (address indexed victim, address indexed theif);
    event BullStolen (address indexed victim, address indexed theif);
    event RunnerStaked (address indexed staker, uint16 stakedID);
    event BullStaked (address indexed staker, uint16 stakedID);
    event MatadorStaked (address indexed staker, uint16 stakedID);
    event AlphaStaked (address indexed staker, uint16 stakedID);
    event RunnerUnstaked (address indexed staker, uint16 unstakedID);
    event BullUnstaked (address indexed staker, uint16 unstakedID);
    event MatadorUnstaked (address indexed staker, uint16 unstakedID);
    event AlphaUnstaked (address indexed staker, uint16 unstakedID);
    event TopiaClaimed (address indexed claimer, uint256 amount);
    event AlphaClaimed(uint16 indexed tokenId, bool indexed unstaked, uint256 earned);
    event BetRewardClaimed (address indexed claimer, uint256 amount);
    event BullsWin (uint80 timestamp, uint256 encierroID);
    event RunnersWin (uint80 timestamp, uint256 encierroID);
   
    event EncierroOpened(
        uint256 indexed encierroId,
        uint256 startTime,
        uint256 endTime,
        uint256 minBet,
        uint256 maxBet
    );

    event BetPlaced(
        address indexed player, 
        uint256 indexed encierroId, 
        uint256 amount,
        uint8 choice,
        uint16[] tokenIDs
    );

    event EncierroClosed(
        uint256 indexed encierroId, 
        uint256 endTime,
        uint16 numRunners,
        uint16 numBulls,
        uint16 numMatadors,
        uint16 numberOfBetsOnRunnersWinning,
        uint16 numberOfBetsOnBullsWinning,
        uint256 topiaBetByRunners, // all TOPIA bet by runners
        uint256 topiaBetByBulls, // all TOPIA bet by bulls
        uint256 topiaBetByMatadors, // all TOPIA bet by matadors
        uint256 topiaBetOnRunners, // all TOPIA bet that runners will win
        uint256 topiaBetOnBulls, // all TOPIA bet that bulls will win
        uint256 totalTopiaCollected
    );

    event CoinFlipped(
        uint256 flipResult,
        uint256 indexed encierroId
    );

    // @param: _minStakeTime should be # of SECONDS (ex: if minStakeTime is 1 day, pass 86400)
    // @param: _runner/bull/alphaMult = number of topia per period
    // topia: 0x218BF48694bb196F8dFCC0661b16ba03635459B0
    // coinflip 0x36CB8d2Af75bDd994DcAD8938531776754111510
    // randomizer 0x3cb1dB3417958222e5C1A98bA859211b9402a12f
    // bullpen 0x9c215c9Ab78b544345047b9aB604c9c9AC391100
    // arena 0xF84BD9d391c9d4874032809BE3Fd121103de5F60
    // gensis 0x810FeDb4a6927D02A6427f7441F6110d7A1096d5
    // alpha 0x96Af517c414B3726c1B2Ecc744ebf9d292DCbF60
    // hub 0x9FAd19Ecf23d440B87fF91Dd9424155e03D755cE
    // 0
    // 18000000000000000000
    // 20000000000000000000
    // 35000000000000000000
    // 500
    constructor(
        address _topiaToken, 
        address _coinFlipContract,
        address _randomizer,
        address _bullpen,
        address _arena,
        address _genesis,
        address _alpha,
        address _hub,
        uint80 _minStakeTime,
        uint256 _runnerMult,
        uint256 _bullMult,
        uint256 _alphaMult,
        uint256 _matadorCut) {

        Risk[1] = 10; // runners
        Risk[2] = 10; // bulls

        minimumStakeTime = _minStakeTime;

        Genesis = IERC721(_genesis);
        Alpha = IERC721(_alpha);

        HubInterface = IHub(_hub);

        TopiaInterface = ITopia(_topiaToken);

        RandomizerContract = payable(_randomizer);
        RandomizerInterface = IRandomizer(_randomizer);

        MetatopiaCoinFlipRNGInterface = IMetatopiaCoinFlipRNG(_coinFlipContract);

        BullpenContract = _bullpen;
        BullpenInterface = IBullpen(_bullpen);

        ArenaContract = _arena;
        ArenaInterface = IArena(_arena);

        runnerRewardMult = _runnerMult;
        bullRewardMult = _bullMult;
        alphaRewardMult = _alphaMult;
        matadorCut = _matadorCut;
    }

    receive() external payable {}

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    // INTERNAL HELPERS ----------------------------------------------------

    function _flipCoin() internal returns (uint256) {
        uint256 result = MetatopiaCoinFlipRNGInterface.oneOutOfTwo();
        Encierros[currentEncierroId].status = Status.Standby;
        if (result == 0) {
            Encierros[currentEncierroId].flipResult = 0;
            emit BullsWin(uint80(block.timestamp), currentEncierroId);
        } else {
            Encierros[currentEncierroId].flipResult = 1;
            emit RunnersWin(uint80(block.timestamp), currentEncierroId);
        }
        emit CoinFlipped(result, currentEncierroId);
        return result;
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

    // SETTERS ----------------------------------------------------

    function setTopiaToken(address _topiaToken) external onlyOwner {
        TopiaInterface = ITopia(_topiaToken);
    }

    function setRNGContract(address _coinFlipContract) external onlyOwner {
        MetatopiaCoinFlipRNGInterface = IMetatopiaCoinFlipRNG(_coinFlipContract);
    }

    function setBullpenContract(address _bullpenContract) external onlyOwner {
        BullpenContract = _bullpenContract;
        BullpenInterface = IBullpen(_bullpenContract);
    }

    function setArenaContract(address _arenaContract) external onlyOwner {
        ArenaContract = _arenaContract;
        ArenaInterface = IArena(_arenaContract);
    }

    // IN SECONDS
    function setMinStakeTime(uint80 _minStakeTime) external onlyOwner {
        minimumStakeTime = _minStakeTime;
    }
    
    function setPaymentMultipliers(uint8 _runnerMult, uint8 _bullMult, uint8 _alphaMult, uint8 _matadorCut) external onlyOwner {
        runnerRewardMult = _runnerMult;
        bullRewardMult = _bullMult;
        alphaRewardMult = _alphaMult;
        matadorCut = _matadorCut;
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
        for (uint16 i = 0; i < _idNumbers.length; i++) {
            require(_types[i] != 0 && _types[i] <= 3);
            NFTType[_idNumbers[i]] = _types[i];
        }
    }

    function setMinMaxDuration(uint256 _min, uint256 _max) external onlyOwner {
        minDuration = _min;
        maxDuration = _max;
    }

    // GETTERS ----------------------------------------------------

    function viewEncierroById(uint256 _encierroId) external view returns (Encierro memory) {
        return Encierros[_encierroId];
    }

    function getEnteredEncierrosLength(address _better) external view returns (uint256) {
        return EnteredEncierros[_better].length;
    }

    // CLAIM FUNCTIONS ----------------------------------------------------    

    function claimManyGenesis(uint16[] calldata tokenIds, bool unstake) external payable nonReentrant returns (uint16[] memory stolenNFTs) {
        uint256 numWords = tokenIds.length;
        uint256[] memory seed;

        if(unstake) {
            require(msg.value == SEED_COST * numWords, "Invalid value for randomness");
            RandomizerContract.transfer(msg.value);
            uint256 remainingWords = RandomizerInterface.getRemainingWords();
            require(remainingWords >= numWords, "Not enough random numbers. Please try again soon.");
            seed = RandomizerInterface.getRandomWords(numWords);
            HubInterface.emitGenesisUnstaked(msg.sender, tokenIds);
            stolenNFTs = new uint16[](numWords);
        } else {
            stolenNFTs = new uint16[](1);
            stolenNFTs[0] = 0;
        }
        
        uint256 owed = 0;
        for (uint i = 0; i < tokenIds.length; i++) {
            if (NFTType[tokenIds[i]] == 1) {
                (uint256 _owed, uint16 _stolenId) = claimRunner(tokenIds[i], unstake, unstake ? seed[i] : 0);
                owed += _owed;
                if(unstake) { stolenNFTs[i] = _stolenId; }
            } else if (NFTType[tokenIds[i]] == 2) {
                (uint256 _owed, uint16 _stolenId) = claimBull(tokenIds[i], unstake, unstake ? seed[i] : 0);
                owed += _owed;
                if(unstake) { stolenNFTs[i] = _stolenId; }
            } else if (NFTType[tokenIds[i]] == 3) {
                owed += claimMatador(tokenIds[i], unstake);
                if(unstake) { stolenNFTs[i] = 0;}
            } else if (NFTType[tokenIds[i]] == 0) {
                revert("Invalid Token Id");
            }
        }
        if (owed == 0) {
            return stolenNFTs;
        }
        totalTOPIAEarned += owed;
        emit TopiaClaimed(msg.sender, owed);
        TopiaInterface.mint(msg.sender, owed);
        HubInterface.emitTopiaClaimed(msg.sender, owed);
    }

    function claimManyAlphas(uint16[] calldata _tokenIds, bool unstake) external nonReentrant {
        uint256 owed = 0;
        for (uint i = 0; i < _tokenIds.length; i++) { 
            require(StakedAlphaInfo[_tokenIds[i]].owner == msg.sender, "not owner");
            owed += (block.timestamp - StakedAlphaInfo[_tokenIds[i]].value) * alphaRewardMult / PERIOD;
            if (unstake) {
                delete StakedAlphaInfo[_tokenIds[i]];
                stakedAlphas -= 1;
                StakedAlphasOfWallet[msg.sender].remove(_tokenIds[i]);
                Alpha.safeTransferFrom(address(this), msg.sender, _tokenIds[i]);
                HubInterface.emitAlphaUnstaked(msg.sender, _tokenIds);
                emit AlphaUnstaked(msg.sender, _tokenIds[i]);
            } else {
                StakedAlphaInfo[_tokenIds[i]].value = uint80(block.timestamp);
            }
            emit AlphaClaimed(_tokenIds[i], unstake, owed);
        }
        if (owed == 0) {
            return;
        }
        TopiaInterface.mint(msg.sender, owed);
        HubInterface.emitTopiaClaimed(msg.sender, owed);
        emit TopiaClaimed(msg.sender, owed);
    }

    // this fxn allows caller to claim winnings from their BET (not daily TOPIA)
    // @param: the calldata array is each of the tokenIDs they are attempting to claim FOR
    // function claimBetReward(uint256 _encierroId) external 
    // nonReentrant notContract() {
    //     require(_encierroId <= currentEncierroId , 
    //     "Invalid id");
    //     require(Encierros[_encierroId].status == Status.Claimable , 
    //     "not claimable");
    //     require(!HasClaimed[msg.sender][_encierroId] , 
    //     "user already claimed");
    //     require(HasBet[msg.sender][_encierroId] , 
    //     "user did not bet");

    //     uint8 winningResult = uint8(Encierros[_encierroId].flipResult);
    //     require(winningResult <= 1 , "Invalid flip result");

    //     uint256 owed; // what caller collects for winning

    //     for (uint16 i = 0; i < BetNFTsPerEncierro[msg.sender][_encierroId].length; i++) { // fetch their bet NFT ids for this encierro
    //         require(BetNFTInfo[BetNFTsPerEncierro[msg.sender][_encierroId][i]][_encierroId].player == msg.sender , 
    //         "not owner");
            
    //         // calculate winnings
    //         if (BetNFTInfo[BetNFTsPerEncierro[msg.sender][_encierroId][i]][_encierroId].choice == winningResult && 
    //             BetNFTInfo[BetNFTsPerEncierro[msg.sender][_encierroId][i]][_encierroId].typeOfNFT == 1) {
    //                 // get how much topia was bet on this NFT id in this session
    //                 uint256 topiaBetOnThisNFT = BetNFTInfo[BetNFTsPerEncierro[msg.sender][_encierroId][i]][_encierroId].amount;
    //                 owed += (topiaBetOnThisNFT * 5) / 4;

    //         } else if (BetNFTInfo[BetNFTsPerEncierro[msg.sender][_encierroId][i]][_encierroId].choice == winningResult && 
    //                    BetNFTInfo[BetNFTsPerEncierro[msg.sender][_encierroId][i]][_encierroId].typeOfNFT == 2) {
    //                 // get how much topia was bet on this NFT id in this session
    //                 uint256 topiaBetOnThisNFT = BetNFTInfo[BetNFTsPerEncierro[msg.sender][_encierroId][i]][_encierroId].amount;
    //                 owed += (topiaBetOnThisNFT * 3) / 2;

    //         } else if (BetNFTInfo[BetNFTsPerEncierro[msg.sender][_encierroId][i]][_encierroId].choice == winningResult && 
    //                    BetNFTInfo[BetNFTsPerEncierro[msg.sender][_encierroId][i]][_encierroId].typeOfNFT == 3) {
    //                 // get how much topia was bet on this NFT id in this session
    //                 uint256 topiaBetOnThisNFT = BetNFTInfo[BetNFTsPerEncierro[msg.sender][_encierroId][i]][_encierroId].amount;
    //                 owed += (topiaBetOnThisNFT * 2);
    //         }
    //     }
    //     HasClaimed[msg.sender][_encierroId] = true;
    //     TopiaInterface.mint(msg.sender, owed);
    //     HubInterface.emitTopiaClaimed(msg.sender, owed);
    //     emit BetRewardClaimed(msg.sender, owed);
    // }

    // this fxn allows caller to claim winnings from their BET (not daily TOPIA)
    // @param: the calldata array is each of the tokenIDs they are attempting to claim FOR
    function claimManyBetRewards() external 
    nonReentrant notContract() {

        uint256 owed; // what caller collects for winning
        for(uint i = 0; i < EnteredEncierros[msg.sender].length; i++) {
            if(Encierros[i].status == Status.Claimable && !HasClaimed[msg.sender][i] && HasBet[msg.sender][i]) {
                uint8 winningResult = uint8(Encierros[i].flipResult);
                require(winningResult <= 1 , "Invalid flip result");
                for (uint16 z = 0; z < BetNFTsPerEncierro[msg.sender][i].length; z++) { // fetch their bet NFT ids for this encierro
                    require(BetNFTInfo[BetNFTsPerEncierro[msg.sender][i][z]][i].player == msg.sender , 
                    "not owner");
                    
                    // calculate winnings
                    if (BetNFTInfo[BetNFTsPerEncierro[msg.sender][i][z]][i].choice == winningResult && 
                        BetNFTInfo[BetNFTsPerEncierro[msg.sender][i][z]][i].typeOfNFT == 1) {
                            // get how much topia was bet on this NFT id in this session
                            uint256 topiaBetOnThisNFT = BetNFTInfo[BetNFTsPerEncierro[msg.sender][i][z]][i].amount;
                            owed += (topiaBetOnThisNFT * 5) / 4;

                    } else if (BetNFTInfo[BetNFTsPerEncierro[msg.sender][i][z]][i].choice == winningResult && 
                               BetNFTInfo[BetNFTsPerEncierro[msg.sender][i][z]][i].typeOfNFT == 2) {
                            // get how much topia was bet on this NFT id in this session
                            uint256 topiaBetOnThisNFT = BetNFTInfo[BetNFTsPerEncierro[msg.sender][i][z]][i].amount;
                            owed += (topiaBetOnThisNFT * 3) / 2;

                    } else if (BetNFTInfo[BetNFTsPerEncierro[msg.sender][i][z]][i].choice == winningResult && 
                               BetNFTInfo[BetNFTsPerEncierro[msg.sender][i][z]][i].typeOfNFT == 3) {
                            // get how much topia was bet on this NFT id in this session
                            uint256 topiaBetOnThisNFT = BetNFTInfo[BetNFTsPerEncierro[msg.sender][i][z]][i].amount;
                            owed += (topiaBetOnThisNFT * 2);
                    }
                    else {
                        continue;
                    }
                }
                HasClaimed[msg.sender][i] = true;
            } else {
                continue;
            }
        }

        TopiaInterface.mint(msg.sender, owed);
        HubInterface.emitTopiaClaimed(msg.sender, owed);
        emit BetRewardClaimed(msg.sender, owed);
    }

    // STAKING FUNCTIONS ----------------------------------------------------

    function stakeMany(uint16[] calldata _tokenIds) external nonReentrant {
        require(msg.sender == tx.origin, "account to send mismatch");
        for (uint i = 0; i < _tokenIds.length; i++) {
            require(Genesis.ownerOf(_tokenIds[i]) == msg.sender, "not owner");

            if (NFTType[_tokenIds[i]] == 1) {
                stakeRunner(_tokenIds[i]);
            } else if (NFTType[_tokenIds[i]] == 2) {
                stakeBull(_tokenIds[i]);
            } else if (NFTType[_tokenIds[i]] == 3) {
                stakeMatador(_tokenIds[i]);
            } else if (NFTType[_tokenIds[i]] == 0) {
                revert("invalid NFT");
            }

        }
        HubInterface.emitGenesisStaked(msg.sender, _tokenIds, 4);
    }

    function stakeRunner(uint16 tokenID) internal {

        IsNFTStaked[tokenID] = true;
        StakedTokensOfWallet[msg.sender].add(tokenID);
        StakedNFTInfo[tokenID].tokenID = tokenID;
        StakedNFTInfo[tokenID].owner = msg.sender;
        StakedNFTInfo[tokenID].stakeTimestamp = uint80(block.timestamp);
        StakedNFTInfo[tokenID].value = uint80(block.timestamp);
        StakedNFTInfo[tokenID].typeOfNFT = 1;
        Genesis.safeTransferFrom(msg.sender, address(this), tokenID);

        stakedRunners++;
        NumberOfStakedNFTs[msg.sender]++;
        emit RunnerStaked(msg.sender, tokenID);     
    }

    function stakeBull(uint16 tokenID) internal {
        
        IsNFTStaked[tokenID] = true;
        StakedTokensOfWallet[msg.sender].add(tokenID);
        StakedNFTInfo[tokenID].tokenID = tokenID;
        StakedNFTInfo[tokenID].owner = msg.sender;
        StakedNFTInfo[tokenID].stakeTimestamp = uint80(block.timestamp);
        StakedNFTInfo[tokenID].value = uint80(block.timestamp);
        StakedNFTInfo[tokenID].typeOfNFT = 2;
        Genesis.safeTransferFrom(msg.sender, BullpenContract, tokenID); // bulls go to the pen
        BullpenInterface.receiveBull(msg.sender, tokenID); // tell the bullpen they're getting a new bull

        stakedBulls++;
        NumberOfStakedNFTs[msg.sender]++;
        emit BullStaked(msg.sender, tokenID);    
    }

    function stakeMatador(uint16 tokenID) internal {

        IsNFTStaked[tokenID] = true;
        StakedTokensOfWallet[msg.sender].add(tokenID);
        MatadorsStakedPerWallet[msg.sender].add(tokenID);
        StakedNFTInfo[tokenID].tokenID = tokenID;
        StakedNFTInfo[tokenID].owner = msg.sender;
        StakedNFTInfo[tokenID].stakeTimestamp = uint80(block.timestamp);
        StakedNFTInfo[tokenID].typeOfNFT = 3;
        StakedNFTInfo[tokenID].value = TOPIAPerMatador; // for matadors only
        Genesis.safeTransferFrom(msg.sender, ArenaContract, tokenID); // matadors go to the arena
        ArenaInterface.receiveMatador(msg.sender, tokenID); // tell the arena they are receiving a new matador

        stakedMatadors++;
        NumberOfStakedNFTs[msg.sender]++;
        emit MatadorStaked(msg.sender, tokenID);   
    }

    function claimRunner(uint16 tokenId, bool unstake, uint256 seed) internal returns (uint256 owed, uint16 stolenId) {
        require(StakedNFTInfo[tokenId].owner == msg.sender, "not owner");
        require(block.timestamp - StakedNFTInfo[tokenId].stakeTimestamp > minimumStakeTime, "Must wait minimum stake time");
        stolenId = 0;
        
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
            StakedTokensOfWallet[msg.sender].remove(tokenId);

            if (BullpenInterface.bullCount() > 0 && (seed % 100) < Risk[1]) { 
                // nft gets stolen
                address thief = BullpenInterface.selectRandomBullOwnerToReceiveStolenRunner(seed);
                Genesis.safeTransferFrom(address(this), thief, tokenId);
                stolenId = tokenId;
                emit RunnerStolen(msg.sender, thief);
            } else {
                Genesis.safeTransferFrom(address(this), msg.sender, tokenId);
                emit RunnerUnstaked(msg.sender, tokenId);
            }
            
            stakedRunners--;
            NumberOfStakedNFTs[msg.sender]--;
        } else {
            StakedNFTInfo[tokenId].value = uint80(block.timestamp); // reset the stakeTime for this NFT
        }
    }

    function claimBull(uint16 tokenId, bool unstake, uint256 seed) internal returns (uint256 owed, uint16 stolenId) {
        require(StakedNFTInfo[tokenId].owner == msg.sender, "not owner");
        require(block.timestamp - StakedNFTInfo[tokenId].stakeTimestamp > minimumStakeTime, "Must wait minimum stake time");
        stolenId = 0;
        
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
            StakedTokensOfWallet[msg.sender].remove(tokenId);

            if (ArenaInterface.matadorCount() > 0 && (seed % 100) < Risk[2]) { 
                // nft gets stolen
                address thief = ArenaInterface.selectRandomMatadorOwnerToReceiveStolenBull(seed);
                BullpenInterface.stealBull(thief, tokenId);
                stolenId = tokenId;
                emit BullStolen(msg.sender, thief);
            } else {
                BullpenInterface.returnBullToOwner(msg.sender, tokenId);
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
        require(block.timestamp - StakedNFTInfo[tokenID].stakeTimestamp > minimumStakeTime, "Must wait minimum stake time");

        owed += (TOPIAPerMatador - StakedNFTInfo[tokenID].value);

        if(unstake) {
            IsNFTStaked[tokenID] = false;
            delete StakedNFTInfo[tokenID]; // reset the struct for this token ID
            StakedTokensOfWallet[msg.sender].remove(tokenID);
            MatadorsStakedPerWallet[msg.sender].remove(tokenID);
            ArenaInterface.returnMatadorToOwner(msg.sender, tokenID);

            stakedMatadors--;
            NumberOfStakedNFTs[msg.sender]--;
            emit MatadorUnstaked(msg.sender, tokenID);
        } else {
            StakedNFTInfo[tokenID].value = TOPIAPerMatador;
        }
    }

    function stakeManyAlphas(uint16[] calldata _tokenIds) external nonReentrant {
        require(tx.origin == msg.sender, "Only EOA");
        for (uint i = 0; i < _tokenIds.length; i++) {
            require(Alpha.ownerOf(_tokenIds[i]) == msg.sender, "not owner");
            
            IsAlphaStaked[_tokenIds[i]] = true;
            StakedAlphasOfWallet[msg.sender].add(_tokenIds[i]);
            StakedAlphaInfo[_tokenIds[i]].tokenID = _tokenIds[i];
            StakedAlphaInfo[_tokenIds[i]].owner = msg.sender;
            StakedAlphaInfo[_tokenIds[i]].stakeTimestamp = uint80(block.timestamp);
            StakedAlphaInfo[_tokenIds[i]].value = uint80(block.timestamp);
            StakedAlphaInfo[_tokenIds[i]].typeOfNFT = 0;
            Alpha.safeTransferFrom(msg.sender, address(this), _tokenIds[i]);

            stakedAlphas++;
            NumberOfStakedAlphas[msg.sender]++;
            emit AlphaStaked(msg.sender, _tokenIds[i]);
            }
        
        HubInterface.emitAlphaStaked(msg.sender, _tokenIds, 4);
    }

    function getUnclaimedAlpha(uint16 tokenId) external view returns (uint256) {
        return (block.timestamp - StakedAlphaInfo[tokenId].value) * alphaRewardMult / PERIOD;
    }

    function getUnclaimedGenesis(uint16 tokenId) external view returns (uint256 owed) {
        if (!IsNFTStaked[tokenId]) { return 0; }
        if (NFTType[tokenId] == 1) {
            if(block.timestamp <= claimEndTime) {
                owed = (block.timestamp - StakedNFTInfo[tokenId].value) * runnerRewardMult / PERIOD;
            } else if (StakedNFTInfo[tokenId].value < claimEndTime) {
                owed = (claimEndTime - StakedNFTInfo[tokenId].value) * runnerRewardMult / PERIOD;
            } else {
                owed = 0;
            }
        } else if (NFTType[tokenId] == 2) {
            if(block.timestamp <= claimEndTime) {
                owed = (block.timestamp - StakedNFTInfo[tokenId].value) * bullRewardMult / PERIOD;
            } else if (StakedNFTInfo[tokenId].value < claimEndTime) {
                owed = (claimEndTime - StakedNFTInfo[tokenId].value) * bullRewardMult / PERIOD;
            } else {
                owed = 0;
            }
        } else if (NFTType[tokenId] == 3) {
            owed = (TOPIAPerMatador - StakedNFTInfo[tokenId].value);
        }
        return owed;
    }

    function getUnclaimedTopiaForUser(address _account) external view returns (uint256) {
        uint256 owed;
        uint256 genesisLength = StakedTokensOfWallet[_account].length();
        uint256 alphaLength = StakedAlphasOfWallet[_account].length();
        
        for (uint i = 0; i < genesisLength; i++) {
            uint16 tokenId = uint16(StakedTokensOfWallet[_account].at(i));
            if (NFTType[tokenId] == 1) {
                if(block.timestamp <= claimEndTime) {
                    owed += (block.timestamp - StakedNFTInfo[tokenId].value) * runnerRewardMult / PERIOD;
                } else if (StakedNFTInfo[tokenId].value < claimEndTime) {
                    owed += (claimEndTime - StakedNFTInfo[tokenId].value) * runnerRewardMult / PERIOD;
                } else {
                    owed += 0;
                }
            } else if (NFTType[tokenId] == 2) {
                if(block.timestamp <= claimEndTime) {
                    owed += (block.timestamp - StakedNFTInfo[tokenId].value) * bullRewardMult / PERIOD;
                } else if (StakedNFTInfo[tokenId].value < claimEndTime) {
                    owed += (claimEndTime - StakedNFTInfo[tokenId].value) * bullRewardMult / PERIOD;
                } else {
                    owed += 0;
                }
            } else if (NFTType[tokenId] == 3) {
                owed += (TOPIAPerMatador - StakedNFTInfo[tokenId].value);
            } else if (NFTType[tokenId] == 0) {
                continue;
            }
        }
        for (uint i = 0; i < alphaLength; i++) {
            uint16 tokenId = uint16(StakedAlphasOfWallet[_account].at(i));
            owed += (block.timestamp - StakedAlphaInfo[tokenId].value) * alphaRewardMult / PERIOD;
        }

        return owed;
    }

    function getStakedGenesisForUser(address _account) external view returns (uint16[] memory stakedGensis) {
        uint256 length = StakedTokensOfWallet[_account].length();
        stakedGensis = new uint16[](length);
        for (uint i = 0; i < length; i++) {
            stakedGensis[i] = uint16(StakedTokensOfWallet[_account].at(i));
        }
    }

    function getStakedAlphasForUser(address _account) external view returns (uint16[] memory _stakedAlphas) {
        uint256 length = StakedAlphasOfWallet[_account].length();
        _stakedAlphas = new uint16[](length);
        for (uint i = 0; i < length; i++) {
            _stakedAlphas[i] = uint16(StakedAlphasOfWallet[_account].at(i));
        }
    }

    // BET FUNCTIONS ----------------------------------------------------

    // @param: choice is FOR ALL NFTS being passed. Each NFT ID gets assigned the same choice (0 = bulls, 1 = runners)
    // @param: betAmount is PER NFT. If 10 NFTs are bet, and amount passed in is 10 TOPIA, total is 100 TOPIA BET
    function betMany(uint16[] calldata _tokenIds, uint256 _encierroId, uint256 _betAmount, uint8 _choice) external 
    nonReentrant {
        require(Encierros[_encierroId].endTime > block.timestamp , "Betting has ended");
        require(_encierroId <= currentEncierroId, "Non-existent encierro id!");
        require(TopiaInterface.balanceOf(address(msg.sender)) >= (_betAmount * _tokenIds.length), "not enough TOPIA");
        require(_choice == 1 || _choice == 0, "Invalid choice");
        require(Encierros[_encierroId].status == Status.Open, "not open");
        require(_betAmount >= Encierros[_encierroId].minBet && _betAmount <= Encierros[_encierroId].maxBet, "Bet not within limits");

        uint16 numberOfNFTs = uint16(_tokenIds.length);
        uint256 totalBet = _betAmount * numberOfNFTs;
        for (uint i = 0; i < numberOfNFTs; i++) {
            require(StakedNFTInfo[_tokenIds[i]].owner == msg.sender, "not owner");

            if (NFTType[_tokenIds[i]] == 1) {
                betRunner(_tokenIds[i], _encierroId, _betAmount, _choice);
            } else if (NFTType[_tokenIds[i]] == 2) {
                betBull(_tokenIds[i], _encierroId, _betAmount, _choice);
            } else if (NFTType[_tokenIds[i]] == 3) {
                betMatador(_tokenIds[i], _encierroId, _betAmount, _choice);
            } else if (NFTType[_tokenIds[i]] == 0) {
                continue;
            }

        Encierros[_encierroId].totalTopiaCollected += totalBet;
        
        if (_choice == 0) {
            Encierros[_encierroId].numberOfBetsOnBullsWinning += numberOfNFTs; // increase the number of bets on bulls winning by # of NFTs being bet
            Encierros[_encierroId].topiaBetOnBulls += totalBet; // multiply the bet amount per NFT by the number of NFTs
        } else {
            Encierros[_encierroId].numberOfBetsOnRunnersWinning += numberOfNFTs; // increase number of bets on runners...
            Encierros[_encierroId].topiaBetOnRunners += totalBet;
        }

        if (!HasBet[msg.sender][_encierroId]) {
            HasBet[msg.sender][_encierroId] = true;
            EnteredEncierros[msg.sender].push(_encierroId);
        }
        TopiaInterface.burnFrom(msg.sender, totalBet);
        emit BetPlaced(msg.sender, _encierroId, totalBet, _choice, _tokenIds);
        }
    }

    function betRunner(uint16 _runnerID, uint256 _encierroId, uint256 _betAmount, uint8 _choice) internal {

        require(IsNFTStaked[_runnerID] , "not staked");
        require(StakedNFTInfo[_runnerID].owner == msg.sender , "not owner");
        BetNFTsPerEncierro[msg.sender][_encierroId].push(_runnerID); // add the token IDs being bet to their personal mapping for this session
        BetNFTInfo[_runnerID][_encierroId].player = msg.sender; // map bet token id to caller for this session
        BetNFTInfo[_runnerID][_encierroId].amount = _betAmount; // map bet token id to bet amount for this session
        BetNFTInfo[_runnerID][_encierroId].choice = _choice; // map bet token id to choice for this session
        BetNFTInfo[_runnerID][_encierroId].tokenID = _runnerID; // map bet token id to struct id for this session
        BetNFTInfo[_runnerID][_encierroId].typeOfNFT = 1; // 1 = runner

        Encierros[_encierroId].topiaBetByRunners += _betAmount;
        Encierros[_encierroId].numRunners++;
    }

    function betBull(uint16 _bullID, uint256 _encierroId, uint256 _betAmount, uint8 _choice) internal {

        require(IsNFTStaked[_bullID] , "not staked");
        require(StakedNFTInfo[_bullID].owner == msg.sender , "not owner");
        BetNFTsPerEncierro[msg.sender][_encierroId].push(_bullID); // add the token IDs being bet to their personal mapping for this session
        BetNFTInfo[_bullID][_encierroId].player = msg.sender; // map bet token id to caller for this session
        BetNFTInfo[_bullID][_encierroId].amount = _betAmount; // map bet token id to bet amount for this session
        BetNFTInfo[_bullID][_encierroId].choice = _choice; // map bet token id to choice for this session
        BetNFTInfo[_bullID][_encierroId].tokenID = _bullID; // map bet token id to struct id for this session
        BetNFTInfo[_bullID][_encierroId].typeOfNFT = 2; // 2 = bull

        Encierros[_encierroId].topiaBetByBulls += _betAmount;
        Encierros[_encierroId].numBulls++;
    }

    function betMatador(uint16 _matadorID, uint256 _encierroId, uint256 _betAmount, uint8 _choice) internal {

        require(IsNFTStaked[_matadorID] , "not staked");
        require(StakedNFTInfo[_matadorID].owner == msg.sender , "not owner");
        BetNFTsPerEncierro[msg.sender][_encierroId].push(_matadorID); // add the token IDs being bet to their personal mapping for this session
        BetNFTInfo[_matadorID][_encierroId].player = msg.sender; // map bet token id to caller for this session
        BetNFTInfo[_matadorID][_encierroId].amount = _betAmount; // map bet token id to bet amount for this session
        BetNFTInfo[_matadorID][_encierroId].choice = _choice; // map bet token id to choice for this session
        BetNFTInfo[_matadorID][_encierroId].tokenID = _matadorID; // map bet token id to struct id for this session
        BetNFTInfo[_matadorID][_encierroId].typeOfNFT = 3; // 3 = matador

        Encierros[_encierroId].topiaBetByMatadors += _betAmount;
        Encierros[_encierroId].numMatadors++;
    }

    // Encierro SESSION LOGIC ---------------------------------------------------- 

    function startEncierro(
        uint256 _endTime,
        uint256 _minBet,
        uint256 _maxBet) 
        external
        payable
        nonReentrant
        {
        require(
            (currentEncierroId == 0) || 
            (Encierros[currentEncierroId].status == Status.Claimable), "session not claimable");

        require(((_endTime - block.timestamp) >= minDuration) && ((_endTime - block.timestamp) <= maxDuration), "invalid time");
        require(msg.value == SEED_COST, "seed cost not met");

        currentEncierroId++;

        Encierros[currentEncierroId] = Encierro({
            status: Status.Open,
            encierroId: currentEncierroId,
            startTime: block.timestamp,
            endTime: _endTime,
            minBet: _minBet,
            maxBet: _maxBet,
            numRunners: 0,
            numBulls: 0,
            numMatadors: 0,
            numberOfBetsOnRunnersWinning: 0,
            numberOfBetsOnBullsWinning: 0,
            topiaBetByRunners: 0,
            topiaBetByBulls: 0,
            topiaBetByMatadors: 0,
            topiaBetOnRunners: 0,
            topiaBetOnBulls: 0,
            totalTopiaCollected: 0,
            flipResult: 2 // init to 2 to avoid conflict with 0 (bulls) or 1 (runners). is set to 0 or 1 later depending on coin flip result.
        });

        RandomizerContract.transfer(msg.value);
        
        emit EncierroOpened(
            currentEncierroId,
            block.timestamp,
            _endTime,
            _minBet,
            _maxBet
        );
    }

    // bulls = 0, runners = 1
    function closeEncierro(uint256 _encierroId) external nonReentrant {
        require(Encierros[_encierroId].status == Status.Open , "must be open first");
        require(block.timestamp > Encierros[_encierroId].endTime, "not over yet");
        MetatopiaCoinFlipRNGInterface.requestRandomWords();
        Encierros[_encierroId].status = Status.Closed;
        emit EncierroClosed(
            _encierroId,
            block.timestamp,
            Encierros[_encierroId].numRunners,
            Encierros[_encierroId].numBulls,
            Encierros[_encierroId].numMatadors,
            Encierros[_encierroId].numberOfBetsOnRunnersWinning,
            Encierros[_encierroId].numberOfBetsOnBullsWinning,
            Encierros[_encierroId].topiaBetByRunners,
            Encierros[_encierroId].topiaBetByBulls,
            Encierros[_encierroId].topiaBetByMatadors,
            Encierros[_encierroId].topiaBetOnRunners,
            Encierros[_encierroId].topiaBetOnBulls,
            Encierros[_encierroId].totalTopiaCollected
        );
    }

    /**
     * add $TOPIA to claimable pot for the Matador Yield
     * @param amount $TOPIA to add to the pot
   */
    function _payMatadorTax(uint256 amount) internal {
        if (stakedMatadors == 0) {// if there's no staked matadors
            unaccountedMatadorRewards += amount;
            return;
        }
        TOPIAPerMatador += (amount + unaccountedMatadorRewards) / stakedMatadors;
        unaccountedMatadorRewards = 0;
    }

    function flipCoinAndMakeClaimable(uint256 _encierroId) external nonReentrant notContract() returns (uint256) {
        require(_encierroId <= currentEncierroId , "Nonexistent session!");
        require(Encierros[_encierroId].status == Status.Closed , "must be closed first");
        uint256 encierroFlipResult = _flipCoin();
        Encierros[_encierroId].flipResult = encierroFlipResult;

        if (encierroFlipResult == 0) { // if bulls win
            uint256 amountToMatadors = (Encierros[_encierroId].topiaBetOnRunners * matadorCut) / 10000;
            _payMatadorTax(amountToMatadors);
        } else { // if runners win
            uint256 amountToMatadors = (Encierros[_encierroId].topiaBetOnBulls * matadorCut) / 10000;
            _payMatadorTax(amountToMatadors);
        }

        Encierros[_encierroId].status = Status.Claimable;
        return encierroFlipResult;
    }
}
// SPDX-License-Identifier: UNLICENSED

/*
 _______   _______  __        ______   .___________.   __    ______   
|       \ |   ____||  |      /  __  \  |           |  |  |  /  __  \  
|  .--.  ||  |__   |  |     |  |  |  | `---|  |----`  |  | |  |  |  | 
|  |  |  ||   __|  |  |     |  |  |  |     |  |       |  | |  |  |  | 
|  '--'  ||  |____ |  `----.|  `--'  |     |  |     __|  | |  `--'  | 
|_______/ |_______||_______| \______/      |__|    (__)__|  \______/  

The world’s first innovative decentralized lottery game for token holders.
The more token you hold the more ticket you get.
The more ticket you have the more chance to win the grand prize.

DELOT token is the utility token that is used in the Lottery game.

Try out the Lottery game version 2 with NFT: https://app.delot.io
NFT Holders get rewards (DELOT tokens) up to 20% of deposited tokens in all lottery rounds.

Website: https://www.delot.io
Telegram: https://t.me/delot_io
Twitter: https://twitter.com/delot_io
*/

pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

contract DELOT_Lottery_V2 is VRFConsumerBaseV2, Ownable, KeeperCompatibleInterface {    
    using SafeMath for uint256;

    //
    IERC20 public _token;
    
    //
    struct UserInfo {
        uint256 depositAmount; 
        uint256 depositTickets;
        uint256 holdAmount;
        uint256 holdTickets;
        uint256 tickets; 
        address addr;
    }
    
    // Rounds
    struct Round {
        uint256 startBlock;
        uint256 endBlock; 
        uint256 endBlock2;
        uint256 Id;
        
        uint256 depositMultiplier;
        uint256 holdMultiplier;
        
        uint256 totalTickets;
        
        uint256[] winnerRatios;
        uint256[] indexWinners;

        uint256[] randomResult;
        uint256 depositAmount;
        
        uint256 winnerPayoutRatio;
        uint256 nftHoldersPayoutRatio;
        
        uint256 numPlayers;
        mapping (uint256 => UserInfo) players;
        mapping (address => uint256) playerIndex; //+1
    }
    
    uint256 public _numRounds = 0;
    mapping (uint256 => Round) public _rounds;
    
    enum RoundState { START, ACTIVE, END }
    RoundState public _activeRoundState = RoundState.START;
    uint256 public _endRoundState;
    
    uint256 public _pIndex;
    uint256 public _numberOfPlayersToProcessAtStart = 5;
    uint256 public _numberOfPlayersToProcessAtEnd   = 10;
    
    uint256 VRF_WAITING_BLOCKS      = 28328; // ~24 hours
    uint256 _lastVRFRequestId;
    uint256 _lastVRFRequestBlockNumber;
    
    uint256  _sumTickets;
    uint256[] _randomTickets;
    
    // Round parameters
    uint256 public _roundDuration               = 7*28328; // blocks
    
    uint256 public _roundDepositMultiplier      = 50;
    uint256 public _roundHoldMultiplier         = 10;
    
    uint256[] public _roundWinnerRatios;
    
    // 
    uint256 public _roundWinnerPayoutRatio          = 80; // percent
    uint256 public _roundNftHoldersPayoutRatio      = 0; // percent
    
    // Auto Pool
    uint256 public _autoPoolBalance; 
    address[] public _autoPoolUsers; 
    mapping (address => uint256) public _autoPoolUserIndex; // +1
    mapping (address => uint256) public _autoPoolUserJoiningAmount; 
    mapping (address => uint256) public _autoPoolUserBalance; 
    
    //
    uint256 public _minJoiningAmount            = 2000 * 10**18;
    uint256 public _minAutoJoiningAmount        = 4000 * 10**18;
    
    // 
    address public _operationAddress          = 0x311b86F211c4B9652dA5f3eFDA17303ba20559bF;
    address public _dividerAddress            = address(0);
    
    //
    bool public _isGamePaused = false;
    bool public _informToPauseTheGame = false;       
    
    // ChainLink VRF
    VRFCoordinatorV2Interface CHAINLINKVRF_COORDINATOR;
    address _chainLinkVRFCoordinator = 0xc587d9053cd1118f25F645F9E08BB98c9712A4EE; // VRF Coordinator
    bytes32 _chainLinkVRFKeyHash = 0xba6e730de88d94a5510ae6613898bfb0c3de5d16e609c5b7da808747125506f7;  // The gas lane to use, which specifies the maximum gas price to bump to.
    uint32 _chainLinkVRFCallbackGasLimit = 100000;    
    uint16 _chainLinkVRFRequestConfirmations = 20;
    uint64 public _chainLinkVRFSubscriptionId;

    // Events
    event AutoPoolDeposited(address indexed user, uint256 amount);
    event AutoPoolWithdrawal(address indexed user, uint256 amount);
    
    event PlayerDeposited(address indexed user, uint256 indexed roundId, bool isAuto, uint256 amount);
    event PlayerUpdated(address indexed user, uint256 indexed roundId,
        uint256 depositAmount, uint256 depositTickets, uint256 holdAmount, uint256 holdTickets, uint256 tickets);
    
    event Awarded(address indexed winner, uint256 indexed roundId, uint256 amount);
    event OperationTransferred(uint256 indexed roundId, uint256 amount);
    event DividerTransferred(uint256 indexed roundId, uint256 amount);
    
    //
    constructor(IERC20 token, uint64 chainLinkVRFSubscriptionId) 
        VRFConsumerBaseV2(_chainLinkVRFCoordinator)         
    {
        _token = token;
        
        //
        CHAINLINKVRF_COORDINATOR = VRFCoordinatorV2Interface(_chainLinkVRFCoordinator);
        _chainLinkVRFSubscriptionId = chainLinkVRFSubscriptionId;
        
        //
        _roundWinnerRatios.push(50);
        _roundWinnerRatios.push(30);
        _roundWinnerRatios.push(20);
        
        // Init 1st round
        initNewRound();
    }   

   function updateChainLinkVRF(bytes32 keyHash, uint64 subscriptionId,
        uint32 callbackGasLimit, uint16 requestConfirmations) external onlyOwner() {
        if (keyHash != 0) {
            _chainLinkVRFKeyHash = keyHash;        
        }

        if (subscriptionId > 0) {
            _chainLinkVRFSubscriptionId = subscriptionId;        
        }
        
        if (callbackGasLimit > 0) {
            _chainLinkVRFCallbackGasLimit = callbackGasLimit;
        }
        
        if (requestConfirmations > 0) {
            _chainLinkVRFRequestConfirmations = requestConfirmations;
        }        
   }

   function updateRoundParameters(uint256 roundDuration,
        uint256 depositMultiplier, uint256 holdMultiplier,
        uint256 winnerRatio, uint256 nftHoldersRatio,
        uint256 ppNumberAtStart, uint256 ppNumberAtEnd) external onlyOwner() {               

        if (roundDuration > 0) {
            _roundDuration = roundDuration;
            return;
        }

        if (depositMultiplier > 0) {
            _roundDepositMultiplier = depositMultiplier;
        }

        if (holdMultiplier > 0) {
            _roundHoldMultiplier = holdMultiplier;
        }
        
        //
        if (winnerRatio>0) {
            require((winnerRatio >= 70) && (winnerRatio <= 100));            
            require(winnerRatio.add(nftHoldersRatio) <= 100);
            _roundWinnerPayoutRatio         = winnerRatio;
            _roundNftHoldersPayoutRatio     = nftHoldersRatio;
        }
        
        //
        if (ppNumberAtStart > 0) {
            _numberOfPlayersToProcessAtStart = ppNumberAtStart;
        }

        if (ppNumberAtEnd > 0) {
            _numberOfPlayersToProcessAtEnd = ppNumberAtEnd;
        }
    }

    function updateMinAmountAndAddress(uint8 command, uint256 amount, address addr) external onlyOwner() {        
        if (command==0) {            
            require(amount>0);
            _minJoiningAmount = amount;
        } else if (command==1) {
            require(amount>0);
            _minAutoJoiningAmount = amount;
        } else if (command==3) {
            _operationAddress = addr;
        } else if (command==4) {
            _dividerAddress = addr;
        }
    }      

    function cudWinner(uint8 command, uint256 pos, uint256 ratio) external onlyOwner() {
        if (command==0) { 
            // create
            require(_roundWinnerRatios.length < 3);
            _roundWinnerRatios.push(ratio);            
            require(sumRoundRatioWinners()<=100);
        } else if (command==1) { 
            // update
            require(_roundWinnerRatios.length-1 >= pos);
            _roundWinnerRatios[pos] = ratio;            
            require(sumRoundRatioWinners()<=100);
        } else if (command==2) { 
            // delete
            require(_roundWinnerRatios.length > 1);
            _roundWinnerRatios.pop();
        }
    }  
    
    function sumRoundRatioWinners() private view returns (uint256 sum) {
        sum = 0;
        
        for (uint256 i=0; i<_roundWinnerRatios.length; i++)
        {
            sum+=_roundWinnerRatios[i];
        }
    }      
    
    function getRoundWinnerRatios(uint256 Id) external view returns (uint256[] memory) {
        require(Id<_numRounds);
        return (_rounds[Id].winnerRatios);
    }
    
    function getRoundIndexWinners(uint256 Id) external view returns (uint256[] memory) {
        require(Id<_numRounds);
        return (_rounds[Id].indexWinners);
    }  
    
    function getRoundPlayerInfo(uint256 Id, address userAddress) external view returns (
        uint256 depositAmount, uint256 depositTickets, uint256 holdAmount, uint256 holdTickets, uint256 tickets) {
        require(Id<_numRounds);
        Round storage round = _rounds[Id];
        uint256 index = round.playerIndex[userAddress];
        if (index > 0) {
            --index;
            UserInfo storage player = round.players[index];
            return (player.depositAmount, player.depositTickets, 
                    player.holdAmount, player.holdTickets, player.tickets);
        }
        else {
            return (0,0,0,0,0);
        }
    }

    function getRoundPlayerInfo2(uint256 Id, uint256 index) external view returns (address addr,
        uint256 depositAmount, uint256 depositTickets, uint256 holdAmount, uint256 holdTickets, uint256 tickets) {
        require(Id < _numRounds);        
        Round storage round = _rounds[Id];
        require(index < round.numPlayers);   
        UserInfo storage player = round.players[index];
        return (player.addr,
            player.depositAmount, player.depositTickets, 
            player.holdAmount, player.holdTickets, player.tickets);        
    }

    function getRoundPlayerAddress(uint256 Id, uint256 playerIndex) external view returns (address) {
        require(Id<_numRounds);
        Round storage round = _rounds[Id];
        require(playerIndex < round.numPlayers);
        UserInfo storage player = round.players[playerIndex];
        return player.addr;
    }
    
    function getAutoPoolUsersLength() external view returns (uint256) {
        return _autoPoolUsers.length;
    }

    function hasUserJoinedRound(uint256 roundId, address addr) public view returns (bool) {
        if (roundId < _numRounds) {
            if (_rounds[roundId].playerIndex[addr] > 0) {
                return true;
            }
        }
        
        return false;
    }

    function hasUserJoinedActiveRound(address addr) external view returns (bool){
        return hasUserJoinedRound(_numRounds-1, addr);        
    }    
    
    // Auto Pool    
    function depositToAutoPool(uint256 amount) external {        
        // check balance        
        require((amount > 0) && (_token.balanceOf(_msgSender()) >= amount));
        
        // transfer
        _token.transferFrom(_msgSender(), address(this), amount);
        
        //
        _autoPoolUserBalance[_msgSender()] += amount;
        _autoPoolBalance += amount;
        
        // Enable auto join
        if (_autoPoolUserBalance[_msgSender()] >= _autoPoolUserJoiningAmount[_msgSender()] &&
            _autoPoolUserJoiningAmount[_msgSender()] >= _minAutoJoiningAmount)
        {
            enableAutoJoin(_msgSender());
        }
        
        //
        emit AutoPoolDeposited(_msgSender(), amount);
    }
    
    function withdrawFromAutoPool(uint256 amount) external {
        require((amount > 0) && 
                (amount <= _autoPoolUserBalance[_msgSender()]) &&
                (amount <= _autoPoolBalance) &&
                (amount <= _token.balanceOf(address(this))));
                
        // transfer tokens
        _token.transfer(_msgSender(), amount);
        
        // 
        _autoPoolUserBalance[_msgSender()] -= amount;
        _autoPoolBalance -= amount;

        // Disable auto join
        if (_autoPoolUserBalance[_msgSender()] < _autoPoolUserJoiningAmount[_msgSender()])
        {
            disableAutoJoin(_msgSender());
        }
                
        //
        emit AutoPoolWithdrawal(_msgSender(), amount);
    }
    
    function userUpdateAutoPoolJoiningAmount(uint256 amount) external {
        
        require(_token.totalSupply() >= amount);
        
        _autoPoolUserJoiningAmount[_msgSender()] = amount;
        
        // Enable auto join
        if (amount >= _minAutoJoiningAmount && _autoPoolUserBalance[_msgSender()]>= amount)
        {
            enableAutoJoin(_msgSender());
        }
    }
    
    function enableAutoJoin(address userAddress) private {
        
        if (_autoPoolUserIndex[userAddress]==0) {  
            _autoPoolUsers.push(userAddress);
            _autoPoolUserIndex[userAddress] = _autoPoolUsers.length;
        }
    }
    
    function disableAutoJoin(address userAddress) private {
        
        uint256 indexOfUser = _autoPoolUserIndex[userAddress];
        
        if (indexOfUser>0) {
        
            indexOfUser--; // index in array
            
            if (indexOfUser < _autoPoolUsers.length - 1)
            {
                address addrLastElement = _autoPoolUsers[_autoPoolUsers.length-1];
                
                // Move the last element into the place to delete
                _autoPoolUsers[indexOfUser] = addrLastElement;
                
                // update index of last element
                _autoPoolUserIndex[addrLastElement] = indexOfUser + 1;
            }
            
            // update index of user to zero
            _autoPoolUserIndex[userAddress] = 0;
            
            // Remove the last element
            _autoPoolUsers.pop();
        }
    }      
    
    function isUserInAutoPool(address userAddress) public view returns (bool) {
        return (_autoPoolUserIndex[userAddress] > 0);
    }
    
    // Init new round
    function initNewRound() private {        
        uint256 roundId = _numRounds++;
        
        Round storage newRound = _rounds[roundId];
        newRound.startBlock = block.number;
        newRound.endBlock = block.number + _roundDuration;
        newRound.endBlock2 = newRound.endBlock;
        newRound.Id = roundId;
        newRound.depositMultiplier = _roundDepositMultiplier;
        newRound.holdMultiplier = _roundHoldMultiplier;
        newRound.winnerPayoutRatio = _roundWinnerPayoutRatio;
        newRound.nftHoldersPayoutRatio = _roundNftHoldersPayoutRatio;
        
        //
        for (uint256 i = 0; i < _roundWinnerRatios.length; i++) {
            newRound.winnerRatios.push(_roundWinnerRatios[i]);
        }       
        
        //        
        if (_informToPauseTheGame) {
            _informToPauseTheGame = false;
            _isGamePaused = true;
            _pIndex = 0;
            _activeRoundState = RoundState.ACTIVE;
        } else {
            _pIndex = (_autoPoolUsers.length > 0 ? _autoPoolUsers.length : 0 );
            _activeRoundState = (_pIndex == 0 ? RoundState.ACTIVE : RoundState.START);
        }
    }
    
    function controlTheGame(uint8 command) external onlyOwner() {
        if (command==0) { // Pause            
            _informToPauseTheGame = !_informToPauseTheGame;
        } else if (command==1) {// Resume
            require(_isGamePaused);
            _isGamePaused = false;       
            _informToPauseTheGame = false;     
        } else { // Force to end active round
            require(_activeRoundState == RoundState.ACTIVE);
        
            //
            Round storage round = _rounds[_numRounds-1];
            round.endBlock = block.number;
        }        
    }    

    function userJoinActiveRound(uint256 depositAmount) external {
        
        require(_isGamePaused == false, "Game is paused.");
        require(depositAmount > 0, "Amount is zero.");
        
        //
        require(_activeRoundState == RoundState.ACTIVE, "Cannot join at this state.");
        
        //
        Round storage round = _rounds[_numRounds-1];
        
        //
        require(block.number < round.endBlock, "Cannot join at this block.");
        
        //
        if (round.playerIndex[_msgSender()] == 0) {
            require(depositAmount >= _minJoiningAmount, "Deposit amount is less than minimum joining amount.");    
        }       
        
        // check balance
        uint256 balance = _token.balanceOf(_msgSender());
        require(balance >= depositAmount, "Balance is not enough.");
        
        // transfer the fee
        _token.transferFrom(_msgSender(), address(this), depositAmount);
        
        round.depositAmount += depositAmount;
        
        // add/update player of the round
        if (round.playerIndex[_msgSender()] > 0) {
            // update 
            UserInfo storage player = round.players[round.playerIndex[_msgSender()]-1];
            player.depositAmount += depositAmount;
            
            // add tickets for newly deposited amount
            uint256 newDepositTickets = depositAmount*round.depositMultiplier;
            player.depositTickets += newDepositTickets;
            player.tickets += newDepositTickets;
            round.totalTickets += newDepositTickets;
            
            //
            emit PlayerUpdated(_msgSender(), round.Id, 
                player.depositAmount, player.depositTickets, player.holdAmount, player.holdTickets, player.tickets);
        }
        else {
            // add player 
            uint256 holdDuration = ((round.endBlock>=block.number?round.endBlock-block.number:0)*100) / (round.endBlock-round.startBlock);
            uint256 remainingBalance = (balance-depositAmount) + _autoPoolUserBalance[_msgSender()];
            
            //
            round.players[round.numPlayers] = UserInfo({
                addr: _msgSender(),
                depositAmount: depositAmount,
                depositTickets: depositAmount*round.depositMultiplier,
                holdAmount: remainingBalance,
                holdTickets: remainingBalance*round.holdMultiplier*holdDuration/100,
                tickets: 0
            });

            //
            UserInfo storage player = round.players[round.numPlayers];
            player.tickets = player.depositTickets + player.holdTickets;
            round.totalTickets += player.tickets;
            
            //
            ++round.numPlayers;
            round.playerIndex[_msgSender()] = round.numPlayers;
            
            //
            emit PlayerUpdated(_msgSender(), round.Id, 
                player.depositAmount, player.depositTickets, player.holdAmount, player.holdTickets, player.tickets);
        }
        
        //
        emit PlayerDeposited(_msgSender(), round.Id, false, depositAmount);
    }    

    // KEEPER
    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory performData) {
        upkeepNeeded = hasWork();
        performData = "";
    }

    function performUpkeep(bytes calldata /* performData */) external override {        
        if (hasWork()==false) {
            return;
        }

        //
        Round storage round = _rounds[_numRounds-1];
        
        //
        if (_activeRoundState == RoundState.START) {                       
            // Start of round
            uint256 countPlayer = _numberOfPlayersToProcessAtStart;
            
            uint256 mRoundTotalTickets = round.totalTickets;
            uint256 mRoundDepositAmount = round.depositAmount;
            uint256 mRoundNumberPlayers = round.numPlayers;
            uint256 mRoundIndex = _pIndex;
            
            // Not overflow
            if (_autoPoolUsers.length>0)
            {
                if (mRoundIndex > _autoPoolUsers.length) {
                    mRoundIndex = _autoPoolUsers.length;
                }
            } else {
                _pIndex = 0;
                _activeRoundState = RoundState.ACTIVE;
                                
                return;
            }
            
            //
            uint256 joiningAmount;
            uint256 autoPoolUserBalance;
            
            //
            while (countPlayer>0 && mRoundIndex>0) {
                
                address addr = _autoPoolUsers[mRoundIndex-1];
                
                // check if this address is started
                if (round.playerIndex[addr]>0) {
                    if (mRoundIndex>1) {
                        --mRoundIndex;
                        continue;
                    } else {
                        mRoundIndex = 0;
                        break;
                    }
                }
                
                // meet the requirements?
                joiningAmount = _autoPoolUserJoiningAmount[addr];
                autoPoolUserBalance = _autoPoolUserBalance[addr];
                
                if (autoPoolUserBalance < joiningAmount || joiningAmount < _minAutoJoiningAmount) {
                    
                    disableAutoJoin(addr);
                    
                    //
                    if (mRoundIndex>1) {
                        --mRoundIndex;
                        continue;
                    } else {
                        mRoundIndex = 0;
                        break;
                    }
                }
                
                //
                autoPoolUserBalance -= joiningAmount;
                
                //
                require(_autoPoolBalance >= joiningAmount, "Auto Pool balance is not enough");
                _autoPoolBalance -= joiningAmount;
                
                //
                _autoPoolUserBalance[addr] = autoPoolUserBalance;
                mRoundDepositAmount += joiningAmount;
                
                //
                uint256 balance = _token.balanceOf(addr) + autoPoolUserBalance;
                
                // add player
                round.players[mRoundNumberPlayers] = UserInfo({
                    addr: addr,
                    depositAmount: joiningAmount,
                    depositTickets: joiningAmount*round.depositMultiplier,
                    holdAmount: balance,
                    holdTickets: balance*round.holdMultiplier,
                    tickets: 0
                });
                
                //
                UserInfo storage player = round.players[mRoundNumberPlayers];
                
                //
                player.tickets = player.depositTickets + player.holdTickets;
                mRoundTotalTickets += player.tickets;
                
                //
                ++mRoundNumberPlayers;
                round.playerIndex[addr] = mRoundNumberPlayers;
                
                //
                --countPlayer;
                
                //
                emit PlayerDeposited(addr, round.Id, true, joiningAmount);
                emit PlayerUpdated(addr, round.Id, 
                    player.depositAmount, player.depositTickets, player.holdAmount, player.holdTickets, player.tickets);
                
                //
                if (mRoundIndex>1) {
                    --mRoundIndex;
                } else {
                    mRoundIndex = 0;
                    break;
                }
            }
            
            //
            round.totalTickets = mRoundTotalTickets;
            round.depositAmount = mRoundDepositAmount;
            round.numPlayers = mRoundNumberPlayers;
            _pIndex = mRoundIndex;
            
            // 
            if (mRoundIndex==0) {
                _activeRoundState = RoundState.ACTIVE;
            }            
        } 
        else if (_activeRoundState == RoundState.ACTIVE) {
            // 
            _activeRoundState = RoundState.END;
            
            //
            _pIndex = round.numPlayers;
            _endRoundState = 0;            
        }
        else if (_activeRoundState == RoundState.END) {
            // End of round
            if (round.numPlayers==0) { // no player
                initNewRound();                
                return;
            }
            
            //
            if (_endRoundState==0) { // State 0: check balance of players
                uint256 countPlayer = _numberOfPlayersToProcessAtEnd;
                
                uint256 mRoundTotalTickets = round.totalTickets;
                uint256 mRoundIndex = _pIndex;
                uint256 holdTickets;
                
                while (countPlayer>0 && mRoundIndex>0) {
                    //
                    UserInfo storage player = round.players[mRoundIndex-1];
                    holdTickets = player.holdTickets;
                    
                    if (holdTickets > 0) {
                        // check balance
                        uint256 balance = _token.balanceOf(player.addr) + _autoPoolUserBalance[player.addr];
                        
                        if (balance < player.holdAmount) {
                            // reset hold tickets due to player does not hold token as the first deposit
                            player.tickets          -= holdTickets;
                            mRoundTotalTickets      -= holdTickets;
                            player.holdTickets      = 0;
                            
                            //
                            emit PlayerUpdated(player.addr, round.Id, 
                                player.depositAmount, player.depositTickets, player.holdAmount, player.holdTickets, player.tickets);
                        }
                    }
                    
                    //
                    --countPlayer;
                    --mRoundIndex;
                }
                
                round.totalTickets = mRoundTotalTickets;
                _pIndex = mRoundIndex;
                
                //
                if (mRoundIndex==0) {
                    round.endBlock2 = block.number;
                    _lastVRFRequestBlockNumber = 0;
                    _endRoundState = 1;
                }                
            }
            else if (_endRoundState==1) { // State 1: get random numbers based on total tickets. Random number:  [0, total tickets-1]
                
                if (round.randomResult.length == 0) {
                    //
                    if (block.number > _lastVRFRequestBlockNumber + VRF_WAITING_BLOCKS) {                        
                        _lastVRFRequestId = CHAINLINKVRF_COORDINATOR.requestRandomWords(
                            _chainLinkVRFKeyHash,
                            _chainLinkVRFSubscriptionId,
                            _chainLinkVRFRequestConfirmations,
                            _chainLinkVRFCallbackGasLimit,
                            uint32(round.winnerRatios.length)
                        );
                        
                        _lastVRFRequestBlockNumber = block.number;
                    }
                }
                else {
                    // 
                    _endRoundState = 2;
                    _pIndex = round.numPlayers;
                    _sumTickets = 0;
                    
                    //
                    delete _randomTickets;                    

                    for (uint256 i = 0; i < round.winnerRatios.length; i++) {
                        _randomTickets.push(round.randomResult[i] % round.totalTickets);
                    }
                    
                    sortDesc(_randomTickets, int(0), int(_randomTickets.length-1), false, round.players);                    
                }
                
            } 
            else if (_endRoundState==2) { // State 2: Find winners based on random ticket numbers
                
                require(_randomTickets.length > 0);
            
                uint256 countPlayer = _numberOfPlayersToProcessAtEnd;
                uint256 mRoundIndex = _pIndex;
                uint256 sumTickets = _sumTickets;
                uint256 idx;
                
                while (countPlayer>0 && mRoundIndex>0) {
                    idx = mRoundIndex-1;
                    
                    //
                    sumTickets += round.players[idx].tickets;
                    
                    while (_randomTickets.length>0) {
                        if (sumTickets > _randomTickets[_randomTickets.length-1]) {
                            // found a winner
                            round.indexWinners.push(idx);
                            _randomTickets.pop();
                        }
                        else
                        {
                            break;
                        }
                    }
                    
                    // finish ?
                    if (_randomTickets.length==0) {
                        --countPlayer;
                        mRoundIndex=0;                        
                        break;
                    }
                    
                    //
                    --countPlayer;
                    --mRoundIndex;
                }
                
                //
                _pIndex = mRoundIndex;
                _sumTickets = sumTickets;
                
                // finished
                if (mRoundIndex==0) {
                    _endRoundState = 3;
                }                
            } 
            else if (_endRoundState==3) { // State 3: Reward
                
                require(round.indexWinners.length > 0);

                // Sort winners based on tickets descending
                sortDesc(round.indexWinners, int(0), int(round.indexWinners.length-1), true, round.players);
                
                // 
                uint256 balance = _token.balanceOf(address(this));
                uint256 pBalance = balance.sub(_autoPoolBalance);
                uint256 rBalance = pBalance.sub(round.depositAmount);
                
                // Reward winners
                uint256 winnersAmount = round.depositAmount * round.winnerPayoutRatio / 100;
                uint256 oneWinnerAmount;
                
                for (uint256 i=0; i < round.indexWinners.length && i < round.winnerRatios.length; i++) {
                    oneWinnerAmount = winnersAmount*round.winnerRatios[i]/100;
                    _token.transfer(round.players[round.indexWinners[i]].addr, oneWinnerAmount);
                    
                    //
                    emit Awarded(round.players[round.indexWinners[i]].addr, round.Id, oneWinnerAmount);
                }
                
                // Transfer to Divider Wallet
                uint256 nftHoldersAmount = round.depositAmount * round.nftHoldersPayoutRatio / 100;
                
                if (nftHoldersAmount>0) {
                    _token.transfer(_dividerAddress, nftHoldersAmount);
                    emit DividerTransferred(round.Id, nftHoldersAmount);
                }
               
                // Transfer to Operation Wallet
                uint256 operationAmount = rBalance +
                    round.depositAmount * (100 - round.winnerPayoutRatio - round.nftHoldersPayoutRatio) / 100;
                    
                if (operationAmount>0) {
                    _token.transfer(_operationAddress, operationAmount);
                    emit OperationTransferred(round.Id, operationAmount);
                }
                
                // Start a new round
                initNewRound();
            }
        }        
    }
    
    function hasWork() private view returns (bool) {
        
        if (_isGamePaused) {
            return false;
        }

        Round storage round = _rounds[_numRounds-1];
        
        //
        if (_activeRoundState == RoundState.START)
        {
            if (_pIndex>0) {
                return true;
            }
        } 
        else if (_activeRoundState == RoundState.ACTIVE) {
            if (round.endBlock <= block.number) {
                return true;    
            }
        }
        else  {            
            if (round.numPlayers>0) {
                if (_endRoundState<=3) {
                    if (_endRoundState==1) {
                        if ((round.randomResult.length == 0 && block.number > _lastVRFRequestBlockNumber + VRF_WAITING_BLOCKS) ||
                            (round.randomResult.length > 0)) {
                            return true;
                        }
                        else {
                            return false;
                        }
                    }
                    else {
                        return true;
                    }
                }
            }
            else {
                return true;
            }
        }
            
        //
        return false;
    }

    /**
     * Callback function used by VRF Coordinator
     */      
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        if (_lastVRFRequestId == requestId) {
            _rounds[_numRounds-1].randomResult = randomWords;
        }
    }

    // SORTING    
    function sortDesc(uint[] storage arr, int left, int right, bool usePlayerTickets, mapping (uint256 => UserInfo) storage players) private {
        int i = left;
        int j = right;
        if(i==j) return;
        uint pivot = (usePlayerTickets ? players[arr[uint(left + (right - left) / 2)]].tickets : arr[uint(left + (right - left) / 2)]);
        while (i < j) {
            if (usePlayerTickets) {
                while (players[arr[uint(i)]].tickets > pivot) i++;
                while (players[arr[uint(j)]].tickets < pivot) j--;
            }
            else {
                while (arr[uint(i)] > pivot) i++;
                while (arr[uint(j)] < pivot) j--;
            }
            if (i <= j) {
                (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j) {
            sortDesc(arr, left, j, usePlayerTickets, players);
        }

        if (i < right) {
            sortDesc(arr, i, right, usePlayerTickets, players);
        }
    }
}
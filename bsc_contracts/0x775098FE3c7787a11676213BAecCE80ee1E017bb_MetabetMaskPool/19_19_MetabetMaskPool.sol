// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./interfaces/IMetabetMask.sol";
import "./interfaces/ITreasury.sol";
import "./interfaces/ITokenPool.sol";
import "./interfaces/IBNBPool.sol";

/** 
 * This smart-contract takes bets placed on sport events.
 * Then once the event outcome is confirmed,
 * it makes the earnings ready for the winners 
 * to claim
 * @notice Takes Bets and handles payouts for sport events
 * @title  a Smart-Contract in charge of handling bets on a sport events.
 */
contract MetabetMaskPool is 
    Initializable, 
    UUPSUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint;

    /**
    *  @dev Instance of GOAL token
    */
    IERC20Upgradeable public GOAL;

    /**
    *  @dev Instance of BUSD token
    */
    IERC20Upgradeable public BUSD;

    /**
    *  @dev Instance of USDC token
    */
    IERC20Upgradeable public USDC;

    /**
    *  @dev Instance of METABET token
    */
    IERC20Upgradeable public METABET;

    /**
    *  @dev Instance of the sport events(used to register sport events get their outcome).
    */
    IMetabetMask public sportOracle;

    /**
    *  @dev Instance of the metabetmask treasury (used to handle fees funds).
    */
    ITreasury public treasury;


    

    /**
     *  @dev for any given event, get the Bet that have been made by a user for that event
     *  map composed of (event id => address of user => Bet ) pairs
     */
    mapping(bytes32 => mapping(address => Bet)) public eventToUserBet;


    /**
     *  @dev for any given event, get the pool that have been deposited with a token for that event
     *  map composed of (event id => address of token => pool ) pairs
     */
    mapping(bytes32 => mapping(address => uint)) public eventToPoolTotal;

    /**
     *  @dev for any given event, get the pool that have been deposited with a token for that event
     *  map composed of (event id => address of token => pool ) pairs
     */
    mapping(bytes32 => mapping(address => mapping(int8 => uint))) public eventToPoolTotalTeam;

    /**
     *  @dev for any given event, get the pool that have been deposited with a token for that event
     *  map composed of (event id => address of token => pool ) pairs
     */
    mapping(bytes32 => mapping(address => uint)) public eventToPoolSize;


    /**
     * @dev list of all eventIds predicted per user,
     * ie. a map composed (player address => eventIds) pairs
     */
    mapping(address => bytes32[]) public userToEvents;


    /**
     *  @dev for any given event, get a list of all addresses that predicted for that event
     */
    mapping(bytes32 => address[]) public eventToUsers;


    /**
     *  @dev for any given token address, get a fee for the token
     */
    mapping(address => uint) public tokenFees;

    



    /**
     * @dev payload of a Bet on a sport event
     */
    struct Bet {
        address user;          // who placed it
        address token;
        bytes32 eventId;       // id of the sport event as registered in the Oracle
        uint    amount;        // Bet amount
        uint    timestamp;
        int8    result;    // user predicted result
        bool    claimed;        // check if user(winner) claimed his/her reward
    }

    struct LeaderBoard {
        address user;
        bytes32 id;
        uint amount;
    }

    /**
     * @dev Emitted when a Bet is placed
     */
    event BetPlaced(
        bytes32 indexed _eventId,
        address indexed _player,
        int8    result,
        uint    _amount
    );

    /**
    * @dev Emitted when user claims reward
    */
    event Claim( address indexed user, bytes32 indexed eventId, uint reward);

    /**
    * @dev Emitted when the Sport Event Oracle is set
    */
    event OracleAddressSet( address _address);

    /**
     * @dev Emitted when the token fee is set
     */
    event TokenFeeUpdated(uint newFee);

    /**
     * @dev check that the address passed is not 0. 
     */
    modifier notAddress0(address _address) {
        require(_address != address(0), "Address 0 is not allowed");
        _;
    }

    /**
    * @dev all the sport events
    */
    LeaderBoard[] private boards;


    
    /**
     * @notice Contract constructor
     * @param _oracleAddress oracle contract address
     * @param _treasury treasury address
     */
    function initialize(
        address _oracleAddress,
        address _treasury)public initializer{
            __Ownable_init();

        sportOracle = IMetabetMask(_oracleAddress);
        treasury = ITreasury(_treasury);
        GOAL = IERC20Upgradeable(0x438Fc473Ba340D0734E2D05acdf5BEE775D1B0A4);
        METABET = IERC20Upgradeable(0xdc50861c0895470f25602e03Eab0c5503F5b731d);
        BUSD = IERC20Upgradeable(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
        USDC = IERC20Upgradeable(0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d);
        tokenFees[address(BUSD)] = tokenFees[address(USDC)] = tokenFees[address(0)] = 1;
    }


    /**
     *@notice Authorizes upgrade allowed to only proxy
     *@param newImplementation the address of the new implementation contract
     */
    function _authorizeUpgrade(address newImplementation)internal override onlyOwner{}

    
    /**
     * @notice sets the address of the sport event oracle contract to use 
     * @dev setting a wrong address may result in false return value, or error 
     * @param _oracleAddress the address of the sport event oracle 
     */
    function setOracleAddress(address _oracleAddress)
        external 
        onlyOwner notAddress0(_oracleAddress)
    {
        sportOracle = IMetabetMask(_oracleAddress);
        emit OracleAddressSet(_oracleAddress);
    }


    /**
     * @notice update the fee of the token
     * @param _fee of the updated fee 
     */
    function updateTokenFee(uint _fee, address _token)
        external onlyOwner
    {
        require(_fee != 0, "MetabetMaskPool: fee cannot be 0");
        tokenFees[_token] = _fee;
        emit TokenFeeUpdated(_fee);
    }


    /**
    * @notice gets a list of all currently predictable events
    * @return pendingEvents the list of pending sport events 
    */
    function getPredictableEvents()
        public view returns (IMetabetMask.SportEvent[] memory)
    {
        return sportOracle.getPendingEvents(); 
    }

    /**
    * @notice gets a list of all currently live events
    * @return liveEvents the list of live sport events 
    */
    function getLiveEvents()
        public view returns (IMetabetMask.SportEvent[] memory)
    {
        return sportOracle.getLiveEvents(); 
    }

    /**
    * @notice gets a list of events, fails if an eventId does not exist
    * @param _eventIds the ids of events
    * @return the list of events needed 
    */
    function getEvents(bytes32[] memory _eventIds)
        public view returns (IMetabetMask.SportEvent[] memory)    
    {
        return sportOracle.getEvents(_eventIds);
    }


    /**
     * @notice get the reward multiplier
     * @return _multiplier reward multiplier
     */
    function getPayout(address _user,address _token, bytes32 _eventId)public view returns(uint)
    {
        Bet memory userBet = eventToUserBet[_eventId][_user];
        uint odd = getOdds(userBet.result, _token, _eventId);
        if(userBet.eventId == _eventId){
            return (userBet.amount * odd);
        }

        return 0;
    }


    /**
     * @notice get the event pool total
     * @return _poolTotal return pool total
     */
    function getPoolTotal(address _token, bytes32 _eventId)public view returns(uint)
    {
        uint poolTotal = eventToPoolTotal[_eventId][_token];

        return poolTotal;
    }

    /**
     * @notice get the event pool total
     * @return _poolTotal return pool total
     */
    function getPoolTotalTeam(int8 _team, address _token, bytes32 _eventId)public view returns(uint)
    {
        uint poolTotalTeam = eventToPoolTotalTeam[_eventId][_token][_team];

        return poolTotalTeam;
    }


    /**
     * @notice get the reward multiplier
     * @return _multiplier reward multiplier
     */
    function getPoolSize(address _token, bytes32 _eventId)public view returns(uint)
    {
        uint poolSize = eventToPoolSize[_eventId][_token];

        return poolSize;
    }


    /**
     * @notice get the event odds
     * @return _odd reward odd
     */
    function getOdds(int8 _team, address _token, bytes32 _eventId)public view returns(uint)
    {
        uint poolTotalTeam = getPoolTotalTeam(_team, _token, _eventId);
        uint poolTotal = getPoolTotal(_token, _eventId);

        if(poolTotalTeam != 0 && poolTotal != 0){
            return (poolTotal / poolTotalTeam);
        }
        else
        {
            return 0;
        }
    }



    /**
    * @notice gets a list of events
    * @param indexes the ids of events
    * @return the list of events needed 
    */
    function getIndexedEvents(uint[] memory indexes)
        public view returns (IMetabetMask.SportEvent[] memory)    
    {
        return sportOracle.getIndexedEvents(indexes);
    }

    /**
    * @notice gets the total number of events
    * @return the total number of events
    */
    function getEventsLength()
        public view returns (uint)
    {
        return sportOracle.getEventsLength();
    }



    /**
     * @notice predict on the given event 
     * @param _eventId      id of the sport event on which to bet 
     * @param _predictResult the predicted result of the event
     */
    function bet(
        bytes32 _eventId,
        address _token,
        uint _amount,
        int8 _predictResult)
        public nonReentrant
    {
        // Make sure game has not started or ended
        bytes32[] memory ids = new bytes32[](1);

        //%fee
        uint fee = (_amount.mul(tokenFees[_token])).div(100);
        uint deposit = _amount.sub(fee);

        ids[0] = _eventId;
        IMetabetMask.SportEvent memory sportEvent = sportOracle.getEvents(ids)[0];
        require(sportEvent.startTimestamp >= block.timestamp, "MetabetMaskPool: Event has started or ended.");

        userToEvents[msg.sender].push(_eventId); 

        eventToUsers[_eventId].push(msg.sender);

        eventToPoolTotal[_eventId][_token] += _amount;

        eventToPoolTotalTeam[_eventId][_token][_predictResult] += _amount;

        eventToPoolSize[_eventId][_token] += 1;
        Bet memory _bet = Bet(
                msg.sender,
                _token,
                _eventId,
                deposit,
                block.timestamp,
                _predictResult,
                false
            );

        eventToUserBet[_eventId][msg.sender] = _bet;


        if(_token == address(GOAL)){
            bool success = IERC20Upgradeable(_token).transferFrom(
                msg.sender,
                sportEvent.goalPool,
                _amount
            );
            require(success);
        } else if(_token == address(METABET)){
            boards.push(LeaderBoard(msg.sender, _eventId,_amount));
            bool success = IERC20Upgradeable(_token).transferFrom(
                msg.sender,
                sportEvent.metabetPool,
                _amount
            );
            require(success);
        } else if(_token == address(BUSD)){
            bool success = IERC20Upgradeable(_token).transferFrom(
                msg.sender,
                sportEvent.busdPool,
                _amount
            );
            require(success);
        } else if(_token == address(USDC)){
            bool success = IERC20Upgradeable(_token).transferFrom(
                msg.sender,
                sportEvent.usdcPool,
                _amount
            );
            require(success);
        }


        if(_token == address(BUSD)){
            ITokenPool(sportEvent.busdPool).withdrawToken(
                _token, 
                address(treasury), 
                fee
            );
        }

        else if(_token == address(USDC)){
            ITokenPool(sportEvent.usdcPool).withdrawToken(
                _token, 
                address(treasury), 
                fee
            );
        }

        emit BetPlaced(
            _eventId,
            msg.sender,
            _predictResult,
            deposit
        );
    }

    /**
     * @notice predict on the given event 
     * @param _eventId      id of the sport event on which to bet 
     * @param _predictResult the predicted result of the event
     */
    function betBNB(
        bytes32 _eventId,
        uint _amount,
        int8 _predictResult)
        public payable nonReentrant
    {
        require(msg.value >= _amount);

        //%fee
        uint fee = (_amount.mul(tokenFees[address(0)])).div(100);
        uint deposit = _amount.sub(fee);

        // Make sure game has not started or ended
        bytes32[] memory ids = new bytes32[](1);
        ids[0] = _eventId;
        IMetabetMask.SportEvent memory sportEvent = sportOracle.getEvents(ids)[0];
        require(sportEvent.startTimestamp >= block.timestamp, "MetabetMaskPool: Event has started or ended.");

        userToEvents[msg.sender].push(_eventId); 

        eventToUsers[_eventId].push(msg.sender);
        eventToPoolTotal[_eventId][address(0)] += _amount;
        eventToPoolTotalTeam[_eventId][address(0)][_predictResult] += _amount;

        eventToPoolSize[_eventId][address(0)] += 1;

        Bet memory _bet = Bet(
                msg.sender,
                address(0),
                _eventId,
                deposit,
                block.timestamp,
                _predictResult,
                false
            );

        eventToUserBet[_eventId][msg.sender] = _bet;

        //trasfer bnb
        payable(address(treasury)).transfer(fee);
        payable(sportEvent.bnbPool).transfer(deposit);

        emit BetPlaced(
            _eventId,
            msg.sender,
           _predictResult,
            deposit
        );
    }


    /**
     * @notice get the users status on an event if he win or loss 
     * @param _user  user who made the Bet 
     * @param _eventId id of the predicted event
     * @return  bool return true if user win and false when loss
     */
    function userPredictStatus(
        address _user, 
        bytes32 _eventId)
        public
        view returns(bool)
    {
        bytes32[] memory eventArr = new bytes32[](1); 
        eventArr[0] = _eventId;
        IMetabetMask.SportEvent[] memory events =  sportOracle.getEvents(eventArr);
        
        //require that event is decided
        require(events[0].outcome == IMetabetMask.EventOutcome.Decided, 
        "MetabetMaskPool: Event has not been decided yet");

        // Require that event id exists
        require(sportOracle.eventExists(_eventId), "MetabetMaskPool: Event does not exist"); 
        Bet memory userBet = eventToUserBet[_eventId][_user];
        
        if(userBet.result ==events[0].result){
            
           return true;
        } else{
            return false;
        }

    }




    /**
     * @notice get bets on event(s)
     * @return output return array of bets
     */
    function getBets(bytes32 _eventId)
        public
        view returns(Bet[] memory)
    {
        uint length = eventToUsers[_eventId].length;
        Bet[] memory output = new Bet[](length);
        for(uint i = 0; i < length; i++){
            output[i] = eventToUserBet[_eventId][eventToUsers[_eventId][i]];
        }

        return output;
    }


    /**
     * @notice get all user bets
     * @return output return array of bets
     */
    function getAllUserBets(address _user)
        public
        view returns(Bet[] memory)
    {
        uint length = userToEvents[_user].length;
        Bet[] memory output = new Bet[](length);
        for(uint i = 0; i < length; i++){
            output[i] = eventToUserBet[userToEvents[_user][i]][_user];
        }

        return output;
    }

    /**
     * @notice get all user active bets
     * @return output return array of bets
     */
    function getAllUserActiveBets(address _user)
        public
        view returns(Bet[] memory)
    {
        IMetabetMask.SportEvent[] memory events = sportOracle.getLiveEvents();
        Bet[] memory output = new Bet[](events.length);
        for(uint i = 0; i < events.length; i++){
            output[i] = eventToUserBet[events[i].id][_user];
        }

        return output;
    }


    /**
     * @notice claim reward
     * @param _eventIds ids of events to claim reward
     */
    function claim(bytes32[] memory _eventIds, address _token)
        external nonReentrant
    {
        bytes32[] memory eventArr = new bytes32[](_eventIds.length); 
        bool[] memory predictStatuses = new bool[](_eventIds.length);
        IMetabetMask.SportEvent[] memory events =  sportOracle.getEvents(_eventIds);
         

        for(uint i; i < _eventIds.length; i++){
            eventArr[i] = _eventIds[i];
            require(userPredictStatus(msg.sender, _eventIds[i]),
                "MetabetMaskPool: Only winner can claim reward");
            require(!eventToUserBet[_eventIds[i]][msg.sender].claimed,
                "MetabetMaskPool: User has already claimed reward");

            
            Bet storage userPrediction = eventToUserBet[_eventIds[i]][msg.sender];
            userPrediction.claimed = true;
            uint reward = getPayout(msg.sender, _token, _eventIds[i]);
            
        if (_token == address(0)) {
            IBNBPool(events[i].bnbPool).withdraw(reward);
            (bool success, ) = msg.sender.call{value: reward}("");
            require(success, "claim of bnb was unsuccessful");
        } else if(_token == address(GOAL)){
            ITokenPool(events[i].goalPool).withdrawToken(
                _token, 
                msg.sender, 
                reward
            );
        } else if(_token == address(BUSD)){
            ITokenPool(events[i].busdPool).withdrawToken(
                _token, 
                msg.sender, 
                reward
            );
        }

            emit Claim(msg.sender, _eventIds[i], reward);
        }

    } 


    function getLeaderBoard() external returns(LeaderBoard[] memory){

        
        // Collect up all the boards 
        LeaderBoard[] memory output = new LeaderBoard[](boards.length);

        uint index = 0;
        for(uint n = 0; n < boards.length; n++){
            if(userPredictStatus(boards[n].user, boards[n].id)){
                output[index] = boards[n];
                index = index + 1;
            }
        }

        for (uint n = 1;  n < output.length;  n = n + 1) {
            uint key = output[n].amount;
            uint j = n - 1;
            while((j) >= 0 && (output[j].amount > key)){
                output[j+1].amount = output[j].amount;
                j--;
            }
            output[j+1].amount = key;
        }

        return output;
    }

    //for depositing BNB as currency
    receive() external payable {
    }

}
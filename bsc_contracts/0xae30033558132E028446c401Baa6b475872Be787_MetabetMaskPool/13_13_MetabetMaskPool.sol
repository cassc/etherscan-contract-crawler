// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
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
    Ownable, 
    ReentrancyGuard{
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    /**
    *  @dev Instance of GOAL token
    */
    IERC20 public GOAL;

    /**
    *  @dev Instance of BUSD token
    */
    IERC20 public BUSD;

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
        require(_address != address(0), "MetabetMaskPool: Address 0 is not allowed");
        _;
    }

    
    /**
     * @notice Contract constructor
     * @param _oracleAddress oracle contract address
     * @param _goal goal token address
     * @param _busd busd token address
     */
    constructor(
        address _oracleAddress,
        address _treasury,
        IERC20 _goal,
        IERC20 _busd
        ){
            sportOracle = IMetabetMask(_oracleAddress);
            treasury = ITreasury(_treasury);
            GOAL = _goal;
            BUSD = _busd;
            tokenFees[address(_goal)] = tokenFees[address(_busd)] = tokenFees[address(0)] = 1;
    }

    
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
            bool success = IERC20(_token).transferFrom(
                msg.sender,
                sportEvent.goalPool,
                deposit
            );
            require(success);
        } else {
            bool success = IERC20(_token).transferFrom(
                msg.sender,
                sportEvent.busdPool,
                deposit
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
     * @param _eventIds id of the predicted events
     * @return  bool return true if user win and false when loss
     */
    function userPredictStatus(
        address _user, 
        bytes32[] memory _eventIds)
        public
        view returns(bool[] memory)
    {
        bool[] memory output = new bool[](_eventIds.length);
        IMetabetMask.SportEvent[] memory events =  sportOracle.getEvents(_eventIds);
        
        for (uint i = 0; i < _eventIds.length; i = i + 1 ) {

            //require that event is decided
            require(events[i].outcome == IMetabetMask.EventOutcome.Decided, 
            "MetabetMaskPool: Event has not been decided yet");

            // Require that event id exists
            require(sportOracle.eventExists(_eventIds[i]), "MetabetMaskPool: Event does not exist"); 
            Bet memory userBet = eventToUserBet[_eventIds[i]][_user];
            
            if(userBet.result ==events[i].result){
                
                output[i] = true;
            } else{
                output[i] = false;
            }

        }

        return output;
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
     * @notice claim reward
     * @param _eventIds ids of events to claim reward
     */
    function claim(bytes32[] memory _eventIds, address _token)
        external nonReentrant
    {
        bytes32[] memory eventArr = new bytes32[](_eventIds.length); 
        bool[] memory predictStatuses = new bool[](_eventIds.length);
        IMetabetMask.SportEvent[] memory events =  sportOracle.getEvents(_eventIds);
        predictStatuses = userPredictStatus(msg.sender, _eventIds);

        for(uint i; i < _eventIds.length; i++){
            eventArr[i] = _eventIds[i];
            require(predictStatuses[i],
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

    //for depositing BNB as currency
    receive() external payable {
    }

}
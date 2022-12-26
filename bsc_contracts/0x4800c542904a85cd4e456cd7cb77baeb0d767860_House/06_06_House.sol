// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "solmate/utils/SafeTransferLib.sol";
import "solmate/utils/ReentrancyGuard.sol";
import "chainlink/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "chainlink/v0.8/VRFConsumerBaseV2.sol";

contract House is VRFConsumerBaseV2, ReentrancyGuard {
    // VRF
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 subscriptionId;
    address internal constant vrfCoordinator = 0xc587d9053cd1118f25F645F9E08BB98c9712A4EE;
    bytes32 internal constant keyHash = 0x114f3da0a805b6a67d6e9cd2ec746f7028f1b7376365af575cfea3550dd1aa04;
    uint32 internal constant callbackGasLimit = 200000;
    uint16 internal constant requestConfirmations = 5;
    uint32 internal constant numWords =  1;
    bool public paused;
    uint lastRequestId;
    uint[] public requestIds;
    mapping (uint => RequestStatus) requests;
    struct RequestStatus {
        address player;
        uint8 direction;
        uint amount;
        bool isRebet;
        bool fulfilled;
        bool exists;
        uint randomWord;
    }

    // State
    address internal owner;
    uint public totalWinnings;
    mapping (address => uint) winnings;

    error RequestError();
    error InvalidBet();
    error InvalidWithdraw();

    event Result(
        bool rebet,
        uint8 direction,
        uint8 result,
        address better,
        uint value);

    event CashOut(
        address player, 
        uint amount
    );

    constructor(uint64 _subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        owner = msg.sender;
        subscriptionId = _subscriptionId;
        paused = false;
    }

    /* Modifiers */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier notPaused() {
        require(paused == false);
        _;
    }

    /* VRF functions */
    function requestRandomWords(uint8 _direction, address _player, uint _amount, bool _isRebet) internal returns (uint requestId) {
        // Will revert if subscription is not set and funded.
        requestId = COORDINATOR.requestRandomWords(
        keyHash,
        subscriptionId,
        requestConfirmations,
        callbackGasLimit,
        numWords
        );
        requestIds.push(requestId);
        requests[requestId] = RequestStatus({player: _player, direction: _direction, amount: _amount, isRebet: _isRebet, randomWord: 0, exists:true, fulfilled: false});
        lastRequestId = requestId;
    }

    function fulfillRandomWords(
        uint requestId, /* requestId */
        uint[] memory randomWords
    ) internal override {
        uint result = randomWords[0];

        requests[requestId].fulfilled = true;
        requests[requestId].randomWord = result;
        _settleBet(result, requestId);
    }

    /* View */

    function getWinnings(address _player) public view returns (uint) {
        return winnings[_player];
    }

    function getAdjustedBalance() public view returns(uint) {
        return address(this).balance - totalWinnings;
    }

    function getRequestStatus(uint _requestId) external view returns (bool, uint result) {
        if(!requests[_requestId].exists || msg.sender != requests[_requestId].player) {
            revert RequestError();
        }
        RequestStatus memory request = requests[_requestId];
        return (request.fulfilled, request.randomWord);
    }

    function getMinBalance() public view returns(uint) {
        return (address(this).balance/10)*1;
    }

    /* Play functions */
    function makeBet(uint8 _direction) external payable notPaused {
        if(address(msg.sender).balance < msg.value || msg.value <= 0 || (getAdjustedBalance() - msg.value) < getMinBalance() || (_direction != 1 && _direction != 2)) {
            revert InvalidBet();
        }
        
        requestRandomWords(_direction, msg.sender, msg.value, false);
    }

    function _settleBet(uint result, uint requestId) internal {
        RequestStatus storage rqs = requests[requestId];
        result = result % 2 + 1;
        uint winAfterFee = rqs.amount + (rqs.amount*965)/1000;
        if (result == rqs.direction) {
            winnings[rqs.player] += winAfterFee;
            totalWinnings += winAfterFee;
        } else if (rqs.isRebet) {
            winnings[msg.sender] -= rqs.amount;
            totalWinnings -= rqs.amount;
        }
        emit Result(rqs.isRebet, rqs.direction, uint8(result), rqs.player, rqs.amount);
    }

    function cashOut(uint _amount) external nonReentrant notPaused {
        if(_amount <= 0 || winnings[msg.sender] < _amount) {
            revert InvalidWithdraw();
        }

        winnings[msg.sender] -= _amount;
        totalWinnings -= _amount;
        SafeTransferLib.safeTransferETH(msg.sender, _amount);
        emit CashOut(msg.sender, _amount);
    }
    
    /* Owner functions */
    function withdraw(uint _amount, address _to) external onlyOwner {
        SafeTransferLib.safeTransferETH(_to, _amount);
    }

    function setOwner(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function pause() external onlyOwner {
        paused = true;
    }

    function unpause() external onlyOwner {
        paused = false;
    }

    receive() external payable {}

    fallback() external payable {}
}
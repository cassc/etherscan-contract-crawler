// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;


import "Ownable.sol";
import "VRFConsumerBase.sol";

contract Lottery is VRFConsumerBase, Ownable {
    address payable[] public players;
    address payable public recentWinner;
    address payable public manegerwallet;
    uint256 public randomness;
    uint256 costToEnter ;
    uint256 public DRAWVALUE;
    
  
    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }
    LOTTERY_STATE public lottery_state;
    uint256 public fee;
    bytes32 public keyhash;
    event RequestedRandomness(bytes32 requestId);

    constructor(
        address _vrfCoordinator,
        address _link,
        uint256 _fee,
        bytes32 _keyhash,
        address payable _manegerwallet,
        uint256 _drawvalue
    ) public VRFConsumerBase(_vrfCoordinator, _link) {
        costToEnter = (0.02 * 10**18);
      
        lottery_state = LOTTERY_STATE.CLOSED;
        fee = _fee;
        keyhash = _keyhash;
        manegerwallet=_manegerwallet;
        DRAWVALUE=_drawvalue;
    }

    function enter() public payable {
      
        uint256 extravalue=msg.value %getEntranceFee();
        require(extravalue==0);
        require(lottery_state == LOTTERY_STATE.OPEN);
        require(msg.value >= costToEnter, "Not enough ETH!");
        require(address(this).balance<=DRAWVALUE,"Lottrey is on DRAW!");

        uint256 _usertiketcount;
        _usertiketcount=msg.value / costToEnter;
        for(uint i=0; i<_usertiketcount; i++){
        players.push(payable(msg.sender));
        
     }
    }
    function getDRAWVALUE() public view returns (uint256){
        return DRAWVALUE;
    }
    function getEntranceFee() public view returns (uint256) {
       
       
        return costToEnter;
    }

    function getplayes() public view returns (address payable[] memory){
        return players;
    }

    function startLottery() public onlyOwner {
        require(
            lottery_state == LOTTERY_STATE.CLOSED,
            "Can't start a new lottery yet!"
        );
        lottery_state = LOTTERY_STATE.OPEN;
    }

    function endLottery() public onlyOwner {
        require(address(this).balance >= DRAWVALUE);
        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
        bytes32 requestId = requestRandomness(keyhash, fee);
        emit RequestedRandomness(requestId);
    }


    function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
        internal
        override
    {
        require(
            lottery_state == LOTTERY_STATE.CALCULATING_WINNER,
            "You aren't there yet!"
        );
        require(_randomness > 0, "random-not-found");
        uint256 indexOfWinner = _randomness % players.length;
        recentWinner = players[indexOfWinner];
        uint256 manegercut=((address(this).balance)*3)/100;  
        recentWinner.transfer((address(this).balance)-(manegercut));
        manegerwallet.transfer(manegercut);


        // Reset
        players = new address payable[](0);
        lottery_state = LOTTERY_STATE.CLOSED;
        randomness = _randomness;
    }
}
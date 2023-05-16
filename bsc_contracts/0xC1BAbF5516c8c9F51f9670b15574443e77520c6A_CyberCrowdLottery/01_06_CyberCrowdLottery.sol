// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.17;

import "./SafeMath.sol";
import "./AdminControl.sol";
import "./SafeCast.sol";

contract CyberCrowdLottery is AdminControl{

    using SafeMath for uint256;
    using SafeCast for uint256;

    //decimals of the bunus amount
    uint256 constant decimals = 10000;

    address[] historyPlayers;
    mapping(address => uint256) private playersPoints;

    mapping(uint256 => Player[]) private roundPlayers;
    uint256  round = 10000;
    //balance of the current round
    uint256  roundPool = 0;

    Player[] winnerPlayers;
    
    //ticket price
    uint256 ticketPrice;
    //winner chance of all the players
    uint8 winningRate;
    //fee percentage
    uint8 fee;
    uint256 rewardPoints;
    uint256 inviterRewardPoints;
    uint256 pointsToTicket;

    //Lottery status
    LOTTERY_STATUS _status;

    enum  LOTTERY_STATUS {PLAY_START, DRAW_LOTTERY}
    event TransEvent(address,uint);
    event BuyTicketEvent(address player_, uint256 value_, uint256 rewardPoints_, uint256 inviterRewardPoints_);
    event DrawLotteryEvent(uint256 timestamp, Player[] winners);

    struct Player{
        address playerAddress;
        address inviterAddress;
        uint256 round;
        uint64  roundIndex;
        uint256 amount;
        uint256 randomNum;
        uint256 bonus;
        bool    isWinner;
        uint256 timestamp;
    }

    // constructor()payable{}

    constructor() payable {
        _status = LOTTERY_STATUS.PLAY_START;
    }

    fallback() external {
        emit TransEvent(address(this),1);
    }

    receive() external payable {
        emit TransEvent(address(this),2);
    }

    function withdraw(address to, uint256 _amount) public onlyOwner {
        require(_amount <= address(this).balance, "Not enough funds");
        payable(to).transfer(_amount);
    }

    function updateLotteryData(
        uint256 _ticketPrice,
        uint8   _winningRate,
        uint8   _fee,
        uint256 _rewardPoints,
        uint256 _inviterRewardPoints,
        uint256 _pointsToTicket
    ) public onlyOwner {

        ticketPrice = _ticketPrice;
        winningRate = _winningRate;
        fee = _fee;
        
        rewardPoints = _rewardPoints;
        inviterRewardPoints = _inviterRewardPoints;
        pointsToTicket = _pointsToTicket;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getRoundPool() public view returns (uint256) {
        return roundPool;
    }

    function getRoundIndex() public view returns (uint256) {
        return round;
    }

    function getWinningRate() public view returns (uint8) {
        return winningRate;
    }

    function getTicketPrice() public view returns (uint256) {
        return ticketPrice;
    }

    function getPlayers() external view returns (Player[] memory){
        return roundPlayers[round];
    }

    function getLastRoundPlayers() external view returns (Player[] memory){
        return roundPlayers[round - 1];
    }

    function getLastRoundWinners() external view returns (Player[] memory){
        return winnerPlayers;
    }

    function getHistoryPlayers() external view returns (address[] memory){
        return historyPlayers;
    }

    function getPlayerPoints() external view returns (uint256){
        return playersPoints[msg.sender];
    }

    function getPlayerPoints(address _playerAddress) external view returns (uint256){
        return playersPoints[_playerAddress];
    }

    function getLotteryStatus() public view returns (LOTTERY_STATUS){
        return _status;
    }

    function playerExists(address _address) public view returns (bool){
        bool exists = false;
        for (uint i = 0;i < historyPlayers.length;i++){
            if (_address == historyPlayers[i]){
                exists = true;
                break;
            }
        }
        return exists;
    }

    function getWinnerIndex(uint256 _totalPlayerAmount, uint8 _winningRate)internal pure returns (uint256){
        uint256 last = _totalPlayerAmount.mul(100 - _winningRate) % 100;
        if (last >= 50){
            return (_totalPlayerAmount.mul(100 - _winningRate) + 100 - last).div(100);
        } else {
            return (_totalPlayerAmount.mul(100 - _winningRate) - last).div(100);
        }
    }

    function multipleSameWinnerExists(address playerAddress) private view returns(bool,uint){
        bool exists = false;
        uint index = 0;
        for (uint j = 0;j < winnerPlayers.length;j++){
            if (playerAddress == winnerPlayers[j].playerAddress){
                exists = true;
                index = j;
                break;
            } 
        }
        return (exists,index);
    }

    function createRandomNumber(address _address, uint256 _timestamp, uint64 _roundIndex) internal view returns(uint256){
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty,block.number,block.timestamp,_timestamp,_roundIndex,_address)));
        return random;
    }

    function buyTicket(address _inviterAddress, uint ticketAmount) payable public {

        require(_status == LOTTERY_STATUS.PLAY_START, "Buy: can not buy when it is not started");

        require(msg.value >= ticketPrice * ticketAmount,"Buy: Value must be higher than the ticket price");

        roundPool = roundPool + msg.value;

        for (uint i = 0;i < ticketAmount;i++){

            Player memory player = Player({
                playerAddress:  msg.sender,
                inviterAddress: _inviterAddress,
                round:          round,
                roundIndex:     uint64(roundPlayers[round].length),
                amount:         ticketPrice,
                randomNum:      0,
                bonus:          0,
                isWinner:       false,
                timestamp:      block.timestamp
            });

            roundPlayers[round].push(player);
        }

        // add points to buyer
        playersPoints[msg.sender] = playersPoints[msg.sender] + ticketAmount * rewardPoints;

        // add points to inviter
        if (msg.sender != _inviterAddress && playerExists(_inviterAddress) && !playerExists(msg.sender)){

            playersPoints[_inviterAddress] = playersPoints[_inviterAddress] + inviterRewardPoints;

            emit BuyTicketEvent(msg.sender, msg.value, rewardPoints, inviterRewardPoints);

        } else {

            emit BuyTicketEvent(msg.sender, msg.value, rewardPoints, 0);

        }

        // push new player to historyPlayers
        if(!playerExists(msg.sender)){
            historyPlayers.push(msg.sender);
        }
    }

    function swapPointsToTicket(uint ticketAmount) public {

        require(_status == LOTTERY_STATUS.PLAY_START, "SwapPointsToTicket: can not swap when it is not started");

        require(playersPoints[msg.sender] >= ticketAmount * pointsToTicket, "SwapPointsToTicket: points not enough");

        roundPool = roundPool + ticketPrice * ticketAmount;

        playersPoints[msg.sender] = playersPoints[msg.sender] - ticketAmount * pointsToTicket;

        for (uint i = 0;i < ticketAmount;i++){

            Player memory player = Player({
                playerAddress:  msg.sender,
                inviterAddress: msg.sender,
                round:          round,
                roundIndex:     uint64(roundPlayers[round].length),
                amount:         0,
                randomNum:      0,
                bonus:          0,
                isWinner:       false,
                timestamp:      block.timestamp
            });

            roundPlayers[round].push(player);
        }
    }

    //Draw lottery for all the users,this function is only for the owner of this contract.
    function drawLottery() public isAdmin{

        require(roundPlayers[round].length > 0, "DrawLottery: can not draw lottery, no players yet");

        require(roundPool > 0, "DrawLottery: can not draw lottery, balance is not enough");

        require(_status == LOTTERY_STATUS.PLAY_START, "DrawLottery: can not draw lottery, the owner is drawing");
        
        _status = LOTTERY_STATUS.DRAW_LOTTERY;

        for (uint i = 0;i < roundPlayers[round].length;i++){
            uint256 random = createRandomNumber(roundPlayers[round][i].playerAddress, roundPlayers[round][i].timestamp, roundPlayers[round][i].roundIndex);
            roundPlayers[round][i].randomNum = random % 10000;
        }

        //clear all players of last round
        delete winnerPlayers;

        //sort players random number from min to max
        for (uint i = 1;i < roundPlayers[round].length;i++){
            uint256 temp = roundPlayers[round][i].randomNum;
            Player memory tempPlayer;
            uint j=i;
            while((j >= 1) && (temp < roundPlayers[round][j-1].randomNum)){
                tempPlayer = roundPlayers[round][j];
                roundPlayers[round][j] = roundPlayers[round][j-1];
                roundPlayers[round][j-1] = tempPlayer;
                j--;
            }
            roundPlayers[round][j].randomNum = temp;
        }

        //calc total bonus for all winners of this round
        uint256 totalBonus = roundPool.mul(100 - fee);

        //calc winners
        uint256 total = roundPlayers[round].length;
        //calc winner player's index of all players
        uint256 index = getWinnerIndex(total,winningRate);
        
        //calc winner bonus and send bonus to the winners
        uint256 sumRndNum = 0;
        for (uint i = index;i < total;i++){
            sumRndNum = sumRndNum + roundPlayers[round][i].randomNum;
        }
        
        for (uint i = index;i < total;i++){

            uint256 ran = roundPlayers[round][i].randomNum;

            uint256 _bonus = ran.mul(totalBonus).mul(decimals).div(sumRndNum).div(decimals).div(100);
            roundPlayers[round][i].bonus = _bonus;
            roundPlayers[round][i].isWinner = true;

            (bool exists,uint winnerIndex) = multipleSameWinnerExists(roundPlayers[round][i].playerAddress);

            if (exists){
                winnerPlayers[winnerIndex].bonus = winnerPlayers[winnerIndex].bonus + roundPlayers[round][i].bonus;
            } else {
                winnerPlayers.push(roundPlayers[round][i]);
            }

        }

        for (uint i = 0;i < winnerPlayers.length;i++){
            //transfer bonus to the winners
            payable(winnerPlayers[i].playerAddress).transfer(winnerPlayers[i].bonus);
        }

        //clear all datas of this round and reset the status
        round = round + 1;
        
        roundPool = 0;
        _status = LOTTERY_STATUS.PLAY_START;

        emit DrawLotteryEvent(block.timestamp,roundPlayers[round - 1]);
    }
}
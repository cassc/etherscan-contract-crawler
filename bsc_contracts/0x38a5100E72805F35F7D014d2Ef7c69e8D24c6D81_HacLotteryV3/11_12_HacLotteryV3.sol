// SPDX-License-Identifier: GPL-3.0
import "@openzeppelin/contracts/utils/Strings.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "./RewardsToken.sol";

pragma solidity >=0.7.0 <0.9.0;

contract HacLotteryV3 is VRFConsumerBaseV2, Ownable  {

    VRFCoordinatorV2Interface COORDINATOR;
    uint64 s_subscriptionId = 313;
    address vrfCoordinator = 0xc587d9053cd1118f25F645F9E08BB98c9712A4EE;
    bytes32 keyHash = 0xba6e730de88d94a5510ae6613898bfb0c3de5d16e609c5b7da808747125506f7;
    uint32 callbackGasLimit = 50000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;
    uint256 public s_requestId;
    uint256 public duration = 2 weeks; 
    uint256 public expiration;
    uint256 public lotteryID = 1;
    uint256 maxTicketsPerPlayer = 1000;
    uint256 public fee = 10 ether;

    string public LotteryName;

    address[] public tickets;

    mapping(uint256 => uint256[]) public s_randomWords;
    mapping(uint256 => mapping(address => uint256)) public numTicketsBought;
    mapping(uint256 => address) lotteryWinners;
    mapping(uint256 => uint256) potSizes;
    mapping(uint256 => uint256) endTimes;

    RewardsToken public lotteryToken;


    constructor(RewardsToken _token, string memory _lotteryName) VRFConsumerBaseV2(vrfCoordinator) {
        lotteryToken = _token;
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        LotteryName = _lotteryName;
    }


    function start() external onlyOwner {
        expiration = block.timestamp + duration;
        endTimes[lotteryID] = block.timestamp + duration;
    }

    function pickWinner() external onlyOwner {
        require(block.timestamp >= expiration && tickets.length > 0, "Lottery is not over");

        s_requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        potSizes[lotteryID] = tickets.length;
    }

    function fulfillRandomWords(uint256, uint256[] memory randomWords)
        internal
        override
    {
        s_randomWords[lotteryID] = randomWords;
    }

    function payoutLottery() external {
        require(s_randomWords[lotteryID][0] > 0, "Randomness not set");
            uint256 index = s_randomWords[lotteryID][0] % tickets.length;
            lotteryWinners[lotteryID] = tickets[index];
            lotteryID++;
            tickets = new address[](0);
            expiration = block.timestamp + duration;
            endTimes[lotteryID] = block.timestamp + duration;
    }
    

    // return all the tickets
    function getTickets() public view returns (address[] memory) {
        return tickets;
    }

    function userEntries(address user) external view returns (uint256) {
        return numTicketsBought[lotteryID][user];
    }

    function totalEntries() external view returns (uint256) {
        return tickets.length;
    }

    function pastEntries(uint256 _id) external view returns (uint256) {
        return potSizes[_id];
    }

    function previousWinner() external view returns (address) {
        if(lotteryID == 1) {
            return address(0);
        }
        else {
            return lotteryWinners[lotteryID - 1];
        }
    }

    function pastWinner(uint256 _id) external view returns (address) {
        require(_id < lotteryID, "No winner yet");
        return lotteryWinners[_id];
    }

    function endTime(uint256 _id) external view returns (uint256) {
        return endTimes[_id];
    }

    function isActive() external view returns (bool) {
        return (endTimes[lotteryID] > block.timestamp);
    }

    //callable functions

    function BuyTickets(uint64[] calldata _amount) public payable {
        require(_amount[0] + numTicketsBought[lotteryID][msg.sender] <= maxTicketsPerPlayer, "the value must be multiple of ");
        require(expiration > block.timestamp, 'lottery not started');

        numTicketsBought[lotteryID][msg.sender] += _amount[0];
        uint256 i = 0;
        for (i = 0; i < _amount[0]; i++) {
            unchecked{
              tickets.push(msg.sender);  
            }
        }
        lotteryToken.transferFrom(msg.sender, address(this), _amount[0] * fee);
    }

    function restartDraw() public onlyOwner {
        require(tickets.length == 0, "Cannot Restart Draw as Draw is in play");

        delete tickets;
        expiration = block.timestamp + duration;
        endTimes[lotteryID] = block.timestamp + duration;
    }


    function RefundAll() public {
        require(block.timestamp >= expiration, "the lottery not expired yet");

        for (uint256 i = 0; i < tickets.length; i++) {
            address to = (tickets[i]);
            tickets[i] = address(0);
            lotteryToken.transfer(to, fee);
        }
        delete tickets;
    }


    function CurrentWinningReward() public view returns (uint256) {
        return tickets.length * fee;
    }

    function changeDuration(uint256 _newDuration) external onlyOwner {
        duration = _newDuration;
    }

    function maxParams(uint256 _newMaxAmountPerPlayer, uint256 _newFee) external onlyOwner {
        maxTicketsPerPlayer = _newMaxAmountPerPlayer;
        fee = _newFee;
    }

    function transferTokens(uint256 _amount, address _destination) external onlyOwner {
        lotteryToken.transfer(_destination, _amount);
    }

    function witdraw(address _destination) external onlyOwner {
       (bool success,) = payable(_destination).call{value:address(this).balance}('');
       require(success, 'call failed');
    }

    receive() external payable{}
    fallback() external payable{}
}
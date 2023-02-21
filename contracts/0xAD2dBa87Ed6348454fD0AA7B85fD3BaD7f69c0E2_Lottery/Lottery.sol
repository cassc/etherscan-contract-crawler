/**
 *Submitted for verification at Etherscan.io on 2023-02-20
*/

pragma solidity ^0.8.0;

contract Lottery {
    address payable public owner;
    uint256 public ticketPrice = 10000000000000000; // 0.01 ETH in wei
    uint256 public quotaToReach = 500 ether;
    uint256 public ownerQuota = 200 ether;
    uint256 public totalQuota;
    uint256 public winningNumber;
    bool public isFinished;
    mapping(address => uint256) public ticketCounts;
    address[] public participants;

    event TicketPurchased(address indexed buyer, uint256 ticketCount);
    event LotteryFinished(address indexed winner, uint256 winningNumber, uint256 totalPrize);

    constructor() {
        owner = payable(msg.sender);
    }

    function buyTickets(uint256 _ticketCount) external payable {
        require(msg.value == _ticketCount * ticketPrice, "Incorrect value sent");
        require(_ticketCount > 0, "Ticket count must be greater than 0");
        require(!isFinished, "Ticket lottery is finished");

        ticketCounts[msg.sender] += _ticketCount;
        totalQuota += msg.value;
        participants.push(msg.sender);

        emit TicketPurchased(msg.sender, _ticketCount);

        if (totalQuota >= quotaToReach) {
            finishLottery();
        }
    }

    function generateWinningNumber() public onlyOwner {
        require(isFinished, "Lottery is not finished yet");

        winningNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, participants.length))) % participants.length;
    }

    function finishLottery() internal onlyOwner {
        require(!isFinished, "Lottery is already finished");

        generateWinningNumber();
        isFinished = true;

        uint256 totalPrize = totalQuota - ownerQuota;
        owner.transfer(ownerQuota);

        address payable winner = payable(participants[winningNumber]);
        winner.transfer(totalPrize);

        emit LotteryFinished(winner, winningNumber, totalPrize);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
}
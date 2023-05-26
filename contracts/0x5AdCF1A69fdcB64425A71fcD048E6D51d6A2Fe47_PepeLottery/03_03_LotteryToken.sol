// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract PepeLottery {
    uint256 public constant ticketPrice = 2000 * 10**18; // 100 tokens (wei value)
    uint256 public constant maxTickets = 100; // maximum tickets per lottery
    uint256 public constant ticketCommission = 40 * 10**18; // 10 tokens (wei value) commission per ticket
    uint256 public constant duration = 1440 minutes; // The duration set for the lottery

    uint256 public expiration; // Timeout in case the lottery was not carried out.
    address public lotteryOperator; // the creator of the lottery
    uint256 public operatorTotalCommission = 0; // the total commission balance
    address public lastWinner; // the last winner of the lottery
    uint256 public lastWinnerAmount; // the last winner amount of the lottery

    mapping(address => uint256) public winnings; // maps the winners to their winnings
    address[] public tickets; // array of purchased Tickets

    IERC20 public token; // the ERC20 token used for buying tickets

    // modifier to check if the caller is the lottery operator
    modifier isOperator() {
        require(
            (msg.sender == lotteryOperator),
            "Caller is not the lottery operator"
        );
        _;
    }

    // modifier to check if the caller is a winner
    modifier isWinner() {
        require(IsWinner(), "Caller is not a winner");
        _;
    }

    constructor(address _tokenAddress) {
        lotteryOperator = msg.sender;
        expiration = block.timestamp + duration;
        token = IERC20(_tokenAddress);
    }

    // return all the tickets
    function getTickets() public view returns (address[] memory) {
        return tickets;
    }

    function getWinningsForAddress(address addr) public view returns (uint256) {
        return winnings[addr];
    }

    function BuyTickets(uint256 numOfTicketsToBuy) public {
        require(
            numOfTicketsToBuy > 0,
            "Number of tickets to buy must be greater than zero"
        );

        uint256 totalPrice = ticketPrice * numOfTicketsToBuy;

        require(
            token.allowance(msg.sender, address(this)) >= totalPrice,
            "Insufficient token allowance"
        );

        require(
            numOfTicketsToBuy <= RemainingTickets(),
            "Not enough tickets available."
        );

        for (uint256 i = 0; i < numOfTicketsToBuy; i++) {
            tickets.push(msg.sender);
        }

        token.transferFrom(msg.sender, address(this), totalPrice);
    }

    function DrawWinnerTicket() public isOperator {
    require(tickets.length > 0, "No tickets were purchased");

    bytes32 blockHash = blockhash(block.number - tickets.length);
    uint256 randomNumber = uint256(
        keccak256(abi.encodePacked(block.timestamp, blockHash))
    );
    uint256 winningTicket = randomNumber % tickets.length;

    address winner = tickets[winningTicket];
    lastWinner = winner;
    winnings[winner] += (tickets.length * (ticketPrice - ticketCommission));
    lastWinnerAmount = winnings[winner];
    operatorTotalCommission += (tickets.length * ticketCommission);
    delete tickets;
    expiration = block.timestamp + duration;
}

function restartDraw() public isOperator {
    require(tickets.length == 0, "Cannot restart draw as draw is in play");

    delete tickets;
    expiration = block.timestamp + duration;
}

function checkWinningsAmount() public view returns (uint256) {
    address payable winner = payable(msg.sender);

    uint256 reward2Transfer = winnings[winner];

    return reward2Transfer;
}

function WithdrawWinnings(address tokenAddress) public isWinner {
    address payable winner = payable(msg.sender);

    uint256 reward2Transfer = winnings[winner];
    require(reward2Transfer > 0, "No winnings to withdraw");

    winnings[winner] = 0;

    if (tokenAddress == address(0)) {
        // Withdraw Ether
        (bool success, ) = winner.call{ value: reward2Transfer }("");
        require(success, "Failed to withdraw winnings in Ether");
    } else {
        // Withdraw Tokens
        IERC20 tokenToWithdraw = IERC20(tokenAddress);
        require(tokenToWithdraw.transfer(winner, reward2Transfer), "Token transfer failed");
    }
}

function RefundAll() public {
    require(block.timestamp >= expiration, "The lottery has not expired yet");

    for (uint256 i = 0; i < tickets.length; i++) {
        address payable to = payable(tickets[i]);
        tickets[i] = address(0);
        (bool success, ) = to.call{ value: ticketPrice }("");
        require(success, "Failed to refund ticket");
    }
    delete tickets;
	}

    function WithdrawCommission(address tokenAddress) public isOperator {
    address payable operator = payable(msg.sender);

    uint256 commission2Transfer = operatorTotalCommission;
    operatorTotalCommission = 0;

    if (tokenAddress == address(0)) {
        // Withdraw Ether
        (bool success, ) = operator.call{ value: commission2Transfer }("");
        require(success, "Failed to withdraw commission in Ether");
    } else {
        // Withdraw Tokens
        IERC20 commissionToken = IERC20(tokenAddress);
        require(commissionToken.transfer(operator, commission2Transfer), "Token transfer failed");
    }
}

	function IsWinner() public view returns (bool) {
    return winnings[msg.sender] > 0;
	}

	function CurrentWinningReward() public view returns (uint256) {
    return tickets.length * ticketPrice;
	}

	function RemainingTickets() public view returns (uint256) {
    return maxTickets - tickets.length;
	}
}
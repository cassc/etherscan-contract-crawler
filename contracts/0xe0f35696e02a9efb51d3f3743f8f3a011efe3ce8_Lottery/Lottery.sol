/**
 *Submitted for verification at Etherscan.io on 2023-10-21
*/

/**
 *Submitted for verification at Etherscan.io on 2023-10-17
 */

// SPDX-License-Identifier: MIT

// Lottery Contract: 20 October 2023
// Version: 2.2

// Website: https://kekw.gg/
// telegram: https://t.me/kekw_gg
// X: https://x.com/kekw_gg

pragma solidity ^0.8.18;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract Lottery {
    IERC20 public token;
    address public manager;
    address public previousWinner;
    address[] public players;
    mapping(address => uint256) public playerTicketCounts;
    address public burnAddress = 0x000000000000000000000000000000000000dEaD;
    uint256 MAX_INT =
        115792089237316195423570985008687907853269984665640564039457584007913129639935;

    uint256 public winnerPercentage = 90;
    uint256 public totalTickets = 0;
    uint256 public burnPercentage = 5;
    uint256 public feePercentage = 100 - winnerPercentage - burnPercentage;

    uint256 public ticketPrice = 10000000000 * 10**18; // 10 Billion $KEKW

    constructor(address _token) {
        manager = msg.sender;
        token = IERC20(_token);
    }

    function updateTicketPrice(uint256 newTicketPrice) public restricted {
        require(
            newTicketPrice > 0,
            "Minimum ticket price should be greater than zero."
        );
        require(
            players.length == 0,
            "Reset Lottery before updating ticket price."
        );
        ticketPrice = newTicketPrice * 10**18;
    }

    function resetTicketCounts() private {
        for (uint256 i = 0; i < players.length; i++) {
            playerTicketCounts[players[i]] = 0;
        }
        totalTickets = 0;
        players = new address[](0);
    }

    function enter(uint256 _amount, uint256 _mintAmount) public {
        require(_mintAmount > 0, "Mint Amount should be greater than 0.");
        uint256 amount_sent = _amount * 10**18;
        uint256 total_price = ticketPrice * _mintAmount;
        require(
            amount_sent == total_price,
            "Mint Amount and Amount Sent should match."
        );
        token.transferFrom(msg.sender, address(this), amount_sent);
        players.push(msg.sender);
        playerTicketCounts[msg.sender] += _mintAmount;
        totalTickets += _mintAmount;
    }

    function getSmartContractBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function random() private view returns (uint256) {
        return uint256(keccak256(abi.encode(block.timestamp, players)));
    }

    function getTicketCount(address playerAddress)
        public
        view
        returns (uint256)
    {
        uint256 count = 0;
        for (uint256 i = 0; i < players.length; i++) {
            if (players[i] == playerAddress) {
                count += playerTicketCounts[players[i]];
            }
        }
        return count;
    }

    function pickWinner() public restricted {
        require(players.length > 0, "There are no players in the lottery.");
        require(totalTickets > 0, "Total tickets count is zero.");
        token.approve(address(this), MAX_INT);

        uint256 winnerAmount = (token.balanceOf(address(this)) *
            winnerPercentage) / 100;
        uint256 feesAmount = (token.balanceOf(address(this)) * feePercentage) /
            100;
        uint256 burnAmount = (token.balanceOf(address(this)) * burnPercentage) /
            100;

        uint256 rand = random();
        uint256 winnerIndex = rand % totalTickets;

        address winner = address(0);
        for (uint256 i = 0; i < players.length; i++) {
            if (winnerIndex < playerTicketCounts[players[i]]) {
                winner = players[i];
                break;
            }
            winnerIndex -= playerTicketCounts[players[i]];
        }

        resetTicketCounts();
        previousWinner = winner;
        token.transferFrom(address(this), winner, winnerAmount);
        token.transferFrom(address(this), manager, feesAmount);
        token.transferFrom(address(this), burnAddress, burnAmount);
    }

    modifier restricted() {
        require(msg.sender == manager);
        _;
    }
}
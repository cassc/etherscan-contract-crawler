// SPDX-License-Identifier: GPL-3.0
import "./libraries/SafeMath.sol";
import "./utils/Context.sol";

pragma solidity 0.8.17;

/**
 * @title HeisenVerse Lottery Contract
 * @author HeisenDev
 */
contract HeisenVerseLottery is Context {
    using SafeMath for uint256;

    address private heisenVerse;
    address[] public players;
    address[] public winners;
    uint public lotteryCount = 1;
    uint public lotteryPrice = 0.017 ether;
    event Deposit(address indexed sender, uint amount);
    event BuyLottery(address indexed sender, uint amount);
    event Winner(address indexed winner, uint amount);

    constructor() {
        heisenVerse = payable(_msgSender());
    }
    modifier restricted(){
        require(_msgSender() == heisenVerse);
        _;
    }

    /// @dev Fallback function allows to deposit ether.
    receive() external payable {
        if (msg.value > 0) {
            emit Deposit(_msgSender(), msg.value);
        }
    }

    function buyLottery() public payable {
        require(msg.value >= lotteryPrice, "Lottery: underpriced");
        players.push(_msgSender());
        emit BuyLottery(_msgSender(), msg.value);
    }

    function pickWinner() public restricted{
        uint index = random() % players.length;
        uint256 contractBalance = address(this).balance;
        uint256 winnerAmount =  contractBalance.div(2);
        uint256 heisenVerseAmount = contractBalance.sub(winnerAmount);
        address payable winner = payable(players[index]);
        (bool sentPlayer, ) = winner.call{value: winnerAmount}("");
        require(sentPlayer, "Deposit ETH: Failed to send ETH");
        (bool sentHeisenVerse, ) = heisenVerse.call{value: heisenVerseAmount}("");
        require(sentHeisenVerse, "Deposit ETH: Failed to send ETH");
        winners.push(players[index]);
        players = new address[](0);
        lotteryCount++;
        emit Winner(winner, winnerAmount);
    }

    function random() public view returns(uint){
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players, lotteryCount)));
    }

    function setPrice(uint256 _lotteryPrice) public restricted{
        require(players.length == 0, "Need empty Lottery");
        lotteryPrice = _lotteryPrice;
    }

    function totalPlayers() public view returns(uint){
        return players.length;
    }
}
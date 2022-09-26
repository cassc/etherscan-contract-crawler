// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "./LotteryWinner.sol";

contract Zepto is LotteryWinner {
    address payable private _team;

    uint256 private _prizePool;
    address payable private _winner;
    uint256 private _lastClick = 0;

    uint256 private _price;
    uint256 private _feeTeam; // /10000
    uint256 private _feeAffiliation; // /10000
    uint8 private _indexFiftyWinners = 0;

    uint256 private _ticketsSold;
    address[51] private _fiftyWinners;
    address[] private _lotteryWinners;

    bool private _isAlreadyIn;

    uint256 private _window;

    event Click(
        address indexed bidder,
        address indexed referrer,
        uint256 blockNumber
    );

    constructor(
        uint256 price_,
        uint256 feeTeam_,
        uint256 feeAffiliation_,
        uint256 window_,
        uint64 sId,
        address vrfCoordinator_,
        bytes32 keyHash_
    ) payable LotteryWinner(sId, vrfCoordinator_, keyHash_) {
        _team = payable(msg.sender);
        _winner = payable(msg.sender);
        _price = price_;
        _feeTeam = feeTeam_;
        _feeAffiliation = feeAffiliation_;
        _window = window_;
    }

    receive() external payable {
        click(address(0));
    }

    fallback() external payable {
        click(address(0));
    }

    modifier reentrancyGuard() {
        require(!_isAlreadyIn, "reentrancyGuard");
        _isAlreadyIn = true;
        _;
        _isAlreadyIn = false;
    }

    function startGame() public payable {
        require(msg.value >= _price * 10, "invalid price");
        require(_lastClick == 0, "Game already started !");
        _lastClick = block.number;
    }

    function prizePool() public view returns (uint256) {
        return _prizePool;
    }

    function winner() public view returns (address) {
        return _winner;
    }

    function lastClick() public view returns (uint256) {
        return _lastClick;
    }

    function price() public view returns (uint256) {
        return _price;
    }

    function feeAffiliation() public view returns (uint256) {
        return _feeAffiliation;
    }

    function feeTeam() public view returns (uint256) {
        return _feeTeam;
    }

    function indexFiftyWinners() public view returns (uint256) {
        return _indexFiftyWinners;
    }

    function ticketsSold() public view returns (uint256) {
        return _ticketsSold;
    }

    function fiftyWinners() public view returns (address[51] memory) {
        return _fiftyWinners;
    }

    function lotteryWinners() public view returns (address[] memory) {
        return _lotteryWinners;
    }

    function window() public view returns (uint256) {
        return _window;
    }

    function topFiftyParticipants() public view returns (uint256 count) {
        for (uint256 i; i < _fiftyWinners.length; i++) {
            if (_fiftyWinners[i] != address(0)) {
                count++;
            }
        }
    }

    function topFiftyWinners() public view returns (address[] memory winners) {
        uint256 _counter;
        for (uint256 i; i < _fiftyWinners.length; i++) {
            if (_fiftyWinners[i] != address(0)) {
                winners[_counter] = _fiftyWinners[i];
                _counter++;
            }
        }
    }

    function lotteryTicketsSold() public view returns (uint256) {
        return _lotteryWinners.length;
    }

    function remainingTime() public view returns (uint256) {
        if (_lastClick + _window > block.number) {
            return _lastClick + _window - block.number;
        } else {
            return 0;
        }
    }

    function click(address _referrer) public payable reentrancyGuard {
        uint256 _amount = msg.value;
        require(_amount >= _price, "Too low amount");
        require(remainingTime() > 0, "Game is closed");

        _winner = payable(msg.sender);
        _lastClick = block.number;

        if (_referrer != address(0)) {
            payable(_referrer).send((_amount * _feeAffiliation) / 10000);
        }
        // add to 50+ winners
        _indexFiftyWinners = _indexFiftyWinners == 50
            ? 0
            : _indexFiftyWinners + 1;
        _fiftyWinners[_indexFiftyWinners] = payable(msg.sender);
        // add to lottery
        _lotteryWinners.push(payable(msg.sender));

        _team.send((_amount * _feeTeam) / 10000);
        _ticketsSold++;
        emit Click(msg.sender, _referrer, block.number);
    }

    function payWinner() external reentrancyGuard {
        require(block.number > _lastClick + _window, "Game window is not over");
        require(_lastClick > 0, "Game is not started");

        // Sets final amount of the prize pool
        _prizePool = address(this).balance;

        // Pay top 50 winners
        // 0,6% per winner -> 30% total
        uint256 topFiftyPrize = (_prizePool * 6) / 1000;
        for (uint256 index = 0; index < 50; index++) {
            if (_fiftyWinners[index] != address(0)) {
                payable(_fiftyWinners[index]).send(topFiftyPrize);
            }
        }

        // Determine lottery winner
        // 20% total
        require(requestSubmitted == 0, "no you don't, you dirty goblin");
        requestRandomWords(_lotteryWinners.length);

        // Pay grand prize winner
        _winner.send(address(this).balance - (_prizePool / 5));
    }

    function payLotteryWinner() external {
        require(winningTicketPlusOne != 0, "no winner yet");

        uint256 lotteryWinner = winningTicketPlusOne - 1;
        payable(_lotteryWinners[lotteryWinner]).send(_prizePool / 5);
    }

    function rngFailsafe() external {
        // Approximatley a month's worth of blocks (3 sec block time)
        uint256 nbBlockPerMonth = 30 days;
        require(requestSubmitted + nbBlockPerMonth < block.number, "not yet");

        requestRandomWords(_lotteryWinners.length);
    }

    function winnerSaveFunds(address token, uint256 amount) external {
        require(block.number > _lastClick + _window, "Game window is not over");

        // Calls transfer() on token contract
        // this enables winner to claim any BEP-20 tokens
        // that were mistakenly sent to the contract
        token.call(abi.encodeWithSelector(0xa9059cbb, _winner, amount));
    }
}
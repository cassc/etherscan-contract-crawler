// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract XOGame is Ownable {
    Cell public nextTurn;
    Cell public winner;
    uint16 public nonce;
    uint64 public lastMoveTimestamp;

    address public immutable partyX;
    address public immutable partyO;

    enum Cell {
        Empty,
        X,
        O
    }

    Cell[256][256] public field;

    event Move(uint8 x, uint8 y, Cell cell);
    event Victory(address player, Cell cell);
    event PrizeContribution(address sponsor, uint256 amount);

    constructor(address _partyX, address _partyO) payable {
        partyX = _partyX;
        partyO = _partyO;
    }

    function play(uint8 x, uint8 y, uint256 _nonce) public {
        require(msg.sender == partyX || msg.sender == partyO, "Not a player");
        require(winner == Cell.Empty, "Game is over");
        require(nonce == _nonce, "Invalid nonce");
        Cell cell = msg.sender == partyX ? Cell.X : Cell.O;

        require(cell == nextTurn || nextTurn == Cell.Empty, "Not your turn");
        require(field[x][y] == Cell.Empty, "Cell is not empty");

        field[x][y] = cell;
        nextTurn = cell == Cell.X ? Cell.O : Cell.X;
        lastMoveTimestamp = uint64(block.timestamp);
        nonce = nonce + 1;

        emit Move(x, y, cell);
    }

    function win(uint8 x, uint8 y, int8 dx, int8 dy) public {
        require(dx == -1 || dx == 0 || dx == 1, "dx must be -1, 0 or 1");
        require(dy == -1 || dy == 0 || dy == 1, "dy must be -1, 0 or 1");
        require(dx != 0 || dy != 0, "dx and dy cannot be both 0");
        require(winner == Cell.Empty, "Game is over");

        Cell cell = field[x][y];
        require(cell != Cell.Empty, "Cell is empty");

        for (uint256 i = 0; i < 5; i++) {
            require(field[x][y] == cell, "Not a line");
            x = inc(x, dx);
            y = inc(y, dy);
        }

        declareWinner(cell == Cell.X ? partyX : partyO);
    }

    function playAndWin(uint8 x, uint8 y, uint256 _nonce, uint8 startX, uint8 startY, int8 dx, int8 dy) public {
        play(x, y, _nonce);
        win(startX, startY, dx, dy);
    }

    function timedOut() external {
        require(winner == Cell.Empty, "Already won");
        require(nextTurn != Cell.Empty, "Not started");
        require(block.timestamp - lastMoveTimestamp > 3 days, "Too soon");

        declareWinner(nextTurn == Cell.X ? partyO : partyX);
    }

    function declareWinner(address party) internal {
        safeSend(party, address(this).balance);
        winner = party == partyX ? Cell.X : Cell.O;

        emit Victory(party, winner);
    }

    function emergencyStop() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            safeSend(partyX, balance / 2);
            safeSend(partyO, balance / 2);
        }
    }

    function safeSend(address to, uint256 amount) internal {
        bool success = payable(to).send(amount);
        if (!success) {
            WETH weth = WETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
            weth.deposit{value: amount}();
            require(weth.transfer(to, amount), "Payment failed");
        }
    }

    function inc(uint8 v, int8 d) internal pure returns (uint8) {
        if (d == 0) {
            return v;
        }

        int256 r = int256(uint256(v)) + int256(d);
        require(r >= 0 && r < 256, "Out of bounds");
        return uint8(uint256(r));
    }

    receive() external payable {
        // Prevent contributions after the game is over
        require(winner == Cell.Empty, "Game is over");
        emit PrizeContribution(msg.sender, msg.value);
    }
}

interface WETH {
    function deposit() external payable;
    function transfer(address dst, uint256 wad) external returns (bool);
}
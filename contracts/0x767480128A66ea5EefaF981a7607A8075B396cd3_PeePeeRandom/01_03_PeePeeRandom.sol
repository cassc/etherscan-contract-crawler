// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract PeePeeRandom is Ownable {

    struct Raffle {
        uint256 winners;
        uint256 slots;
        uint256 rng;
    }

    uint256 currentId = 0;

    mapping(uint256 => Raffle) public idToRaffle;

    function startRaffle(uint winners, uint slots) public onlyOwner {
        uint256 rng = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, block.number, msg.sender)));
        
        idToRaffle[currentId++] = Raffle(winners, slots, rng);
    }

    function showResult(uint256 id) public view returns (uint256[] memory) {
        Raffle memory raffle = idToRaffle[id];

        uint256 slots = raffle.slots;
        uint256 winners = raffle.winners;
        uint256 winnerCount = 0;
        uint256 attempts = 0;

        bool[] memory winnerArray = new bool[](slots);

        while (winnerCount < winners) {
            uint256 extraRandomness = uint256(keccak256(abi.encodePacked(raffle.rng, attempts)));

            uint256 winnerPos = (extraRandomness % slots);

            attempts++;

            if (winnerArray[winnerPos])
                continue;

            winnerArray[winnerPos] = true;

            winnerCount++;
        }

        uint256[] memory winnerIds = new uint256[](winners);

        uint256 j = 0;

        for (uint i = 0; i < winnerArray.length; i++) {
            if (winnerArray[i]) {
                winnerIds[j] = i;
                j++;
            }
        }

        return winnerIds;
    }
}
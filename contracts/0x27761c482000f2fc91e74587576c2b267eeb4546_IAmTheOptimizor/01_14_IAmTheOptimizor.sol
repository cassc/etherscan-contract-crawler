// SPDX-License-Identifier: MIT

// This was a weird idea I had at 1am but thought could be fun. This has not been tested very well
// nor optimized - cut me some slack. This is heavily inspired from the project "I Am The Chad".
//
// Goal: Create a smart contract (a "player") by implementing the IPlayer interface that uses the smallest
// size of bytecode and uses the smallest amount of gas to solve the problem.
//
// Problem: An array of length 10 will be pseudo randomly generated along with a target number `n`. Find the
// 3 indexes in the array where the values of the array at the 3 indexes sum up to `n`.
//
// e.g. inputArr = [1,2,3,4,5,6,7,8,11,15], n = 18.
// solution is [1,4,8] becaues inputArr[1] + inputArr[4] + inputArr[8] == 18.
//
// Constraints: The input array will always be length 10. All numbers in the inputArr are [0, 49]. ANY permutation
// of 3 indexes are allowed as long as they are all unique indexes and sum up to `n`. There will ALWAYS be a set of 3
// numbers that add up to `n`.
//
// Everytime you write a more optimized player contract, you get minted THE OPTIMIZOR NFT and the previous optimizor's
// NFT is burnt. There will always just be 1 holder - the current best optimizor.
//
// You get to mint the NFT by having the LOWEST score. score = bytecode_size + gasUsed().
//
// How to play:
// 1. Create a player contract by implementing IPLAYER.sol
// It is CRUCIAL to set the owner of the player contract to be the EOA you will be calling IAmTheOptimizor.sol from. We check to see
// msg.sender == player.owner() to prevent random ppl from using your code and cheating.
//
// 2. Implement solve(). The first argument is the inputArr and second arg is the target number. Return an array of length 3
// of the 3 indexes.
//
// 3. Once you finished your player contract, deploy your contract and call becomeTheOptimizor(player_contract_address) when you think
// you can beat the current best optimizor. NOTE: The txn WILL fail if your player is less optimized than the current optimizors
// that holds the NFT.
//
// Have fun!
/// @author: 0xBeans

pragma solidity ^0.8.13;

import "./IPlayer.sol";
import "openzeppelin/token/ERC721/ERC721.sol";
import "openzeppelin/access/Ownable.sol";

import {console} from "forge-std/console.sol";

contract IAmTheOptimizor is ERC721, Ownable {
    // used to generate random numbers in array
    uint256 public constant BIT_MASK_LENGTH = 10;
    uint256 public constant BIT_MASK = 2**BIT_MASK_LENGTH - 1;

    struct LowestPoints {
        address optimizor;
        uint64 bytecodeSize;
        uint64 gasUsage;
        uint64 totalScore;
    }

    // current best optimizor
    LowestPoints public lowestPoints;

    // history of optimizors
    address[] public hallOfFame;

    string internal _baseTokenUri;

    constructor() ERC721("I Am The Optimizor", "IAMTHEOPTIMIZOR") {
        // set to highest limits so first submission is new optimizor
        lowestPoints = LowestPoints(
            address(0),
            type(uint64).max,
            type(uint64).max,
            type(uint64).max
        );

        _mint(msg.sender, 1);
        hallOfFame.push(msg.sender);
    }

    function becomeTheOptimizor(address player) external {
        // check so players dont use other ppls code
        require(IPlayer(player).owner() == msg.sender, "not your player");

        // grab bytecode size
        uint256 size;
        assembly {
            size := extcodesize(player)
        }

        unchecked {
            // pseudo random number to seed the arrays
            uint256 seed = uint256(
                keccak256(
                    abi.encodePacked(
                        block.coinbase,
                        block.number,
                        block.timestamp,
                        size
                    )
                )
            );

            // generate random arrays using seed
            uint256[10] memory inputArr = constructProblemArray(seed);

            // we shift the seed by 100 bits because we used the first 100 bits
            // to see the inputArr. We want to use fresh bits to seed the index array
            uint256[3] memory indexesFor3Sum = constructIndexesFor3Sum(
                seed >> (BIT_MASK_LENGTH * 10)
            );

            // target sum for player, calculated from the generated arrays
            // we take our pseudo random indexes and sum up the values at the indexes
            // in the inputArr to get our desired target 'n' for the player
            uint256 desiredSum = inputArr[indexesFor3Sum[0]] +
                inputArr[indexesFor3Sum[1]] +
                inputArr[indexesFor3Sum[2]];

            // calculate gas usage of player
            uint256 startGas = gasleft();
            uint256[3] memory playerAnswerIndexes = IPlayer(player).solve(
                inputArr,
                desiredSum
            );
            uint256 gasUsed = startGas - gasleft();

            // cache
            LowestPoints memory currLowestPoints = lowestPoints;

            // new submission needs to be more optimized
            require(
                gasUsed + size < currLowestPoints.totalScore,
                "not optimized enough"
            );

            // check indexes are unique
            require(
                playerAnswerIndexes[0] != playerAnswerIndexes[1] &&
                    playerAnswerIndexes[0] != playerAnswerIndexes[2] &&
                    playerAnswerIndexes[1] != playerAnswerIndexes[2],
                "not unique indexes"
            );

            // check indexes actually lead to correct sum
            require(
                inputArr[playerAnswerIndexes[0]] +
                    inputArr[playerAnswerIndexes[1]] +
                    inputArr[playerAnswerIndexes[2]] ==
                    desiredSum,
                "incorrect answer"
            );

            // burn previous optimizors token and issue a new one to new optimizor
            _burn(1);
            _mint(msg.sender, 1);
            hallOfFame.push(msg.sender);

            // set new optimizor requirement
            lowestPoints = LowestPoints(
                msg.sender,
                uint64(size),
                uint64(gasUsed),
                uint64(size + gasUsed)
            );
        }
    }

    // seed the array with random numbers from [0, 49] by taking 10 bits
    // of the seed for every number and mod by 50 (we end up using 100 bits of the seed)
    function constructProblemArray(uint256 seed)
        public
        pure
        returns (uint256[10] memory arr)
    {
        unchecked {
            for (uint256 i = 0; i < 10; i++) {
                arr[i] = (seed & BIT_MASK) % 50;
                seed >>= BIT_MASK_LENGTH;
            }
        }
    }

    // this function pseudo randomly chooses the desired number we want
    // the player to figure out. We already have a pseudo random array of
    // 10 elements, and we want pseudo randomly choose 3 unique (index) elements.
    function constructIndexesFor3Sum(uint256 seed)
        public
        pure
        returns (uint256[3] memory arr)
    {
        unchecked {
            arr[0] = (seed & BIT_MASK) % 10;
            seed >>= BIT_MASK_LENGTH;

            // make sure indexes are unique
            // statistically, this loop shouldnt run much
            while (true) {
                arr[1] = (seed & BIT_MASK) % 10;
                seed >>= BIT_MASK_LENGTH;

                if (arr[1] != arr[0]) {
                    break;
                }
            }

            // make sure indexes are unique
            // statistically, this loop shouldnt run much
            while (true) {
                arr[2] = (seed & BIT_MASK) % 10;
                seed >>= BIT_MASK_LENGTH;

                if (arr[2] != arr[1] && arr[2] != arr[0]) {
                    break;
                }
            }
        }
    }

    function changeTokenURI(string calldata uri) external onlyOwner {
        _baseTokenUri = uri;
    }

    function tokenURI(uint256) public view override returns (string memory) {
        return _baseTokenUri;
    }
}
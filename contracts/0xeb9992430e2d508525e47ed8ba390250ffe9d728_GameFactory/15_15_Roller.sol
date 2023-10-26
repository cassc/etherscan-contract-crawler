pragma solidity ^0.8.0;

/* 
*       ____
*      /\' .\    _____
*     /: \___\  / .  /\
*     \' / . / /____/..\
*      \/___/  \'  '\  /
*               \'__'\/                                 
*/

contract Roller {

    uint public constant MAX_VALUE = 75;
    uint public constant MAX_BLOCKS = 256;

    constructor() {
    }

    function count(uint startBlock, uint freq) public view returns (uint, uint) {
        require(startBlock <= block.number, "Start block must be less than or equal to the current block");
        require(freq > 0, "Frequency must be greater than 0");
        return (((block.number - startBlock) + freq - 1) / freq, MAX_BLOCKS / freq);
    }

    function getBlockNumbers(uint startBlock, uint freq) public view returns (uint[] memory) {
        require(startBlock <= block.number, "Start block must be less than or equal to the current block");
        require(startBlock > block.number - MAX_BLOCKS, "Block hash is not stored");
        require(freq > 0, "Frequency must be greater than 0");
        (uint arraySize,) = count(startBlock, freq);
        uint[] memory blocks = new uint[](arraySize);

        for(uint i = 0; i < arraySize; i++) {
            if (startBlock + freq * i >= block.number)
                break;
            else
                blocks[i] = startBlock + freq * i;
        }  
        return blocks;
    }

    function getRolls(uint startBlock, uint freq, bytes32 seed) public view returns (uint[] memory) {
        require(startBlock <= block.number, "Start block must be less than or equal to the current block");
        require(startBlock > block.number - MAX_BLOCKS, "Block hash is not stored");
        require(freq > 0, "Frequency must be greater than 0");
        (uint arraySize,) = count(startBlock, freq);
        uint[] memory blocks = new uint[](arraySize);

        for(uint i = 0; i < arraySize; i++) {
            if (startBlock + freq * i >= block.number)
                break;
            else
                blocks[i] = generateRandomNumber(startBlock + freq * i, seed);
        }  
        return blocks;
    }

    function fiveRollsByIndex(uint[5] memory indexes, uint startBlock, uint freq, bytes32 seed) public view returns (uint[5] memory) {
        require(startBlock <= block.number, "Start block must be less than or equal to the current block");
        require(startBlock > block.number - MAX_BLOCKS, "Block hash is not stored");
        require(freq > 0, "Frequency must be greater than 0");
        require(indexes.length == 5, "Array length must be 5");
        uint[5] memory rolls;
        for(uint i = 0; i < 5; i++) {
            if (startBlock + freq * indexes[i] >= block.number)
                break;
            else
                rolls[i] = generateRandomNumber(startBlock + freq * indexes[i], seed);
        }  
        return rolls;
    }

// Check Numbers

    function isNumberInList(uint startBlock, uint freq, uint number) public view returns (bool) {
        require(startBlock <= block.number, "Start block must be less than or equal to the current block");
        require(startBlock > block.number - MAX_BLOCKS, "Block hash is not stored");
        if (freq == 0)
            freq++;

        if (number >= startBlock && number < block.number) {
            if ((number - startBlock) % freq == 0) {
                return true;
            }
        }
        return false;
    }

    function areNumbersInList(uint startBlock, uint freq, uint[] memory numbers) public view returns (bool) {
        require(numbers.length >= 1 && numbers.length <= 5, "Array length must be between 1 and 5");

        for (uint i = 0; i < numbers.length; i++) {
            if (!isNumberInList(startBlock, freq, numbers[i])) {
                return false;
            }
        }
        return true;
    }

// Misc

    function currentBlockNumber() public view returns (uint) {
        return block.number;
    }

// Internal

    function generateRandomNumber(uint256 _blockNumber, bytes32 _seed) internal view returns (uint256) {
        require(block.number > _blockNumber, "Block not yet mined");
        require(_blockNumber > block.number - MAX_BLOCKS, "Block hash is not stored");
        return uint256(keccak256(abi.encodePacked(blockhash(_blockNumber), _seed))) % MAX_VALUE + 1;
    }

}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Puzzle {

    function _getShuffledNumbersForToken(uint16 tokenId) internal pure returns (uint8[9] memory shuffledOrder, uint16 shuffleIteration) {
        return _getShuffledNumbersForToken(tokenId, 0, false);
    }

    function _getShuffledNumbersForToken(uint16 tokenId, uint16 shuffleIterationCount, bool skipCheckSolvable) private pure returns (uint8[9] memory shuffledOrder, uint16 shuffleIteration) {
        return _shuffleNumbers(tokenId, shuffleIterationCount, skipCheckSolvable);
    }

    function _shuffleNumbers(uint16 tokenId, uint16 shuffleIteration, bool skipCheckSolvable) private pure returns (uint8[9] memory, uint16 shuffleIterationCount) {
        uint8[9] memory _numbers = [0, 1, 2, 3, 4, 5, 6, 7, 8];

        uint16 shuffledTokenId = tokenId + shuffleIteration;

        for (uint8 i = 0; i < _numbers.length; i++) {
            uint256 n = i + uint256(keccak256(abi.encodePacked(shuffledTokenId))) % (_numbers.length - i);
            uint8 temp = _numbers[n];
            _numbers[n] = _numbers[i];
            _numbers[i] = temp;
        }
        // the order created based on a tokenId might not be solvable, check if this order is solvable in a 3x3 puzzle else
        // create another shuffle order based on next tokenId.
        // The shuffleIterations required to get a solvable shuffled order (generally 0 or 1) is also passed in return so that 
        // we can skip the isSolvable checks in actual minting to prevent gas
        if (skipCheckSolvable || _checkSolvable(_numbers)) {
            return (_numbers, shuffleIteration);
        } else {
            return _shuffleNumbers(tokenId, shuffleIteration + 1, skipCheckSolvable);
        }
    }

    function verifyMoves(uint16 tokenId, bytes memory moves, uint16 shuffleIterationCount) public pure returns (bool) {

        (uint8[9] memory shuffledOrder, ) = _getShuffledNumbersForToken(tokenId, shuffleIterationCount, true);

        bytes1 indexOf1 = 0;
        bytes1 indexOf2 = 0;
        bytes1 indexOf3 = 0;
        bytes1 indexOf4 = 0;
        bytes1 indexOf5 = 0;
        bytes1 indexOf6 = 0;
        bytes1 indexOf7 = 0;
        bytes1 indexOf8 = 0;
        bytes1 indexOf0 = 0;

        
        for (uint8 i=0; i < shuffledOrder.length; i++) {
            uint8 order = shuffledOrder[i];
            if (order == 0) {
                indexOf0 = bytes1(i);
            } else if (order == 1) {
                indexOf1 = bytes1(i);
            } else if (order == 2) {
                indexOf2 = bytes1(i);
            } else if (order == 3) {
                indexOf3 = bytes1(i);
            } else if (order == 4) {
                indexOf4 = bytes1(i);
            } else if (order == 5) {
                indexOf5 = bytes1(i);
            } else if (order == 6) {
                indexOf6 = bytes1(i);
            } else if (order == 7) {
                indexOf7 = bytes1(i);
            } else if (order == 8) {
                indexOf8 = bytes1(i);
            }
        }

        for (uint16 i=0; i < moves.length; i++) {

            bytes1 move = moves[i];

            if (move == 0x01) {
                (indexOf0, indexOf1) = (indexOf1, indexOf0);
            } else if (move == 0x02) {
                (indexOf0, indexOf2) = (indexOf2, indexOf0);
            } else if (move == 0x03) {
                (indexOf0, indexOf3) = (indexOf3, indexOf0);
            } else if (move == 0x04) {
                (indexOf0, indexOf4) = (indexOf4, indexOf0);
            } else if (move == 0x05) {
                (indexOf0, indexOf5) = (indexOf5, indexOf0);
            } else if (move == 0x06) {
                (indexOf0, indexOf6) = (indexOf6, indexOf0);
            } else if (move == 0x07) {
                (indexOf0, indexOf7) = (indexOf7, indexOf0);
            } else if (move == 0x08) {
                (indexOf0, indexOf8) = (indexOf8, indexOf0);
            }
        }

        // final array should be 1,2,3,4,5,6,7,8,0
        return indexOf1 == 0 && indexOf2 == 0x01 && indexOf3 == 0x02 && indexOf4 == 0x03
                && indexOf5 == 0x04 && indexOf6 == 0x05 && indexOf7 == 0x06 && indexOf8 == 0x07
                && indexOf0 == 0x08;
    }

    function _checkSolvable(uint8[9] memory puzzle) private pure returns (bool) {

        uint16 parity = 0;
        uint8 gridWidth = 3;
        uint8 row = 0; 
        uint8 blankRow = 0;

        for (uint16 i = 0; i < puzzle.length; i++)
        {
            if (i % gridWidth == 0) { 
                row++;
            }
            if (puzzle[i] == 0) { 
                blankRow = row;
                continue;
            }
            for (uint16 j = i + 1; j < puzzle.length; j++)
            {
                if (puzzle[i] > puzzle[j] && puzzle[j] != 0)
                {
                    parity++;
                }
            }
        }

        if (gridWidth % 2 == 0) {
            if (blankRow % 2 == 0) {
                return parity % 2 == 0;
            } else { 
                return parity % 2 != 0;
            }
        } else {
            return parity % 2 == 0;
        }
    }
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


contract Leaderboard {
    uint256 constant public LEADERBOARD_ENTRY_SIZE = 20;
    uint256 constant public LEADERBOARD_LENGTH = 3;

    struct Entry {
        uint32 score;
        uint32 tokenId;
        bytes24 name;
    }

    struct EntryMemory {
        uint32 tokenId;
        string name;
        uint32 score;
    }

    Entry[LEADERBOARD_LENGTH] leaderBoard;

    function addEntry(string calldata name, uint32 score, uint32 tokenId) internal {
        bytes memory _name = bytes(name);
        require(_name.length <= LEADERBOARD_ENTRY_SIZE, "The name is too long");

        Entry memory newEntry = Entry({
            score: score,
            name: bytes24(_name),
            tokenId: tokenId
        });

        uint256 i = LEADERBOARD_LENGTH - 1;
        while ((i > 0) && (newEntry.score > leaderBoard[i].score)) {
            leaderBoard[i] = leaderBoard[i - 1];
            i--;
        }

        require(i < LEADERBOARD_LENGTH - 1, "Didn't make it");

        leaderBoard[i] = newEntry;
    }

    function getLeaderboard() public view returns (EntryMemory[] memory) {
        uint tableSize = 0;
        for (; tableSize < LEADERBOARD_LENGTH; tableSize++) {
            if (leaderBoard[tableSize].score == 0) {
                break;
            }
        }
        EntryMemory[] memory result = new EntryMemory[](tableSize);
//        return result;
        for (uint i = 0; i < tableSize; i++) {
            Entry storage current = leaderBoard[i];
            result[i] = EntryMemory({
                score: current.score,
                tokenId: current.tokenId,
                name: bytesToString(current.name)
            });
        }
        return result;
    }

    function bytesToString(bytes24 _bytes) internal pure returns (string memory) {
        uint8 i = 0;
        while(i < 24 && _bytes[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 24 && _bytes[i] != 0; i++) {
            bytesArray[i] = _bytes[i];
        }
        return string(bytesArray);
    }
}
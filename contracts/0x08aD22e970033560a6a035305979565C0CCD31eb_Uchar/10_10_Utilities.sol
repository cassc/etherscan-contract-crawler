/*

░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░                                                        ░░
░░    . . . . .    . . . . .    . . . . .    . . . . .    ░░
░░   . \  |  / .  . \  |  / .  . \  |  / .  . \  |  / .   ░░
░░   .  \ | /  .  .  \ | /  .  .  \ | /  .  .  \ | /  .   ░░
░░   .   \|/   .  .   \|/   .  .   \|/   .  .   \|/   .   ░░
░░    . . . . .    . . . . .    . . . . .    . . . . .    ░░
░░   .   /|\   .  .   /|\   .  .   /|\   .  .   /|\   .   ░░
░░   .  / | \  .  .  / | \  .  .  / | \  .  .  / | \  .   ░░
░░   . /  |  \ .  . /  |  \ .  . /  |  \ .  . /  |  \ .   ░░
░░    . . . . .    . . . . .    . . . . .    . . . . .    ░░
░░                                                        ░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library utils {
    string constant letters = "HTZRDTHSMOCLASVYOFPTIENEFNCHSMOTOASTWESKRENEICUQAILIAAHDTREMNSRADPBEEWIEETDRIGIOUOLYOJRNTUONEHTGXLEA";

    function uint2str(
        uint _i
    ) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function bytesToNum(bytes1 strBytes) internal pure returns (uint8) {
        return uint8(strBytes)-65;
    }

    // Get a pseudo random number
    function random(uint input, uint min, uint max) internal pure returns (uint) {
        uint randRange = max - min;
        return max - (uint(keccak256(abi.encodePacked(input + 6969))) % randRange) - 1;
    }

    function getLetter(uint num) internal pure returns (string memory) {
        bytes memory charByte = new bytes(1);
        charByte[0] = bytes(letters)[num];
        return string(charByte);
    }

    function getPoints(uint num) internal pure returns (uint) {
        uint points = 0;
        if (num == 1 || num == 5 || num == 9 || num == 15 || num == 18 || num == 19 || num == 20) {
            points = 1;
        } else if (num == 4 || num == 12 || num == 14 || num == 21) {
            points = 2;
        } else if (num == 7 || num == 8 || num == 25) {
            points = 3;
        } else if (num == 2 || num == 3 || num == 6 || num == 13 || num == 16 || num == 23) {
            points = 4;
        } else if (num == 11 || num == 22) {
            points = 5;
        } else if (num == 24) {
            points = 8;
        } else if (num == 10 || num == 17 || num == 26) {
            points = 10;
        }
        return points;
    }

    function initValue(uint tokenId) internal pure returns (string memory letter, uint value) {
        value = random(tokenId, 0, 100);
        letter = getLetter(value);
        return (letter, getPoints(bytesToNum(bytes(letter)[0])+1));
    }

    function getRgbs(uint tokenId, uint baseColor) internal pure returns (uint256[3] memory rgbValues) {
        if (baseColor > 0) {
            for (uint i = 0; i < 3; i++) {
                if (baseColor == i + 1) {
                    rgbValues[i] = 255;
                } else {
                    rgbValues[i] = utils.random(tokenId + i, 0, 256);
                }
            }
        } else {
            for (uint i = 0; i < 3; i++) {
                rgbValues[i] = 255;
            }
        }
        return rgbValues;
    }

    function getMintPhase(uint tokenId) internal pure returns (uint mintPhase) {
        if (tokenId <= 1000) {
            mintPhase = 1;
        } else if (tokenId <= 5000) {
            mintPhase = 2;
        } else {
            mintPhase = 3;
        }
    }

    function secondsRemaining(uint end) internal view returns (uint) {
        if (block.timestamp <= end) {
            return end - block.timestamp;
        } else {
            return 0;
        }
    }

    function minutesRemaining(uint end) internal view returns (uint) {
        if (secondsRemaining(end) >= 60) {
            return (end - block.timestamp) / 60;
        } else {
            return 0;
        }
    }
}
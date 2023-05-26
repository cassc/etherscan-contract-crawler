/*

░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░                                                        ░░
░░    . . . . .    . . . . .    . . . . .    . . . . .    ░░
░░   .         .  .         .  .         .  .         .   ░░
░░   .         .  .         .  .         .  .         .   ░░
░░   .         .  .         .  .         .  .         .   ░░
░░    . . . . .    . . . . .    . . . . .    . . . . .    ░░
░░   .         .  .         .  .         .  .         .   ░░
░░   .         .  .         .  .         .  .         .   ░░
░░   .         .  .         .  .         .  .         .   ░░
░░    . . . . .    . . . . .    . . . . .    . . . . .    ░░
░░                                                        ░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library utils {
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

    // Get a pseudo random number
    function random(uint input, uint min, uint max) internal pure returns (uint) {
        uint randRange = max - min;
        return max - (uint(keccak256(abi.encodePacked(input + 2023))) % randRange) - 1;
    }

    function initValue(uint tokenId) internal pure returns (uint value) {
        if (tokenId < 1000) {
            value = random(tokenId, 1, 51);
        } else if (tokenId < 2000) {
            value = random(tokenId, 1, 46);
        }  else if (tokenId < 3000) {
            value = random(tokenId, 1, 41);
        }  else if (tokenId < 4000) {
            value = random(tokenId, 1, 36);
        }  else if (tokenId < 5000) {
            value = random(tokenId, 1, 31);
        }  else if (tokenId < 6000) {
            value = random(tokenId, 1, 26);
        }  else if (tokenId < 7000) {
            value = random(tokenId, 1, 21);
        }  else if (tokenId < 8000) {
            value = random(tokenId, 1, 16);
        }  else if (tokenId < 9000) {
            value = random(tokenId, 1, 11);
        }  else if (tokenId < 10000) {
            value = random(tokenId, 1, 6);
        } else {
            value = 1;
        }
        return value;
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
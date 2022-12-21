// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../Interfaces/IOracle.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NTOracle is Ownable {
    mapping(uint256 => uint256) randomSeeds;
    mapping(address => bool) admins;
    uint256 nextSeed;

    function toggleAdmin(address adminToToggle) external onlyOwner {
        admins[adminToToggle] = !admins[adminToToggle];
    }

    function isAdmin(address addressToCheck) external view returns (bool) {
        return admins[addressToCheck];
    }

    function getSeed(uint256 seedKey) external view returns (uint256) {
        return randomSeeds[seedKey];
    }

    function getNextSeed() external view returns (uint256) {
        return nextSeed;
    }

    function setSeed() external {
        require(admins[msg.sender], "Only admins can set seed");
        //Gurantee random seed is never 0
        randomSeeds[nextSeed] =
            (uint256(
                keccak256(
                    abi.encodePacked(
                        toString(uint256(block.timestamp)),
                        toString(block.difficulty),
                        toString(block.gaslimit)
                    )
                )
            ) / 2) +
            1;
        ++nextSeed;
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    constructor() Ownable() {
        //Never set seed 0 to use as default case
        nextSeed = 1;
    }
}
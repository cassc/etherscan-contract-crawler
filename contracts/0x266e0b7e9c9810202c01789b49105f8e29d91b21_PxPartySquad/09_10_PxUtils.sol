// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

contract PxUtils {
    modifier noContracts() {
        uint256 size;
        address acc = msg.sender;
        assembly {
            size := extcodesize(acc)
        }
        require(msg.sender == tx.origin, "tx.origin != msg.sender");
        require(size == 0, "Contract calls are not allowed");
        _;
    }

    function _uncheckedInc(uint256 value) internal pure returns (uint256) {
        unchecked {
            return value + 1;
        }
    }

    function getRandomNumber() internal view returns (uint256) {
        uint256 randomNumber = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp +
                        block.difficulty +
                        ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
                        block.gaslimit +
                        ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
                        block.number
                )
            )
        );

        return randomNumber;
    }
}
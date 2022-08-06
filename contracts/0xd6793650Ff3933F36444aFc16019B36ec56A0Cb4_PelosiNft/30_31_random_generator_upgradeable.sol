// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract RandomGeneratorUpgradeable is Initializable {
    uint256 private randNonce;

    function __RandomGenerator_init() internal onlyInitializing {
        __RandomGenerator_init_unchained();
    }

    function __RandomGenerator_init_unchained() internal onlyInitializing {
        randNonce = 0;
    }

    function random(uint256 seed) internal returns (uint256) {
        randNonce += 1;
        return uint256(keccak256(abi.encodePacked(
                blockhash(block.number - 1),
                blockhash(block.number - 2),
                blockhash(block.number - 3),
                blockhash(block.number - 4),
                blockhash(block.number - 5),
                blockhash(block.number - 6),
                blockhash(block.number - 7),
                blockhash(block.number - 8),
                block.timestamp,
                msg.sender,
                randNonce,
                seed
            ))
        );
    }

    function randomCeil(uint256 q) internal returns (uint256) {
        return (random(gasleft()) % q) + 1;
    }
}
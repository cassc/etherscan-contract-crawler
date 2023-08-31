//SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/utils/cryptography/ECDSAUpgradeable.sol";

/// @title Moves OpenZeppelin's ECDSA implementation into a separate library to save
///        code size in the main contract.
library ECDSABridge {
    function recover(bytes32 hash, bytes memory signature) external pure returns (address) {
        return ECDSAUpgradeable.recover(hash, signature);
    }
}
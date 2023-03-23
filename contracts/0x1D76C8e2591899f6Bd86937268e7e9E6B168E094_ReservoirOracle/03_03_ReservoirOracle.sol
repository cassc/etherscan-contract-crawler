// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

// OZ libraries
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// Inspired by https://github.com/ZeframLou/trustus
contract ReservoirOracle is Ownable {
    // --- State --- 

    address public reservoirOracleAddress;

    // --- Structs ---

    struct Message {
        bytes32 id;
        bytes payload;
        // The UNIX timestamp when the message was signed by the oracle
        uint256 timestamp;
        // ECDSA signature or EIP-2098 compact signature
        bytes signature;
    }

    // --- Errors ---

    error InvalidId();
    error InvalidTimestamp();
    error InvalidSignatureLength();
    error InvalidReservoirOracleAddress();

    // --- Events ---
    
    event ReservoirOracleAddressUpdated(address indexed reservoirOracleAddress);

    // --- Constructor ---

    constructor(address _reservoirOracleAddress) {
        if (_reservoirOracleAddress == address(0)) revert InvalidReservoirOracleAddress(); 
        reservoirOracleAddress = _reservoirOracleAddress;
    }

    // --- Methods ---

    function updateReservoirOracleAddress(address _reservoirOracleAddress) external onlyOwner {
        if (_reservoirOracleAddress == address(0)) revert InvalidReservoirOracleAddress(); 
        reservoirOracleAddress = _reservoirOracleAddress;

        emit ReservoirOracleAddressUpdated(_reservoirOracleAddress);
    }

    function verifyMessage(
        bytes32 id,
        uint256 validFor,
        Message memory message
    ) external view returns (bool success) {
        // Ensure the message matches the requested id
        if (id != message.id) {
            revert InvalidId();
        }

        // Ensure the message timestamp is valid
        if (
            message.timestamp > block.timestamp ||
            message.timestamp + validFor < block.timestamp
        ) {
            revert InvalidTimestamp();
        }

        bytes32 r;
        bytes32 s;
        uint8 v;

        // Extract the individual signature fields from the signature
        bytes memory signature = message.signature;
        if (signature.length == 64) {
            // EIP-2098 compact signature
            bytes32 vs;
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
                s := and(
                    vs,
                    0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
                )
                v := add(shr(255, vs), 27)
            }
        } else if (signature.length == 65) {
            // ECDSA signature
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
        } else {
            revert InvalidSignatureLength();
        }

        address signerAddress = ecrecover(
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    // EIP-712 structured-data hash
                    keccak256(
                        abi.encode(
                            keccak256(
                                "Message(bytes32 id,bytes payload,uint256 timestamp)"
                            ),
                            message.id,
                            keccak256(message.payload),
                            message.timestamp
                        )
                    )
                )
            ),
            v,
            r,
            s
        );

        // Ensure the signer matches the designated oracle address
        return signerAddress == reservoirOracleAddress;
    }
}
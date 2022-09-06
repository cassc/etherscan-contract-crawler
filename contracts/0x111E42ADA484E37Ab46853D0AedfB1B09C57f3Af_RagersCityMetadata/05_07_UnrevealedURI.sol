// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

// @title:  Ragers City
// @desc:   Ragers City is a next-gen decentralized Manga owned by the community, featuring a collection of 5000 NFTs.
// @team:   https://twitter.com/RagersCity
// @author: https://linkedin.com/in/antoine-andrieux
// @url:    https://ragerscity.com

import "./interface/IUnrevealedURI.sol";

abstract contract UnrevealedURI is IUnrevealedURI {
    bytes public encryptedURI;

    // Set the encrypted URI
    function _setEncryptedURI(bytes memory _encryptedURI) internal {
        encryptedURI = _encryptedURI;
    }

    // Get the decrypted revealed URI
    function getRevealURI(bytes calldata _key) public view returns (string memory revealedURI) {
        bytes memory _encryptedURI = encryptedURI;
        if (_encryptedURI.length == 0) {
            revert("Nothing to reveal");
        }

        revealedURI = string(encryptDecrypt(_encryptedURI, _key));
    }

    // Encrypt/decrypt string data
    function encryptDecryptString(string memory _data, bytes calldata _key) public pure returns (bytes memory result) {
        return encryptDecrypt(bytes(_data), _key);
    }

    // https://ethereum.stackexchange.com/questions/69825/decrypt-message-on-chain
    function encryptDecrypt(bytes memory data, bytes calldata key) public pure override returns (bytes memory result) {
        // Store data length on stack for later use
        uint256 length = data.length;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Set result to free memory pointer
            result := mload(0x40)
            // Increase free memory pointer by lenght + 32
            mstore(0x40, add(add(result, length), 32))
            // Set result length
            mstore(result, length)
        }

        // Iterate over the data stepping by 32 bytes
        for (uint256 i = 0; i < length; i += 32) {
            // Generate hash of the key and offset
            bytes32 hash = keccak256(abi.encodePacked(key, i));

            bytes32 chunk;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                // Read 32-bytes data chunk
                chunk := mload(add(data, add(i, 32)))
            }
            // XOR the chunk with hash
            chunk ^= hash;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                // Write 32-byte encrypted chunk
                mstore(add(result, add(i, 32)), chunk)
            }
        }
    }

    function isEncryptedURI() public view returns (bool) {
        return encryptedURI.length != 0;
    }
}
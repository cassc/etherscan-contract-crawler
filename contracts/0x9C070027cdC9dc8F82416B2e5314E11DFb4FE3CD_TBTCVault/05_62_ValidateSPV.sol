pragma solidity ^0.8.4;

/** @title ValidateSPV*/
/** @author Summa (https://summa.one) */

import {BytesLib} from "./BytesLib.sol";
import {SafeMath} from "./SafeMath.sol";
import {BTCUtils} from "./BTCUtils.sol";


library ValidateSPV {

    using BTCUtils for bytes;
    using BTCUtils for uint256;
    using BytesLib for bytes;
    using SafeMath for uint256;

    enum InputTypes { NONE, LEGACY, COMPATIBILITY, WITNESS }
    enum OutputTypes { NONE, WPKH, WSH, OP_RETURN, PKH, SH, NONSTANDARD }

    uint256 constant ERR_BAD_LENGTH = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    uint256 constant ERR_INVALID_CHAIN = 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe;
    uint256 constant ERR_LOW_WORK = 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffd;

    function getErrBadLength() internal pure returns (uint256) {
        return ERR_BAD_LENGTH;
    }

    function getErrInvalidChain() internal pure returns (uint256) {
        return ERR_INVALID_CHAIN;
    }

    function getErrLowWork() internal pure returns (uint256) {
        return ERR_LOW_WORK;
    }

    /// @notice                     Validates a tx inclusion in the block
    /// @dev                        `index` is not a reliable indicator of location within a block
    /// @param _txid                The txid (LE)
    /// @param _merkleRoot          The merkle root (as in the block header)
    /// @param _intermediateNodes   The proof's intermediate nodes (digests between leaf and root)
    /// @param _index               The leaf's index in the tree (0-indexed)
    /// @return                     true if fully valid, false otherwise
    function prove(
        bytes32 _txid,
        bytes32 _merkleRoot,
        bytes memory _intermediateNodes,
        uint _index
    ) internal view returns (bool) {
        // Shortcut the empty-block case
        if (_txid == _merkleRoot && _index == 0 && _intermediateNodes.length == 0) {
            return true;
        }

        // If the Merkle proof failed, bubble up error
        return BTCUtils.verifyHash256Merkle(
            _txid,
            _intermediateNodes,
            _merkleRoot,
            _index
        );
    }

    /// @notice             Hashes transaction to get txid
    /// @dev                Supports Legacy and Witness
    /// @param _version     4-bytes version
    /// @param _vin         Raw bytes length-prefixed input vector
    /// @param _vout        Raw bytes length-prefixed output vector
    /// @param _locktime    4-byte tx locktime
    /// @return             32-byte transaction id, little endian
    function calculateTxId(
        bytes4 _version,
        bytes memory _vin,
        bytes memory _vout,
        bytes4 _locktime
    ) internal view returns (bytes32) {
        // Get transaction hash double-Sha256(version + nIns + inputs + nOuts + outputs + locktime)
        return abi.encodePacked(_version, _vin, _vout, _locktime).hash256View();
    }

    /// @notice                  Checks validity of header chain
    /// @notice                  Compares the hash of each header to the prevHash in the next header
    /// @param headers           Raw byte array of header chain
    /// @return totalDifficulty  The total accumulated difficulty of the header chain, or an error code
    function validateHeaderChain(
        bytes memory headers
    ) internal view returns (uint256 totalDifficulty) {

        // Check header chain length
        if (headers.length % 80 != 0) {return ERR_BAD_LENGTH;}

        // Initialize header start index
        bytes32 digest;

        totalDifficulty = 0;

        for (uint256 start = 0; start < headers.length; start += 80) {

            // After the first header, check that headers are in a chain
            if (start != 0) {
                if (!validateHeaderPrevHash(headers, start, digest)) {return ERR_INVALID_CHAIN;}
            }

            // ith header target
            uint256 target = headers.extractTargetAt(start);

            // Require that the header has sufficient work
            digest = headers.hash256Slice(start, 80);
            if(uint256(digest).reverseUint256() > target) {
                return ERR_LOW_WORK;
            }

            // Add ith header difficulty to difficulty sum
            totalDifficulty = totalDifficulty + target.calculateDifficulty();
        }
    }

    /// @notice             Checks validity of header work
    /// @param digest       Header digest
    /// @param target       The target threshold
    /// @return             true if header work is valid, false otherwise
    function validateHeaderWork(
        bytes32 digest,
        uint256 target
    ) internal pure returns (bool) {
        if (digest == bytes32(0)) {return false;}
        return (uint256(digest).reverseUint256() < target);
    }

    /// @notice                     Checks validity of header chain
    /// @dev                        Compares current header prevHash to previous header's digest
    /// @param headers              The raw bytes array containing the header
    /// @param at                   The position of the header
    /// @param prevHeaderDigest     The previous header's digest
    /// @return                     true if the connect is valid, false otherwise
    function validateHeaderPrevHash(
        bytes memory headers,
        uint256 at,
        bytes32 prevHeaderDigest
    ) internal pure returns (bool) {

        // Extract prevHash of current header
        bytes32 prevHash = headers.extractPrevBlockLEAt(at);

        // Compare prevHash of current header to previous header's digest
        if (prevHash != prevHeaderDigest) {return false;}

        return true;
    }
}
pragma solidity ^0.8.4;

/** @title BitcoinSPV */
/** @author Summa (https://summa.one) */

import {BytesLib} from "./BytesLib.sol";
import {SafeMath} from "./SafeMath.sol";

library BTCUtils {
    using BytesLib for bytes;
    using SafeMath for uint256;

    // The target at minimum Difficulty. Also the target of the genesis block
    uint256 public constant DIFF1_TARGET = 0xffff0000000000000000000000000000000000000000000000000000;

    uint256 public constant RETARGET_PERIOD = 2 * 7 * 24 * 60 * 60;  // 2 weeks in seconds
    uint256 public constant RETARGET_PERIOD_BLOCKS = 2016;  // 2 weeks in blocks

    uint256 public constant ERR_BAD_ARG = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    /* ***** */
    /* UTILS */
    /* ***** */

    /// @notice         Determines the length of a VarInt in bytes
    /// @dev            A VarInt of >1 byte is prefixed with a flag indicating its length
    /// @param _flag    The first byte of a VarInt
    /// @return         The number of non-flag bytes in the VarInt
    function determineVarIntDataLength(bytes memory _flag) internal pure returns (uint8) {
        return determineVarIntDataLengthAt(_flag, 0);
    }

    /// @notice         Determines the length of a VarInt in bytes
    /// @dev            A VarInt of >1 byte is prefixed with a flag indicating its length
    /// @param _b       The byte array containing a VarInt
    /// @param _at      The position of the VarInt in the array
    /// @return         The number of non-flag bytes in the VarInt
    function determineVarIntDataLengthAt(bytes memory _b, uint256 _at) internal pure returns (uint8) {
        if (uint8(_b[_at]) == 0xff) {
            return 8;  // one-byte flag, 8 bytes data
        }
        if (uint8(_b[_at]) == 0xfe) {
            return 4;  // one-byte flag, 4 bytes data
        }
        if (uint8(_b[_at]) == 0xfd) {
            return 2;  // one-byte flag, 2 bytes data
        }

        return 0;  // flag is data
    }

    /// @notice     Parse a VarInt into its data length and the number it represents
    /// @dev        Useful for Parsing Vins and Vouts. Returns ERR_BAD_ARG if insufficient bytes.
    ///             Caller SHOULD explicitly handle this case (or bubble it up)
    /// @param _b   A byte-string starting with a VarInt
    /// @return     number of bytes in the encoding (not counting the tag), the encoded int
    function parseVarInt(bytes memory _b) internal pure returns (uint256, uint256) {
        return parseVarIntAt(_b, 0);
    }

    /// @notice     Parse a VarInt into its data length and the number it represents
    /// @dev        Useful for Parsing Vins and Vouts. Returns ERR_BAD_ARG if insufficient bytes.
    ///             Caller SHOULD explicitly handle this case (or bubble it up)
    /// @param _b   A byte-string containing a VarInt
    /// @param _at  The position of the VarInt
    /// @return     number of bytes in the encoding (not counting the tag), the encoded int
    function parseVarIntAt(bytes memory _b, uint256 _at) internal pure returns (uint256, uint256) {
        uint8 _dataLen = determineVarIntDataLengthAt(_b, _at);

        if (_dataLen == 0) {
            return (0, uint8(_b[_at]));
        }
        if (_b.length < 1 + _dataLen + _at) {
            return (ERR_BAD_ARG, 0);
        }
        uint256 _number;
        if (_dataLen == 2) {
            _number = reverseUint16(uint16(_b.slice2(1 + _at)));
        } else if (_dataLen == 4) {
            _number = reverseUint32(uint32(_b.slice4(1 + _at)));
        } else if (_dataLen == 8) {
            _number = reverseUint64(uint64(_b.slice8(1 + _at)));
        }
        return (_dataLen, _number);
    }

    /// @notice          Changes the endianness of a byte array
    /// @dev             Returns a new, backwards, bytes
    /// @param _b        The bytes to reverse
    /// @return          The reversed bytes
    function reverseEndianness(bytes memory _b) internal pure returns (bytes memory) {
        bytes memory _newValue = new bytes(_b.length);

        for (uint i = 0; i < _b.length; i++) {
            _newValue[_b.length - i - 1] = _b[i];
        }

        return _newValue;
    }

    /// @notice          Changes the endianness of a uint256
    /// @dev             https://graphics.stanford.edu/~seander/bithacks.html#ReverseParallel
    /// @param _b        The unsigned integer to reverse
    /// @return v        The reversed value
    function reverseUint256(uint256 _b) internal pure returns (uint256 v) {
        v = _b;

        // swap bytes
        v = ((v >> 8) & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF) |
            ((v & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF) << 8);
        // swap 2-byte long pairs
        v = ((v >> 16) & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) |
            ((v & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) << 16);
        // swap 4-byte long pairs
        v = ((v >> 32) & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) |
            ((v & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) << 32);
        // swap 8-byte long pairs
        v = ((v >> 64) & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) |
            ((v & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) << 64);
        // swap 16-byte long pairs
        v = (v >> 128) | (v << 128);
    }

    /// @notice          Changes the endianness of a uint64
    /// @param _b        The unsigned integer to reverse
    /// @return v        The reversed value
    function reverseUint64(uint64 _b) internal pure returns (uint64 v) {
        v = _b;

        // swap bytes
        v = ((v >> 8) & 0x00FF00FF00FF00FF) |
            ((v & 0x00FF00FF00FF00FF) << 8);
        // swap 2-byte long pairs
        v = ((v >> 16) & 0x0000FFFF0000FFFF) |
            ((v & 0x0000FFFF0000FFFF) << 16);
        // swap 4-byte long pairs
        v = (v >> 32) | (v << 32);
    }

    /// @notice          Changes the endianness of a uint32
    /// @param _b        The unsigned integer to reverse
    /// @return v        The reversed value
    function reverseUint32(uint32 _b) internal pure returns (uint32 v) {
        v = _b;

        // swap bytes
        v = ((v >> 8) & 0x00FF00FF) |
            ((v & 0x00FF00FF) << 8);
        // swap 2-byte long pairs
        v = (v >> 16) | (v << 16);
    }

    /// @notice          Changes the endianness of a uint24
    /// @param _b        The unsigned integer to reverse
    /// @return v        The reversed value
    function reverseUint24(uint24 _b) internal pure returns (uint24 v) {
        v =  (_b << 16) | (_b & 0x00FF00) | (_b >> 16);
    }

    /// @notice          Changes the endianness of a uint16
    /// @param _b        The unsigned integer to reverse
    /// @return v        The reversed value
    function reverseUint16(uint16 _b) internal pure returns (uint16 v) {
        v =  (_b << 8) | (_b >> 8);
    }


    /// @notice          Converts big-endian bytes to a uint
    /// @dev             Traverses the byte array and sums the bytes
    /// @param _b        The big-endian bytes-encoded integer
    /// @return          The integer representation
    function bytesToUint(bytes memory _b) internal pure returns (uint256) {
        uint256 _number;

        for (uint i = 0; i < _b.length; i++) {
            _number = _number + uint8(_b[i]) * (2 ** (8 * (_b.length - (i + 1))));
        }

        return _number;
    }

    /// @notice          Get the last _num bytes from a byte array
    /// @param _b        The byte array to slice
    /// @param _num      The number of bytes to extract from the end
    /// @return          The last _num bytes of _b
    function lastBytes(bytes memory _b, uint256 _num) internal pure returns (bytes memory) {
        uint256 _start = _b.length.sub(_num);

        return _b.slice(_start, _num);
    }

    /// @notice          Implements bitcoin's hash160 (rmd160(sha2()))
    /// @dev             abi.encodePacked changes the return to bytes instead of bytes32
    /// @param _b        The pre-image
    /// @return          The digest
    function hash160(bytes memory _b) internal pure returns (bytes memory) {
        return abi.encodePacked(ripemd160(abi.encodePacked(sha256(_b))));
    }

    /// @notice          Implements bitcoin's hash160 (sha2 + ripemd160)
    /// @dev             sha2 precompile at address(2), ripemd160 at address(3)
    /// @param _b        The pre-image
    /// @return res      The digest
    function hash160View(bytes memory _b) internal view returns (bytes20 res) {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            pop(staticcall(gas(), 2, add(_b, 32), mload(_b), 0x00, 32))
            pop(staticcall(gas(), 3, 0x00, 32, 0x00, 32))
            // read from position 12 = 0c
            res := mload(0x0c)
        }
    }

    /// @notice          Implements bitcoin's hash256 (double sha2)
    /// @dev             abi.encodePacked changes the return to bytes instead of bytes32
    /// @param _b        The pre-image
    /// @return          The digest
    function hash256(bytes memory _b) internal pure returns (bytes32) {
        return sha256(abi.encodePacked(sha256(_b)));
    }

    /// @notice          Implements bitcoin's hash256 (double sha2)
    /// @dev             sha2 is precompiled smart contract located at address(2)
    /// @param _b        The pre-image
    /// @return res      The digest
    function hash256View(bytes memory _b) internal view returns (bytes32 res) {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            pop(staticcall(gas(), 2, add(_b, 32), mload(_b), 0x00, 32))
            pop(staticcall(gas(), 2, 0x00, 32, 0x00, 32))
            res := mload(0x00)
        }
    }

    /// @notice          Implements bitcoin's hash256 on a pair of bytes32
    /// @dev             sha2 is precompiled smart contract located at address(2)
    /// @param _a        The first bytes32 of the pre-image
    /// @param _b        The second bytes32 of the pre-image
    /// @return res      The digest
    function hash256Pair(bytes32 _a, bytes32 _b) internal view returns (bytes32 res) {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            mstore(0x00, _a)
            mstore(0x20, _b)
            pop(staticcall(gas(), 2, 0x00, 64, 0x00, 32))
            pop(staticcall(gas(), 2, 0x00, 32, 0x00, 32))
            res := mload(0x00)
        }
    }

    /// @notice          Implements bitcoin's hash256 (double sha2)
    /// @dev             sha2 is precompiled smart contract located at address(2)
    /// @param _b        The array containing the pre-image
    /// @param at        The start of the pre-image
    /// @param len       The length of the pre-image
    /// @return res      The digest
    function hash256Slice(
        bytes memory _b,
        uint256 at,
        uint256 len
    ) internal view returns (bytes32 res) {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            pop(staticcall(gas(), 2, add(_b, add(32, at)), len, 0x00, 32))
            pop(staticcall(gas(), 2, 0x00, 32, 0x00, 32))
            res := mload(0x00)
        }
    }

    /* ************ */
    /* Legacy Input */
    /* ************ */

    /// @notice          Extracts the nth input from the vin (0-indexed)
    /// @dev             Iterates over the vin. If you need to extract several, write a custom function
    /// @param _vin      The vin as a tightly-packed byte array
    /// @param _index    The 0-indexed location of the input to extract
    /// @return          The input as a byte array
    function extractInputAtIndex(bytes memory _vin, uint256 _index) internal pure returns (bytes memory) {
        uint256 _varIntDataLen;
        uint256 _nIns;

        (_varIntDataLen, _nIns) = parseVarInt(_vin);
        require(_varIntDataLen != ERR_BAD_ARG, "Read overrun during VarInt parsing");
        require(_index < _nIns, "Vin read overrun");

        uint256 _len = 0;
        uint256 _offset = 1 + _varIntDataLen;

        for (uint256 _i = 0; _i < _index; _i ++) {
            _len = determineInputLengthAt(_vin, _offset);
            require(_len != ERR_BAD_ARG, "Bad VarInt in scriptSig");
            _offset = _offset + _len;
        }

        _len = determineInputLengthAt(_vin, _offset);
        require(_len != ERR_BAD_ARG, "Bad VarInt in scriptSig");
        return _vin.slice(_offset, _len);
    }

    /// @notice          Determines whether an input is legacy
    /// @dev             False if no scriptSig, otherwise True
    /// @param _input    The input
    /// @return          True for legacy, False for witness
    function isLegacyInput(bytes memory _input) internal pure returns (bool) {
        return _input[36] != hex"00";
    }

    /// @notice          Determines the length of a scriptSig in an input
    /// @dev             Will return 0 if passed a witness input.
    /// @param _input    The LEGACY input
    /// @return          The length of the script sig
    function extractScriptSigLen(bytes memory _input) internal pure returns (uint256, uint256) {
        return extractScriptSigLenAt(_input, 0);
    }

    /// @notice          Determines the length of a scriptSig in an input
    ///                  starting at the specified position
    /// @dev             Will return 0 if passed a witness input.
    /// @param _input    The byte array containing the LEGACY input
    /// @param _at       The position of the input in the array
    /// @return          The length of the script sig
    function extractScriptSigLenAt(bytes memory _input, uint256 _at) internal pure returns (uint256, uint256) {
        if (_input.length < 37 + _at) {
            return (ERR_BAD_ARG, 0);
        }

        uint256 _varIntDataLen;
        uint256 _scriptSigLen;
        (_varIntDataLen, _scriptSigLen) = parseVarIntAt(_input, _at + 36);

        return (_varIntDataLen, _scriptSigLen);
    }

    /// @notice          Determines the length of an input from its scriptSig
    /// @dev             36 for outpoint, 1 for scriptSig length, 4 for sequence
    /// @param _input    The input
    /// @return          The length of the input in bytes
    function determineInputLength(bytes memory _input) internal pure returns (uint256) {
        return determineInputLengthAt(_input, 0);
    }

    /// @notice          Determines the length of an input from its scriptSig,
    ///                  starting at the specified position
    /// @dev             36 for outpoint, 1 for scriptSig length, 4 for sequence
    /// @param _input    The byte array containing the input
    /// @param _at       The position of the input in the array
    /// @return          The length of the input in bytes
    function determineInputLengthAt(bytes memory _input, uint256 _at) internal pure returns (uint256) {
        uint256 _varIntDataLen;
        uint256 _scriptSigLen;
        (_varIntDataLen, _scriptSigLen) = extractScriptSigLenAt(_input, _at);
        if (_varIntDataLen == ERR_BAD_ARG) {
            return ERR_BAD_ARG;
        }

        return 36 + 1 + _varIntDataLen + _scriptSigLen + 4;
    }

    /// @notice          Extracts the LE sequence bytes from an input
    /// @dev             Sequence is used for relative time locks
    /// @param _input    The LEGACY input
    /// @return          The sequence bytes (LE uint)
    function extractSequenceLELegacy(bytes memory _input) internal pure returns (bytes4) {
        uint256 _varIntDataLen;
        uint256 _scriptSigLen;
        (_varIntDataLen, _scriptSigLen) = extractScriptSigLen(_input);
        require(_varIntDataLen != ERR_BAD_ARG, "Bad VarInt in scriptSig");
        return _input.slice4(36 + 1 + _varIntDataLen + _scriptSigLen);
    }

    /// @notice          Extracts the sequence from the input
    /// @dev             Sequence is a 4-byte little-endian number
    /// @param _input    The LEGACY input
    /// @return          The sequence number (big-endian uint)
    function extractSequenceLegacy(bytes memory _input) internal pure returns (uint32) {
        uint32 _leSeqence = uint32(extractSequenceLELegacy(_input));
        uint32 _beSequence = reverseUint32(_leSeqence);
        return _beSequence;
    }
    /// @notice          Extracts the VarInt-prepended scriptSig from the input in a tx
    /// @dev             Will return hex"00" if passed a witness input
    /// @param _input    The LEGACY input
    /// @return          The length-prepended scriptSig
    function extractScriptSig(bytes memory _input) internal pure returns (bytes memory) {
        uint256 _varIntDataLen;
        uint256 _scriptSigLen;
        (_varIntDataLen, _scriptSigLen) = extractScriptSigLen(_input);
        require(_varIntDataLen != ERR_BAD_ARG, "Bad VarInt in scriptSig");
        return _input.slice(36, 1 + _varIntDataLen + _scriptSigLen);
    }


    /* ************* */
    /* Witness Input */
    /* ************* */

    /// @notice          Extracts the LE sequence bytes from an input
    /// @dev             Sequence is used for relative time locks
    /// @param _input    The WITNESS input
    /// @return          The sequence bytes (LE uint)
    function extractSequenceLEWitness(bytes memory _input) internal pure returns (bytes4) {
        return _input.slice4(37);
    }

    /// @notice          Extracts the sequence from the input in a tx
    /// @dev             Sequence is a 4-byte little-endian number
    /// @param _input    The WITNESS input
    /// @return          The sequence number (big-endian uint)
    function extractSequenceWitness(bytes memory _input) internal pure returns (uint32) {
        uint32 _leSeqence = uint32(extractSequenceLEWitness(_input));
        uint32 _inputeSequence = reverseUint32(_leSeqence);
        return _inputeSequence;
    }

    /// @notice          Extracts the outpoint from the input in a tx
    /// @dev             32-byte tx id with 4-byte index
    /// @param _input    The input
    /// @return          The outpoint (LE bytes of prev tx hash + LE bytes of prev tx index)
    function extractOutpoint(bytes memory _input) internal pure returns (bytes memory) {
        return _input.slice(0, 36);
    }

    /// @notice          Extracts the outpoint tx id from an input
    /// @dev             32-byte tx id
    /// @param _input    The input
    /// @return          The tx id (little-endian bytes)
    function extractInputTxIdLE(bytes memory _input) internal pure returns (bytes32) {
        return _input.slice32(0);
    }

    /// @notice          Extracts the outpoint tx id from an input
    ///                  starting at the specified position
    /// @dev             32-byte tx id
    /// @param _input    The byte array containing the input
    /// @param _at       The position of the input
    /// @return          The tx id (little-endian bytes)
    function extractInputTxIdLeAt(bytes memory _input, uint256 _at) internal pure returns (bytes32) {
        return _input.slice32(_at);
    }

    /// @notice          Extracts the LE tx input index from the input in a tx
    /// @dev             4-byte tx index
    /// @param _input    The input
    /// @return          The tx index (little-endian bytes)
    function extractTxIndexLE(bytes memory _input) internal pure returns (bytes4) {
        return _input.slice4(32);
    }

    /// @notice          Extracts the LE tx input index from the input in a tx
    ///                  starting at the specified position
    /// @dev             4-byte tx index
    /// @param _input    The byte array containing the input
    /// @param _at       The position of the input
    /// @return          The tx index (little-endian bytes)
    function extractTxIndexLeAt(bytes memory _input, uint256 _at) internal pure returns (bytes4) {
        return _input.slice4(32 + _at);
    }

    /* ****** */
    /* Output */
    /* ****** */

    /// @notice          Determines the length of an output
    /// @dev             Works with any properly formatted output
    /// @param _output   The output
    /// @return          The length indicated by the prefix, error if invalid length
    function determineOutputLength(bytes memory _output) internal pure returns (uint256) {
        return determineOutputLengthAt(_output, 0);
    }

    /// @notice          Determines the length of an output
    ///                  starting at the specified position
    /// @dev             Works with any properly formatted output
    /// @param _output   The byte array containing the output
    /// @param _at       The position of the output
    /// @return          The length indicated by the prefix, error if invalid length
    function determineOutputLengthAt(bytes memory _output, uint256 _at) internal pure returns (uint256) {
        if (_output.length < 9 + _at) {
            return ERR_BAD_ARG;
        }
        uint256 _varIntDataLen;
        uint256 _scriptPubkeyLength;
        (_varIntDataLen, _scriptPubkeyLength) = parseVarIntAt(_output, 8 + _at);

        if (_varIntDataLen == ERR_BAD_ARG) {
            return ERR_BAD_ARG;
        }

        // 8-byte value, 1-byte for tag itself
        return 8 + 1 + _varIntDataLen + _scriptPubkeyLength;
    }

    /// @notice          Extracts the output at a given index in the TxOuts vector
    /// @dev             Iterates over the vout. If you need to extract multiple, write a custom function
    /// @param _vout     The _vout to extract from
    /// @param _index    The 0-indexed location of the output to extract
    /// @return          The specified output
    function extractOutputAtIndex(bytes memory _vout, uint256 _index) internal pure returns (bytes memory) {
        uint256 _varIntDataLen;
        uint256 _nOuts;

        (_varIntDataLen, _nOuts) = parseVarInt(_vout);
        require(_varIntDataLen != ERR_BAD_ARG, "Read overrun during VarInt parsing");
        require(_index < _nOuts, "Vout read overrun");

        uint256 _len = 0;
        uint256 _offset = 1 + _varIntDataLen;

        for (uint256 _i = 0; _i < _index; _i ++) {
            _len = determineOutputLengthAt(_vout, _offset);
            require(_len != ERR_BAD_ARG, "Bad VarInt in scriptPubkey");
            _offset += _len;
        }

        _len = determineOutputLengthAt(_vout, _offset);
        require(_len != ERR_BAD_ARG, "Bad VarInt in scriptPubkey");
        return _vout.slice(_offset, _len);
    }

    /// @notice          Extracts the value bytes from the output in a tx
    /// @dev             Value is an 8-byte little-endian number
    /// @param _output   The output
    /// @return          The output value as LE bytes
    function extractValueLE(bytes memory _output) internal pure returns (bytes8) {
        return _output.slice8(0);
    }

    /// @notice          Extracts the value from the output in a tx
    /// @dev             Value is an 8-byte little-endian number
    /// @param _output   The output
    /// @return          The output value
    function extractValue(bytes memory _output) internal pure returns (uint64) {
        uint64 _leValue = uint64(extractValueLE(_output));
        uint64 _beValue = reverseUint64(_leValue);
        return _beValue;
    }

    /// @notice          Extracts the value from the output in a tx
    /// @dev             Value is an 8-byte little-endian number
    /// @param _output   The byte array containing the output
    /// @param _at       The starting index of the output in the array
    /// @return          The output value
    function extractValueAt(bytes memory _output, uint256 _at) internal pure returns (uint64) {
        uint64 _leValue = uint64(_output.slice8(_at));
        uint64 _beValue = reverseUint64(_leValue);
        return _beValue;
    }

    /// @notice          Extracts the data from an op return output
    /// @dev             Returns hex"" if no data or not an op return
    /// @param _output   The output
    /// @return          Any data contained in the opreturn output, null if not an op return
    function extractOpReturnData(bytes memory _output) internal pure returns (bytes memory) {
        if (_output[9] != hex"6a") {
            return hex"";
        }
        bytes1 _dataLen = _output[10];
        return _output.slice(11, uint256(uint8(_dataLen)));
    }

    /// @notice          Extracts the hash from the output script
    /// @dev             Determines type by the length prefix and validates format
    /// @param _output   The output
    /// @return          The hash committed to by the pk_script, or null for errors
    function extractHash(bytes memory _output) internal pure returns (bytes memory) {
        return extractHashAt(_output, 8, _output.length - 8);
    }

    /// @notice          Extracts the hash from the output script
    /// @dev             Determines type by the length prefix and validates format
    /// @param _output   The byte array containing the output
    /// @param _at       The starting index of the output script in the array
    ///                  (output start + 8)
    /// @param _len      The length of the output script
    ///                  (output length - 8)
    /// @return          The hash committed to by the pk_script, or null for errors
    function extractHashAt(
        bytes memory _output,
        uint256 _at,
        uint256 _len
    ) internal pure returns (bytes memory) {
        uint8 _scriptLen = uint8(_output[_at]);

        // don't have to worry about overflow here.
        // if _scriptLen + 1 overflows, then output length would have to be < 1
        // for this check to pass. if it's < 1, then we errored when assigning
        // _scriptLen
        if (_scriptLen + 1 != _len) {
            return hex"";
        }

        if (uint8(_output[_at + 1]) == 0) {
            if (_scriptLen < 2) {
                return hex"";
            }
            uint256 _payloadLen = uint8(_output[_at + 2]);
            // Check for maliciously formatted witness outputs.
            // No need to worry about underflow as long b/c of the `< 2` check
            if (_payloadLen != _scriptLen - 2 || (_payloadLen != 0x20 && _payloadLen != 0x14)) {
                return hex"";
            }
            return _output.slice(_at + 3, _payloadLen);
        } else {
            bytes3 _tag = _output.slice3(_at);
            // p2pkh
            if (_tag == hex"1976a9") {
                // Check for maliciously formatted p2pkh
                // No need to worry about underflow, b/c of _scriptLen check
                if (uint8(_output[_at + 3]) != 0x14 ||
                    _output.slice2(_at + _len - 2) != hex"88ac") {
                    return hex"";
                }
                return _output.slice(_at + 4, 20);
            //p2sh
            } else if (_tag == hex"17a914") {
                // Check for maliciously formatted p2sh
                // No need to worry about underflow, b/c of _scriptLen check
                if (uint8(_output[_at + _len - 1]) != 0x87) {
                    return hex"";
                }
                return _output.slice(_at + 3, 20);
            }
        }
        return hex"";  /* NB: will trigger on OPRETURN and any non-standard that doesn't overrun */
    }

    /* ********** */
    /* Witness TX */
    /* ********** */


    /// @notice      Checks that the vin passed up is properly formatted
    /// @dev         Consider a vin with a valid vout in its scriptsig
    /// @param _vin  Raw bytes length-prefixed input vector
    /// @return      True if it represents a validly formatted vin
    function validateVin(bytes memory _vin) internal pure returns (bool) {
        uint256 _varIntDataLen;
        uint256 _nIns;

        (_varIntDataLen, _nIns) = parseVarInt(_vin);

        // Not valid if it says there are too many or no inputs
        if (_nIns == 0 || _varIntDataLen == ERR_BAD_ARG) {
            return false;
        }

        uint256 _offset = 1 + _varIntDataLen;

        for (uint256 i = 0; i < _nIns; i++) {
            // If we're at the end, but still expect more
            if (_offset >= _vin.length) {
                return false;
            }

            // Grab the next input and determine its length.
            uint256 _nextLen = determineInputLengthAt(_vin, _offset);
            if (_nextLen == ERR_BAD_ARG) {
                return false;
            }

            // Increase the offset by that much
            _offset += _nextLen;
        }

        // Returns false if we're not exactly at the end
        return _offset == _vin.length;
    }

    /// @notice      Checks that the vout passed up is properly formatted
    /// @dev         Consider a vout with a valid scriptpubkey
    /// @param _vout Raw bytes length-prefixed output vector
    /// @return      True if it represents a validly formatted vout
    function validateVout(bytes memory _vout) internal pure returns (bool) {
        uint256 _varIntDataLen;
        uint256 _nOuts;

        (_varIntDataLen, _nOuts) = parseVarInt(_vout);

        // Not valid if it says there are too many or no outputs
        if (_nOuts == 0 || _varIntDataLen == ERR_BAD_ARG) {
            return false;
        }

        uint256 _offset = 1 + _varIntDataLen;

        for (uint256 i = 0; i < _nOuts; i++) {
            // If we're at the end, but still expect more
            if (_offset >= _vout.length) {
                return false;
            }

            // Grab the next output and determine its length.
            // Increase the offset by that much
            uint256 _nextLen = determineOutputLengthAt(_vout, _offset);
            if (_nextLen == ERR_BAD_ARG) {
                return false;
            }

            _offset += _nextLen;
        }

        // Returns false if we're not exactly at the end
        return _offset == _vout.length;
    }



    /* ************ */
    /* Block Header */
    /* ************ */

    /// @notice          Extracts the transaction merkle root from a block header
    /// @dev             Use verifyHash256Merkle to verify proofs with this root
    /// @param _header   The header
    /// @return          The merkle root (little-endian)
    function extractMerkleRootLE(bytes memory _header) internal pure returns (bytes32) {
        return _header.slice32(36);
    }

    /// @notice          Extracts the target from a block header
    /// @dev             Target is a 256-bit number encoded as a 3-byte mantissa and 1-byte exponent
    /// @param _header   The header
    /// @return          The target threshold
    function extractTarget(bytes memory _header) internal pure returns (uint256) {
        return extractTargetAt(_header, 0);
    }

    /// @notice          Extracts the target from a block header
    /// @dev             Target is a 256-bit number encoded as a 3-byte mantissa and 1-byte exponent
    /// @param _header   The array containing the header
    /// @param at        The start of the header
    /// @return          The target threshold
    function extractTargetAt(bytes memory _header, uint256 at) internal pure returns (uint256) {
        uint24 _m = uint24(_header.slice3(72 + at));
        uint8 _e = uint8(_header[75 + at]);
        uint256 _mantissa = uint256(reverseUint24(_m));
        uint _exponent = _e - 3;

        return _mantissa * (256 ** _exponent);
    }

    /// @notice          Calculate difficulty from the difficulty 1 target and current target
    /// @dev             Difficulty 1 is 0x1d00ffff on mainnet and testnet
    /// @dev             Difficulty 1 is a 256-bit number encoded as a 3-byte mantissa and 1-byte exponent
    /// @param _target   The current target
    /// @return          The block difficulty (bdiff)
    function calculateDifficulty(uint256 _target) internal pure returns (uint256) {
        // Difficulty 1 calculated from 0x1d00ffff
        return DIFF1_TARGET.div(_target);
    }

    /// @notice          Extracts the previous block's hash from a block header
    /// @dev             Block headers do NOT include block number :(
    /// @param _header   The header
    /// @return          The previous block's hash (little-endian)
    function extractPrevBlockLE(bytes memory _header) internal pure returns (bytes32) {
        return _header.slice32(4);
    }

    /// @notice          Extracts the previous block's hash from a block header
    /// @dev             Block headers do NOT include block number :(
    /// @param _header   The array containing the header
    /// @param at        The start of the header
    /// @return          The previous block's hash (little-endian)
    function extractPrevBlockLEAt(
        bytes memory _header,
        uint256 at
    ) internal pure returns (bytes32) {
        return _header.slice32(4 + at);
    }

    /// @notice          Extracts the timestamp from a block header
    /// @dev             Time is not 100% reliable
    /// @param _header   The header
    /// @return          The timestamp (little-endian bytes)
    function extractTimestampLE(bytes memory _header) internal pure returns (bytes4) {
        return _header.slice4(68);
    }

    /// @notice          Extracts the timestamp from a block header
    /// @dev             Time is not 100% reliable
    /// @param _header   The header
    /// @return          The timestamp (uint)
    function extractTimestamp(bytes memory _header) internal pure returns (uint32) {
        return reverseUint32(uint32(extractTimestampLE(_header)));
    }

    /// @notice          Extracts the expected difficulty from a block header
    /// @dev             Does NOT verify the work
    /// @param _header   The header
    /// @return          The difficulty as an integer
    function extractDifficulty(bytes memory _header) internal pure returns (uint256) {
        return calculateDifficulty(extractTarget(_header));
    }

    /// @notice          Concatenates and hashes two inputs for merkle proving
    /// @param _a        The first hash
    /// @param _b        The second hash
    /// @return          The double-sha256 of the concatenated hashes
    function _hash256MerkleStep(bytes memory _a, bytes memory _b) internal view returns (bytes32) {
        return hash256View(abi.encodePacked(_a, _b));
    }

    /// @notice          Concatenates and hashes two inputs for merkle proving
    /// @param _a        The first hash
    /// @param _b        The second hash
    /// @return          The double-sha256 of the concatenated hashes
    function _hash256MerkleStep(bytes32 _a, bytes32 _b) internal view returns (bytes32) {
        return hash256Pair(_a, _b);
    }


    /// @notice          Verifies a Bitcoin-style merkle tree
    /// @dev             Leaves are 0-indexed. Inefficient version.
    /// @param _proof    The proof. Tightly packed LE sha256 hashes. The last hash is the root
    /// @param _index    The index of the leaf
    /// @return          true if the proof is valid, else false
    function verifyHash256Merkle(bytes memory _proof, uint _index) internal view returns (bool) {
        // Not an even number of hashes
        if (_proof.length % 32 != 0) {
            return false;
        }

        // Special case for coinbase-only blocks
        if (_proof.length == 32) {
            return true;
        }

        // Should never occur
        if (_proof.length == 64) {
            return false;
        }

        bytes32 _root = _proof.slice32(_proof.length - 32);
        bytes32 _current = _proof.slice32(0);
        bytes memory _tree = _proof.slice(32, _proof.length - 64);

        return verifyHash256Merkle(_current, _tree, _root, _index);
    }

    /// @notice          Verifies a Bitcoin-style merkle tree
    /// @dev             Leaves are 0-indexed. Efficient version.
    /// @param _leaf     The leaf of the proof. LE sha256 hash.
    /// @param _tree     The intermediate nodes in the proof.
    ///                  Tightly packed LE sha256 hashes.
    /// @param _root     The root of the proof. LE sha256 hash.
    /// @param _index    The index of the leaf
    /// @return          true if the proof is valid, else false
    function verifyHash256Merkle(
        bytes32 _leaf,
        bytes memory _tree,
        bytes32 _root,
        uint _index
    ) internal view returns (bool) {
        // Not an even number of hashes
        if (_tree.length % 32 != 0) {
            return false;
        }

        // Should never occur
        if (_tree.length == 0) {
            return false;
        }

        uint _idx = _index;
        bytes32 _current = _leaf;

        // i moves in increments of 32
        for (uint i = 0; i < _tree.length; i += 32) {
            if (_idx % 2 == 1) {
                _current = _hash256MerkleStep(_tree.slice32(i), _current);
            } else {
                _current = _hash256MerkleStep(_current, _tree.slice32(i));
            }
            _idx = _idx >> 1;
        }
        return _current == _root;
    }

    /*
    NB: https://github.com/bitcoin/bitcoin/blob/78dae8caccd82cfbfd76557f1fb7d7557c7b5edb/src/pow.cpp#L49-L72
    NB: We get a full-bitlength target from this. For comparison with
        header-encoded targets we need to mask it with the header target
        e.g. (full & truncated) == truncated
    */
    /// @notice                 performs the bitcoin difficulty retarget
    /// @dev                    implements the Bitcoin algorithm precisely
    /// @param _previousTarget  the target of the previous period
    /// @param _firstTimestamp  the timestamp of the first block in the difficulty period
    /// @param _secondTimestamp the timestamp of the last block in the difficulty period
    /// @return                 the new period's target threshold
    function retargetAlgorithm(
        uint256 _previousTarget,
        uint256 _firstTimestamp,
        uint256 _secondTimestamp
    ) internal pure returns (uint256) {
        uint256 _elapsedTime = _secondTimestamp.sub(_firstTimestamp);

        // Normalize ratio to factor of 4 if very long or very short
        if (_elapsedTime < RETARGET_PERIOD.div(4)) {
            _elapsedTime = RETARGET_PERIOD.div(4);
        }
        if (_elapsedTime > RETARGET_PERIOD.mul(4)) {
            _elapsedTime = RETARGET_PERIOD.mul(4);
        }

        /*
          NB: high targets e.g. ffff0020 can cause overflows here
              so we divide it by 256**2, then multiply by 256**2 later
              we know the target is evenly divisible by 256**2, so this isn't an issue
        */

        uint256 _adjusted = _previousTarget.div(65536).mul(_elapsedTime);
        return _adjusted.div(RETARGET_PERIOD).mul(65536);
    }
}
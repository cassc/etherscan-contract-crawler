// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./WitnetV2.sol";

/// @title A library for decoding Witnet request results
/// @notice The library exposes functions to check the Witnet request success.
/// and retrieve Witnet results from CBOR values into solidity types.
/// @author The Witnet Foundation.
library WitnetLib {

    using WitnetBuffer for WitnetBuffer.Buffer;
    using WitnetCBOR for WitnetCBOR.CBOR;
    using WitnetCBOR for WitnetCBOR.CBOR[];
    using WitnetLib for bytes;

    
    /// ===============================================================================================================
    /// --- WitnetLib internal methods --------------------------------------------------------------------------------

    /// @notice Decode raw CBOR bytes into a Witnet.Result instance.
    /// @param bytecode Raw bytes representing a CBOR-encoded value.
    /// @return A `Witnet.Result` instance.
    function resultFromCborBytes(bytes memory bytecode)
        internal pure
        returns (Witnet.Result memory)
    {
        WitnetCBOR.CBOR memory cborValue = WitnetCBOR.fromBytes(bytecode);
        return _resultFromCborValue(cborValue);
    }

    function toAddress(bytes memory _value) internal pure returns (address) {
        return address(toBytes20(_value));
    }

    function toBytes4(bytes memory _value) internal pure returns (bytes4) {
        return bytes4(toFixedBytes(_value, 4));
    }
    
    function toBytes20(bytes memory _value) internal pure returns (bytes20) {
        return bytes20(toFixedBytes(_value, 20));
    }
    
    function toBytes32(bytes memory _value) internal pure returns (bytes32) {
        return toFixedBytes(_value, 32);
    }

    function toFixedBytes(bytes memory _value, uint8 _numBytes)
        internal pure
        returns (bytes32 _bytes32)
    {
        assert(_numBytes <= 32);
        unchecked {
            uint _len = _value.length > _numBytes ? _numBytes : _value.length;
            for (uint _i = 0; _i < _len; _i ++) {
                _bytes32 |= bytes32(_value[_i] & 0xff) >> (_i * 8);
            }
        }
    }

    function toLowerCase(string memory str)
        internal pure
        returns (string memory)
    {
        bytes memory lowered = new bytes(bytes(str).length);
        unchecked {
            for (uint i = 0; i < lowered.length; i ++) {
                uint8 char = uint8(bytes(str)[i]);
                if (char >= 65 && char <= 90) {
                    lowered[i] = bytes1(char + 32);
                } else {
                    lowered[i] = bytes1(char);
                }
            }
        }
        return string(lowered);
    }

    /// @notice Convert a `uint64` into a 2 characters long `string` representing its two less significant hexadecimal values.
    /// @param _u A `uint64` value.
    /// @return The `string` representing its hexadecimal value.
    function toHexString(uint8 _u)
        internal pure
        returns (string memory)
    {
        bytes memory b2 = new bytes(2);
        uint8 d0 = uint8(_u / 16) + 48;
        uint8 d1 = uint8(_u % 16) + 48;
        if (d0 > 57)
            d0 += 7;
        if (d1 > 57)
            d1 += 7;
        b2[0] = bytes1(d0);
        b2[1] = bytes1(d1);
        return string(b2);
    }

    /// @notice Convert a `uint64` into a 1, 2 or 3 characters long `string` representing its.
    /// three less significant decimal values.
    /// @param _u A `uint64` value.
    /// @return The `string` representing its decimal value.
    function toString(uint8 _u)
        internal pure
        returns (string memory)
    {
        if (_u < 10) {
            bytes memory b1 = new bytes(1);
            b1[0] = bytes1(uint8(_u) + 48);
            return string(b1);
        } else if (_u < 100) {
            bytes memory b2 = new bytes(2);
            b2[0] = bytes1(uint8(_u / 10) + 48);
            b2[1] = bytes1(uint8(_u % 10) + 48);
            return string(b2);
        } else {
            bytes memory b3 = new bytes(3);
            b3[0] = bytes1(uint8(_u / 100) + 48);
            b3[1] = bytes1(uint8(_u % 100 / 10) + 48);
            b3[2] = bytes1(uint8(_u % 10) + 48);
            return string(b3);
        }
    }

    function tryUint(string memory str)
        internal pure
        returns (uint res, bool)
    {
        unchecked {
            for (uint256 i = 0; i < bytes(str).length; i++) {
                if (
                    (uint8(bytes(str)[i]) - 48) < 0
                        || (uint8(bytes(str)[i]) - 48) > 9
                ) {
                    return (0, false);
                }
                res += (uint8(bytes(str)[i]) - 48) * 10 ** (bytes(str).length - i - 1);
            }
            return (res, true);
        }   
    }

    /// @notice Returns true if Witnet.Result contains an error.
    /// @param result An instance of Witnet.Result.
    /// @return `true` if errored, `false` if successful.
    function failed(Witnet.Result memory result)
      internal pure
      returns (bool)
    {
        return !result.success;
    }

    /// @notice Returns true if Witnet.Result contains valid result.
    /// @param result An instance of Witnet.Result.
    /// @return `true` if errored, `false` if successful.
    function succeeded(Witnet.Result memory result)
      internal pure
      returns (bool)
    {
        return result.success;
    }

    /// ===============================================================================================================
    /// --- WitnetLib private methods ---------------------------------------------------------------------------------

    /// @notice Decode an errored `Witnet.Result` as a `uint[]`.
    /// @param result An instance of `Witnet.Result`.
    /// @return The `uint[]` error parameters as decoded from the `Witnet.Result`.
    function _errorsFromResult(Witnet.Result memory result)
        private pure
        returns(uint[] memory)
    {
        require(
            failed(result),
            "WitnetLib: no actual error"
        );
        return result.value.readUintArray();
    }

    /// @notice Decode a CBOR value into a Witnet.Result instance.
    /// @param cbor An instance of `Witnet.Value`.
    /// @return A `Witnet.Result` instance.
    function _resultFromCborValue(WitnetCBOR.CBOR memory cbor)
        private pure
        returns (Witnet.Result memory)    
    {
        // Witnet uses CBOR tag 39 to represent RADON error code identifiers.
        // [CBOR tag 39] Identifiers for CBOR: https://github.com/lucas-clemente/cbor-specs/blob/master/id.md
        bool success = cbor.tag != 39;
        return Witnet.Result(success, cbor);
    }

    /// @notice Convert a stage index number into the name of the matching Witnet request stage.
    /// @param stageIndex A `uint64` identifying the index of one of the Witnet request stages.
    /// @return The name of the matching stage.
    function _stageName(uint64 stageIndex)
        private pure
        returns (string memory)
    {
        if (stageIndex == 0) {
            return "retrieval";
        } else if (stageIndex == 1) {
            return "aggregation";
        } else if (stageIndex == 2) {
            return "tally";
        } else {
            return "unknown";
        }
    }


    /// ===============================================================================================================
    /// --- WitnetLib public methods (if used library will have to linked to calling contracts) -----------------------

    function asAddress(Witnet.Result memory result)
        public pure
        returns (address)
    {
        require(
            result.success,
            "WitnetLib: tried to read `address` from errored result."
        );
        if (result.value.majorType == uint8(WitnetCBOR.MAJOR_TYPE_BYTES)) {
            return result.value.readBytes().toAddress();
        } else {
            revert("WitnetLib: reading address from string not yet supported.");
        }
    }

    /// @notice Decode a boolean value from a Witnet.Result as an `bool` value.
    /// @param result An instance of Witnet.Result.
    /// @return The `bool` decoded from the Witnet.Result.
    function asBool(Witnet.Result memory result)
        public pure
        returns (bool)
    {
        require(
            result.success,
            "WitnetLib: tried to read `bool` value from errored result."
        );
        return result.value.readBool();
    }

    /// @notice Decode a bytes value from a Witnet.Result as a `bytes` value.
    /// @param result An instance of Witnet.Result.
    /// @return The `bytes` decoded from the Witnet.Result.
    function asBytes(Witnet.Result memory result)
        public pure
        returns(bytes memory)
    {
        require(
            result.success,
            "WitnetLib: Tried to read bytes value from errored Witnet.Result"
        );
        return result.value.readBytes();
    }

    function asBytes4(Witnet.Result memory result)
        public pure
        returns (bytes4)
    {
        return asBytes(result).toBytes4();
    }

    /// @notice Decode a bytes value from a Witnet.Result as a `bytes32` value.
    /// @param result An instance of Witnet.Result.
    /// @return The `bytes32` decoded from the Witnet.Result.
    function asBytes32(Witnet.Result memory result)
        public pure
        returns (bytes32)
    {
        return asBytes(result).toBytes32();
    }

    /// @notice Decode an error code from a Witnet.Result as a member of `Witnet.ErrorCodes`.
    /// @param result An instance of `Witnet.Result`.
    function asErrorCode(Witnet.Result memory result)
        public pure
        returns (Witnet.ErrorCodes)
    {
        uint[] memory errors = _errorsFromResult(result);
        if (errors.length == 0) {
            return Witnet.ErrorCodes.Unknown;
        } else {
            return Witnet.ErrorCodes(errors[0]);
        }
    }

    /// @notice Generate a suitable error message for a member of `Witnet.ErrorCodes` and its corresponding arguments.
    /// @dev WARN: Note that client contracts should wrap this function into a try-catch foreseing potential errors generated in this function
    /// @param result An instance of `Witnet.Result`.
    /// @return errorCode Decoded error code.
    /// @return errorString Decoded error message.
    function asErrorMessage(Witnet.Result memory result)
        public pure
        returns (
            Witnet.ErrorCodes errorCode,
            string memory errorString
        )
    {
        uint[] memory errors = _errorsFromResult(result);
        if (errors.length == 0) {
            return (
                Witnet.ErrorCodes.Unknown,
                "Unknown error: no error code."
            );
        }
        else {
            errorCode = Witnet.ErrorCodes(errors[0]);
        }
        if (
            errorCode == Witnet.ErrorCodes.SourceScriptNotCBOR
                && errors.length >= 2
        ) {
            errorString = string(abi.encodePacked(
                "Source script #",
                toString(uint8(errors[1])),
                " was not a valid CBOR value"
            ));
        } else if (
            errorCode == Witnet.ErrorCodes.SourceScriptNotArray
                && errors.length >= 2
        ) {
            errorString = string(abi.encodePacked(
                "The CBOR value in script #",
                toString(uint8(errors[1])),
                " was not an Array of calls"
            ));
        } else if (
            errorCode == Witnet.ErrorCodes.SourceScriptNotRADON
                && errors.length >= 2
        ) {
            errorString = string(abi.encodePacked(
                "The CBOR value in script #",
                toString(uint8(errors[1])),
                " was not a valid Data Request"
            ));
        } else if (
            errorCode == Witnet.ErrorCodes.RequestTooManySources
                && errors.length >= 2
        ) {
            errorString = string(abi.encodePacked(
                "The request contained too many sources (", 
                toString(uint8(errors[1])), 
                ")"
            ));
        } else if (
            errorCode == Witnet.ErrorCodes.ScriptTooManyCalls
                && errors.length >= 4
        ) {
            errorString = string(abi.encodePacked(
                "Script #",
                toString(uint8(errors[2])),
                " from the ",
                _stageName(uint8(errors[1])),
                " stage contained too many calls (",
                toString(uint8(errors[3])),
                ")"
            ));
        } else if (
            errorCode == Witnet.ErrorCodes.UnsupportedOperator
                && errors.length >= 5
        ) {
            errorString = string(abi.encodePacked(
                "Operator code 0x",
                toHexString(uint8(errors[4])),
                " found at call #",
                toString(uint8(errors[3])),
                " in script #",
                toString(uint8(errors[2])),
                " from ",
                _stageName(uint8(errors[1])),
                " stage is not supported"
            ));
        } else if (
            errorCode == Witnet.ErrorCodes.HTTP
                && errors.length >= 3
        ) {
            errorString = string(abi.encodePacked(
                "Source #",
                toString(uint8(errors[1])),
                " could not be retrieved. Failed with HTTP error code: ",
                toString(uint8(errors[2] / 100)),
                toString(uint8(errors[2] % 100 / 10)),
                toString(uint8(errors[2] % 10))
            ));
        } else if (
            errorCode == Witnet.ErrorCodes.RetrievalTimeout
                && errors.length >= 2
        ) {
            errorString = string(abi.encodePacked(
                "Source #",
                toString(uint8(errors[1])),
                " could not be retrieved because of a timeout"
            ));
        } else if (
            errorCode == Witnet.ErrorCodes.Underflow
                && errors.length >= 5
        ) {
            errorString = string(abi.encodePacked(
                "Underflow at operator code 0x",
                toHexString(uint8(errors[4])),
                " found at call #",
                toString(uint8(errors[3])),
                " in script #",
                toString(uint8(errors[2])),
                " from ",
                _stageName(uint8(errors[1])),
                " stage"
            ));
        } else if (
            errorCode == Witnet.ErrorCodes.Overflow
                && errors.length >= 5
        ) {
            errorString = string(abi.encodePacked(
                "Overflow at operator code 0x",
                toHexString(uint8(errors[4])),
                " found at call #",
                toString(uint8(errors[3])),
                " in script #",
                toString(uint8(errors[2])),
                " from ",
                _stageName(uint8(errors[1])),
                " stage"
            ));
        } else if (
            errorCode == Witnet.ErrorCodes.DivisionByZero
                && errors.length >= 5
        ) {
            errorString = string(abi.encodePacked(
                "Division by zero at operator code 0x",
                toHexString(uint8(errors[4])),
                " found at call #",
                toString(uint8(errors[3])),
                " in script #",
                toString(uint8(errors[2])),
                " from ",
                _stageName(uint8(errors[1])),
                " stage"
            ));
        } else if (
            errorCode == Witnet.ErrorCodes.BridgeMalformedRequest
        ) {
            errorString = "The structure of the request is invalid and it cannot be parsed";
        } else if (
            errorCode == Witnet.ErrorCodes.BridgePoorIncentives
        ) {
            errorString = "The request has been rejected by the bridge node due to poor incentives";
        } else if (
            errorCode == Witnet.ErrorCodes.BridgeOversizedResult
        ) {
            errorString = "The request result length exceeds a bridge contract defined limit";
        } else {
            errorString = string(abi.encodePacked(
                "Unknown error (0x",
                toHexString(uint8(errors[0])),
                ")"
            ));
        }
        return (
            errorCode,
            errorString
        );
    }

    /// @notice Decode a fixed16 (half-precision) numeric value from a Witnet.Result as an `int32` value.
    /// @dev Due to the lack of support for floating or fixed point arithmetic in the EVM, this method offsets all values.
    /// by 5 decimal orders so as to get a fixed precision of 5 decimal positions, which should be OK for most `fixed16`.
    /// use cases. In other words, the output of this method is 10,000 times the actual value, encoded into an `int32`.
    /// @param result An instance of Witnet.Result.
    /// @return The `int128` decoded from the Witnet.Result.
    function asFixed16(Witnet.Result memory result)
        public pure
        returns (int32)
    {
        require(
            result.success,
            "WitnetLib: tried to read `fixed16` value from errored result."
        );
        return result.value.readFloat16();
    }

    /// @notice Decode an array of fixed16 values from a Witnet.Result as an `int32[]` array.
    /// @param result An instance of Witnet.Result.
    /// @return The `int128[]` decoded from the Witnet.Result.
    function asFixed16Array(Witnet.Result memory result)
        public pure
        returns (int32[] memory)
    {
        require(
            result.success,
            "WitnetLib: tried to read `fixed16[]` value from errored result."
        );
        return result.value.readFloat16Array();
    }

    /// @notice Decode a integer numeric value from a Witnet.Result as an `int128` value.
    /// @param result An instance of Witnet.Result.
    /// @return The `int` decoded from the Witnet.Result.
    function asInt(Witnet.Result memory result)
      public pure
      returns (int)
    {
        require(
            result.success,
            "WitnetLib: tried to read `int` value from errored result."
        );
        return result.value.readInt();
    }

    /// @notice Decode an array of integer numeric values from a Witnet.Result as an `int[]` array.
    /// @param result An instance of Witnet.Result.
    /// @return The `int[]` decoded from the Witnet.Result.
    function asIntArray(Witnet.Result memory result)
        public pure
        returns (int[] memory)
    {
        require(
            result.success,
            "WitnetLib: tried to read `int[]` value from errored result."
        );
        return result.value.readIntArray();
    }

    /// @notice Decode a string value from a Witnet.Result as a `string` value.
    /// @param result An instance of Witnet.Result.
    /// @return The `string` decoded from the Witnet.Result.
    function asString(Witnet.Result memory result)
        public pure
        returns(string memory)
    {
        require(
            result.success,
            "WitnetLib: tried to read `string` value from errored result."
        );
        return result.value.readString();
    }

    /// @notice Decode an array of string values from a Witnet.Result as a `string[]` value.
    /// @param result An instance of Witnet.Result.
    /// @return The `string[]` decoded from the Witnet.Result.
    function asStringArray(Witnet.Result memory result)
        public pure
        returns (string[] memory)
    {
        require(
            result.success,
            "WitnetLib: tried to read `string[]` value from errored result.");
        return result.value.readStringArray();
    }

    /// @notice Decode a natural numeric value from a Witnet.Result as a `uint` value.
    /// @param result An instance of Witnet.Result.
    /// @return The `uint` decoded from the Witnet.Result.
    function asUint(Witnet.Result memory result)
        public pure
        returns(uint)
    {
        require(
            result.success,
            "WitnetLib: tried to read `uint64` value from errored result"
        );
        return result.value.readUint();
    }

    /// @notice Decode an array of natural numeric values from a Witnet.Result as a `uint[]` value.
    /// @param result An instance of Witnet.Result.
    /// @return The `uint[]` decoded from the Witnet.Result.
    function asUintArray(Witnet.Result memory result)
        public pure
        returns (uint[] memory)
    {
        require(
            result.success,
            "WitnetLib: tried to read `uint[]` value from errored result."
        );
        return result.value.readUintArray();
    }

}
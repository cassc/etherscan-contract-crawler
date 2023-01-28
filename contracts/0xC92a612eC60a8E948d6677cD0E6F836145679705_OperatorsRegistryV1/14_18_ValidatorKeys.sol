//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../../libraries/LibBytes.sol";

/// @title Validator Keys Storage
/// @notice Utility to manage the validator keys in storage
library ValidatorKeys {
    /// @notice Storage slot of the Validator Keys
    bytes32 internal constant VALIDATOR_KEYS_SLOT = bytes32(uint256(keccak256("river.state.validatorKeys")) - 1);

    /// @notice Length in bytes of a BLS Public Key used for validator deposits
    uint256 internal constant PUBLIC_KEY_LENGTH = 48;

    /// @notice Length in bytes of a BLS Signature used for validator deposits
    uint256 internal constant SIGNATURE_LENGTH = 96;

    /// @notice The provided public key is not matching the expected length
    error InvalidPublicKey();

    /// @notice The provided signature is not matching the expected length
    error InvalidSignature();

    /// @notice Structure of the Validator Keys in storage
    struct Slot {
        /// @custom:attribute The mapping from operator index to key index to key value
        mapping(uint256 => mapping(uint256 => bytes)) value;
    }

    /// @notice Retrieve the Validator Key of an operator at a specific index
    /// @param _operatorIndex The operator index
    /// @param _idx the Validator Key index
    /// @return publicKey The Validator Key public key
    /// @return signature The Validator Key signature
    function get(uint256 _operatorIndex, uint256 _idx)
        internal
        view
        returns (bytes memory publicKey, bytes memory signature)
    {
        bytes32 slot = VALIDATOR_KEYS_SLOT;

        Slot storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        bytes storage entry = r.value[_operatorIndex][_idx];

        publicKey = LibBytes.slice(entry, 0, PUBLIC_KEY_LENGTH);
        signature = LibBytes.slice(entry, PUBLIC_KEY_LENGTH, SIGNATURE_LENGTH);
    }

    /// @notice Retrieve the raw concatenated Validator Keys
    /// @param _operatorIndex The operator index
    /// @param _idx The Validator Key index
    /// @return The concatenated public key and signature
    function getRaw(uint256 _operatorIndex, uint256 _idx) internal view returns (bytes memory) {
        bytes32 slot = VALIDATOR_KEYS_SLOT;

        Slot storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        return r.value[_operatorIndex][_idx];
    }

    /// @notice Retrieve multiple keys of an operator starting at an index
    /// @param _operatorIndex The operator index
    /// @param _startIdx The starting index to retrieve the keys from
    /// @param _amount The amount of keys to retrieve
    /// @return publicKeys The public keys retrieved
    /// @return signatures The signatures associated with the public keys
    function getKeys(uint256 _operatorIndex, uint256 _startIdx, uint256 _amount)
        internal
        view
        returns (bytes[] memory publicKeys, bytes[] memory signatures)
    {
        publicKeys = new bytes[](_amount);
        signatures = new bytes[](_amount);

        bytes32 slot = VALIDATOR_KEYS_SLOT;

        Slot storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }
        uint256 idx;
        for (; idx < _amount;) {
            bytes memory rawCredentials = r.value[_operatorIndex][idx + _startIdx];
            publicKeys[idx] = LibBytes.slice(rawCredentials, 0, PUBLIC_KEY_LENGTH);
            signatures[idx] = LibBytes.slice(rawCredentials, PUBLIC_KEY_LENGTH, SIGNATURE_LENGTH);
            unchecked {
                ++idx;
            }
        }
    }

    /// @notice Set the concatenated Validator Keys at an index for an operator
    /// @param _operatorIndex The operator index
    /// @param _idx The key index to write on
    /// @param _publicKeyAndSignature The concatenated Validator Keys
    function set(uint256 _operatorIndex, uint256 _idx, bytes memory _publicKeyAndSignature) internal {
        bytes32 slot = VALIDATOR_KEYS_SLOT;

        Slot storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        r.value[_operatorIndex][_idx] = _publicKeyAndSignature;
    }
}
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "../../utils/DataTypes.sol";
import "../../utils/LoanDataTypes.sol";

/// @title NF3 Validation Utils
/// @author NF3 Exchange
/// @dev  Helper library for Protocol. This contract manages validation checks
///       commonly required throughout the protocol

library ValidationUtils {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    enum ValidationUtilsErrorCodes {
        INVALID_ITEMS,
        ONLY_OWNER,
        OWNER_NOT_ALLOWED
    }

    error ValidationUtilsError(ValidationUtilsErrorCodes code);

    /// -----------------------------------------------------------------------
    /// Asset Validation Actions
    /// -----------------------------------------------------------------------

    /// @dev Verify assets1 and assets2 if they are the same.
    /// @param _assets1 First assets
    /// @param _assets2 Second assets
    function verifyAssets(Assets calldata _assets1, Assets calldata _assets2)
        internal
        pure
    {
        if (
            _assets1.paymentTokens.length != _assets2.paymentTokens.length ||
            _assets1.tokens.length != _assets2.tokens.length
        ) revert ValidationUtilsError(ValidationUtilsErrorCodes.INVALID_ITEMS);

        unchecked {
            uint256 i;
            for (i = 0; i < _assets1.paymentTokens.length; i++) {
                if (
                    _assets1.paymentTokens[i] != _assets2.paymentTokens[i] ||
                    _assets1.amounts[i] != _assets2.amounts[i]
                )
                    revert ValidationUtilsError(
                        ValidationUtilsErrorCodes.INVALID_ITEMS
                    );
            }

            for (i = 0; i < _assets1.tokens.length; i++) {
                if (
                    _assets1.tokens[i] != _assets2.tokens[i] ||
                    _assets1.tokenIds[i] != _assets2.tokenIds[i]
                )
                    revert ValidationUtilsError(
                        ValidationUtilsErrorCodes.INVALID_ITEMS
                    );
            }
        }
    }

    /// @dev Verify swap assets to be satisfied as the consideration items by the seller.
    /// @param _swapAssets Swap assets
    /// @param _tokens NFT addresses
    /// @param _tokenIds NFT token ids
    /// @param _value Eth value
    /// @return assets Verified swap assets
    function verifySwapAssets(
        SwapAssets memory _swapAssets,
        address[] memory _tokens,
        uint256[] memory _tokenIds,
        bytes32[][] memory _proofs,
        uint256 _value
    ) internal pure returns (Assets memory) {
        // check Eth amounts
        checkEthAmount(
            Assets({
                tokens: new address[](0),
                tokenIds: new uint256[](0),
                paymentTokens: _swapAssets.paymentTokens,
                amounts: _swapAssets.amounts
            }),
            _value
        );

        uint256 i;
        unchecked {
            // check compatible NFTs
            for (i = 0; i < _swapAssets.tokens.length; i++) {
                if (
                    _swapAssets.tokens[i] != _tokens[i] ||
                    (!verifyMerkleProof(
                        _swapAssets.roots[i],
                        _proofs[i],
                        keccak256(abi.encodePacked(_tokenIds[i]))
                    ) && _swapAssets.roots[i] != bytes32(0))
                ) {
                    revert ValidationUtilsError(
                        ValidationUtilsErrorCodes.INVALID_ITEMS
                    );
                }
            }
        }

        return
            Assets(
                _tokens,
                _tokenIds,
                _swapAssets.paymentTokens,
                _swapAssets.amounts
            );
    }

    /// @dev Verify if the passed asset is present in the merkle root passed.
    /// @param _root Merkle root to check in
    /// @param _consideration Consideration assets
    /// @param _proof Merkle proof
    function verifyAssetProof(
        bytes32 _root,
        Assets calldata _consideration,
        bytes32[] calldata _proof
    ) internal pure {
        bytes32 _leaf = hashAssets(_consideration, bytes32(0));

        if (!verifyMerkleProof(_root, _proof, _leaf)) {
            revert ValidationUtilsError(
                ValidationUtilsErrorCodes.INVALID_ITEMS
            );
        }
    }

    /// @dev Check if the ETH amount is valid.
    /// @param _assets Assets
    /// @param _value ETH amount
    function checkEthAmount(Assets memory _assets, uint256 _value)
        internal
        pure
    {
        uint256 ethAmount;

        for (uint256 i = 0; i < _assets.paymentTokens.length; ) {
            if (_assets.paymentTokens[i] == address(0))
                ethAmount += _assets.amounts[i];
            unchecked {
                ++i;
            }
        }
        if (ethAmount > _value) {
            revert ValidationUtilsError(
                ValidationUtilsErrorCodes.INVALID_ITEMS
            );
        }
    }

    /// @dev Verify that the given leaf exist in the passed root and has the correct proof.
    /// @param _root Merkle root of the given criterial
    /// @param _proof Merkle proof of the given leaf and root
    /// @param _leaf Hash of the token id to be searched in the root
    /// @return bool Validation of the leaf, root and proof
    function verifyMerkleProof(
        bytes32 _root,
        bytes32[] memory _proof,
        bytes32 _leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = _leaf;

        unchecked {
            for (uint256 i = 0; i < _proof.length; i++) {
                computedHash = getHash(computedHash, _proof[i]);
            }
        }

        return computedHash == _root;
    }

    /// -----------------------------------------------------------------------
    /// Owner Validation Actions
    /// -----------------------------------------------------------------------

    /// @dev Check if the function is called by the item owner.
    /// @param _owner Owner address
    /// @param _caller Caller address
    function itemOwnerOnly(address _owner, address _caller) internal pure {
        if (_owner != _caller) {
            revert ValidationUtilsError(ValidationUtilsErrorCodes.ONLY_OWNER);
        }
    }

    /// @dev Check if the function is not called by the item owner.
    /// @param _owner Owner address
    /// @param _caller Caller address
    function notItemOwner(address _owner, address _caller) internal pure {
        if (_owner == _caller) {
            revert ValidationUtilsError(
                ValidationUtilsErrorCodes.OWNER_NOT_ALLOWED
            );
        }
    }

    /// -----------------------------------------------------------------------
    /// Getter Actions
    /// -----------------------------------------------------------------------

    /// @dev Get the hash of data saved in position token.
    /// @param _listingAssets Listing assets
    /// @param _reserveInfo Reserve ino
    /// @param _listingOwner Listing owner
    /// @return hash Hash of the passed data
    function getPositionTokenDataHash(
        Assets calldata _listingAssets,
        ReserveInfo calldata _reserveInfo,
        address _listingOwner
    ) internal pure returns (bytes32 hash) {
        hash = hashAssets(_listingAssets, hash);

        hash = keccak256(
            abi.encodePacked(getReserveHash(_reserveInfo), _listingOwner, hash)
        );
    }

    /// -----------------------------------------------------------------------
    /// Internal functions
    /// -----------------------------------------------------------------------

    /// @dev Get the hash of the given pair of hashes.
    /// @param _a First hash
    /// @param _b Second hash
    function getHash(bytes32 _a, bytes32 _b) internal pure returns (bytes32) {
        return _a < _b ? _hash(_a, _b) : _hash(_b, _a);
    }

    /// @dev Hash two bytes32 variables efficiently using assembly
    /// @param a First bytes variable
    /// @param b Second bytes variable
    function _hash(bytes32 a, bytes32 b) internal pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }

    /// @dev Add the hash of type assets to signature.
    /// @param _assets Assets to be added in hash
    /// @param _sig Hash to which assets need to be added
    /// @return hash Hash result
    function hashAssets(Assets calldata _assets, bytes32 _sig)
        internal
        pure
        returns (bytes32)
    {
        _sig = _addTokensArray(_assets.tokens, _assets.tokenIds, _sig);
        _sig = _addTokensArray(_assets.paymentTokens, _assets.amounts, _sig);

        return _sig;
    }

    /// @dev Add the hash of NFT information to signature.
    /// @param _tokens Array of nft address to be hashed
    /// @param _value Array of NFT tokenIds or amount of FT to be hashed
    /// @param _sig Hash to which assets need to be added
    /// @return hash Hash result
    function _addTokensArray(
        address[] memory _tokens,
        uint256[] memory _value,
        bytes32 _sig
    ) internal pure returns (bytes32) {
        assembly {
            let len := mload(_tokens)
            if eq(eq(len, mload(_value)), 0) {
                revert(0, 0)
            }

            let fmp := mload(0x40)

            let tokenPtr := add(_tokens, 0x20)
            let idPtr := add(_value, 0x20)

            for {
                let tokenIdx := tokenPtr
            } lt(tokenIdx, add(tokenPtr, mul(len, 0x20))) {
                tokenIdx := add(tokenIdx, 0x20)
                idPtr := add(idPtr, 0x20)
            } {
                mstore(fmp, mload(tokenIdx))
                mstore(add(fmp, 0x20), mload(idPtr))
                mstore(add(fmp, 0x40), _sig)

                _sig := keccak256(add(fmp, 0xc), 0x54)
            }
        }
        return _sig;
    }

    /// @dev Get the hash of reserve info.
    /// @param _reserve Reserve info
    /// @return hash Hash of the reserve info
    function getReserveHash(ReserveInfo calldata _reserve)
        internal
        pure
        returns (bytes32)
    {
        bytes32 signature;

        signature = hashAssets(_reserve.deposit, signature);

        signature = hashAssets(_reserve.remaining, signature);

        signature = keccak256(abi.encodePacked(_reserve.duration, signature));

        return signature;
    }
}
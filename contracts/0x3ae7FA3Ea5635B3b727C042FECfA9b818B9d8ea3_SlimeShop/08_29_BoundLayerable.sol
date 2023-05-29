// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {PackedByteUtility} from './lib/PackedByteUtility.sol';
import {BitMapUtility} from './lib/BitMapUtility.sol';
import {ILayerable} from './metadata/ILayerable.sol';
import {RandomTraits} from './traits/RandomTraits.sol';
import {MaxSupply, NotOwner, CannotBindBase, OnlyBase, LayerAlreadyBound, NoActiveLayers} from './interface/Errors.sol';
import {NOT_0TH_BITMASK, DUPLICATE_ACTIVE_LAYERS_SIGNATURE, LAYER_NOT_BOUND_TO_TOKEN_ID_SIGNATURE} from './interface/Constants.sol';
import {BoundLayerableEvents} from './interface/Events.sol';

abstract contract BoundLayerable is RandomTraits, BoundLayerableEvents {
    using BitMapUtility for uint256;

    // mapping from tokenID to a bitmap of bound layers, where each bit is a boolean indicating the layerId at its
    // position has been bound. Layers are bound to bases by burning them with one of the burnAndBind methods.
    // LayerID zero is not valid, but is set at mint to reduce gas cost when binding the first layers, when it is unset
    mapping(uint256 => uint256) internal _tokenIdToBoundLayers;
    // mapping from tokenID to packed array of (nonzero) bytes indicating the ordered layerIds that are active for the token
    // only layerIds bound to the base tokenId can be set as active, and duplicates are not allowed.
    mapping(uint256 => uint256) internal _tokenIdToPackedActiveLayers;

    ILayerable public metadataContract;

    modifier canMint(uint256 numSets) {
        // get number of tokens to be minted, add next token id, compare to max token id (MAX_NUM_SETS * NUM_TOKENS_PER_SET)
        if (
            numSets * uint256(NUM_TOKENS_PER_SET) + _nextTokenId() - 1 >
            MAX_TOKEN_ID
        ) {
            revert MaxSupply();
        }
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        address vrfCoordinatorAddress,
        uint240 maxNumSets,
        uint8 numTokensPerSet,
        uint64 subscriptionId,
        address _metadataContractAddress,
        uint8 numRandomBatches,
        bytes32 keyHash
    )
        RandomTraits(
            name,
            symbol,
            vrfCoordinatorAddress,
            maxNumSets,
            numTokensPerSet,
            subscriptionId,
            numRandomBatches,
            keyHash
        )
    {
        metadataContract = ILayerable(_metadataContractAddress);
    }

    /////////////
    // GETTERS //
    /////////////

    /// @notice get the layerIds currently bound to a tokenId
    function getBoundLayers(uint256 tokenId)
        external
        view
        returns (uint256[] memory)
    {
        return BitMapUtility.unpackBitMap(getBoundLayerBitMap(tokenId));
    }

    /// @notice get the layerIds currently bound to a tokenId as a bit map
    function getBoundLayerBitMap(uint256 tokenId)
        public
        view
        virtual
        returns (uint256)
    {
        return _tokenIdToBoundLayers[tokenId] & NOT_0TH_BITMASK;
    }

    /// @notice get the layerIds currently active on a tokenId
    function getActiveLayers(uint256 tokenId)
        public
        view
        virtual
        returns (uint256[] memory)
    {
        uint256 activePackedLayers = _tokenIdToPackedActiveLayers[tokenId];
        return PackedByteUtility.unpackByteArray(activePackedLayers);
    }

    function _tokenURI(uint256 tokenId) internal view returns (string memory) {
        // get the random seed for the token, which may not be revealed yet
        bytes32 retrievedRandomSeed = getRandomnessForTokenIdFromSeed(
            tokenId,
            packedBatchRandomness
        );
        return
            metadataContract.getTokenURI(
                tokenId,
                // only get layerId if token is revealed
                retrievedRandomSeed == 0x00 ? 0 : getLayerId(tokenId),
                getBoundLayerBitMap(tokenId),
                getActiveLayers(tokenId),
                retrievedRandomSeed
            );
    }

    /////////////
    // SETTERS //
    /////////////

    /// @notice set the address of the metadata contract. OnlyOwner
    /// @param _metadataContract the address of the metadata contract
    function setMetadataContract(ILayerable _metadataContract)
        external
        onlyOwner
    {
        _setMetadataContract(_metadataContract);
    }

    /**
     * @notice Bind a layer token to a base token and burn the layer token. User must own both tokens.
     * @param baseTokenId TokenID of a base token
     * @param layerTokenId TokenID of a layer token
     * @param packedActiveLayerIds Ordered layer IDs packed as bytes into uint256s to set as active on the base token
     * emits LayersBoundToToken
     * emits ActiveLayersChanged
     */
    function burnAndBindSingleAndSetActiveLayers(
        uint256 baseTokenId,
        uint256 layerTokenId,
        uint256 packedActiveLayerIds
    ) public {
        _burnAndBindSingle(baseTokenId, layerTokenId);
        _setActiveLayers(baseTokenId, packedActiveLayerIds);
    }

    /**
     * @notice Bind a layer token to a base token and burn the layer token. User must own both tokens.
     * @param baseTokenId TokenID of a base token
     * @param layerTokenIds TokenIDs of layer tokens
     * @param packedActiveLayerIds Ordered layer IDs packed as bytes into uint256s to set as active on the base token
     * emits LayersBoundToToken
     * emits ActiveLayersChanged
     */
    function burnAndBindMultipleAndSetActiveLayers(
        uint256 baseTokenId,
        uint256[] calldata layerTokenIds,
        uint256 packedActiveLayerIds
    ) public {
        _burnAndBindMultiple(baseTokenId, layerTokenIds);
        _setActiveLayers(baseTokenId, packedActiveLayerIds);
    }

    /**
     * @notice Bind a layer token to a base token and burn the layer token. User must own both tokens.
     * @param baseTokenId TokenID of a base token
     * @param layerTokenId TokenID of a layer token
     * emits LayersBoundToToken
     */
    function burnAndBindSingle(uint256 baseTokenId, uint256 layerTokenId)
        public
        virtual
    {
        _burnAndBindSingle(baseTokenId, layerTokenId);
    }

    /**
     * @notice Bind layer tokens to a base token and burn the layer tokens. User must own all tokens.
     * @param baseTokenId TokenID of a base token
     * @param layerTokenIds TokenIDs of layer tokens
     * emits LayersBoundToToken
     */
    function burnAndBindMultiple(
        uint256 baseTokenId,
        uint256[] calldata layerTokenIds
    ) public virtual {
        _burnAndBindMultiple(baseTokenId, layerTokenIds);
    }

    /**
     * @notice Set the active layer IDs for a base token. Layers must be bound to token
     * @param baseTokenId TokenID of a base token
     * @param packedLayerIds Ordered layer IDs packed as bytes into uint256s to set as active on the base token
     * emits ActiveLayersChanged
     */
    function setActiveLayers(uint256 baseTokenId, uint256 packedLayerIds)
        external
        virtual
    {
        _setActiveLayers(baseTokenId, packedLayerIds);
    }

    function _burnAndBindMultiple(
        uint256 baseTokenId,
        uint256[] calldata layerTokenIds
    ) internal virtual {
        // check owner
        if (ownerOf(baseTokenId) != msg.sender) {
            revert NotOwner();
        }

        // check base
        if (baseTokenId % NUM_TOKENS_PER_SET != 0) {
            revert OnlyBase();
        }
        bytes32 traitSeed = packedBatchRandomness;

        bytes32 baseSeed = getRandomnessForTokenIdFromSeed(
            baseTokenId,
            traitSeed
        );
        uint256 baseLayerId = getLayerId(baseTokenId, baseSeed);

        uint256 bindings = getBoundLayerBitMap(baseTokenId);
        // always bind baseLayer, since it won't be set automatically
        bindings |= baseLayerId.toBitMap();

        // todo: try to batch with arrays by LayerType, fetching distribution for type,
        unchecked {
            // todo: revisit if via_ir = true
            uint256 length = layerTokenIds.length;
            for (uint256 i; i < length; ) {
                uint256 tokenId = layerTokenIds[i];

                // check owner of layer
                if (ownerOf(tokenId) != msg.sender) {
                    revert NotOwner();
                }

                // check layer
                if (tokenId % NUM_TOKENS_PER_SET == 0) {
                    revert CannotBindBase();
                }
                bytes32 layerSeed = getRandomnessForTokenIdFromSeed(
                    tokenId,
                    traitSeed
                );
                uint256 layerId = getLayerId(tokenId, layerSeed);

                // check for duplicates
                uint256 layerIdBitMap = layerId.toBitMap();
                if (bindings & layerIdBitMap > 0) {
                    revert LayerAlreadyBound();
                }

                bindings |= layerIdBitMap;
                _burn(tokenId);
                ++i;
            }
        }
        _setBoundLayersAndEmitEvent(baseTokenId, bindings);
    }

    function _burnAndBindSingle(uint256 baseTokenId, uint256 layerTokenId)
        internal
        virtual
    {
        // check ownership
        if (
            ownerOf(baseTokenId) != msg.sender ||
            ownerOf(layerTokenId) != msg.sender
        ) {
            revert NotOwner();
        }

        // check seed
        bytes32 traitSeed = packedBatchRandomness;
        bytes32 baseSeed = getRandomnessForTokenIdFromSeed(
            baseTokenId,
            traitSeed
        );

        // check base
        if (baseTokenId % NUM_TOKENS_PER_SET != 0) {
            revert OnlyBase();
        }
        uint256 baseLayerId = getLayerId(baseTokenId, baseSeed);

        bytes32 layerSeed = getRandomnessForTokenIdFromSeed(
            layerTokenId,
            traitSeed
        );
        // check layer
        if (layerTokenId % NUM_TOKENS_PER_SET == 0) {
            revert CannotBindBase();
        }
        uint256 layerId = getLayerId(layerTokenId, layerSeed);

        uint256 bindings = getBoundLayerBitMap(baseTokenId);
        // always bind baseLayer, since it won't be set automatically
        bindings |= baseLayerId.toBitMap();
        // TODO: necessary?
        uint256 layerIdBitMap = layerId.toBitMap();
        if (bindings & layerIdBitMap > 0) {
            revert LayerAlreadyBound();
        }

        _burn(layerTokenId);
        _setBoundLayersAndEmitEvent(baseTokenId, bindings | layerIdBitMap);
    }

    function _setActiveLayers(uint256 baseTokenId, uint256 packedLayerIds)
        internal
        virtual
    {
        // TODO: explicitly test this
        if (packedLayerIds == 0) {
            revert NoActiveLayers();
        }
        // check owner
        if (ownerOf(baseTokenId) != msg.sender) {
            revert NotOwner();
        }

        // check base
        if (baseTokenId % NUM_TOKENS_PER_SET != 0) {
            revert OnlyBase();
        }

        // unpack layers into a single bitmap and check there are no duplicates
        (
            uint256 unpackedLayers,
            uint256 numLayers
        ) = _unpackLayersToBitMapAndCheckForDuplicates(packedLayerIds);

        // check new active layers are all bound to baseTokenId
        uint256 boundLayers = getBoundLayerBitMap(baseTokenId);
        _checkUnpackedIsSubsetOfBound(unpackedLayers, boundLayers);

        // clear all bytes after last non-zero bit on packedLayerIds,
        // since unpacking to bitmap short-circuits on first zero byte
        uint256 maskedPackedLayerIds;
        // num layers can never be >32, so 256 - (numLayers * 8) can never negative-oveflow
        unchecked {
            maskedPackedLayerIds =
                packedLayerIds &
                (type(uint256).max << (256 - (numLayers * 8)));
        }

        _tokenIdToPackedActiveLayers[baseTokenId] = maskedPackedLayerIds;
        emit ActiveLayersChanged(msg.sender, baseTokenId, maskedPackedLayerIds);
    }

    function _setBoundLayersAndEmitEvent(uint256 baseTokenId, uint256 bindings)
        internal
        virtual
    {
        // 0 is not a valid layerId, so make sure it is not set on bindings.
        bindings = bindings & NOT_0TH_BITMASK;
        _tokenIdToBoundLayers[baseTokenId] = bindings;
        emit LayersBoundToToken(msg.sender, baseTokenId, bindings);
    }

    /**
     * @notice Unpack bytepacked layerIds and check that there are no duplicates
     * @param bytePackedLayers uint256 of packed layerIds
     * @return bitMap uint256 of unpacked layerIds
     */
    function _unpackLayersToBitMapAndCheckForDuplicates(
        uint256 bytePackedLayers
    ) internal virtual returns (uint256 bitMap, uint256 numLayers) {
        /// @solidity memory-safe-assembly
        assembly {
            for {

            } lt(numLayers, 32) {
                numLayers := add(1, numLayers)
            } {
                let layer := byte(numLayers, bytePackedLayers)
                if iszero(layer) {
                    break
                }
                // put copy of bitmap on stack
                let lastBitMap := bitMap
                // OR layer into bitmap
                bitMap := or(bitMap, shl(layer, 1))
                // check equality - if equal, layer is a duplicate
                if eq(lastBitMap, bitMap) {
                    mstore(
                        0,
                        // revert DuplicateActiveLayers()
                        DUPLICATE_ACTIVE_LAYERS_SIGNATURE
                    )
                    revert(0, 4)
                }
            }
        }
    }

    function _checkUnpackedIsSubsetOfBound(uint256 subset, uint256 superset)
        internal
        pure
        virtual
    {
        // superset should be superset of subset, compare union to superset

        /// @solidity memory-safe-assembly
        assembly {
            if iszero(eq(or(superset, subset), superset)) {
                mstore(
                    0,
                    // revert LayerNotBoundToTokenId()
                    LAYER_NOT_BOUND_TO_TOKEN_ID_SIGNATURE
                )
                let disjoint := xor(superset, subset)
                let notBound := and(disjoint, subset)
                mstore(4, notBound)
                revert(0, 36)
            }
        }
    }

    function _setMetadataContract(ILayerable _metadataContract)
        internal
        virtual
    {
        metadataContract = _metadataContract;
    }

    /////////////
    // HELPERS //
    /////////////

    /// @dev set 0th bit to 1 in order to make first binding cost cheaper for user
    function _setPlaceholderBinding(uint256 tokenId) internal {
        _tokenIdToBoundLayers[tokenId] = 1;
    }

    function _setPlaceholderActiveLayers(uint256 tokenId) internal {
        _tokenIdToPackedActiveLayers[tokenId] = 1;
    }
}
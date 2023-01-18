//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {Base721A, IBase721A, ERC721A, IERC721A} from "../../utils/tokens/ERC721/Base721A.sol";

import {ITPLStatsHolder} from "../TPLStatsHolder/ITPLStatsHolder.sol";
import {ITPLBodyParts} from "../TPLBodyParts/ITPLBodyParts.sol";

import {ITPLRevealedParts} from "./ITPLRevealedParts.sol";

/// @title TPLRevealedParts
/// @author CyberBrokers
/// @author dev by @dievardump
/// @notice registry of all the TPL Revealed Mech Parts
/// @dev Each token referencesits generation id and the original id in the TPL Mech Parts contract
///      New Generation of mech and parts might introduce new body parts, models, styles and stats
///      The current contract is made to accept those new changes through updatable bodyPartsHolder & statsHolder contracts
contract TPLRevealedParts is ITPLRevealedParts, Base721A {
    error MethodDisabled();

    /// @notice the contract that may at some point contain on-chain stats for all the tokens
    address public statsHolder;

    /// @notice the contract that is used to detect the body parts from (generationId, originalId)
    address public bodyPartsHolder;

    /// @dev List of operators allowed to do batch actions (to automatically allow MechCrafting and other actions)
    mapping(address => bool) public batchOperators;

    constructor(ERC721CommonConfig memory config, address newBodyPartsHolder)
        Base721A("TPL Revealed Mech Parts", "TPLRMP", config)
    {
        bodyPartsHolder = newBodyPartsHolder;
    }

    /////////////////////////////////////////////////////////
    // Getters                                             //
    /////////////////////////////////////////////////////////

    /// @notice returns the tokenURI of a tokenId, even if the token has been burned
    /// @param tokenId the token id
    /// @return the token URI
    function ethernalTokenURI(uint256 tokenId) external view returns (string memory) {
        return _tokenURI(tokenId);
    }

    /// @notice returns a token mech part data (generation id, original id, part type, model & stats)
    /// @param tokenId the tokenId to check
    /// @return the token mech part data (generation id, original id, part type, model & stats)
    function partData(uint256 tokenId) public view returns (TokenData memory) {
        (uint256 generationId, uint256 originalId, uint256 partType, uint256 partModel) = getTokenExtra(tokenId);
        return TokenData(generationId, originalId, partType, partModel, getStats(tokenId));
    }

    /// @notice returns a list of token mech part data (generation id, original id, part type, model & stats)
    /// @param tokenIds the tokenIds to know the mech parts type of
    /// @return a list of token mech part data (generation id, original id, part type, model & stats)
    function partDataBatch(uint256[] calldata tokenIds) public view returns (TokenData[] memory) {
        uint256 length = tokenIds.length;
        TokenData[] memory list = new TokenData[](length);
        do {
            unchecked {
                length--;
            }
            list[length] = partData(tokenIds[length]);
        } while (length > 0);

        return list;
    }

    /// @notice gets stats for a token id
    /// @param tokenId the tokenId
    /// @return stats an array containing all stats values for this item
    function getStats(uint256 tokenId) public view returns (uint256[] memory stats) {
        address statsHolder_ = statsHolder;
        if (address(0) != statsHolder_) {
            stats = ITPLStatsHolder(statsHolder_).getRevealedPartStats(tokenId);
        }
    }

    /// @notice gets stats for all tokens in tokenIds
    /// @param tokenIds the token ids
    /// @return stats an array of array containing all stats values for those tokens
    function getStatsBatch(uint256[] calldata tokenIds) public view returns (uint256[][] memory stats) {
        uint256 length = tokenIds.length;
        if (length > 0) {
            address statsHolder_ = statsHolder;
            if (address(0) != statsHolder_) {
                stats = ITPLStatsHolder(statsHolder_).getRevealedPartStatsBatch(tokenIds);
            }
        }

        return stats;
    }

    /// @notice verifies that `account` owns all `tokenIds`
    /// @param account the account
    /// @param tokenIds the token ids to check
    /// @return if account owns all tokens
    function isOwnerOfBatch(address account, uint256[] calldata tokenIds) public view returns (bool) {
        uint256 length = tokenIds.length;
        do {
            unchecked {
                length--;
            }
            if (ownerOf(tokenIds[length]) != account) {
                return false;
            }
        } while (length > 0);

        return true;
    }

    /// @inheritdoc ERC721A
    function isApprovedForAll(address owner_, address operator)
        public
        view
        virtual
        override(ERC721A, IERC721A)
        returns (bool)
    {
        // this allows to automatically approve some contracts like the MechCrafter contract
        // to do batch actions and save the setApprovalForAll transaction
        return batchOperators[msg.sender] || super.isApprovedForAll(owner_, operator);
    }

    /// @notice allows to get token extra data set at creation
    /// @param tokenId the tokenId
    /// @return generationId (Genesis, ...)
    /// @return originalId in the Unrevealed Parts contract
    /// @return partType (Right Arm, Left Arm, Legs, ...)
    function getTokenExtra(uint256 tokenId)
        public
        view
        returns (
            uint256 generationId,
            uint256 originalId,
            uint256 partType,
            uint256 model
        )
    {
        uint24 tokenData = extraData(tokenId);

        generationId = uint256(tokenData & (2**12 - 1));
        originalId = uint256(tokenData >> 12);

        address bodyPartsHolder_ = bodyPartsHolder;
        partType = ITPLBodyParts(bodyPartsHolder_).getBodyPart(generationId, originalId);
        model = ITPLBodyParts(bodyPartsHolder_).getBodyPartModel(generationId, originalId);
    }

    /////////////////////////////////////////////////////////
    // Interactions                                        //
    /////////////////////////////////////////////////////////

    /// @notice Allows to burn tokens in batch
    /// @param tokenIds the tokens to burn
    function burnBatch(uint256[] calldata tokenIds) public {
        uint256 length = tokenIds.length;
        do {
            unchecked {
                length--;
            }
            burn(tokenIds[length]);
        } while (length > 0);
    }

    /// @notice Transfers the ownership of multiple NFTs from one address to another address
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenIds The NFTs to transfer
    function batchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _tokenIds
    ) public {
        uint256 length = _tokenIds.length;
        for (uint256 i; i < length; i++) {
            transferFrom(_from, _to, _tokenIds[i]);
        }
    }

    /////////////////////////////////////////////////////////
    // Gated Owner                                         //
    /////////////////////////////////////////////////////////

    /// @inheritdoc Base721A
    function mintTo(
        address to,
        uint256 amount,
        uint24 extraData_
    ) public override(Base721A, IBase721A) onlyMinter {
        super.mintTo(to, amount, extraData_);
    }

    /////////////////////////////////////////////////////////
    // Gated Owner                                         //
    /////////////////////////////////////////////////////////

    /// @notice Allows owner to add "batchOperators" to the contract
    /// @dev batchOperators are contract that have the right to use batch actions (like transferBatch when Crafting).
    /// @param newBatchOperators the new minters to add
    function addBatchOperators(address[] memory newBatchOperators) external onlyOwner {
        uint256 length = newBatchOperators.length;
        do {
            unchecked {
                length--;
                batchOperators[newBatchOperators[length]] = true;
            }
        } while (length > 0);
    }

    /// @notice Allows owner to remove "batchOperators" from the contract
    /// @dev batchOperators are contract that have the right to use batch actions (like transferBatch when Crafting).
    /// @param oldBatchOperators the old minters to remove
    function removeBatchOperators(address[] memory oldBatchOperators) external onlyOwner {
        uint256 length = oldBatchOperators.length;
        do {
            length--;
            batchOperators[oldBatchOperators[length]] = false;
        } while (length > 0);
    }

    /// @notice Allows owner to set the new statsHolder contract
    /// @param newStatsHolder the new address to call to get stats
    function setStatsHolder(address newStatsHolder) external onlyOwner {
        statsHolder = newStatsHolder;
    }

    /// @notice Allows owner to update the bodyPartsHolder contract
    /// @param newBodyPartsHolder the address of the new bodyPartsHolder contract
    function setBodyPartsHolder(address newBodyPartsHolder) external onlyOwner {
        bodyPartsHolder = newBodyPartsHolder;
    }

    /////////////////////////////////////////////////////////
    // Internals                                           //
    /////////////////////////////////////////////////////////

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}
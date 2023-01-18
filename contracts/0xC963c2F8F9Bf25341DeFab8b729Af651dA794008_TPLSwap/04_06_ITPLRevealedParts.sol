//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {IBase721A} from "../../utils/tokens/ERC721/IBase721A.sol";

/// @title ITPLRevealedParts
/// @author CyberBrokers
/// @author dev by @dievardump
/// @notice Interface for the Revealed Parts contract.
interface ITPLRevealedParts is IBase721A {
    struct TokenData {
        uint256 generation;
        uint256 originalId;
        uint256 bodyPart;
        uint256 model;
        uint256[] stats;
    }

    /// @notice verifies that `account` owns all `tokenIds`
    /// @param account the account
    /// @param tokenIds the token ids to check
    /// @return if account owns all tokens
    function isOwnerOfBatch(address account, uint256[] calldata tokenIds) external view returns (bool);

    /// @notice returns a Mech Part data (body part and original id)
    /// @param tokenId the tokenId to check
    /// @return the Mech Part data (body part and original id)
    function partData(uint256 tokenId) external view returns (TokenData memory);

    /// @notice returns a list of Mech Part data (body part and original id)
    /// @param tokenIds the tokenIds to knoMechParts type of
    /// @return a list of Mech Part data (body part and original id)
    function partDataBatch(uint256[] calldata tokenIds) external view returns (TokenData[] memory);

    /// @notice Allows to burn tokens in batch
    /// @param tokenIds the tokens to burn
    function burnBatch(uint256[] calldata tokenIds) external;
}
// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

interface ICedarUpdateBaseURIV0 {
    /// @dev Emitted when base URI is updated.
    event BaseURIUpdated(uint256 baseURIIndex, string baseURI);

    /**
     *  @notice Lets a minter (account with `MINTER_ROLE`) update base URI
     */
    function updateBaseURI(uint256 baseURIIndex, string calldata _baseURIForTokens) external;

    /**
     *  @dev Gets the base URI indices
     */
    function getBaseURIIndices() external view returns (uint256[] memory);
}

interface IPublicUpdateBaseURIV0 {
    /**
     *  @dev Gets the base URI indices
     */
    function getBaseURIIndices() external view returns (uint256[] memory);
}

interface IDelegatedUpdateBaseURIV0 {
    /**
     *  @dev Gets the base URI indices
     */
    function getBaseURIIndices() external view returns (uint256[] memory);
}

interface IDelegatedUpdateBaseURIV1 is IDelegatedUpdateBaseURIV0 {
    function getBaseURICount() external view returns (uint256);
}

interface IRestrictedUpdateBaseURIV0 {
    /**
     *  @notice Lets a minter (account with `MINTER_ROLE`) update base URI
     */
    function updateBaseURI(uint256 baseURIIndex, string calldata _baseURIForTokens) external;
}

interface IRestrictedUpdateBaseURIV1 is IRestrictedUpdateBaseURIV0 {
    /// @dev Emitted when base URI is updated.
    event BaseURIUpdated(uint256 baseURIIndex, string baseURI);
}
// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

/**
 * @title IAccessNFT
 * @author Souq.Finance
 * @notice Defines the interface of the Access NFT contract
 * @notice License: https://souq-peripheral-v1.s3.amazonaws.com/LICENSE.md
 */
interface IAccessNFT {
    /**
     * @dev Event emitted wjem deadline for the function name and token id combination is set
     * @param functionName The function name in bytes32
     * @param deadline The deadline is seconds
     * @param tokenId The token id
     */
    event DeadlineSet(string functionName, bytes32 functionHash, uint256 deadline, uint256 tokenId);

    /**
     * @dev event emitted when the use of deadlines in the contract is toggled
     * @param deadlinesOn The flag returned (true=turned on)
     */
    event ToggleDeadlines(bool deadlinesOn);

    /**
     * @dev Checks if a user has access to a specific function based on ownership of NFTs. If current time > deadline of the function and token id combination
     * @param user The address of the user
     * @param tokenId The token id
     * @param functionName The function name
     * @return bool The boolean (true = has nft)
     */
    function HasAccessNFT(address user, uint256 tokenId, string calldata functionName) external view returns (bool);
    /**
     * @dev Sets the deadline for a specific function and token id (NFT)
     * @param functionName The function name
     * @param deadline The new deadline
     * @param tokenId The token id
     */
    function setDeadline(string calldata functionName, uint256 deadline, uint256 tokenId) external;
    /**
     * @dev Retrieves the deadline for a specific function and NFT.
     * @param hashedFunctionName The hashed function name
     * @param tokenId The token id
     * @return deadline The deadline
     */
    function getDeadline(bytes32 hashedFunctionName, uint256 tokenId) external view returns (uint256);
    /**
     * @dev Toggles the state of deadlines for function access.
     */
    function toggleDeadlines() external;
    /**
     * @dev Sets the fee discount percentage for a specific NFT
     * @param tokenId The token id
     * @param discount The discount in wei
     */
    function setFeeDiscount(uint256 tokenId, uint256 discount) external;
    /**
     * @dev Sets the URI for the token metadata
     * @param newuri The token id
     */
    function setURI(string memory newuri) external;
    /**
     * @dev Burns a specific amount of tokens owned by an account
     * @param account The account to burn from
     * @param id The token id
     * @param amount The amount to burn
     */
    function adminBurn(address account, uint256 id, uint256 amount) external;
}
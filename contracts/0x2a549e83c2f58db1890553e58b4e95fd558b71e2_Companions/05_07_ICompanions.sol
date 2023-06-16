// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20;

/**
 * @title Companions Interface
 * @dev This interface includes the functions related to the Cornerstone Companions NFTs. It includes functions for
 * minting, setting various parameters, and managing prioritylist, allowlist and public sales.
 * @author Roope R. Pajunen
 */
interface ICompanions {
    /*
     * @notice Merkle root for prioritylist minting.
     * @dev This function returns the current Merkle root used for verifying prioritylist minting.
     * @return The current Merkle root for prioritylist minting.
     */
    function prioritylistMerkleRoot() external returns (bytes32);

    /*
     * @notice Merkle root for allowlist minting.
     * @dev This function returns the current Merkle root used for verifying allowlist minting.
     * @return The current Merkle root for allowlist minting.
     */
    function allowlistMerkleRoot() external returns (bytes32);

    /*
     * @notice Prioritylist sale status.
     * @dev Returns true if prioritylist minting is currently allowed, false otherwise.
     * @return A boolean indicating if prioritylist minting is active.
     */
    function isPrioritylistMintActive() external returns (bool);

    /*
     * @notice Allowlist sale status.
     * @dev Returns true if allowlist minting is currently allowed, false otherwise.
     * @return A boolean indicating if allowlist minting is active.
     */
    function isAllowlistMintActive() external returns (bool);

    /*
     * @notice Public sale status.
     * @dev Returns true if public sale minting is currently allowed, false otherwise.
     * @return A boolean indicating if public sale minting is active.
     */
    function isPublicMintActive() external returns (bool);

    /*
     * @notice Set a new Merkle root for prioritylist minting.
     * @dev This function allows the contract owner to update the Merkle root used for prioritylist minting.
     * @param root The new Merkle root.
     */
    function setPrioritylistMerkleRoot(bytes32 root) external;

    /*
     * @notice Set a new Merkle root for allowlist minting.
     * @dev This function allows the contract owner to update the Merkle root used for allowlist minting.
     * @param root The new Merkle root.
     */
    function setAllowlistMerkleRoot(bytes32 root) external;

    /**
     * @notice Enable or disable prioritylist minting.
     * @dev This function allows the contract owner to control if prioritylist minting is active or not.
     * @param state A boolean indicating the new state of prioritylist minting.
     */
    function setIsPrioritylistMintActive(bool state) external;

    /**
     * @notice Enable or disable allowlist minting.
     * @dev This function allows the contract owner to control if allowlist minting is active or not.
     * @param state A boolean indicating the new state of allowlist minting.
     */
    function setIsAllowlistMintActive(bool state) external;

    /**
     * @notice Enable or disable public sale minting.
     * @dev This function allows the contract owner to control if public sale minting is active or not.
     * @param state A boolean indicating the new state of public sale minting.
     */
    function setIsPublicMintActive(bool state) external;

    /**
     * @notice Set a new base URI.
     * @dev This function allows the contract owner to set a new base URI for the tokens.
     * @param baseURI The new base URI.
     */
    function setBaseURI(string calldata baseURI) external;

    /**
     * @notice Airdrop tokens to a list of recipients.
     * @dev This function allows the contract owner to mint tokens and send them to a list of recipients.
     * @param recipients The addresses that will receive the minted tokens.
     * @param amount The number of tokens each address will receive.
     */
    function airdrop(address[] calldata recipients, uint256 amount) external;

    /**
     * @notice Prioritylist mint.
     * @dev This function allows a user, who is on the prioritylist, to mint tokens during the prioritylist sale.
     *
     * Requirements:
     *
     * - `merkleProof` must be valid.
     * - `quantity` must not exceed the `MAX_SUPPLY`.
     * - `maxMintAmount` must not be exceeded.
     * - prioritylist sale must be active.
     *
     * @param merkleProof The Merkle proof, used to verify the user's presence on the prioritylist.
     * @param quantity The number of tokens the user wishes to mint.
     * @param maxMintAmount The maximum number of tokens the user is allowed to mint.
     */
    function prioritylistMint(bytes32[] calldata merkleProof, uint256 quantity, uint256 maxMintAmount) external;

    /**
     * @notice Allowlist mint.
     * @dev This function allows a user, who is on the allowlist, to mint tokens during the allowlist sale.
     *
     * Requirements:
     *
     * - `merkleProof` must be valid.
     * - `quantity` must not exceed the `MAX_SUPPLY`.
     * - `maxMintAmount` must not be exceeded.
     * - allowlist sale must be active.
     *
     * @param merkleProof The Merkle proof, used to verify the user's presence on the allowlist.
     * @param quantity The number of tokens the user wishes to mint.
     * @param maxMintAmount The maximum number of tokens the user is allowed to mint.
     */
    function allowlistMint(bytes32[] calldata merkleProof, uint256 quantity, uint256 maxMintAmount) external;

    /**
     * @notice Public sale mint.
     * @dev This function allows a user to mint tokens during the public sale.
     *
     * Requirements:
     *
     * - `MAX_SUPPLY` must not be exceeded.
     * - public sale must be active.
     */
    function publicMint() external;
}
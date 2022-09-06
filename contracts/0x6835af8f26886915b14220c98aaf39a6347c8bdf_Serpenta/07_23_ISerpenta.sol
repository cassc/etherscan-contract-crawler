// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IAccessControlEnumerableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/IAccessControlEnumerableUpgradeable.sol";

import { IERC721AUpgradeable } from "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";

import { IERC721ABatchUpgradeable } from "../interfaces/old/IERC721ABatchUpgradeable.sol";

interface ISerpenta is
    IAccessControlEnumerableUpgradeable,
    IERC721AUpgradeable,
    IERC721ABatchUpgradeable
{
    /* ------------------------------------------------------------------------------------------ */
    /*                                           ERRORS                                           */
    /* ------------------------------------------------------------------------------------------ */

    /// @dev Thrown when the sale hasn't been activated yet.
    error NotLive();

    /// @dev Thrown when the collection has sold out ({totalSupply} == {MAX_SUPPLY}).
    error SoldOut();

    /// @dev Thrown when trying to mint an invalid amount of tokens.
    error InvalidMintAmount();

    /// @dev Thrown when `msg.sender` is not `tx.origin` (caller is a contract).
    error CallerIsContract();

    /// @dev Thrown when `msg.value` is not the necessary ETH when minting.
    error IncorrectEtherValue();

    /// @dev Thrown when providing an invalid merkle proof.
    error InvalidProof();

    /// @dev Thrown when training is not enabled.
    error TrainingNotEnabled();

    /// @dev Thrown when transferring a token that is in training.
    error TransferWhileInTraining();

    /// @dev Thrown when providing an empty array of IDs.
    error InvalidIds();

    /* ------------------------------------------------------------------------------------------ */
    /*                                           EVENTS                                           */
    /* ------------------------------------------------------------------------------------------ */

    /// @dev Emitted when training is enabled for a token.
    /// @param user The address
    /// @param id The ID that is training
    /// @param timestamp The UNIX timestamp
    event Train(address indexed user, uint256 indexed id, uint64 timestamp);

    /// @dev Emitted when training is disabled for a token.
    /// @param user The address that performed the action
    /// @param id The token ID
    /// @param timestamp The UNIX timestamp
    /// @param lastTimestamp The UNIX timestamp of when the training was enabled, to calculate the duration
    event Rest(address indexed user, uint256 indexed id, uint64 timestamp, uint64 lastTimestamp);

    /* ------------------------------------------------------------------------------------------ */
    /*                                           STRUCTS                                          */
    /* ------------------------------------------------------------------------------------------ */

    /// @dev Contains information about each token.
    /// Has to be packed into 256 bits.
    struct TokenInfo {
        uint64 lastTimestamp;
    }

    /* ------------------------------------------------------------------------------------------ */
    /*                                          FUNCTIONS                                         */
    /* ------------------------------------------------------------------------------------------ */

    /// @notice Returns the constant max supply of the collection.
    function MAX_SUPPLY() external view returns (uint256);

    /// @notice Returns the constant max mint per address during the private sale.
    function MAX_WALLET_PRIVATE() external view returns (uint256);

    /// @notice Returns the constant max mint per wallet during the public sale.
    function MAX_WALLET_PUBLIC() external view returns (uint256);

    /// @notice Returns the constant max team mint.
    function MAX_TEAM_MINT() external view returns (uint256);

    /// @notice Returns the constant mint price.
    function PRICE() external view returns (uint256);

    /// @notice Returns the merkle root used for private allocations.
    function merkleRoot() external view returns (bytes32);

    /// @notice Returns the private sale UNIX timestamp.
    function privateTimestamp() external view returns (uint256);

    /// @notice Returns the public sale UNIX timestamp.
    function publicTimestamp() external view returns (uint256);

    /// @notice Returns whether training is enabled.
    function isTrainingEnabled() external view returns (bool);

    /// @notice Returns the URI for all the tokens' metadata.
    function baseURI() external view returns (string memory);

    /// @notice Mints `amount` tokens during the private sale.
    /// @param amount The amount of tokens to mint
    /// @param proof The merkle proof
    function privateMint(uint256 amount, bytes32[] calldata proof) external payable;

    /// @notice Mints `amount` tokens during the public sale.
    /// @param amount The amount of tokens to mint
    function publicMint(uint256 amount) external payable;

    /// @notice Toggles training for each ID in `ids` depending on its previous state.
    /// @param ids The token IDs
    function toggleTraining(uint256[] calldata ids) external;

    /// @notice Returns whether a token is in training.
    /// @param id The token ID
    function isTokenInTraining(uint256 id) external view returns (bool);

    /// @notice Returns how long a token has been in training for.
    /// @param id The token ID
    function inTrainingFor(uint256 id) external view returns (uint256);

    /// @notice Transfers `id` token from `from` to `to` while it is in training.
    /// The caller must be the owner of `id`.
    /// @dev See `transferFrom`.
    function transferFromWhileInTraining(
        address from,
        address to,
        uint256 id
    ) external;

    /// @notice Safely transfers `id` token from `from` to `to` while it is in training.
    /// The caller must be the owner of `id`.
    /// @dev See `safeTransferFrom`.
    function safeTransferFromWhileInTraining(
        address from,
        address to,
        uint256 id
    ) external;

    /// @notice Safely transfers `id` token from `from` to `to` while it is in training.
    /// The caller must be the owner of `id`.
    /// @dev See `safeTransferFrom`.
    function safeTransferFromWhileInTraining(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) external;
}
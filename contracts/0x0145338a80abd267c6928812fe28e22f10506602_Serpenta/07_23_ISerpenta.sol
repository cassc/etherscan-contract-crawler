// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IAccessControlEnumerableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/IAccessControlEnumerableUpgradeable.sol";

import { IERC721AUpgradeable } from "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";

import { IERC721ABatchUpgradeable } from "../interfaces/IERC721ABatchUpgradeable.sol";

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

    /// @notice Returns the URI for all the tokens' metadata.
    function baseURI() external view returns (string memory);

    /// @notice Mints `amount` tokens during the private sale.
    /// @param amount The amount of tokens to mint
    /// @param proof The merkle proof
    function privateMint(uint256 amount, bytes32[] calldata proof) external payable;

    /// @notice Mints `amount` tokens during the public sale.
    /// @param amount The amount of tokens to mint
    function publicMint(uint256 amount) external payable;
}
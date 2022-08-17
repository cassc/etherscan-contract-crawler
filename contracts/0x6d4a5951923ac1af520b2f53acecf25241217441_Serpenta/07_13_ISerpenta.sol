// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IERC721A } from "erc721a/contracts/IERC721A.sol";

import { IERC721ABatch } from "../interfaces/IERC721ABatch.sol";

interface ISerpenta is IERC721A, IERC721ABatch {
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
    /*                                           STRUCTS                                          */
    /* ------------------------------------------------------------------------------------------ */

    /// @dev Frequently accessed info about the contract. Packed in 256 bits to reduce SLOAD calls.
    struct ContractInfo {
        uint16 maxSupply;
        uint8 maxTeam;
        uint8 maxWalletPrivate;
        uint8 maxWalletPublic;
        uint128 price;
        uint32 privateTimestamp;
        uint32 publicTimestamp;
    }

    /* ------------------------------------------------------------------------------------------ */
    /*                                          FUNCTIONS                                         */
    /* ------------------------------------------------------------------------------------------ */

    /// @notice Returns the URI for all the tokens' metadata.
    function baseURI() external view returns (string memory);

    /// @notice Returns the merkle root used for private allocations.
    function merkleRoot() external view returns (bytes32);

    /// @notice Returns the immutable payment splitter address.
    function paymentSplitter() external view returns (address);

    /// @notice Mints `amount` tokens during the private sale.
    /// @param amount The amount of tokens to mint
    /// @param proof The merkle proof
    function privateMint(uint256 amount, bytes32[] calldata proof) external payable;

    /// @notice Mints `amount` tokens during the public sale.
    /// @param amount The amount of tokens to mint
    function publicMint(uint256 amount) external payable;
}
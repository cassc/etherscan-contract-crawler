// SPDX-License-Identifier: MIT
// Creator: MoeKun, JayB
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

interface IERC721ASGakuen is IERC721, IERC721Metadata {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller cannot approve to their own address.
     */
    error ApproveToCaller();

    /**
     * The caller cannot approve to the current owner.
     */
    error ApprovalToCurrentOwner();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error SchoolingQueryForNonexistentToken();

    /**
     * Index is out of array's range.
     */
    error CheckpointOutOfArray();

    // Compiler will pack this into a single 256bit word.
    struct TokenStatus {
        // The address of the owner.
        address owner;
        // Keeps track of the latest time User toggled schooling.
        uint40 schoolingTimestamp;
        // Keeps track of the total time of schooling.
        // Left 4Most bit
        uint40 schoolingTotal;
        // State to support multiple seasons
        uint8 schoolingId;
        // Whether the token has been burned.
        bool burned;
    }

    // Compiler will pack this into a single 256bit word.
    struct SchoolingPolicy {
        uint64 alpha;
        uint64 beta;
        uint40 schoolingBegin;
        uint40 schoolingEnd;
        uint8 schoolingId;
        uint40 breaktime;
    }

    /**
     * @dev Returns total schooling time.
     */
    function schoolingTotal(uint256 tokenId) external view returns (uint256);

    /**
     * @dev Returns latest change time of schooling status.
     */
    function schoolingTimestamp(uint256 tokenId)
        external
        view
        returns (uint256);

    /**
     * @dev Returns whether token is schooling or not.
     */
    function isTakingBreak(uint256 tokenId) external view returns (bool);

    /**
     * @dev Returns number of existing checkpoint + deleted checkpoint.
     */
    /**
     * returns number of checkpoints not deleted
     */
    function numOfCheckpoints() external view returns (uint256);

    /**
     * Get URI at certain index.
     * index can be identified as grade.
     */
    function uriAtIndex(uint256 index) external view returns (string memory);

    /**
     * Get Checkpoint at certain index.
     * index can be identified as grade.
     */
    function checkpointAtIndex(uint256 index) external view returns (uint256);

    /**
     * @dev Returns time when schooling begin
     */
    function schoolingBegin() external view returns (uint256);

    /**
     * @dev Returns time when schooling end
     */
    function schoolingEnd() external view returns (uint256);

    /**
     * @dev Returns breaktime for schooling
     */
    function schoolingBreaktime() external view returns (uint256);

    /**
     * @dev Returns breaktime for schooling
     */
    function schoolingId() external view returns (uint256);

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     * @dev Burned tokens are calculated here, use _totalMinted() if you want to count just minted tokens.
     */
    function totalSupply() external view returns (uint256);
}
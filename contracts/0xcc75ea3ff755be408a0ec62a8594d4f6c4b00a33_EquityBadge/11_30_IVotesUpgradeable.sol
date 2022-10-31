// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    @dev AB: OZ override
    @dev Modification scope: getVotes, getPastVotes, delegate, delegateBySig

    ------------------------------

    security-contact:
    - [email protected]
    - [email protected]
    - [email protected]

 **************************************/

/**
 * @dev Common interface for {ERC20Votes}, {ERC721Votes}, and other {Votes}-enabled contracts.
 *
 * _Available since v4.5._
 */
interface IVotesUpgradeable {

    /**
     * @dev Emitted when an account changes their delegate.
     */
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /**
     * @dev Emitted when a token transfer or delegate change results in changes to a delegate's number of votes.
     */
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    // AB: Delegation errors
    error CannotDelegateAddressZero();
    error EmptyDataNotSupported();
    error DataDoesNotContainValidTokenId();

    /**************************************

        @notice Override of OZ getVotes

        ------------------------------

        @dev AB: added data arg
        @dev Example usage for ERC20: empty (value: 0x0)
        @dev Example usage for ERC1155: tokenId (type: bytes<uint256>)

        ------------------------------

        @param account Account that voted
        @param data Bytes encoding optional parameters

     **************************************/

    /**
     * @dev Returns the current amount of votes that `account` has.
     */
    function getVotes(address account, bytes memory data) external view returns (uint256);

    /**************************************

        @notice Override of OZ getPastVotes

        ------------------------------

        @dev AB: added data arg
        @dev Example usage for ERC20: empty (value: 0x0)
        @dev Example usage for ERC1155: tokenId (type: bytes<uint256>)

        ------------------------------

        @param account Account that voted
        @param blockNumber number of block snapshot
        @param data Bytes encoding optional parameters

     **************************************/

    /**
     * @dev Returns the amount of votes that `account` had at the end of a past block (`blockNumber`).
     */
    function getPastVotes(address account, uint256 blockNumber, bytes memory data) external view returns (uint256);

    /**
     * @dev Returns the total supply of votes available at the end of a past block (`blockNumber`).
     *
     * NOTE: This value is the sum of all available votes, which is not necessarily the sum of all delegated votes.
     * Votes that have not been delegated are still part of total supply, even though they would not participate in a
     * vote.
     */
    function getPastTotalSupply(uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the delegate that `account` has chosen.
     */
    function delegates(address account) external view returns (address);

    /**************************************

        @notice Override of OZ delegate

        ------------------------------

        @dev AB: added data arg
        @dev Example usage for ERC20: empty (value: 0x0)
        @dev Example usage for ERC1155: tokenId (type: bytes<uint256>)

        ------------------------------

        @param delegatee Account receiving delegation
        @param data Bytes encoding optional parameters

     **************************************/

    /**
     * @dev Delegates votes from the sender to `delegatee`.
     */
    function delegate(
        address delegatee,
        bytes memory data
    ) external;

    /**************************************

        @notice Override of OZ delegateBySig

        ------------------------------

        @dev AB: added data arg
        @dev Example usage for ERC20: empty (value: 0x0)
        @dev Example usage for ERC1155: tokenId (type: bytes<uint256>)

        ------------------------------

        @param delegatee Account receiving delegation
        @param nonce Number used once
        @param expiry Expiration timestamp
        @param v Part of signature
        @param r Part of signature
        @param s Part of signature
        @param data Bytes encoding optional parameters

     **************************************/

    /**
     * @dev Delegates votes from signer to `delegatee`.
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        bytes memory data,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

}
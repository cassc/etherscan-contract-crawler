// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/**
 * @author [email protected]
 * @notice If token managers implement this, transfer actions will call
 *      postSafeTransferFrom or postTransferFrom on the token manager.
 */
interface IPostTransfer {
    /**
     * @notice Hook called by community after safe transfers, if token manager of transferred token implements this
     *      interface.
     * @param operator Operator transferring tokens
     * @param from Token(s) sender
     * @param to Token(s) recipient
     * @param id Transferred token's id
     * @param data Arbitrary data
     */
    function postSafeTransferFrom(
        address operator,
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) external;

    /**
     * @notice Hook called by community after transfers, if token manager of transferred token implements
     *         this interface.
     * @param operator Operator transferring tokens
     * @param from Token(s) sender
     * @param to Token(s) recipient
     * @param id Transferred token's id
     */
    function postTransferFrom(
        address operator,
        address from,
        address to,
        uint256 id
    ) external;
}
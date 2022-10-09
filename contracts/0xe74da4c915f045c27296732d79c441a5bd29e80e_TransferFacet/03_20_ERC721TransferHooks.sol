// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

contract ERC721TransferHooks {
    /// @notice Before Token Transfer Hook
    /// @param from Token owner
    /// @param to Receiver
    /// @param tokenId The token id
    /* solhint-disable no-empty-blocks */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
    /* solhint-disable no-empty-blocks */

    /// @notice After Token Transfer Hook
    /// @param from Token owner
    /// @param to Receiver
    /// @param tokenId The token id
    /* solhint-disable no-empty-blocks */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
    /* solhint-disable no-empty-blocks */

    /// @notice Token Transfer Condition
    /// @param operator Operator of token
    /// @param tokenId The token id
    /* solhint-disable no-empty-blocks */
    function _mayTransfer(address operator, uint256 tokenId)
        internal virtual
        view
        returns (bool) {}
}
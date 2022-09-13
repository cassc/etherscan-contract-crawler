// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

/**
 *   @title Batch transfer contract for ERC721 tokens
 *   @author Fr0ntier X <[email protected]>
 */

interface ERC721Partial {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

contract ERC721BatchTransfer {
    /// @notice Tokens on the given ERC-721 contract are transferred from you to a recipient.
    ///         Don't forget to execute setApprovalForAll first to authorize this contract.
    /// @param  tokenContract An ERC-721 contract
    /// @param  recipients     Who gets the tokens?
    /// @param  tokenIds      Which token IDs are transferred?
    function batchTransfer(
        ERC721Partial tokenContract,
        address[] calldata recipients,
        uint256[] calldata tokenIds
    ) external {
        require(
            tokenIds.length == recipients.length,
            "tokenIds and recipients length mismatch"
        );
        for (uint256 index; index < tokenIds.length; index++) {
            tokenContract.transferFrom(
                msg.sender,
                recipients[index],
                tokenIds[index]
            );
        }
    }
}
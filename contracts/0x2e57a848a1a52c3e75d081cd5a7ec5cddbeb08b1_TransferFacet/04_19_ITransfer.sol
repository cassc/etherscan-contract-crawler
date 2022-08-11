// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface ITransfer {
    error TokenNotOwnedByFromAddress();
    error CallerNotOwnerOrApprovedOperator();
    error InvalidTransferToZeroAddress();
    error QueryNonExistentToken();
    error TransferToNonERC721ReceiverImplementer();


    /// @notice Emitted when `tokenId` token is transferred from `from` to `to`.
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    /// @param _from transfer address
    /// @param _to receiver address
    /// @param _tokenId the NFT transfered
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 indexed _tokenId
    );
}
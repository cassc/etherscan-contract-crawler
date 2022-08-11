// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {AppStorage} from "./LibAppStorage.sol";
import {ITransfer} from "../interfaces/ITransfer.sol";
import {IERC721Receiver} from "../interfaces/IERC721Receiver.sol";

library LibTransfer {
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

    event AdminTransfer(address indexed sender, address from, address to, uint256 tokenId);

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function adminTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        AppStorage storage s
    ) internal {
        address owner = s.nftStorage.tokenOwners[_tokenId];
        if (owner == address(0)) revert ITransfer.QueryNonExistentToken();
        if (owner != _from) revert ITransfer.TokenNotOwnedByFromAddress();
        if (_to == address(0)) revert ITransfer.InvalidTransferToZeroAddress();

        s.nftStorage.balances[_from] -= 1;
        s.nftStorage.balances[_to] += 1;

        s.nftStorage.tokenOperators[_tokenId] = address(0);
        s.nftStorage.tokenOwners[_tokenId] = _to;

        emit Transfer(_from, _to, _tokenId);
        emit AdminTransfer(msg.sender, _from, _to, _tokenId);
    }

    /// @notice Checking if the receiving contract implements IERC721Receiver
    /// @param from Token owner
    /// @param to Receiver
    /// @param tokenId The token id
    /// @param _data Extra data
    function _checkERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal returns (bool)
    {
        try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
            return retval == IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert ITransfer.TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }
}
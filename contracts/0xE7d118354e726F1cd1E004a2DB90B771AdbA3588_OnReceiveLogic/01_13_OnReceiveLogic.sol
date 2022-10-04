//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@violetprotocol/extendable/extensions/InternalExtension.sol";
import { RoleState, Permissions } from "@violetprotocol/extendable/storage/PermissionStorage.sol";
import "./IOnReceiveLogic.sol";

// Functional logic extracted from openZeppelin:
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol
contract OnReceiveLogic is OnReceiveExtension {
    using Address for address;

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override _internal returns (bool) {
        string memory notReceiver = "ERC721: transfer to non ERC721Receiver implementer";

        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_lastExternalCaller(), from, tokenId, _data) returns (
                bytes4 retval
            ) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(notReceiver);
                } else if (Errors.catchCustomError(reason, ExtensionNotImplemented.selector)) {
                    revert(notReceiver);
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
}
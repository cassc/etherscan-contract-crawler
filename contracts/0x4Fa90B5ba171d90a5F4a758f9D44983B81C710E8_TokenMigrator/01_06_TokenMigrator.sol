// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "IERC721.sol";
import "IERC721Receiver.sol";
import "Ownable.sol";

contract TokenMigrator is IERC721Receiver, Ownable {

    address constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    /**
    * @dev Old token contract
    */
    IERC721 public oldToken;

    /**
    * @dev New token contract
    */
    IERC721 public newToken;

    /**
    * @dev Map old token ids to new token ids
    */
    mapping(uint256 => uint256) private oldTokenIdMap;

    /**
     * @dev This contract must be approved to transfer new tokens
     * from the newTokenDispatcher address
     */
    address private newTokenDispatcher;

    constructor(
        address _oldToken,
        address _newToken,
        address _newTokenDispatcher,
        uint256[] memory oldTokenIds
    ) {
        oldToken = IERC721(_oldToken);
        newToken = IERC721(_newToken);
        newTokenDispatcher = _newTokenDispatcher;
        for (uint256 i = 0; i < oldTokenIds.length; i++) {
            oldTokenIdMap[oldTokenIds[i]] = i + 1;
        }
    }

    /**
     * @dev Transfer received old token to burn address and release corresponding
     * new token to the address that performed the transfer.
     * See {IERC721Receiver-onERC721Received}.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 oldTokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        require (msg.sender == address(oldToken), "IERC721Receiver: Invalid caller");
        uint256 newTokenId = oldTokenIdMap[oldTokenId];
        require (newTokenId != 0, "Received invalid token id");
        newToken.safeTransferFrom(newTokenDispatcher, operator, newTokenId);
        oldToken.transferFrom(address(this), BURN_ADDRESS, oldTokenId);
        return this.onERC721Received.selector;
    }

    /**
     * @dev In case an old token is accidentally sent to this contract using {IERC721-transferFrom}
     * rather than {IERC721-safeTransferFrom} the owner of this contract can recover it and
     * complete the migration.
     */
    function onlyOwner_recoverLostToken(address to, uint256 oldTokenId) external onlyOwner {
        uint256 newTokenId = oldTokenIdMap[oldTokenId];
        newToken.safeTransferFrom(newTokenDispatcher, to, newTokenId);
        oldToken.transferFrom(address(this), BURN_ADDRESS, oldTokenId);
    }
}
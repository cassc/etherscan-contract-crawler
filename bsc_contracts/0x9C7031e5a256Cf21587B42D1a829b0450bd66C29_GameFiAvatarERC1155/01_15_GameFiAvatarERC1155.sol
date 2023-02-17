// SPDX-License-Identifier: BUSL-1.1
// GameFi Core™ by CDEVS

pragma solidity 0.8.10;
// solhint-disable not-rely-on-time

import "../basic/GameFiTokenERC1155.sol";
import "../../../interface/core/token/custom/IGameFiAvatarERC1155.sol";


/**
 * @author Alex Kaufmann
 * @dev ERC1155 token contract for game avatars.
 */
contract GameFiAvatarERC1155 is GameFiTokenERC1155, IGameFiAvatarERC1155 {
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(GameFiTokenERC1155) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        // TODO
        // require(_msgSender() == owner(), "GameFiAvatarERC1155: only for the owner");
        // for (uint256 i = 0; i < amounts.length; i++) {
        //     require(amounts[i] == 1, "GameFiAvatarERC1155: wrong token amount");
        //     require(balanceOf(_msgSender(), ids[i]) == 0, "GameFiAvatarERC1155: target already has this token");
        // }
    }
}
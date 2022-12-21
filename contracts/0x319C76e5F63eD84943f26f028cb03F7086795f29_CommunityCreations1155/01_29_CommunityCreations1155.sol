// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @title: Community Creations 1155
/// @author: x0r (Michael Blau)

import {ERC1155Creator} from "@manifoldxyz/creator-core-solidity/contracts/ERC1155Creator.sol";
import {LicenseVersion, CantBeEvil, ICantBeEvil} from "@a16z/contracts/licenses/CantBeEvil.sol";

contract CommunityCreations1155 is
    ERC1155Creator,
    CantBeEvil(LicenseVersion.PUBLIC)
{
    // =================== CUSTOM ERRORS =================== //
    error NonTransferableToken();

    constructor() ERC1155Creator("x0r Community Creations", "x0rCC") {}

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155Creator, CantBeEvil) returns (bool) {
        return
            ERC1155Creator.supportsInterface(interfaceId) ||
            CantBeEvil.supportsInterface(interfaceId);
    }

    /**
     * @notice override to make NFTs non-transferable.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override {
        if (from != address(0) && to != address(0)) {
            revert NonTransferableToken();
        }
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC1155PresetMinterPauser, ERC1155} from "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";
import {ERC1155Supply} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {DefaultOperatorFilterer} from "operator-filter-registry/src/DefaultOperatorFilterer.sol";

// _____/\\\\\\\\\\\___          __/\\\_____________
//  ___/\\\/////////\\\_          _\/\\\_____________
//   __\//\\\______\///__          _\/\\\_____________
//    ___\////\\\_________          _\/\\\_____________
//     ______\////\\\______          _\/\\\_____________
//      _________\////\\\__ Screaming _\/\\\_____________
//       __/\\\______\//\\\__   Labs   _\/\\\_____________
//        _\///\\\\\\\\\\\/___          _\/\\\\\\\\\\\\\\\_
//         ___\///////////_____          _\///////////////__

contract CursedDrink is
    ERC1155PresetMinterPauser,
    ERC1155Supply,
    ERC2981,
    DefaultOperatorFilterer
{
    constructor(
        address royaltiesReceiver,
        string memory _baseURI
    ) ERC1155PresetMinterPauser(_baseURI) {
        _setDefaultRoyalty(royaltiesReceiver, 400);
    }

    function setURI(string memory newuri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setURI(newuri);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155PresetMinterPauser, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC1155PresetMinterPauser, ERC1155, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
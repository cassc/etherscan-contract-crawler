// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import {DefaultOperatorFilterer} from "./OperatorFilter/DefaultOperatorFilterer.sol";
import "@minteeble/smart-contracts/contracts/token/ERC721/MinteebleERC721A.sol";

//  ___ ___  ___ ___ ___ _      ___   __ __      ___   ___ ___ ___ ___  ___  ___
// | __/ _ \| _ \ __| _ \ |    /_\ \ / / \ \    / /_\ | _ \ _ \_ _/ _ \| _ \/ __|
// | _| (_) |   / _||  _/ |__ / _ \ V /   \ \/\/ / _ \|   /   /| | (_) |   /\__ \
// |_| \___/|_|_\___|_| |____/_/ \_\_|     \_/\_/_/ \_\_|_\_|_\___\___/|_|_\|___/

contract foreplaywarriors is MinteebleERC721A, DefaultOperatorFilterer {
    constructor()
        MinteebleERC721A("Foreplay Warriors", "FPW", 8888, 53000000000000000)
    {
        revealed = false;
        paused = false;
        setPreRevealUri(
            "ipfs://bafkreicyk3ujr7kspznywqxtplhqdasyru3kupjr4ilvkshzfmv67arvrq"
        );
        _safeMint(owner(), 1);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}
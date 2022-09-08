// SPDX-License-Identifier: MIT

//     `..        `.  `... `......`.. ..
//  `..   `..    `. ..     `..  `..    `..
// `..          `.  `..    `..   `..
// `..         `..   `..   `..     `..
// `..        `...... `..  `..        `..
//  `..   `..`..       `.. `..  `..    `..
//    `.... `..         `..`..    `.. ..

pragma solidity 0.8.16;

import { IERC721 } from "@solidstate/contracts/token/ERC721/IERC721.sol";
import { ERC721BaseStorage } from "@solidstate/contracts/token/ERC721/base/ERC721BaseStorage.sol";
import { IERC721Metadata } from "@solidstate/contracts/token/ERC721/metadata/IERC721Metadata.sol";
import { ERC721MetadataStorage } from "@solidstate/contracts/token/ERC721/metadata/ERC721MetadataStorage.sol";
import { UintUtils } from "@solidstate/contracts/utils/UintUtils.sol";
import "@solidstate/contracts/token/ERC721/SolidStateERC721.sol";
import { AnimaStorage } from "./AnimaStorage.sol";
import { AnimaErrors } from "./AnimaErrors.sol";
import { IAnima } from "./IAnima.sol";
import { SBTERC721Base } from "./SBTERC721Base.sol";
import { DiamondOwnable } from "../acl/DiamondOwnable.sol";
import { ERC165Storage } from "@solidstate/contracts/introspection/ERC165Storage.sol";

contract Anima is DiamondOwnable, SBTERC721Base, ERC721Enumerable, ERC721Metadata, ERC165, IAnima {
    using UintUtils for uint256;
    using ERC721BaseStorage for ERC721BaseStorage.Layout;
    using ERC165Storage for ERC165Storage.Layout;

    function initialize() external onlyOwner {
        ERC165Storage.layout().setSupportedInterface(0x01ffc9a7, true);
        ERC165Storage.layout().setSupportedInterface(0x80ac58cd, true);
        ERC165Storage.layout().setSupportedInterface(0x5b5e139f, true);
    }

    function setCatcoinContract(address catcoin) external onlyOwner {
        AnimaStorage.layout().catcoin = catcoin;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        ERC721MetadataStorage.layout().baseURI = baseURI;
    }

    function mint(address recipient, uint256 tokenId) external override {
        uint256 mintId = totalSupply() + 6666;
        AnimaStorage.layout().animaIdToCatId[mintId] = tokenId;
        if (msg.sender != AnimaStorage.layout().catcoin) revert AnimaErrors.Unauthorized(msg.sender);
        _mint(recipient, mintId);
    }

    // ============================= VIEWS =============================

    function name() public view virtual override(ERC721Metadata, IERC721Metadata) returns (string memory) {
        return "Anima";
    }

    function symbol() public view virtual override(ERC721Metadata, IERC721Metadata) returns (string memory) {
        return "ANI";
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721Metadata, IERC721Metadata)
        returns (string memory)
    {
        uint256 catId = AnimaStorage.layout().animaIdToCatId[tokenId];
        if (!ERC721BaseStorage.layout().exists(tokenId)) revert AnimaErrors.URIQueryForNonexistentToken();
        string memory baseURI = ERC721MetadataStorage.layout().baseURI;
        string memory result = string(abi.encodePacked(baseURI, catId.toString(), ".json"));
        return bytes(baseURI).length != 0 ? result : "";
    }

    // ============================= SBT =============================

    function _beforeTokenTransfer(
        address from,
        address,
        uint256
    ) internal virtual override(ERC721BaseInternal, ERC721Metadata) {
        if (from != address(0)) revert AnimaErrors.NotAllowed();
    }

    function _handleApproveMessageValue(
        address,
        uint256,
        uint256
    ) internal virtual override {
        revert AnimaErrors.NotAllowed();
    }
}
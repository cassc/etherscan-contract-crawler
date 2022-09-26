// SPDX-License-Identifier: MIT

//     `..        `.  `... `......`.. ..
//  `..   `..    `. ..     `..  `..    `..
// `..          `.  `..    `..   `..
// `..         `..   `..   `..     `..
// `..        `...... `..  `..        `..
//  `..   `..`..       `.. `..  `..    `..
//    `.... `..         `..`..    `.. ..

pragma solidity 0.8.16;

import { ERC721AQueryableUpgradeable, ERC721AUpgradeable, IERC721AUpgradeable } from "erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol";
import { CatsStorage } from "./CatsStorage.sol";
import { DiamondOwnable } from "../acl/DiamondOwnable.sol";
import { ICats } from "./ICats.sol";
import { LibDiamond } from "../diamond/LibDiamond.sol";

contract CatsV2 is ERC721AQueryableUpgradeable, DiamondOwnable, ICats {
    uint256 constant MAX_TOTAL_SUPPLY = 1000;

    function mint(address recipient, uint256 quantity) external {
        if (msg.sender != owner() && msg.sender != CatsStorage.layout().catcoin) revert Unauthorized(msg.sender);
        if (totalSupply() + quantity > MAX_TOTAL_SUPPLY) revert MaxTotalSupplyBreached();

        _mint(recipient, quantity);
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        CatsStorage.layout().baseURI = baseURI;
    }

    function setContractURI(string calldata contractURI_) external onlyOwner {
        CatsStorage.layout().contractURI = contractURI_;
    }

    function setCatcoinContract(address catcoin) external onlyOwner {
        CatsStorage.layout().catcoin = catcoin;
    }

    // ============================= VIEWS =============================

    function contractURI() public view returns (string memory) {
        return CatsStorage.layout().contractURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return CatsStorage.layout().baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        string memory result = string(abi.encodePacked(baseURI, _toString(tokenId), ".json"));

        return bytes(baseURI).length != 0 ? result : "";
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        returns (bool)
    {
        if (operator == CatsStorage.layout().catcoin) return true;
        return super.isApprovedForAll(owner, operator);
    }
}
// SPDX-License-Identifier: MIT

//     `..        `.  `... `......`.. ..
//  `..   `..    `. ..     `..  `..    `..
// `..          `.  `..    `..   `..
// `..         `..   `..   `..     `..
// `..        `...... `..  `..        `..
//  `..   `..`..       `.. `..  `..    `..
//    `.... `..         `..`..    `.. ..

pragma solidity 0.8.16;
import { ERC721AStorage } from "erc721a-upgradeable/contracts/ERC721AStorage.sol";
import { CatsStorage } from "./CatsStorage.sol";
import { IAuctionable } from "./IAuctionable.sol";
import { CatsV2 } from "./CatsV2.sol";

contract CatsV3 is CatsV2, IAuctionable {
    function mintOne(address recipient) external returns (uint256 catId) {
        if (msg.sender != owner() && msg.sender != CatsStorage.layout().catcoin) revert Unauthorized(msg.sender);
        catId = ERC721AStorage.layout()._currentIndex;
        _mint(recipient, 1);
    }

    function burn(uint256 id) external {
        _burn(id, true);
    }
}
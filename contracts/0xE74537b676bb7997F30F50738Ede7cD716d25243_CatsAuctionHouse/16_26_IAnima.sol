//SPDX-License-Identifier: MIT

//     `..        `.  `... `......`.. ..
//  `..   `..    `. ..     `..  `..    `..
// `..          `.  `..    `..   `..
// `..         `..   `..   `..     `..
// `..        `...... `..  `..        `..
//  `..   `..`..       `.. `..  `..    `..
//    `.... `..         `..`..    `.. ..

pragma solidity 0.8.16;
import "@solidstate/contracts/token/ERC721/ISolidStateERC721.sol";
import { IERC173 } from "@solidstate/contracts/access/IERC173.sol";

interface IAnima is ISolidStateERC721, IERC173 {
    function setBaseURI(string calldata baseURI) external;

    function setCatcoinContract(address catcoins) external;

    function mint(address recipient, uint256 tokenId) external;
}
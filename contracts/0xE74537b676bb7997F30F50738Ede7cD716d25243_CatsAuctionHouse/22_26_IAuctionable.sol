// SPDX-License-Identifier: MIT

//     `..        `.  `... `......`.. ..
//  `..   `..    `. ..     `..  `..    `..
// `..          `.  `..    `..   `..
// `..         `..   `..   `..     `..
// `..        `...... `..  `..        `..
//  `..   `..`..       `.. `..  `..    `..
//    `.... `..         `..`..    `.. ..

pragma solidity 0.8.16;
import { IERC721AUpgradeable } from "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";
import { IERC173 } from "@solidstate/contracts/access/IERC173.sol";

interface IAuctionable is IERC721AUpgradeable, IERC173 {
    function mintOne(address recipient) external returns (uint256);

    function burn(uint256 id) external;
}
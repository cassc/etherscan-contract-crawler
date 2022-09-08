//SPDX-License-Identifier: MIT

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
import { IAnima } from "../anima/IAnima.sol";

interface ICatcoin is IERC721AUpgradeable, IERC173 {
    error WrongCatOwner();

    function setBaseURI(string calldata baseURI) external;

    function exchangeCat(uint256 catId) external;

    function daoMint(address recipient, uint256 amount) external;

    function moveCatTo(address recipient, uint256 catId) external;

    function setCatsContract(IERC721AUpgradeable cats) external;

    function setAnimaContract(IAnima anima) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata tokenIds
    ) external;
}
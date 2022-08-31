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

interface ICats is IERC721AUpgradeable, IERC173 {
    error MaxTotalSupplyBreached();
    error Unauthorized(address);

    function setBaseURI(string calldata baseURI) external;

    function setContractURI(string calldata contractURI) external;

    function mint(address recipient, uint256 quantity) external;

    function setCatcoinContract(address catcoin) external;

    function contractURI() external view returns (string memory);
}
// SPDX-License-Identifier: MIT

//     `..        `.  `... `......`.. ..
//  `..   `..    `. ..     `..  `..    `..
// `..          `.  `..    `..   `..
// `..         `..   `..   `..     `..
// `..        `...... `..  `..        `..
//  `..   `..`..       `.. `..  `..    `..
//    `.... `..         `..`..    `.. ..

import { IERC721AUpgradeable } from "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";
import { IAnima } from "../anima/IAnima.sol";

pragma solidity 0.8.16;

library CatcoinStorage {
    struct Layout {
        IERC721AUpgradeable cats;
        string baseURI;
        mapping(uint256 => uint16) originatingId;
        IAnima anima;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("cats.contracts.storage.catcoin");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
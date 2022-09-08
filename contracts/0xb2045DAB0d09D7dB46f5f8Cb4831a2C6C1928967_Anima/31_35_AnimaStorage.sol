// SPDX-License-Identifier: MIT

//     `..        `.  `... `......`.. ..
//  `..   `..    `. ..     `..  `..    `..
// `..          `.  `..    `..   `..
// `..         `..   `..   `..     `..
// `..        `...... `..  `..        `..
//  `..   `..`..       `.. `..  `..    `..
//    `.... `..         `..`..    `.. ..

import { IERC721AUpgradeable } from "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";

pragma solidity 0.8.16;

library AnimaStorage {
    struct Layout {
        address catcoin;
        mapping(uint256 => uint256) animaIdToCatId;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("cats.contracts.storage.anima");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
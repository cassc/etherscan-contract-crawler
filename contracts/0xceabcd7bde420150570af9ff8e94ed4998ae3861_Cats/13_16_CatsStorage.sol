// SPDX-License-Identifier: MIT

//     `..        `.  `... `......`.. ..
//  `..   `..    `. ..     `..  `..    `..
// `..          `.  `..    `..   `..
// `..         `..   `..   `..     `..
// `..        `...... `..  `..        `..
//  `..   `..`..       `.. `..  `..    `..
//    `.... `..         `..`..    `.. ..

pragma solidity 0.8.16;

library CatsStorage {
    struct Layout {
        address catcoin;
        string baseURI;
        string contractURI;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("cats.contracts.storage.cats");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
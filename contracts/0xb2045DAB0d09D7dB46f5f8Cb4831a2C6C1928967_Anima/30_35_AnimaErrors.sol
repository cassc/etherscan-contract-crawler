//SPDX-License-Identifier: MIT

//     `..        `.  `... `......`.. ..
//  `..   `..    `. ..     `..  `..    `..
// `..          `.  `..    `..   `..
// `..         `..   `..   `..     `..
// `..        `...... `..  `..        `..
//  `..   `..`..       `.. `..  `..    `..
//    `.... `..         `..`..    `.. ..

pragma solidity 0.8.16;

library AnimaErrors {
    error URIQueryForNonexistentToken();
    error NotAllowed();
    error Unauthorized(address);
}
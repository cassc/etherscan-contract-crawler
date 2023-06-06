/**
 *Submitted for verification at Etherscan.io on 2023-06-05
*/

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

// Herzlichen Glückwunsch!
// Du hast diese versteckte Nachricht erfolgreich finden können!
// Damit hast du nun die Möglichkeit, dir als eine oder einer der Ersten ein
// exklusives Hunde-NFT aus unserer Collection zu sichern (nur solange der Vorrat reicht).
// Du findest die Collection unter diesem Link auf Opensea: opensea.io/collection/dogs-of-bnd
// (Bitte beachte die Teilnahme- und Datenschutzbedingungen unter bnd.de/nft).

contract Message {

    string public message;

    constructor(string memory _message) {
        message = _message;
    }

    function updateMessage(string memory _newMessage) public {
        message = _newMessage;
    }
}

// 209d040019f1ad41cef22524d5f20390fe99e65eb93b5d6fe0ce988e793b31b7
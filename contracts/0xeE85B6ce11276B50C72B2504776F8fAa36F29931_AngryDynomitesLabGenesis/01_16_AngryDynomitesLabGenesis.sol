// constracts/AngryDynomitesLabGenesis.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Collection.sol";

/*
 *     ▄▄▄·  ▐ ▄  ▄▄ • ▄▄▄   ▄· ▄▌
 *    ▐█ ▀█ •█▌▐█▐█ ▀ ▪▀▄ █·▐█▪██▌
 *    ▄█▀▀█ ▐█▐▐▌▄█ ▀█▄▐▀▀▄ ▐█▌▐█▪
 *    ▐█ ▪▐▌██▐█▌▐█▄▪▐█▐█•█▌ ▐█▀·.
 *     ▀  ▀ ▀▀ █▪·▀▀▀▀ .▀  ▀  ▀ •
 *    ·▄▄▄▄   ▄· ▄▌ ▐ ▄       • ▌ ▄ ·. ▪ ▄▄▄▄▄▄▄▄ ..▄▄ ·
 *    ██▪ ██ ▐█▪██▌•█▌▐█▪     ·██ ▐███▪██•██  ▀▄.▀·▐█ ▀.
 *    ▐█· ▐█▌▐█▌▐█▪▐█▐▐▌ ▄█▀▄ ▐█ ▌▐▌▐█·▐█·▐█.▪▐▀▀▪▄▄▀▀▀█▄
 *    ██. ██  ▐█▀·.██▐█▌▐█▌.▐▌██ ██▌▐█▌▐█▌▐█▌·▐█▄▄▌▐█▄▪▐█
 *    ▀▀▀▀▀•   ▀ • ▀▀ █▪ ▀█▄▀▪▀▀  █▪▀▀▀▀▀▀▀▀▀  ▀▀▀  ▀▀▀▀
 *    ▄▄▌   ▄▄▄· ▄▄▄▄·
 *    ██•  ▐█ ▀█ ▐█ ▀█▪
 *    ██▪  ▄█▀▀█ ▐█▀▀█▄
 *    ▐█▌▐▌▐█ ▪▐▌██▄▪▐█
 *    .▀▀▀  ▀  ▀ ·▀▀▀▀
 */

contract AngryDynomitesLabGenesis is Collection {
    constructor()
        Collection(
            "Angry Dynomites Lab - Fire Dynos",
            "FDYNO",
            500,
            "136f32e1cdc294519d1b215587ccb39a028f054356c8caebb16bf9adbfcf7a72",
            "ipfs://QmSEzouSiiFkAHapvYE87qq4nhA9CyZQNfEbWucRDZumzN/",
            "ipfs://QmbpZaVPuNUr2NmbLMBzrUUAQgGqSbhwtHxYntNT9PoBmU"
        )
    {}
}
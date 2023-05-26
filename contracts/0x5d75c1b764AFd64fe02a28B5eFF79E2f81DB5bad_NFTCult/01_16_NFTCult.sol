// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./NFTCBase.sol";

/**
 * @title NFT Cult Wrapper Contract
 *
 * ███▄    █   █████▒▄▄▄█████▓    ▄████▄   █    ██  ██▓  ▄▄▄█████▓
 * ██ ▀█   █ ▓██   ▒ ▓  ██▒ ▓▒   ▒██▀ ▀█   ██  ▓██▒▓██▒  ▓  ██▒ ▓▒
 *▓██  ▀█ ██▒▒████ ░ ▒ ▓██░ ▒░   ▒▓█    ▄ ▓██  ▒██░▒██░  ▒ ▓██░ ▒░
 *▓██▒  ▐▌██▒░▓█▒  ░ ░ ▓██▓ ░    ▒▓▓▄ ▄██▒▓▓█  ░██░▒██░  ░ ▓██▓ ░
 *▒██░   ▓██░░▒█░      ▒██▒ ░    ▒ ▓███▀ ░▒▒█████▓ ░██████▒▒██▒ ░
 *░ ▒░   ▒ ▒  ▒ ░      ▒ ░░      ░ ░▒ ▒  ░░▒▓▒ ▒ ▒ ░ ▒░▓  ░▒ ░░
 *░ ░░   ░ ▒░ ░          ░         ░  ▒   ░░▒░ ░ ░ ░ ░ ▒  ░  ░
 *   ░   ░ ░  ░ ░      ░         ░         ░░░ ░ ░   ░ ░   ░
 *         ░                     ░ ░         ░         ░  ░
 *
 * Credit to https://patorjk.com/ for text generator.
 */
contract NFTCult is NFTCBase {
    uint256 private constant MAX_NFT_CULT_MEMBERS = 3333;
    uint256 private constant PRICE_PER_NFT = 0.09 ether;
    string private constant DEFAULT_FLAVOR_URI =
        "Qmd1HmRqqLq4vYUyGNqHHJ2C64H6GcfEKE8KCEjg48Xx3Z/";

    constructor()
        NFTCBase(
            "NFTCult",
            "NFTC",
            "https://gateway.pinata.cloud/ipfs/",
            DEFAULT_FLAVOR_URI,
            13148250,
            MAX_NFT_CULT_MEMBERS,
            PRICE_PER_NFT,
            3,
            true
        )
    {
        // Implementation version: 1
    }

    function _initFlavors(uint256 __numberOfFlavors, bool __lastBitEnabled)
        internal
        virtual
        override
    {
        require(__lastBitEnabled == true, "Unexpected config");

        // Init flavor uris for minting. For clarity, reserve zero val for not using the last bit.
        uint256 idx;
        for (idx = 1; idx <= __numberOfFlavors; idx++) {
            // Some numerical magic here to make the numbers more compatible with forging.
            uint256 flavorIdx = ((idx + 1) * 100) + 1;
            _assignFlavor(flavorIdx, DEFAULT_FLAVOR_URI, false);
            _assignFlavor(flavorIdx + 1, DEFAULT_FLAVOR_URI, false);
        }
    }
}
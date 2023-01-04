// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/*

 ░█▀█░█▀▀░▀█▀░░░█░█░█▀▄░█▀█░█▀█░█▀█░█▀▀░█▀▄
 ░█░█░█▀▀░░█░░░░█▄█░█▀▄░█▀█░█▀▀░█▀▀░█▀▀░█░█
 ░▀░▀░▀░░░░▀░░░░▀░▀░▀░▀░▀░▀░▀░░░▀░░░▀▀▀░▀▀░

*/

import "./NFTWrappedAbstract.sol";

contract NFTWrapped is NFTWrappedAbstract {
    constructor(string memory baseURI, address bundleContract)
        NFTWrappedAbstract("NFT Wrapped", "NFTW", 0.02 ether, baseURI, bundleContract) {}
}
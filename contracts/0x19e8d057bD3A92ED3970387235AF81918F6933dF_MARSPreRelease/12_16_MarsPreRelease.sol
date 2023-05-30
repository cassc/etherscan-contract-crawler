pragma solidity ^0.8.0;

import "./Base721.sol";

contract MARSPreRelease is Base721 {
    constructor() public ERC721A("MARS Pre-release", "MARS Pre-release") {
        maxSupply = 30000;
        baseURI = "ipfs://bafybeifhy6ezok3ljum7bdhh2lst7xy7k23syvynzofpx4n7kffto7lmve/";
    }
}
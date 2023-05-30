pragma solidity ^0.8.0;

import "./Base721.sol";

contract MARSPreRelease is Base721 {
    constructor() public ERC721A("MARS Pre-release", "MARS Pre-release") {
        maxSupply = 30000;
        defaultURI = "ipfs://bafkreiexkbnuolmm3xysb3y66wxfvoxzp3m7qtvs4af7olljqqzygjaody";
    }
}
pragma solidity ^0.8.0;

import "./Base721.sol";

contract ToolKey is Base721 {
    constructor() ERC721A("TOOL KEY", "TOOL KEY") {
        maxSupply = 10000;
        defaultURI = "ipfs://bafkreibx6b3lod54q6edg3imufe3obnnsulqma7rm3kkixh35lmtksbnq4";
    }
}
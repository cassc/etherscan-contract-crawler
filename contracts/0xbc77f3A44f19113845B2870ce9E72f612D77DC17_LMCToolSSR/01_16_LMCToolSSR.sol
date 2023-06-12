pragma solidity ^0.8.0;

import "./Base721.sol";

contract LMCToolSSR is Base721 {
    constructor() public ERC721A("LMC TOOL SSR", "LMC TOOL SSR") {
        maxSupply = 3600;
        defaultURI = "ipfs://bafkreicy63wwc4sn7r4ytdawzb4pfmw4rreipffs4xazt3ik63r737wazi";
    }
}
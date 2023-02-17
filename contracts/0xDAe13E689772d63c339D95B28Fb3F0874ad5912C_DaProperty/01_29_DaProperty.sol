// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC721Tradable.sol";

contract DaProperty is ERC721Tradable {
    constructor()
        ERC721Tradable(
            "Da Property",
            "DaP",
            0xa5409ec958C83C3f309868babACA7c86DCB077c1,
            "https://vrda1-paramount.s3.ap-south-1.amazonaws.com/items/",
            0xc26FB953Aa1Cd0d35bb31bc989d6ac3Af9f4a520,
            750
        )
    {}
}
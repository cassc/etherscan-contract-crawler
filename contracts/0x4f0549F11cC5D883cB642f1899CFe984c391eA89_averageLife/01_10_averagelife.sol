// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract averageLife is ERC1155 {

    constructor() ERC1155("https://ipfs.io/ipfs/bafybeiewq23opiwda5igojlkqb6uweoavxjbxgk3fq2vt5zbrxtfhbpcuu/{id}.json") {
        //337
        for (uint256 i = 1; i < 338; i++) {
            _mint(msg.sender, i, 1, "");
        }

    }

    function uri(uint256 _tokenid) override public pure returns (string memory) {
        return string(
            abi.encodePacked(
                "https://ipfs.io/ipfs/bafybeiewq23opiwda5igojlkqb6uweoavxjbxgk3fq2vt5zbrxtfhbpcuu/",
                Strings.toString(_tokenid),".json"
            )
        );
    }
}
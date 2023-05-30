// SPDX-License-Identifier: MIT
// warrencheng.eth
pragma solidity ^0.8.0;
import "./ERC721ATemplate.sol";

contract O2Land is ERC721ATemplate {
    string public provenance;

    constructor(string memory _provenance)
        ERC721ATemplate("O2 META Land", "O2ML", 10153)
    {
        provenance = "0x8f35fcbcbf715e32663bbac90a04d1df75e8e4045cbb3947a41abbd4c26e3a27";
        _safeMint(msg.sender, 370);
    }
}
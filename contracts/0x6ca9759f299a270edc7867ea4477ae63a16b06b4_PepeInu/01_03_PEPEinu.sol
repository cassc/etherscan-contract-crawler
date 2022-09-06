// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721A.sol";

contract PepeInu is ERC721A {
    bool minted;

    constructor() ERC721A("PEPE Inu", "PEPEINU") {}

    function _baseURI() internal view virtual override returns (string memory) {
        return "ipfs://QmYHV8BcnWHQgRJXb1Tt4xNtmY3F2Mpwm4JWbJr47ucjNb";
    }

    function mint() external payable {
        require(!minted, "Mint already completed");

        _mint(msg.sender, 1000);
        minted = true;
    }
}
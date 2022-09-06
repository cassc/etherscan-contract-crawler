// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721A.sol";

contract SudoWoodo is ERC721A {
    bool minted;

    constructor() ERC721A("SudoWoodo", "WOODO") {}

    function _baseURI() internal view virtual override returns (string memory) {
        return "ipfs://QmbAkZGsAhMNbZ7tLAU9bRZgdFXCuPUGfweN9RRLXHz23t";
    }

    function mint() external payable {
        require(!minted, "Mint already completed");

        _mint(msg.sender, 1000);
        minted = true;
    }
}
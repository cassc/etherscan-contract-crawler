// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721A.sol";

contract SudoSaudi is ERC721A {
    bool minted;

    constructor() ERC721A("Sudo Saudi", "SS") {}

    function _baseURI() internal view virtual override returns (string memory) {
        return "https://gateway.pinata.cloud/ipfs/QmVNkj3t6UbZBC2eNhD1BRoVcnugahYT2Ti3YmSyuBQsWb";
    }

    function mint() external payable {
        require(!minted, "Mint already completed");

        _mint(msg.sender, 1000);
        minted = true;
    }
}
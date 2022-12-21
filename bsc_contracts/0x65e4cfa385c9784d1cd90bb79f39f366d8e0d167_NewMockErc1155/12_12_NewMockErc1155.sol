// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";

contract NewMockErc1155 is ERC1155URIStorage {

    // Token name
    string public name;

    // Token symbol
    string public symbol;

    constructor(string memory _name, string memory _symbol) ERC1155("") {
        name = _name;
        symbol = _symbol;

    }

    function mint(
        address to,
        uint256 tokenId,
        uint256 amount
    ) external {
        _mint(to, tokenId, amount, "");
    }

    function setUri(uint256 id, string memory _uri) external {
        super._setURI(id,_uri);

    }
}
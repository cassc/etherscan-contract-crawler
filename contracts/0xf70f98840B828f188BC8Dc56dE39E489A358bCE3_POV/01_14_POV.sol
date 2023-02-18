// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract POV is ERC721Enumerable, Ownable {
    string private _uri =
        "ipfs://bafybeicpx5kaeqc66v7362yjv5nwz4usysrq5ga7vfoimeovjsxtlmbfkm/";

    event BaseURISet(string indexed baseURI);

    constructor() ERC721("The Magic of Iseltwald", "POV") {}

    function setBaseURI(string memory uri) external onlyOwner {
        _uri = uri;
        emit BaseURISet(uri);
    }

    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    function mintArray(address[] memory tos) external onlyOwner {
        for (uint256 i = 0; i < tos.length; i++) {
            mint(tos[i]);
        }
    }

    function mint(address to) public onlyOwner {
        uint256 currentSupply = totalSupply();
        require(currentSupply < 500, "Max supply reached");
        _safeMint(to, currentSupply + 1);
    }
}
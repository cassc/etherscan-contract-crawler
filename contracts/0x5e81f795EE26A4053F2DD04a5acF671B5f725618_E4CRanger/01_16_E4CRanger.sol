// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./Mintable.sol";

contract E4CRanger is ERC721, Mintable {

    string public baseURI;

    constructor(address imx, string memory name, string memory symbol) ERC721(name, symbol) Mintable(imx) { }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory baseURI_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = baseURI_;
    }

    function _mintFor(
        address to,
        uint256 id,
        bytes memory
    ) internal override {
        _safeMint(to, id);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, Mintable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RubberDuck is ERC721A, Ownable {
    string private __baseURI;

    constructor(address owner_, string memory baseURI_)
        ERC721A("Sweet Rubber Duck", "RDUCK")
    {
        _mint(owner_, 10000);
        _transferOwnership(owner_);
        __baseURI = baseURI_;
    }

    function _baseURI() internal view override returns (string memory) {
        return __baseURI;
    }
}
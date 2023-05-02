// SPDX-License-Identifier: MIT

pragma solidity >0.6.6;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';

// CakeToken with Governance.
contract MockERC721 is ERC721Enumerable {

    constructor (string memory name_, string memory symbol_) ERC721(name_, symbol_) {
    }

    function mint(address to, uint256 num) external {
        for (uint i = 0; i < num; i ++) {
            _mint(to, totalSupply() + i + 1);
        }
    }

}
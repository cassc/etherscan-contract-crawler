// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CyberMania is ERC721A, Ownable {

    uint256 public constant MAX_SUPPLY = 10000;

    constructor() ERC721A("CyberMania", "CYBERMANIA") {}

    function initMint() public onlyOwner {
        require(totalSupply() == 0, 'should be executed only once');
        _mint(msg.sender, MAX_SUPPLY);
    }

    function _baseURI() internal view override virtual returns (string memory) {
        return 'https://storage.googleapis.com/cybermania/';
    }

}
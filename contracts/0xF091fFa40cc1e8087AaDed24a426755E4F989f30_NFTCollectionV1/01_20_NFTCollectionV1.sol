// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./abstract/BaseUpgradable.sol";
// Import this file to use console.log
import "hardhat/console.sol";

contract NFTCollectionV1 is BaseUpgradable {

    event MinterChanged(address indexed from, address to);
 
    mapping (uint256 => string) tokenURIs;
    address public mintable;

    modifier whiteListed() {
        require(mintable == msg.sender, "Not allowed to mint");
        _;
    }

    function __NFTCollection_init(
        string memory name,
        string memory symbol
    ) public initializer {
        BaseUpgradable.initialize(name, symbol);
        mintable = owner();
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return tokenURIs[tokenId];
    }

    function mint(address to, uint256 tokenId, string memory uri) public whiteListed {
        _safeMint(to, tokenId);
        tokenURIs[tokenId] = uri;
    }

    function setMintableAddress(address operator) public onlyOwner {
        emit MinterChanged(msg.sender, operator);
        mintable = operator;
    }
}
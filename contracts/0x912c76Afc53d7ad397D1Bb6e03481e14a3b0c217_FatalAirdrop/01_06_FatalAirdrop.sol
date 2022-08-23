// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract FatalAirdrop is ERC721A, Ownable {
    constructor(string memory name, string memory symbol) ERC721A(name, symbol) {
    }

    uint256 maxSupply = 6666;

    function airdrop(address[] memory addr) external onlyOwner {
        require(addr.length + totalSupply() <= maxSupply, "Max supply is 6666");

        uint256 count;

        while (count < addr.length) {
            _mint(addr[count], 1);

            count = SafeMath.add(count, 1);
        }
    }

    string public baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseTokenURI = uri;
    }

    bool public open;

    function setOpen() public onlyOwner {
        open = _opposite(open);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();

        if (!open) {
            return "https://ipfs.io/ipfs/QmcYFga3LWJfH76q5kv5CULq6d4BuRCWhexRXRNMAeo6Wf";
        }

        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
    }

    function _opposite(bool state) internal pure returns (bool) {
        if (state) {
            return false;
        }
        return true;
    }
}
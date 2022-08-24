// contracts/Box.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AzukiNFT is ERC721A, Ownable {

    string private _tokenBaseURI = '';
    
    string private _blindTokenURI = '';

    bool private _revealed = false;

    constructor(string memory name_, string memory symbol_, uint256 initialMint, string memory blindBoxTokenURI) ERC721A(name_, symbol_) {
        _tokenBaseURI = blindBoxTokenURI;
        if(initialMint>0){
            _mintERC2309(msg.sender, initialMint);
        }
    }

    function mint(uint256 quantity) virtual external payable {
        // `_mint`'s second argument now takes in a `quantity`, not a `tokenId`.
        _mint(msg.sender, quantity);
    }

    function _baseURI() internal view virtual override returns (string memory){
        return _tokenBaseURI;
    }

    function reveal(string memory baseURI) public onlyOwner {
        _tokenBaseURI = baseURI;
        _revealed = true;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if(_revealed){
            return string(abi.encodePacked(super.tokenURI(tokenId), '.json'));
        }

        return _baseURI();
    }
}
/*
SPDX-License-Identifier: GPL-3.0
                                            3DOOPS
                                art by Olivia Pedigo (@oliviapedi on twitter)
                                if you read this, dm @UrMomNFT for a prize :)
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";

contract threeDoop is ERC721, Ownable {
    string private _baseURIextended;
    address constant public goopAddress = 0x2dfF22dcb59D6729Ed543188033CE102f14eF0d1;
    bool private claimIsActive = false;

    constructor () ERC721("3Doops", "3DOOP") {
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override(ERC721) returns (string memory) {
        return _baseURIextended;
    }
    
    function activateClaim() external onlyOwner() {
        claimIsActive = true;
    }

    function closeClaim() external onlyOwner() {
        claimIsActive = false;
    }

    function claim(uint256[] calldata ids) public payable {
        require(claimIsActive == true, "claim is not active!");
        uint256 mintAmount = ids.length;
        uint i;
        for(i = 0; i < mintAmount; ++i) {
            require(IERC721(goopAddress).ownerOf(ids[i]) == msg.sender, "You don't own all of those goops!");
        }
        for(i = 0; i < mintAmount; ++i) {
            _safeMint(msg.sender, ids[i]);
        }
    }
}
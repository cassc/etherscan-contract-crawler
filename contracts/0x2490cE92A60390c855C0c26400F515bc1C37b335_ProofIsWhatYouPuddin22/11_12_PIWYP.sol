// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ProofIsWhatYouPuddin22 is ERC721A, Ownable {

    //#USUAL FARE
    string public baseURI;


    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    constructor() ERC721A("ProofIsWhatYouPuddin22", "PIWYP22") {
    }

    // Only Owner executable functions

    //send to multiple people at different amounts in one go.
    function mintManyByOwner(address[] calldata _to, uint256[] calldata _mintAmount) external onlyOwner {
        for (uint256 i; i < _to.length; i++) {
            _safeMint(_to[i], _mintAmount[i]);
        }
    }
    
    //#SETTERS
    function setBaseURI(string memory _newURI) external onlyOwner {
        baseURI = _newURI;
    }   



}
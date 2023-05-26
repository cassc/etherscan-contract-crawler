// SPDX-License-Identifier: MIT

///////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//        ____                      __   _______      __       __  ___      _____         //
//       / __ )____ _________  ____/ /  / ____(_)____/ /_     /  |/  /___ _/ __(_)___ _   //
//      / __  / __ `/ ___/ _ \/ __  /  / /_  / / ___/ __ \   / /|_/ / __ `/ /_/ / __ `/   //
//     / /_/ / /_/ (__  )  __/ /_/ /  / __/ / (__  ) / / /  / /  / / /_/ / __/ / /_/ /    //
//    /_____/\__,_/____/\___/\__,_/  /_/   /_/____/_/ /_/  /_/  /_/\__,_/_/ /_/\__,_/     //
//                                                                                        //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract BasedFishMafia is ERC721, ERC721Enumerable, Ownable {
    string public PROVENANCE;
    bool public saleIsActive = false;
    string private _baseURIextended;

    constructor() ERC721("Based Fish Mafia", "BFM") {
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setProvenance(string memory provenance) public onlyOwner {
        PROVENANCE = provenance;
    }

    function reserve() public onlyOwner {
        uint supply = totalSupply();
        uint i;
        for (i = 0; i < 200; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }
    
    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }
    
    function mint(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint Tokens");
        require(numberOfTokens <= 15, "Exceeded max token purchase");
        require(totalSupply() + numberOfTokens <= 10000, "Purchase would exceed max supply of tokens");
        require(0.05 ether * numberOfTokens <= msg.value, "Ether value sent is not correct");
        
        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < 10000) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}
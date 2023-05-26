// SPDX-License-Identifier: MIT

/** 
_______ _            _    _       _ _          __   ______                   
|__   __| |          | |  | |     | | |        / _| |  ____|                  
   | |  | |__   ___  | |__| | __ _| | |   ___ | |_  | |__ __ _ _ __ ___   ___ 
   | |  | '_ \ / _ \ |  __  |/ _` | | |  / _ \|  _| |  __/ _` | '_ ` _ \ / _ \
   | |  | | | |  __/ | |  | | (_| | | | | (_) | |   | | | (_| | | | | | |  __/
   |_|  |_| |_|\___| |_|  |_|\__,_|_|_|  \___/|_|   |_|  \__,_|_| |_| |_|\___|
                                                                              
                                                                              
  _____             _     _               _           
 / ____|           | |   | |             | |           
| |  __  ___   __ _| |_  | |     ___   __| | __ _  ___ 
| | |_ |/ _ \ / _` | __| | |    / _ \ / _` |/ _` |/ _ \
| |__| | (_) | (_| | |_  | |___| (_) | (_| | (_| |  __/
 \_____|\___/ \__,_|\__| |______\___/ \__,_|\__, |\___|
                                             __/ |     
                                            |___/      

*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

/**
 * @title HallOfFameGoatLodge contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract HallOfFameGoatLodge is ERC721, ERC721Enumerable, Ownable {

    string public PROVENANCE = "7e99e18a864e0691e9a04cc4c81fe041966a38197e9d36c4b58ad085aaad9260";
    uint256 public constant tokenPrice = 70000000000000000; // 0.07 ETH
    uint public constant maxTokenPurchase = 15;
    uint256 public MAX_TOKENS = 10000;
    bool public saleIsActive = false;

    string private _baseURIextended;

    constructor() ERC721("Hall Of Fame Goat Lodge", "HOFG") {
    }

    // CHANGED: needed to resolve conflicting fns in ERC721 and ERC721Enumerable
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // CHANGED: needed to resolve conflicting fns in ERC721 and ERC721Enumerable
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // CHANGED: added to account for changes in openzeppelin versions
    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    // CHANGED: added to account for changes in openzeppelin versions
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setProvenance(string memory provenance) public onlyOwner {
        PROVENANCE = provenance;
    }

    function reserveTokens() public onlyOwner {        
        uint supply = totalSupply();
        uint i;
        for (i = 0; i < 100; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }
    
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }
    
    function mintGoat(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint Tokens");
        require(numberOfTokens <= maxTokenPurchase, "Exceeded max token purchase");
        // CHANGED: mult and add to + and *
        require(totalSupply() + numberOfTokens <= MAX_TOKENS, "Purchase would exceed max supply of tokens");
        // CHANGED: mult and add to + and *
        require(tokenPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");
        
        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_TOKENS) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

}
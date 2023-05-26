// SPDX-License-Identifier: MIT

/*
 ____    __       ______   __    __  ______   __  __  ____        ______  ____    ______  ____       
/\  _`\ /\ \     /\  _  \ /\ \  /\ \/\__  _\ /\ \/\ \/\  _`\     /\  _  \/\  _`\ /\__  _\/\  _`\     
\ \ \L\ \ \ \    \ \ \L\ \\ `\`\\/'/\/_/\ \/ \ \ `\\ \ \ \L\_\   \ \ \L\ \ \ \L\ \/_/\ \/\ \,\L\_\   
 \ \ ,__/\ \ \  __\ \  __ \`\ `\ /'    \ \ \  \ \ , ` \ \ \L_L    \ \  __ \ \ ,  /  \ \ \ \/_\__ \   
  \ \ \/  \ \ \L\ \\ \ \/\ \ `\ \ \     \_\ \__\ \ \`\ \ \ \/, \   \ \ \/\ \ \ \\ \  \ \ \  /\ \L\ \ 
   \ \_\   \ \____/ \ \_\ \_\  \ \_\    /\_____\\ \_\ \_\ \____/    \ \_\ \_\ \_\ \_\ \ \_\ \ `\____\
    \/_/    \/___/   \/_/\/_/   \/_/    \/_____/ \/_/\/_/\/___/      \/_/\/_/\/_/\/ /  \/_/  \/_____/

*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract PlayingArtsCryptoEdition is ERC721, ERC721Enumerable, Ownable {
    string public PROVENANCE;
    bool public saleIsActive = false;
    string private _baseURIextended;
    uint constant MAX_TOKENS = 3915 * 2;
    uint constant NUM_RESERVED_TOKENS = 55 * 2;
    address constant SHAREHOLDERS_ADDRESS = 0xFcfD26569bE92B1cf46811bca2D45b0BFc3664C3; 

    constructor() ERC721("Playing Arts Crypto Edition", "PACE") {
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
        for (i = 0; i < NUM_RESERVED_TOKENS; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }
    
    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }
    
    function mint(uint numberOfPacks) public payable {
        require(saleIsActive, "Sale must be active to mint Tokens");
        require(numberOfPacks <= 20, "Exceeded max purchase amount");
        require(totalSupply() + (numberOfPacks * 2) <= MAX_TOKENS, "Purchase would exceed max supply of tokens");
        require(0.13 ether * numberOfPacks <= msg.value, "Ether value sent is not correct");
        
        for(uint i = 0; i < numberOfPacks * 2; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_TOKENS) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(SHAREHOLDERS_ADDRESS).transfer(balance);
    }
}
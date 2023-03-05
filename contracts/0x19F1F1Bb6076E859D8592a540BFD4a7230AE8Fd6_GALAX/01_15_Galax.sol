// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract GALAX is ERC721, Ownable, ERC2981 {
    using Counters for Counters.Counter;

    uint256 Max_supply = 313;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("Galax3.13", "GLX") {
        _setDefaultRoyalty(msg.sender, 275);
        _safeMint(msg.sender,Max_supply);
        for(uint i=0;i<30;i++){
            mint(msg.sender);
        }
    }

    function search() internal view returns(uint256){
        uint256 tokenNumber = _tokenIdCounter.current();
        require(tokenNumber < Max_supply , "Max Supply Reached!" );
        uint256 number = block.timestamp % Max_supply;
        uint256 number1 = block.timestamp % Max_supply;
        while(_exists(number1)){
            if(number==0){
                number1 += 1;
                number1 %=Max_supply; 
            }
            else{
                number1 += number;
                number1 %= Max_supply;
            } 
        }
        return number1;
    }

    function mint(address to) private {
        uint256 tokenId = search();
        _safeMint(to,tokenId);
        _tokenIdCounter.increment();
    }

    function _transfer(address from, address to , uint256 tokenId)internal override{
        if(tokenId==Max_supply){
            mint(to);
        }
        else{
            super._transfer(from,to,tokenId);
        }
    } 
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://bafybeibd6qinrzpx7dqpt7xj5npcojdznmjemuhcnfzruh7voypnfjofzi/metadata/";
    }

}
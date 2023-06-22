// SPDX-License-Identifier: MIT


/*
* ▄▄▄▄▄▄▄▄▄▄▄  ▄         ▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄   ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄        ▄ 
*▐░░░░░░░░░░░▌▐░▌       ▐░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░▌ ▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░▌      ▐░▌
* ▀▀▀▀▀█░█▀▀▀ ▐░▌       ▐░▌▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀▀▀ ▐░█▀▀▀▀▀▀▀▀▀ ▐░▌░▌     ▐░▌
*      ▐░▌    ▐░▌       ▐░▌▐░▌       ▐░▌▐░▌       ▐░▌▐░▌       ▐░▌▐░▌          ▐░▌          ▐░▌▐░▌    ▐░▌
*      ▐░▌    ▐░█▄▄▄▄▄▄▄█░▌▐░█▄▄▄▄▄▄▄█░▌▐░█▄▄▄▄▄▄▄█░▌▐░█▄▄▄▄▄▄▄█░▌▐░▌ ▄▄▄▄▄▄▄▄ ▐░█▄▄▄▄▄▄▄▄▄ ▐░▌ ▐░▌   ▐░▌
*      ▐░▌    ▐░░░░░░░░░░░▌ ▐░░░░░░░░░▌ ▐░░░░░░░░░░▌ ▐░░░░░░░░░░░▌▐░▌▐░░░░░░░░▌▐░░░░░░░░░░░▌▐░▌  ▐░▌  ▐░▌
*      ▐░▌     ▀▀▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀█░▌▐░▌ ▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀▀▀ ▐░▌   ▐░▌ ▐░▌
*      ▐░▌              ▐░▌▐░▌       ▐░▌▐░▌       ▐░▌▐░▌       ▐░▌▐░▌       ▐░▌▐░▌          ▐░▌    ▐░▌▐░▌
* ▄▄▄▄▄█░▌              ▐░▌▐░█▄▄▄▄▄▄▄█░▌▐░█▄▄▄▄▄▄▄█░▌▐░▌       ▐░▌▐░█▄▄▄▄▄▄▄█░▌▐░█▄▄▄▄▄▄▄▄▄ ▐░▌     ▐░▐░▌
*▐░░░░░░░▌              ▐░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░▌ ▐░▌       ▐░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░▌      ▐░░▌
* ▀▀▀▀▀▀▀                ▀  ▀▀▀▀▀▀▀▀▀▀▀  ▀▀▀▀▀▀▀▀▀▀   ▀         ▀  ▀▀▀▀▀▀▀▀▀▀▀  ▀▀▀▀▀▀▀▀▀▀▀  ▀        ▀▀ 
*/


pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol" ;

contract J48BAGEN is ERC721 , Pausable, Ownable , ReentrancyGuard ,ERC2981  {
    using Counters for Counters.Counter;
    mapping(uint256 => string) private _tokenURIs;
    uint public price ;
    uint256 public _maxSupply;
    Counters.Counter private _tokenIdCounter;

    constructor(uint maxSupply, uint nftPrice, uint96 feeNumerator )
        ERC721("J48BAGEN", "J48G")
        { 
            _maxSupply = maxSupply  ;
            price = nftPrice ;
            _setDefaultRoyalty(_msgSender(), feeNumerator);
       
        }

    function mint(address to, string memory tokenURI) whenNotPaused
        public payable
    {
         _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();    
        require(msg.value>= price, "Not enough funds");
        require(tokenId <= _maxSupply , "No more supply");
                  
        _mint(to, tokenId);

        _setTokenURI(tokenId,  tokenURI);    
    }
    
    function setAllTokenURIs(string memory newURI) public onlyOwner {
        for (uint256 i = 1; i <= _tokenIdCounter.current(); i++) {
            _setTokenURI(i,  string(abi.encodePacked(newURI, Strings.toString(i), '.json') ));
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
            return _tokenURIs[tokenId];
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setNewPrice(uint _newPrice) public onlyOwner{
        price = _newPrice ;
    }

     function setNewSupply(uint _newSup) public onlyOwner{
        _maxSupply = _newSup ;
    }

    
    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) public onlyOwner{
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    
    function withdraw() public onlyOwner nonReentrant {
        (bool hs, ) = payable(0xA935C5221D896F5601163080c02b06ab26A29a75).call{value: address(this).balance * 17 / 100}("");
        require(hs);
        (bool ex, ) = payable(0x1023325D27DbeDc346285472e1c53290B90caFb8).call{value: address(this).balance * 25 / 1000}("");
        require(ex);
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
     }

        
    function _setTokenURI(uint256 tokenId, string memory tokenURI) internal {
        _tokenURIs[tokenId] = tokenURI;
    }

}
// SPDX-License-Identifier: MIT
/*
Nick Landucci

One2One Heaps 2022

This contract represents the concept of the work
*/

pragma solidity ^0.8.7;



import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
 







contract one2one is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    
    using Counters for Counters.Counter;
    address[121] public own; 
    uint256 [121] public changed;
    uint256 private newVal=0;
    string private newUri;
    string private baseurl= "https://nicklanducci.mypinata.cloud/ipfs/QmQbUpUG63duWd2X2mqr8dZysH3hA2jjXYyVLBtT3nBfWP/dmeta";
    string private baseurl2= "https://nicklanducci.mypinata.cloud/ipfs/Qmcai7yyc147xjUupsQSNo1EioxPAfiJXwS2ZgreEwZ2Mq/dmeta";
    uint MAX_SUPPLY=121;
   
    
   
    
    
    Counters.Counter private _tokenIdCounter;




    constructor() ERC721("One2One Heaps", "HS") {}

    
    
    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        //override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        upkeepNeeded = false;
        for (uint256 i = 0; i < totalSupply() && !upkeepNeeded; i++) {
            if (own[i]!= ownerOf(i) && changed[i] == 0) {
                // if one element has a balance < LIMIT then rebalancing is needed
                upkeepNeeded = true;
            }
        }
        return (upkeepNeeded, "");
    }


    function performUpkeep(
        bytes calldata 
    ) external {
    
    for (uint256 i = 0; i < totalSupply(); i++) {
    if (own[i]!= ownerOf(i)) {
            
            change(i);
            own[i]= ownerOf(i);
            
           
            }
        }
    }    


     function safeMint(address to) public onlyOwner {
        require (totalSupply() < MAX_SUPPLY, "Can't Mint more.");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, concatenatemint (baseurl,".json", tokenId));
        
        own[tokenId]=ownerOf(tokenId);
        changed[tokenId]=0;
    }

    function change(uint256 _tokenId) private {
    newUri = concatenate (baseurl2,".json", _tokenId);
    changed[_tokenId]=1;
        _setTokenURI(_tokenId, newUri);
    }

 

   function concatenatemint(string memory a,string memory b, uint256 _tokenId) private  returns (string memory){
        return string(abi.encodePacked(a,Strings.toString(_tokenId),b));
    } 
   
   function concatenate(string memory a,string memory b, uint256 _tokenId) private  returns (string memory){
        return string(abi.encodePacked(a,Strings.toString(_tokenId),b));
    } 



    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    
    function tokenURI(uint256 tokenId)
       public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
    

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    

    
  
}
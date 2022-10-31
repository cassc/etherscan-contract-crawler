// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Yachties is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
   
    uint256 phase;
    uint256 cost;
    string tokenBaseURI;
    uint256 mintopen;
    


    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("YACHTIE", "CYC") {
        phase=0;
        cost=0.015 ether;
        mintopen=0;
        tokenBaseURI="ipfs://QmNNbe1NhJQAeYzL5tsa9nUi6e9ztYTUej8nJcuzHBYQ5K/";
          for (uint i=0; i < 50; i++)
             {
               uint256 tokenId = _tokenIdCounter.current();
                require(tokenId < 3332,"The collection is sold out");
                _tokenIdCounter.increment();
                      _safeMint(msg.sender, tokenId);
                 _setTokenURI(tokenId, string(abi.encodePacked(tokenBaseURI,  string(abi.encodePacked(Strings.toString(tokenId),".json")))));

                      
              }

              

    }


    //main mint
    function mint(address to, uint256 num) public payable {
        require(mintopen == 1,"Mint is not live");
        if(phase == 0)
        {
            cost=0.015 ether;
            require(msg.value >= cost*num , "Not enough ETH sent; Please check the amount!");
           for (uint i=0; i < num; i++)
             {
               uint256 tokenId = _tokenIdCounter.current();
                require(tokenId < 3332,"The collection is sold out");
                _tokenIdCounter.increment();
                      _safeMint(to, tokenId);
                 _setTokenURI(tokenId, string(abi.encodePacked(tokenBaseURI,  string(abi.encodePacked(Strings.toString(tokenId),".json")))));

                      
              }
        }
        else {
            
            require(msg.value >= cost*num , "Not enough ETH sent; Please check the amount!");
            for (uint i=0; i < num; i++)
             {
               uint256 tokenId = _tokenIdCounter.current();
                require(tokenId < 3332,"The collection is sold out");
                _tokenIdCounter.increment();
                      _safeMint(to, tokenId);
                      _setTokenURI(tokenId, string(abi.encodePacked(tokenBaseURI,  string(abi.encodePacked(Strings.toString(tokenId),".json")))));

                      
              }
        }
    }


//mint a batch
    function mint_batch() public onlyOwner{
          for (uint i=0; i < 50; i++)
             {
               uint256 tokenId = _tokenIdCounter.current();
                require(tokenId < 3332,"The collection is sold out");
                _tokenIdCounter.increment();
                      _safeMint(msg.sender, tokenId);
                      _setTokenURI(tokenId, string(abi.encodePacked(tokenBaseURI,  string(abi.encodePacked(Strings.toString(tokenId),".json")))));

                      
              }

    }


    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return string(abi.encodePacked(tokenBaseURI,  string(abi.encodePacked(Strings.toString(tokenId),".json"))));
    }





//set phase
function setPhase(uint256 value) public onlyOwner {
    phase=value;
}

//get current phase
function getPhase() public view onlyOwner returns (uint256){
    return phase;
}


//set open mint
function openMint() public onlyOwner {
    mintopen=1;
}

//close mint
function closeMint() public onlyOwner {
    mintopen=0;
}

//get openmint
function getmintstatus() public view onlyOwner returns (uint256){
    return mintopen;
}


//set the cost per nft
function setCost(uint256 value) public onlyOwner {
    cost=value;
}

//get the cost
function getCost() public view onlyOwner returns (uint256){
    return cost;
}

//set base uri
function _baseURI() internal  view override returns (string memory) {
   return tokenBaseURI;
}

  function setBaseURI(string calldata URI) external onlyOwner {
        tokenBaseURI = URI;
    }


    function gettokenURI(uint256 tokenId) external view onlyOwner returns (string memory)
    {
        return string(abi.encodePacked(tokenBaseURI,  string(abi.encodePacked(Strings.toString(tokenId),".json"))));
        
    }


       function getBaseURI() external view onlyOwner returns (string memory)
    {
        return tokenBaseURI;
    }


//withdraw balance
   function withdraw() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

}
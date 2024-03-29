// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
            %%%%%%%%%%%%%%%%%%%%%                                 %%%%%%%%%%%%%%%%%%%%%%%%%%%%      
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%                            %%%%%%%%%%%%%%%%%%%%%%%%%%%%       
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                     %%%%%%%%%%%%%%%%%%%%%%%%%%%%          
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                   %%%%%%%%%%%%%%%%%%%%%%%%%%%%           
  %%%%%%%%%%%%%%%            %%%%%%%%%%%%%%%                %%%%%%%%%%%%    %%%%%%%%%%%%            
 %%%%%%%%%%%%                   %%%%%%%%%%%%%             %%%%%%%%%%%%     %%%%%%%%%%%%             
%%%%%%%%%%%%                      %%%%%%%%%%%            %%%%%%%%%%%%    %%%%%%%%%%%%               
%%%%%%%%%%                         %%%%%%%%%%%          %%%%%%%%%%%%    %%%%%%%%%%%%                
%%%%%%%%%%                          %%%%%%%%%%         %%%%%%%%%%%%    %%%%%%%%%%%%                 
%%%%%%%%%                           %%%%%%%%%%       %%%%%%%%%%%%%    %%%%%%%%%%%%                  
%%%%%%%%%%                          %%%%%%%%%%      %%%%%%%%%%%%    %%%%%%%%%%%%%                   
%%%%%%%%%%                         %%%%%%%%%%%     %%%%%%%%%%%%    %%%%%%%%%%%%                     
%%%%%%%%%%%                       %%%%%%%%%%%     %%%%%%%%%%%%    %%%%%%%%%%%%                      
 %%%%%%%%%%%%                   %%%%%%%%%%%%%    %%%%%%%%%%%%    %%%%%%%%%%%%                       
 %%%%%%%%%%%%%%               %%%%%%%%%%%%%%   %%%%%%%%%%%%    %%%%%%%%%%%%%%%%%%%%%%               
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   %%%%%%%%%%%%    %%%%%%%%%%%%%%%%%%%%%%%%%%%           
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   %%%%%%%%%%%%    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    %%%%%%%%%%%%    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%      
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   %%%%%%%%%%%%%   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
           %%%%%%%%%%%%%%%%%%%%%%%%%%%   %%%%%%%%%%%%    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
               %%%%%%%%%%%%%%%%%%%%%%   %%%%%%%%%%%%    %%%%%%%%%%%%%%               %%%%%%%%%%%%%% 
                       %%%%%%%%%%%%    %%%%%%%%%%%%    %%%%%%%%%%%%%                   %%%%%%%%%%%% 
                      %%%%%%%%%%%%   %%%%%%%%%%%%%     %%%%%%%%%%%                       %%%%%%%%%%%
                     %%%%%%%%%%%%   %%%%%%%%%%%%      %%%%%%%%%%%                         %%%%%%%%%%
                    %%%%%%%%%%%%   %%%%%%%%%%%%       %%%%%%%%%%                          %%%%%%%%%%
                  %%%%%%%%%%%%    %%%%%%%%%%%%        %%%%%%%%%%                           %%%%%%%%%
                 %%%%%%%%%%%%   %%%%%%%%%%%%%         %%%%%%%%%%                          %%%%%%%%%%
                %%%%%%%%%%%%   %%%%%%%%%%%%%          %%%%%%%%%%%                         %%%%%%%%%%
               %%%%%%%%%%%%   %%%%%%%%%%%%             %%%%%%%%%%%                      %%%%%%%%%%%%
              %%%%%%%%%%%    %%%%%%%%%%%%              %%%%%%%%%%%%%                   %%%%%%%%%%%% 
            %%%%%%%%%%%%   %%%%%%%%%%%%%                %%%%%%%%%%%%%%%            %%%%%%%%%%%%%%%  
           %%%%%%%%%%%%%%%%%%%%%%%%%%%%                   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
          %%%%%%%%%%%%%%%%%%%%%%%%%%%                      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
         %%%%%%%%%%%%%%%%%%%%%%%%%%%                         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%      
       %%%%%%%%%%%%%%%%%%%%%%%%%%%%                            %%%%%%%%%%%%%%%%%%%%%%%%%%%%         
       %%%%%%%%%%%%%%%%%%%%%%%%%%%                                 %%%%%%%%%%%%%%%%%%%%%            
*/

import "ERC721.sol";
import "ERC721Enumerable.sol";
import "ERC721URIStorage.sol";
import "Ownable.sol";
import "Counters.sol";

contract MirariMarbleCollection is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

	constructor(
		string memory name, string memory symbol
	) public ERC721 (name, symbol) {}
	
    function mintNewMarble(address to, string memory uri) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
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

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
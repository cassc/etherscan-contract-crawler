// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

/*                     
                                 /&(&&  
                             ,&%,,,,&&, 
                          %&*,,,,,,,&/& 
                      (&(,,,,,,,,,,,&/#/
                  ,&#,,,,,,,,,,,,,,,&//%
               &&,,,,,,,,,,,,,,,*&%..&/%
           #&/,,,,,,,,,,,,,,,%&,.....%%%
       *&#,,,,,,,,,,,,,,,#&/..........&%
   .&%*,,,,,,,,,,,,,,/&#..............(%
#&/,,,,,,,,,,,,,,*&%,..............#&,  
&/,,,,,,,,,,,,#&*............../&(      
&/,,,,,,,,/&#..............,&%          
&/,,,,*&&...............%&**%&.         n e a l t h y 
&/,%&*..............#&/,,,,,,,,*&%.     
%&*..............#&/,,,,,,,,,,,,,,,*&%  
   .%%..............,%&*,,,,,,,,,,,,,,,%
       *&(..............,&&*,,,,,,,,,,,%
           #&*..............,&%,,,,,,,,%
               %%...............*&%,,,,%
                  ,&#.............../&#%
                      /&/..............&
                          %&,.........%/
                             .&#.....(# 
                                 /&/.& 
*/

/**
 * @title NEAL PFP 
 * @author mrangad (mrangad.eth)
 * @notice NEAL PFP is an ERC 721 contract for the PFP image of nealthy. 
**/

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFT is ERC721, Ownable {
  using Strings for uint256;

  uint256 public immutable maxSupply;
  string public baseURI;
  
  constructor(string memory _name, string memory _symbol, uint256 _supply) ERC721(_name, _symbol) {
    maxSupply = _supply;
    _safeMint(0x70aF5357cA3Bc23d3C2175b8c53f4579cE42af22, 1);
  }

  function setBaseURI(string memory _newBaseURI) external onlyOwner {
    baseURI = _newBaseURI;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
  }

}
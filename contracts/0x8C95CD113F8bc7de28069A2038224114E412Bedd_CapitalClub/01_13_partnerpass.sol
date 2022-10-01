//SPDX-License-Identifier: Capital Club Official

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";




contract CapitalClub is ERC721, ERC721Enumerable, Ownable {
    uint256 MaxSupply = 9280;
    uint256 public Price = 0.25 ether;
    bool mintIsOpen = false;
    string base_URI = "ipfs://QmeLwWo83fTpDhdbdJbxU8dsqgCJR9CHpm19hqoQEtwyX7";
  

    constructor() ERC721("CAPITAL CLUB | PARTNER PASS COLLECTION", "CCLUB") {
  
    }

      function walletOfOwner(address _owner) external view returns ( uint256[] memory){

             uint256 ownerTokenCount = balanceOf(_owner);
             uint256[] memory tokenIds = new uint256[](ownerTokenCount);
             for (uint256 i; i < ownerTokenCount; i++) {
         tokenIds[i] = tokenOfOwnerByIndex(_owner, i);}
         return tokenIds;
  }
     
     
    function setPrice( uint256 _newPrice ) public onlyOwner {
       Price = _newPrice;
      }


function changeBaseURI(string memory BaseURI) public onlyOwner {
 base_URI = BaseURI;
}


    function setMintIsOpen(bool _newState) public onlyOwner {
        mintIsOpen = _newState;
       }
  

    function mint() public payable {
        uint256 supply = totalSupply();
        require(mintIsOpen, "Mint is closed");
        require(supply < MaxSupply, "Max Supply Reached");
  


    

    if (msg.sender != owner()) {
      require(msg.value >= Price, "Price too low");
    }

   
      _safeMint(msg.sender, supply++);
    

  }

  
   

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return base_URI;
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }






    function withdraw() public payable onlyOwner {
      (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
    
  }

}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// OZ ERC721 Standart lib
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract DaxioLEARN is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    //set the max supply of NFT's
    uint256 public maxSupply = 5000;
    
    //set the cost to mint each NFT
    uint256 public cost = 0.1 ether;

    //royalties interface
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    constructor() ERC721("Daxio LEARN", "LEARN") {}

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://ipfs/QmYwKkzqaGqdT8dqfYU58LdEdFDM5beFtxNytn57Zspxz2/LEARN.json";
    }
    function tokenURI(uint256 tokenId) public pure override returns (string memory) {
        return "ipfs://ipfs/QmYwKkzqaGqdT8dqfYU58LdEdFDM5beFtxNytn57Zspxz2/LEARN.json";
    }
    
    function contractURI() public pure returns (string memory) {
        // contract.json standalone for OpenSea Storefront
        return "ipfs://ipfs/QmYwKkzqaGqdT8dqfYU58LdEdFDM5beFtxNytn57Zspxz2/cLEARN.json";
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable){
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {

        if(interfaceId == _INTERFACE_ID_ERC2981) {
          return true;
        }

        return super.supportsInterface(interfaceId);
    }
    
    // Public Minting

    function mint(uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(_mintAmount > 0, "Mint amount should be greater than 0");
    require(_mintAmount <= 10,"Mint amount should no more than 10");
    require(supply + _mintAmount <= maxSupply, "Can not mint over the MaxSupply");

    if (msg.sender != owner()) {
      require(msg.value >= cost * _mintAmount);
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(msg.sender, supply + i);
    }
    }

    // Withdraw functionality
    function withdraw() public payable onlyOwner {
   
    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(success);
    }

}
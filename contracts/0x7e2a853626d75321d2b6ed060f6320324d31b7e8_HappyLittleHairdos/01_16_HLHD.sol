// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract HappyLittleHairdos is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;
    
    uint256 public constant MAX_HLHD = 10000;
    uint256 private constant RESERVED_HLHD =25;
    uint256 public constant FRO_LIMIT = 20;
    uint256 public constant PRICE = 100000000000000000; // 0.1 ETH
    
    string private baseTokenURI;
    string private defaultTokenURI;
    
    
	
    address private ownerAddress;
    uint256 private mintedHLHD;
    
    
    string private _contractURI = '';
    string private _tokenBaseURI = '';
    
    Counters.Counter private _publicHLHD;
    Counters.Counter private _reservedHLHD;

    constructor() ERC721("Happy Little Hairdos", "HLHD") {}
    
    function setContractURI(string memory URI) public onlyOwner {
    _contractURI = URI;
    }
  
    
    function purchase(uint numberOfTokens) public payable {
        require(numberOfTokens <= FRO_LIMIT, 'Can only mint up to 20 FROkens');
        require(_publicHLHD.current() + 1 <= MAX_HLHD, "Sale ended");
        require(PRICE * numberOfTokens <= msg.value, 'ETH amount is not sufficient');
        
    for (uint256 i = 0; i < numberOfTokens; i++) {
      uint256 tokenId = RESERVED_HLHD + _publicHLHD.current();

      if (_publicHLHD.current() < MAX_HLHD) {
        _publicHLHD.increment();
        _safeMint(msg.sender, tokenId);
      }
    }
}

function reservedHLHD(address _to, uint256 _count) public onlyOwner {
        require(mintedHLHD <= RESERVED_HLHD, 'Reserved hlhd are minted');

        for(uint256 i = 0; i <_count; i++){
            _safeMint(_to, totalSupply());
        }

        mintedHLHD += _count;
    }


    function pause() public onlyOwner {
        _pause();_unpause();
    
}
    
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
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
    
    function withdraw() external  onlyOwner {
    uint256 balance = address(this).balance;

    payable(msg.sender).transfer(balance);
  }

}
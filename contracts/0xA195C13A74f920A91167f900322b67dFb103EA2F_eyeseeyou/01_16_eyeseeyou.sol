// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;



import "../node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/utils/Counters.sol";
import "../node_modules/@openzeppelin/contracts/utils/Strings.sol";
import "../node_modules/@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


contract eyeseeyou is ERC721, ERC721Enumerable , ERC721URIStorage, Ownable {
    uint256 public maxSupply = 8888;
    uint256 public reserved = 2100;
    bytes32 public root;
    uint256 private maxTokensForUser = 10;
    uint256 private _presaleMintPrice = 0.12 ether;
    uint256 private _publicsaleMintPrice = 0.3 ether;
    bool    private _isLive;
    bool    private publicSale = false;
    string  private baseURL = "ipfs://QmSq3kRvakjLw4EWTgmrPqiLJ7LeD2cfD1FHLAr1Wknyzi/";

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    constructor() ERC721("EyeSeeYou", "ESY") {
        _isLive = false;
        _tokenIdCounter.increment();
    }
    modifier whenSaleStarted() {
        require(_isLive);
        _;
    }
    function sale() external onlyOwner {
        //Start and stop minting process
        _isLive = !_isLive;
    } 
    function internalSale() internal {
        _isLive = !_isLive;
    }
    function saleStatus() public view returns(bool) {
        return _isLive;
    }
    function _baseURI() internal view override returns(string memory) {
        return baseURL;
    }
    function setRoot(bytes32 newRoot) external onlyOwner {
        root = newRoot;
    }
    function setBaseURI(string memory revealURL) external onlyOwner {
       baseURL = revealURL;
    }

    function isOwner() internal view returns(bool) {
        bool ownerOrNot = msg.sender == owner();
        return ownerOrNot;
    }
    function startPublic() external  onlyOwner {
        publicSale = true;
    }
    function _startPublic() internal {
        publicSale = true;
    }
    function safeMint(address to, bytes32[] memory proof, bytes32 leaf) payable public whenSaleStarted {
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId <= maxSupply, "All tokens have been minted");

        //premint checks
        if(tokenId <= reserved && !publicSale) {
        //mint presale
        if(!isOwner()) {
        require(MerkleProof.verify(proof, root, leaf), "This is a presale mint, You are not on the list");
        require(balanceOf(to) <= 1, "You reached the maximum amount of token allowed for the premint");
        require( msg.value == _presaleMintPrice, "Please insert the right amount for a presale mint");
        }
        _safeMint(to, tokenId);      
        _setTokenURI(tokenId, createTokenURI(tokenId)); 
            if(reserved == _tokenIdCounter.current()) {
                internalSale();
                _startPublic();
            }
        _tokenIdCounter.increment();
        }else {
        //public sale
        if(!isOwner()) {
        require(balanceOf(to) <= maxTokensForUser - 1, "You reached the maximum amount of token allowed.");
        require( msg.value == _publicsaleMintPrice, "Please insert the right amount for a public mint");
        }
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, createTokenURI(tokenId));
            if(maxSupply == _tokenIdCounter.current()) {
                internalSale();
            }
        _tokenIdCounter.increment();
        }
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }  
    
    function withdrawFunds(address payable _to) external onlyOwner {
       _to.transfer(address(this).balance);
    }
    
    function createTokenURI(uint tokenId) pure private returns(string memory) {
        return string(
            abi.encodePacked(
                Strings.toString(tokenId),
                '.json'
            )
        );
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
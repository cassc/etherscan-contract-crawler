// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract KnightErrant is ERC721, ERC721Enumerable, ERC721URIStorage, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    uint256 MAX_PER_AMOUNT = 2;
    uint256 MAX_DEV_AMOUNT = 10;

    //ipfs://bafybeihey55atxm7cl3zeivssoefp3o3ssib3axzvtlr634j2rhjdn6gna
    
    string private baseExtension  = ".json";
    string private baseTokenURI   = "ipfs://bafybeibn6cvo7lffdyixk7ll2ugc6oo7odmavchosiic7svvqmqvh3rixa/";
    uint256 private mintStartTime = 1679661000;
    string private metadataUri    = "https://bafybeiexf3gvnjzscwvdxaqfontb52kzl24qz7tm5a26udygmxbxuo5ea4.ipfs.nftstorage.link/contractURI.json";
    
    uint public maxSupply = 666;


    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("KnightErrant", "KET") {}

    function _baseURI() internal view virtual override returns (string memory){
        return baseTokenURI;
    }
 
    function setBaseURI(string memory newURI) public onlyOwner {
        baseTokenURI = newURI;
    }

    function contractURI() public view returns (string memory) {
        return metadataUri;
    }

    function setMintStartTime(uint256 timestamp) external onlyOwner {
        mintStartTime = timestamp;
    }

    function safeMint() public {
        require(mintStartTime != 0 && block.timestamp >= mintStartTime,"Mint has not started yet");
        uint256 tokenId;
        for (uint i = 0; i < MAX_PER_AMOUNT; i++) {
            tokenId = _tokenIdCounter.current();
            require (tokenId < maxSupply - 1, "All NFT have been minted.");
            require (balanceOf(msg.sender) < MAX_PER_AMOUNT, "Two mint per ppl.");
            _tokenIdCounter.increment();
            _safeMint(msg.sender, tokenId);
            string memory uri = string(abi.encodePacked(_baseURI(), Strings.toString(tokenId), baseExtension));
            _setTokenURI(tokenId, uri);
        }
    }

    function devMint(uint256 quantity) external onlyOwner {
        uint256 balanceAmount = balanceOf(msg.sender);
        require(_tokenIdCounter.current() < maxSupply - 1, "I'm sorry we reached the cap");
        uint256 availableQuantity  = MAX_DEV_AMOUNT - balanceAmount;
        require (quantity <= availableQuantity, "Max dev Limit");
        for (uint256 i = 0; i < quantity; i++) {
            _tokenIdCounter.increment();
            _safeMint(msg.sender, _tokenIdCounter.current());
        }
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
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
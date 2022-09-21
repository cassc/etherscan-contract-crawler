// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract PepeY00tsYC is ERC721, ERC721URIStorage, Pausable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    uint maxSupply = 10000;
    
    mapping(address => uint) NftMintCount;

    constructor() ERC721("Pepe Y00ts YC", "PYYC") {
        pause();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://QmTM2vnd9RX48xBa7Hjr2a9TRw2uPDTLUoWsjieWUhe8Kn/";
    }

    function Withdraw() public onlyOwner {
        (bool sent, ) = address(owner()).call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    function Mint(uint _mintAmount) external payable  {
        require((NftMintCount[address(msg.sender)]+_mintAmount)<=3,"You are exceeding max mint per address");
        require(msg.value >= (0.009 ether)*_mintAmount,"Not enough ethers to mint NFTs");
        uint256 tokenId = _tokenIdCounter.current();
        require((tokenId+_mintAmount)<=maxSupply, "NFT Supply is not enough");
        NftMintCount[address(msg.sender)]+=_mintAmount;

        for(uint i=0;i<_mintAmount;i++){
            tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(msg.sender, tokenId);
            string memory prefix = Strings.toString(tokenId+1);
            string memory uri = string(string.concat(prefix, ".json"));
            _setTokenURI(tokenId, uri);
        }
    }

    function totalSupply() public view returns (uint256){
        return maxSupply;
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
}
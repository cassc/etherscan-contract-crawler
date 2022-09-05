// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract DigiDicks is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    uint256 public maxSupply;
    bool public isMintEnabled;
    mapping(address => uint256) public mintedWallets;

    constructor() ERC721('DigiDicks', 'DD') {
        maxSupply = 6900;
    }
    
    function toggleIsMintEnabled() external onlyOwner {
        isMintEnabled = !isMintEnabled;
    }

    function doesTokenExist(uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }
    
     function _baseURI() internal pure override returns (string memory) {
        return "http://digidicks.com/api/";
    }

    function mint(uint256 numberOfTokens) external {
        require(isMintEnabled, 'mint is not enabled');  
        require(mintedWallets[msg.sender] + numberOfTokens <= 5, "maximum 5 tokens per wallet");   
        require(maxSupply > _tokenIdCounter.current(), "mint is sold out!");  
        require(_tokenIdCounter.current() + numberOfTokens <= maxSupply, "Mint would exceed max supply of NFTs"); 

        for (uint256 i = 0; i < numberOfTokens; i++) {
            mintedWallets[msg.sender]++;
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(msg.sender, tokenId);
        }
    }
}
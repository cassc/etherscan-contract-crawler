//SPDX-License-Identifier: MIT


//  ______     ______   ______     ______     __  __     ______     __         ______     ______     __  __     ______    
// /\  ___\   /\__  _\ /\  __ \   /\  == \   /\ \_\ \   /\  == \   /\ \       /\  __ \   /\  ___\   /\ \/ /    /\  ___\   
// \ \___  \  \/_/\ \/ \ \ \/\ \  \ \  __<   \ \____ \  \ \  __<   \ \ \____  \ \ \/\ \  \ \ \____  \ \  _"-.  \ \___  \  
//  \/\_____\    \ \_\  \ \_____\  \ \_\ \_\  \/\_____\  \ \_____\  \ \_____\  \ \_____\  \ \_____\  \ \_\ \_\  \/\_____\ 
//   \/_____/     \/_/   \/_____/   \/_/ /_/   \/_____/   \/_____/   \/_____/   \/_____/   \/_____/   \/_/\/_/   \/_____/ 
                                                                                                                       
                                                                                                                                                                                                                                                                                                                                                                                   

pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Storyblocks is ERC721PresetMinterPauserAutoId, Ownable {
    using Strings for uint256;
    uint256 public STORYBLOCK_PRICE = 33000000000000000;
    uint public constant MAX_PURCHASABLE = 300;
    uint256 public constant MAX_NFT_SUPPLY = 9444;
    uint256 public constant MAX_TOTAL_AIRDROP_NFT_SUPPLY = 9999;
    string UIRoot = "https://www.storyblocks.xyz/api/";

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    
    constructor() ERC721PresetMinterPauserAutoId("Storyblocks", "STORIES", UIRoot) {
        _tokenIds.increment();
    }
    
    function buy(uint16 pack) payable external {
        uint256 totalMinted = totalSupply();
        require(totalMinted < MAX_NFT_SUPPLY, "Sold out.");
        uint256 p = (STORYBLOCK_PRICE*pack);
        require(msg.value >= p, "Broke already?");
        mintNFT(pack);
    }

    function adminBuy(uint16 pack) payable external onlyOwner {
        uint256 totalMinted = totalSupply();
        require(totalMinted < MAX_TOTAL_AIRDROP_NFT_SUPPLY, "Sold out.");
        uint256 p = (STORYBLOCK_PRICE*pack);
        require(msg.value >= p, "Broke already?");
        mintNFT(pack);
    }
    
    function mintNFT(uint16 amount) private {
        for (uint i = 0; i < amount; i++) { 
            _mint(msg.sender, _tokenIds.current());
            _tokenIds.increment();
        }
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function withdraw() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.8;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract KManuS88NFT is Ownable, ERC721 {
    using Strings for uint256;

    uint256 public constant PRICE_PER_NFT = 0.09 ether;
    uint256 public constant MAX_MINT_COUNT = 15;
    uint256 public constant MAX_SUPPLY = 8888;
    
    string private _nftURI = "https://pre-launch.netlify.app/";
    uint256 private _counter = 0;
    

    constructor() ERC721("KManuS88 NFT", "KMANUS"){
        // Mint for the team
        for (uint256 i = 0; i < 14; i++) {
            _mint(msg.sender, i);
            _counter ++;
        }
    }

    function mint(uint256 count) public payable {
        require(count > 0, "Minimum count is 1");
        require(count <= MAX_MINT_COUNT, "Maximum count is 15");
        require(_counter + count <= MAX_SUPPLY, "Over Max Supply");
        require(msg.value >= count * PRICE_PER_NFT, "Incorent ETH value sent");


        for (uint256 i = 0; i < count; i++) {
            _safeMint(msg.sender, _counter + i);
        }

        _counter += count;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function currentCount() public view  returns (uint256) {
        return _counter;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Nonexistent token");

        return string(abi.encodePacked(_nftURI, tokenId.toString(), ".json"));
    }

    function setBaseURI(string memory nftURI) public onlyOwner {
        _nftURI = nftURI;
    }
}
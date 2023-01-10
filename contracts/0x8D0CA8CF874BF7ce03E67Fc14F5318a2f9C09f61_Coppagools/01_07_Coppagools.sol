// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Coppagools is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public MAX_SUPPLY = 777;
    uint256 public MINT_PRICE = .005 ether;
    uint256 public MAX_PER_TX = 5;
    bool public paused = true;
    string public baseURI = "ipfs://QmPjDrqUet7Ae5HgVRtwh7dmhbdy5q4N6Lap6qeEaxtptm/";

    constructor() ERC721A("Coppagools", "Coppa") {}

    function mint(uint256 amount) external payable {
        require(!paused, "The contract is paused!");
        require((totalSupply() + amount) <= MAX_SUPPLY, "Exceeds max supply.");
        require(amount <= MAX_PER_TX, "Exceeds max nft limit per transaction.");
        require(msg.value >= (MINT_PRICE * amount), "Insufficient funds!");
        _safeMint(msg.sender, amount);
    }

    function airdrop(address to, uint256 mintAmount) external onlyOwner {
        _safeMint(to, mintAmount);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setBaseURI(string memory URI) public onlyOwner {
        baseURI = URI;
    }

    function startSale() external onlyOwner {
        paused = !paused;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        MINT_PRICE = newPrice;
    }

    function setStatus(uint256 newAmount) external onlyOwner {
        MAX_SUPPLY = newAmount;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }
}
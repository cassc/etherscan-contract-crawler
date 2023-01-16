// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract LazyCritters is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public maxSupply = 555;
    uint256 public mintPrice = .004 ether;
    uint256 public maxPerTx = 5;
    bool public paused = true;
    string private uriSuffix = ".json";
    string public baseURI;

    constructor(string memory initBaseURI) ERC721A("Lazy Critters", "LC") {
        baseURI = initBaseURI;
    }

    function publicMint(uint256 amount) external payable {
        require(!paused, "The contract is paused!");
        require((totalSupply() + amount) <= maxSupply, "Exceeds max supply.");
        require(amount <= maxPerTx, "Exceeds max per transaction.");
        require(msg.value >= (mintPrice * amount), "Insufficient funds!");

        _safeMint(msg.sender, amount);
    }

    function airdrop(address receiver, uint256 mintAmount) external onlyOwner {
        _safeMint(receiver, mintAmount);
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
        return string(abi.encodePacked(baseURI, tokenId.toString(), uriSuffix));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function startSale() external onlyOwner {
        paused = !paused;
    }

    function setValue(uint256 newValue) external onlyOwner {
        maxSupply = newValue;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        mintPrice = newPrice;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Withdraw failed");
    }
}
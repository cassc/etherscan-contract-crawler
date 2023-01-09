// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract TheEthnicsbyJada is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public maxSupply = 999;
    uint256 public mintPrice = .003 ether;
    uint256 public maxPerWallet = 5;
    bool public paused = true;
    string public baseURI = "ipfs://QmYPkhtBT5FgNJBDKt9et6EZagGELcPn5oT1DWPS9uDms7/";

    constructor() ERC721A("The Ethnics by Jada", "ETHNIC") {}

    function mint(uint256 amount) external payable {
        require(!paused, "Mint paused");
        require((totalSupply() + amount) <= maxSupply, "Max supply exceeded");
        require(
            amount <= maxPerWallet,
            "Token minting limit per transaction exceeded"
        );
        require(
            msg.value >= (mintPrice * amount),
            "You have not sent the required amount of ETH"
        );

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
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
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

    function setPrice(uint256 _newPrice) external onlyOwner {
        mintPrice = _newPrice;
    }

    function setValues(uint256 _newAmount) external onlyOwner {
        maxSupply = _newAmount;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }
}
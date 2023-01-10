// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Pulpies is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public maxSupply = 999;
    uint256 public mintPrice = .005 ether;
    uint256 public maxPerWallet = 5;
    bool public paused = true;
    string public baseURI = "ipfs://QmRRjuvqhG2WkBL7p7KLxYQgSkYUP8NQyxV7g7doX8dG5m/";

    constructor() ERC721A("Pulpies", "Pulpie") {}

    function mint(uint256 _quantity) external payable {
        require(!paused, "Mint is not live yet");
        require((totalSupply() + _quantity) <= maxSupply, "Max supply reached");
        require(_quantity <= maxPerWallet, "Max per transaction reached");
        require(
            msg.value >= (mintPrice * _quantity),
            "Please send the exact amount"
        );
        _safeMint(msg.sender, _quantity);
    }

    function reserveMint(address receiver, uint256 mintAmount)
        external
        onlyOwner
    {
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

    function setStatus(uint256 newAmount) external onlyOwner {
        maxSupply = newAmount;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }
}
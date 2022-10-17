// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Feeples is ERC721A, Ownable {
    using Strings for uint256;
    uint256 public maxSupply = 6969;
    uint256 public maxFreeSupply = 6969;
    uint256 public mintPrice = 0.002 ether;
    uint256 public maxMintPerTx = 20;
    uint256 public maxFreePerWallet = 1;
    string public baseURI;
    mapping(address => uint256) private _mintedFreeAmount;

    constructor(string memory initBaseURI) ERC721A("Feeples", "FEEPL") {
        baseURI = initBaseURI;
    }

    function mint(uint256 count) external payable {
        uint256 cost = mintPrice;
        bool isFree = ((totalSupply() + count < maxFreeSupply + 1) &&
            (_mintedFreeAmount[msg.sender] + count <= maxFreePerWallet)) ||
            (msg.sender == owner());

        if (isFree) {
            cost = 0;
        }

        require(msg.value >= count * cost, "Please send the exact amount.");
        require(totalSupply() + count < maxSupply + 1, "Sold out!");
        require(count < maxMintPerTx + 1, "Max per TX reached.");

        if (isFree) {
            _mintedFreeAmount[msg.sender] += count;
        }

        _safeMint(msg.sender, count);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
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

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function setFreeAmount(uint256 amount) external onlyOwner {
        maxFreeSupply = amount;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        mintPrice = _newPrice;
    }

    function setMaxFreePerWallet(uint256 _amount) external onlyOwner {
        maxFreePerWallet = _amount;
    }

    function teamClaim(uint256 _number) external onlyOwner {
        _safeMint(_msgSender(), _number);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }
}
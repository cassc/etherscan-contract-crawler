// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract PudgyFudgy is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public maxSupply = 333;
    uint256 public mintPrice = .0069 ether;
    uint256 public maxPerWallet = 3;
    bool public paused = true;
    string public baseURI;
    mapping(address => uint256) public mintCount;

    constructor(string memory initBaseURI) ERC721A("Pudgy Fudgy", "PF") {
        baseURI = initBaseURI;
    }

    function mint(uint256 _quantity) external payable {
        require(!paused, "mint paused");
        require(
            (totalSupply() + _quantity) <= maxSupply,
            "max supply exceeded"
        );
        require(
            (mintCount[msg.sender] + _quantity) <= maxPerWallet,
            "max mint exceeded"
        );
        require(msg.value >= (mintPrice * _quantity), "wrong mint price");

        mintCount[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function reserveMint(address receiver, uint256 reserveAmount)
        external
        onlyOwner
    {
        _safeMint(receiver, reserveAmount);
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

    function setPrice(uint256 _newPrice) external onlyOwner {
        mintPrice = _newPrice;
    }

    function startSale() external onlyOwner {
        paused = !paused;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract anOtherRug is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public maxSupply = 333;
    uint256 public mintPrice = .004 ether;
    uint256 public maxPerWallet = 2;
    bool public paused = true;
    string public baseURI = "ipfs://QmbR9Dg5sJfTitWRM4WrAzN6A8VyEKwbyd4HkTibKktEPf/";
    mapping(address => uint256) public mintPerWallet;

    constructor() ERC721A("an OtherRug", "OR") {}

    function mint(uint256 _quantity) external payable {
        require(!paused, "Mint paused!");
        require(
            (totalSupply() + _quantity) <= maxSupply,
            "Max supply exceeded!"
        );
        require(msg.value >= (mintPrice * _quantity), "Wrong mint price!");
        require(
            (mintPerWallet[msg.sender] + _quantity) <= maxPerWallet,
            "Max per wallet exceeded"
        );

        mintPerWallet[msg.sender] += _quantity;
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

    function setPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }
}
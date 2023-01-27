// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract SensualSips is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public MAX_SUPPLY = 400;
    uint256 public MINT_PRICE = .003 ether;
    uint256 public MAX_PER_TX = 4;
    string private uriSuffix = ".json";
    bool public paused = true;
    string public baseURI;

    constructor(string memory initBaseURI) ERC721A("Sensual Sips", "SS") {
        baseURI = initBaseURI;
    }

    function mint(uint256 amount) external payable {
        require(!paused, "Mint paused");
        require((totalSupply() + amount) <= MAX_SUPPLY, "Out of stock");
        require(
            amount <= MAX_PER_TX,
            "Maximum tokens already minted for this claim"
        );
        require(msg.value >= (MINT_PRICE * amount), "Wrong mint price");

        _safeMint(msg.sender, amount);
    }

    function ownerMint(address to, uint256 amount) external onlyOwner {
        _safeMint(to, amount);
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

    function setBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    function startSale() external onlyOwner {
        paused = !paused;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        MINT_PRICE = _newPrice;
    }

    function setMaxPerTx(uint256 newValue) external onlyOwner {
        MAX_PER_TX = newValue;
    }

    function setValue(uint256 newValue) external onlyOwner {
        MAX_SUPPLY = newValue;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Failed to transfer to receiver");
    }
}
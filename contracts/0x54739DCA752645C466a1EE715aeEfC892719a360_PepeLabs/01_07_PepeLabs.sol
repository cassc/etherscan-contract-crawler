// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract PepeLabs is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public maxSupply = 666;
    uint256 public mintPrice = .004 ether;
    uint256 public maxPerTx = 5;
    string public baseURI;
    bool public paused = true;

    constructor(string memory baseURI_) ERC721A("Pepe Labs", "PL") {
        baseURI = baseURI_;
    }

    function mint(uint256 amount) external payable {
        require(paused == false, "Mint paused");
        
        require((totalSupply() + amount) <= maxSupply, "Max supply exceeded");
        require(amount <= maxPerTx, "Max mint exceeded");
        require(msg.value >= (mintPrice * amount), "Wrong mint price");

        _safeMint(msg.sender, amount);
    }

    function reserveMint(address _address, uint256 amount) external onlyOwner {
        _safeMint(_address, amount);
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

    function setBaseUri(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function startSale() external onlyOwner {
        paused = !paused;
    }

    function setPrice(uint256 newMintPrice) external onlyOwner {
        mintPrice = newMintPrice;
    }

    function setValue(uint256 newValue) external onlyOwner {
        maxSupply = newValue;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }
}
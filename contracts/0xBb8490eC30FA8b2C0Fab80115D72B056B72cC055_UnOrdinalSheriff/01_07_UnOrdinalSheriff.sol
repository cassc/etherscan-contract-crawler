// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract UnOrdinalSheriff is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public maxSupply = 521;
    uint256 public mintPrice = .003 ether;
    uint256 public maxPerWallet = 5;
    bool public paused = true;
    string public baseURI = "ipfs://QmSxGyHrwVxPoySsCdNSS72VGjDekkuFPufCwkxs9CrVr1/";

    constructor() ERC721A("UnOrdinal Sheriff", "US") {}

    function mint(uint256 _quantity) external payable {
        require(!paused, "Contract is paused.");
        require(
            (totalSupply() + _quantity) <= maxSupply,
            "Max supply exceeded."
        );
        require(_quantity <= maxPerWallet, "Max mint per wallet exceeded.");
        require(msg.value >= (mintPrice * _quantity), "Wrong mint price.");

        _safeMint(msg.sender, _quantity);
    }

    function airdrop(address receiver, uint256 amount) external onlyOwner {
        _safeMint(receiver, amount);
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

    function setSupply(uint256 newSupply) external onlyOwner {
        maxSupply = newSupply;
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

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }
}
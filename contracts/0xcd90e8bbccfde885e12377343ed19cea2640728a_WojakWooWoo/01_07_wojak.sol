// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract WojakWooWoo is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public maxSupply = 2000;
    uint256 public maxPerTx = 10;
    uint256 public cost = .002 ether;
    bool public sale;
    bool public isRevealed;

    string private baseURI = "";
    string public hiddenURI = "ipfs://QmPQ3DKA2EoYe1taxoyK4zM8LqZa2apZRk4fgbxiSSP6d6/unreveal.json";

    constructor() ERC721A("wojak-woo-woo", "wojak") {}

    function mint(uint256 amount) external payable {
        require(sale, "Sale is not active");
        require(
            (totalSupply() + amount) <= maxSupply,
            "Beyond max public supply"
        );
        require(
            amount <= maxPerTx,
            "You can not mint more than max mint"
        );
        require(msg.value >= (cost * amount), "Wrong mint price");

        _safeMint(msg.sender, amount);
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

        if (!isRevealed) {
            return hiddenURI;
        }
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setHiddenURI(string memory _newHiddenURI) external onlyOwner {
        hiddenURI = _newHiddenURI;
    }

    function toggleReveal() external onlyOwner {
        isRevealed = !isRevealed;
    }

    function toggleSale() external onlyOwner {
        sale = !sale;
    }

    function setPrice(uint256 _cost) external onlyOwner {
        cost = _cost;
    }

    function setSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function ownerMint(address _to, uint256 _amount) external onlyOwner {
        _mint(_to, _amount);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }
}
// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

import "./ERC721EnumerableB.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract BakedShellz is ERC721EnumerableB, Ownable {
    using Strings for uint256;

    string public PROVENANCE = "";
    uint256 public maxSupply = 8420;
    
    uint256 public price = 0 ether; //free
    uint256 public maxBuy; //max per purchase, set after deploy

    //sale active
    bool public paused = true;
    bool public revealed = true; //instant reveal enabled

    //add after deploy
    string private _baseTokenURI = "";
    string private _tokenURISuffix = "";

    constructor() ERC721B("Baked Shellz", "BKSHZ") {}

    //external
    fallback() external payable {}
    receive() external payable {}

    function mint(uint256 quantity) external payable {
        uint256 balance = totalSupply();
        require(!paused, "Sale is locked");
        require(balance + quantity <= maxSupply, "Exceeds supply");
        require(quantity <= maxBuy, "Exceeds maxiumum buy");
        require(msg.value >= price * quantity, "Ether sent is not correct");

        for (uint256 i; i < quantity; ++i) {
            _safeMint(msg.sender, balance + i + 1);
        }
    }

    function gift(uint256 quantity, address recipient) external onlyOwner {
        uint256 balance = totalSupply();
        require(balance + quantity <= maxSupply, "Exceeds supply");

        for (uint256 i; i < quantity; ++i) {
            _safeMint(recipient, balance + i);
        }
    }

    function setMaxBuy(uint256 newMaxBuy) external onlyOwner {
        maxBuy = newMaxBuy;
    }

    function setLocked(bool paused_) external onlyOwner {
        paused = paused_;
    }

    function reveal() external onlyOwner {
        revealed = true;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function setProvenance(string memory provenanceHash) external onlyOwner {
        PROVENANCE = provenanceHash;
    }

    function withdraw() external onlyOwner {
        require(address(this).balance >= 0, "No funds available");
        Address.sendValue(payable(owner()), address(this).balance);
    }

    function setBaseURI(string memory baseURI, string memory suffix)
        external
        onlyOwner
    {
        _baseTokenURI = baseURI;
        _tokenURISuffix = suffix;
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
            "ERC721Metadata: TOKEN DOES NOT EXIST"
        );

        return
            string(
                abi.encodePacked(
                    _baseTokenURI,
                    tokenId.toString(),
                    _tokenURISuffix
                )
            );
    }
}
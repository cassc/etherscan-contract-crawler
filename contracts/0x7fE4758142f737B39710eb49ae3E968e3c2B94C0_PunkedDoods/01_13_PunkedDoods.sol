// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

import "./ERC721EnumerableB.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract PunkedDoods is ERC721EnumerableB, Ownable {
    using Strings for uint256;

    string public PROVENANCE = "";
    uint256 public TOTAL_SUPPLY = 5000;

    bool public is_locked = true;

    uint256 public price = 0.015 ether;

    string private _baseTokenURI = "";
    string private _tokenURISuffix = "";

    constructor() ERC721B("PunkedDoods", "Dood") {}

    //external
    fallback() external payable {}

    receive() external payable {}

    function mint(uint256 quantity) external payable {
        uint256 balance = totalSupply();
        require(!is_locked, "Sale is locked");
        require(balance + quantity <= TOTAL_SUPPLY, "Exceeds supply");
        require(msg.value >= price * quantity, "Ether sent is not correct");

        for (uint256 i; i < quantity; ++i) {
            _safeMint(msg.sender, balance + i);
        }
    }

    //onlyOwner
    function gift(uint256 quantity, address recipient) external onlyOwner {
        uint256 balance = totalSupply();
        require(balance + quantity <= TOTAL_SUPPLY, "Exceeds supply");

        for (uint256 i; i < quantity; ++i) {
            _safeMint(recipient, balance + i);
        }
    }

    function setLocked(bool is_locked_) external onlyOwner {
        is_locked = is_locked_;
    }

    function setMaxSupply(uint256 maxSupply) external onlyOwner {
        require(
            maxSupply > totalSupply(),
            "Specified supply is lower than current balance"
        );
        TOTAL_SUPPLY = maxSupply;
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

    //metadata
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
            "ERC721Metadata: URI query for nonexistent token"
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
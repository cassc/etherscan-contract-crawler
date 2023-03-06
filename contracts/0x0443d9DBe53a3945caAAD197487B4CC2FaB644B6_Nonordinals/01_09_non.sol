// SPDX-License-Identifier: MIT
//
// █▄ █ █▀█ █▄ █
// █ ▀█ █▄█ █ ▀█
// https://twitter.com/nonordinals
// Limited pass by Nonordinals.

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";

pragma solidity ^0.8.7;

contract Nonordinals is Ownable, ERC721A, ReentrancyGuard {
    struct Cfg {
        uint256 maxSupply;
        uint256 price;
        uint256 maxMint;
    }

    Cfg public cfg;

    constructor() ERC721A("Nonordinals", "NON") {
        cfg.maxSupply = 1500;
        cfg.price = 35000000000000000;
        cfg.maxMint = 1;
    }

    function getMaxSupply() private view returns (uint256) {
        Cfg memory config = cfg;
        uint256 max = uint256(config.maxSupply);
        return max;
    }

    function numberMinted(address _addr) public view returns (uint256) {
        return _numberMinted(_addr);
    }

    function purchase() external payable {
        Cfg memory config = cfg;
        uint256 price = uint256(config.price);
        uint256 maxMint = uint256(config.maxMint);
        uint256 buyed = numberMinted(msg.sender);

        require(totalSupply() + 1 <= getMaxSupply(), "Sold out.");

        require(buyed + 1 <= maxMint, "Exceed maxmium mint.");

        require(1 * price <= msg.value, "No enough eth.");

        _safeMint(msg.sender, 1);
    }

    function reserve() external onlyOwner {
        require(totalSupply() + 1 <= getMaxSupply(), "Sold out.");

        _safeMint(msg.sender, 1);
    }

    function setPrice(uint256 _price) external onlyOwner {
        cfg.price = _price;
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, ".");
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(tokenId < getMaxSupply(), "Invalid id");
        require(tokenId < totalSupply(), "Invalid id");

        bytes memory image = abi.encodePacked(
            "data:image/svg+xml;base64,",
            Base64.encode(
                bytes(
                    abi.encodePacked(
                        '<?xml version="1.0" encoding="UTF-8"?>',
                        '<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" preserveAspectRatio="xMidYMid meet">',
                        "<style>text {font-family:Sans,Arial;}</style>",
                        '<path d="M0 0h200v200H0z"/>',
                        '<text y="50%" fill="#f7931a"><tspan x="50" dy="-2rem" font-size="14" font-weight="bold">NONORDINALS</tspan> <tspan x="50" dy="2rem" font-size="11">{ "type": "LIMITED",</tspan> <tspan x="56" dy="1rem" font-size="11">"id": ',
                        Strings.toString(tokenId),
                        " }</tspan></text>",
                        '<path d="M38 140h12v30H38zm16 0h12v30H54zm16 0h12v30H70zm16 0h12v30H86zm16 0h12v30h-12zm16 0h12v30h-12zm16 0h12v30h-12zm16 0h12v30h-12z" fill="#fff"/>',
                        "</svg>"
                    )
                )
            )
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"NON", "image_data":"',
                                image,
                                '"}'
                            )
                        )
                    )
                )
            );
    }
}
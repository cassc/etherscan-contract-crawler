// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Mermaid is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    string internal baseTokenURI;
    uint256 public singlePrice = 4 * 10**16;
    uint256 public triplePrice = 11 * 10**16;
    uint256 public halfDozenPrice = 20 * 10**16;

    uint256 public MAX_MERMAIDS = 10000;
    
    uint256 public reservedForClaim = 500;
    uint256 public reservedForGrant = 500;

    address public t1 = 0x5F99A3D61D3C12B7C221C95C3716b723b320B84F;
    address public t2 = 0xEE44C5Fc0a75B22359820C3F1031029c2DCa94AD;
    address public t3 = 0xC8CBBb061765D87571dad6C47C61bD011b455112;

    bool public onSale = true;

    mapping(address=>bool) public claimed;
    
    constructor(string memory baseURI) ERC721("Mermaid Gang", "MermaidGang") {
        setBaseURI(baseURI);
        _mintMermaid(20, t1);
        reservedForGrant = reservedForGrant.sub(20);
    }

    /** mint mermaids */
    function _mintMermaid(uint256 num, address to) internal {
        for(uint256 i = 0; i < num; i++) {
            uint256 tokenIndex = totalSupply();
            _safeMint(to, tokenIndex);
        }
    }
    
    // mint single
    function mintMermaid(uint256 num) public payable {
        require(onSale, "Not on sale");
        require(num <= 10, "10 tokens at max a time");
        require(singlePrice.mul(num) <= msg.value, "Low Fund");
        require(totalSupply().add(num) <= MAX_MERMAIDS, "Exceed Max Supply");
        _mintMermaid(num, msg.sender);
    }

    // mint butch
    function mintThreeMermaids() public payable {
        require(onSale, "Not on sale");
        require(triplePrice <= msg.value, "Low Fund");
        require(totalSupply().add(3) <= MAX_MERMAIDS, "Exceed Max Supply");
        _mintMermaid(3, msg.sender);
    }

    function mintSixMermaids() public payable {
        require(onSale, "Not on sale");
        require(halfDozenPrice <= msg.value, "Low Fund");
        require(totalSupply().add(6) <= MAX_MERMAIDS, "Exceed Max Supply");
        _mintMermaid(6, msg.sender);
    }

    function claimMermaid() public {
        require(!claimed[msg.sender], "Already claimed");
        require(totalSupply().add(1) <= MAX_MERMAIDS, "Exceed Max Supply");
        require(reservedForClaim > 0, "claim out of supply");
        claimed[msg.sender] = true;
        _mintMermaid(1, msg.sender);
        reservedForClaim = reservedForClaim.sub(1);
    }

    function giveAway(address to, uint256 num) public onlyOwner {
        require(num <= reservedForGrant, "Exceed reserved");
        require(totalSupply().add(num) <= MAX_MERMAIDS, "Exceed Max Supply");
        _mintMermaid(num, to);
        reservedForGrant = reservedForGrant.sub(num);
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
    
    function setPrice(uint256 price) public onlyOwner {
        singlePrice = price;
        triplePrice = price.mul(2750).div(1000);
        halfDozenPrice = price.mul(5);
    }

    function pauseSale() public onlyOwner {
        require(onSale, "already paused");
        onSale = false;
    }

    function unpauseSale() public onlyOwner {
        require(!onSale, "already unpaused");
        onSale = true;
    }

    receive() external payable {}
    
    function withdraw() public onlyOwner {
        uint256 val = address(this).balance.div(3);
        (bool success1, ) = t1.call{value: val}("");
        (bool success2, ) = t2.call{value: val}("");
        (bool success3, ) = t3.call{value: val}("");
        require(success1 || success2 || success3, "withdraw failed");
    }
}
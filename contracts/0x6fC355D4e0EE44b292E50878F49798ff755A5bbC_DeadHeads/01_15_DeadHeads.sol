// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title DeadHeads contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */

contract DeadHeads is ERC721, Ownable {
    using SafeMath for uint256;

    string public DEAD_PROVENANCE = "";
    uint256 public constant deadHeadPrice = 90000000000000000; // 0.09 ETH
    uint public constant maxDeadHeadPurchase = 10;
    uint public constant reservedDeadHeads = 20;
    uint256 public constant maxDeadHeads = 10000;
    bool public saleIsActive = false;

    constructor() ERC721("DeadHeads", "DEAD") {
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        msg.sender.transfer(balance);
    }

   function reserveDeadHeads() public onlyOwner {
        uint mintIndex = totalSupply();
        uint i;
        for (i = 0; i < reservedDeadHeads; i++) {
            _safeMint(msg.sender, mintIndex + i);
        }
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        DEAD_PROVENANCE = provenanceHash;
    }

    function mintDeadHeads(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale is not active, you can't mint. The DeadHeads can't rise yet.");
        require(numberOfTokens <= maxDeadHeadPurchase, "You can only mint 20 DeadHeads per transaction. You are evil.");
        require(totalSupply().add(numberOfTokens) <= maxDeadHeads, "Not enough DeadHeads left to mint that amount. Hell is upon us.");
        require(deadHeadPrice.mul(numberOfTokens) <= msg.value, "You sent the incorrect amount of ETH. Are you dead?");

        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < maxDeadHeads) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    // What is dead may never die
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// _________                  __  .__            ____  __.__    .___
// \_   ___ \_____    _______/  |_|  |   ____   |    |/ _|__| __| _/
// /    \  \/\__  \  /  ___/\   __\  | _/ __ \  |      < |  |/ __ | 
// \     \____/ __ \_\___ \  |  | |  |_\  ___/  |    |  \|  / /_/ | 
//  \______  (____  /____  > |__| |____/\___  > |____|__ \__\____ | 
//         \/     \/     \/                 \/          \/       \/ 

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

/**
 * @title CastleKid contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract CastleKidCollection is ERC721, ERC721Enumerable, Ownable {

    string public CASTLE_PROVENANCE = "";
    bool public saleIsActive = false;
    bool public isWhiteListActive = false;
    string _baseTokenURI;

    constructor(string memory baseURI) ERC721("Castle Kid", "CASTLE KID") {
        _baseTokenURI = baseURI;
    }

    function reserve(address[] calldata to) public onlyOwner {
      for (uint256 i = 0; i < to.length; i++) {
            uint256 ts = totalSupply();
            _safeMint(to[i], ts + 1);
        }
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
/*
* Reservation List Sale
*/
    function setIsWhiteListActive() external onlyOwner {
        isWhiteListActive = !isWhiteListActive;
    }


    function mintWhiteList(uint8 numberOfTokens) external payable {
        require(isWhiteListActive, "Allow list is not active");
        require(balanceOf(msg.sender) + numberOfTokens <= 2, "Limit is 2 tokens per wallet, sale not allowed");
        require(msg.sender == tx.origin, "No transaction from smart contracts!");
        require(totalSupply() + numberOfTokens <= 10000, "Purchase would exceed max supply of CastleKids");
        require(0.08 ether * numberOfTokens <= msg.value, "Ether value sent is not correct");
        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 ts = totalSupply();
            _safeMint(msg.sender, ts + 1);
        }
    }

/*
* Set provenance once it's calculated
*/
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        CASTLE_PROVENANCE = provenanceHash;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

/*
* Pause sale if active, make active if paused
*/
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }


/**
* Mint CastleKids
*/
    function mintCastleKid(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint Castle Kid");
        require(msg.sender == tx.origin, "No transaction from smart contracts!");
        require(numberOfTokens <= 5, "Can only mint 5 tokens at a time");
        require(totalSupply() + numberOfTokens <= 10000, "Purchase would exceed max supply of CastleKids");
        require(0.100 ether * numberOfTokens <= msg.value, "Ether value sent is not correct");

        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < 10000) {
                _safeMint(msg.sender, mintIndex + 1);
            }
        }
    }

/*
* Withdraw Contract Balance
*/
    // withdraw addresses
    address t1 = 0xEa122118c3F3B29EF5Ab0aec93De1A4Ff10dB557; //CastleKid
    address t2 = 0x2206168CdE2b3652E2488d9a1283531A4d200aea; //Kev
    address t3 = 0x6a38D9c83bF780aCF34E90047D44e692221C6Aa7; //Sifu

    function withdraw() public onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function withdrawAll() public payable onlyOwner {
        uint256 _core = address(this).balance * 92/100;
        uint256 _kevy = address(this).balance * 4/100;
        uint256 _sifu = address(this).balance * 4/100;
        require(payable(t1).send(_core));
        require(payable(t2).send(_kevy));
        require(payable(t3).send(_sifu));
    }
}
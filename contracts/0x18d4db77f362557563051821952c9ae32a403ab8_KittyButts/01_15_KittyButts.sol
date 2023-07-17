// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// @title: The KittyButts
// @author: KittyButt G

//@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@//
//@01011001 01001000 00100000 01000110 01000100 [email protected]//
//@01010001 01011000 01001001 01010010 01010001 [email protected]//
//@01000001 00100000 01000100 01001010 00100000 [email protected]//
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//
//@@@@@@@@@@@@@#S?*****?%#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//
//@@@@@@@@@@%**+++++++++****[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@//
//@@@@@@@@S+*++;::;;;:;;++++*[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@//
//@@@@@@@@?**;:;+*****;;:++++*[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@//
//@@@@@@@#***;+*********;;;++*%@@@@@@@@@@@@@@@@@@@@@@@@@@//
//@@@@@@@@@*++;*?S#@@%**+:;+**[email protected]@@S*@@@@@@@@@@@@@@@@@@@@@//
//@@@@@@@@@@S??*@@@@@@**++;+*[email protected]@@@#*;%@@@@%[email protected]@@@@@@@@@@@@//
//@@@@@@@@@@@@@@@@@@@S**;:[email protected]@@@@#?+;;*%S%*@@@@@@@@@@@@@//
//@@@@@@@@@@@@@@@@@@@?*+;[email protected]@@?+%%,:+:?++,[email protected]@@@@@@@@@@@@//
//@@@@@@@@@@@@@@@@@%:+*+*%;:%@@#S;:;.:;::::,.%@@@@@@@@@@@//
//@@@@@@@@@@@@@@@%...,+,......,S+............:@@@@@@@@@@@//
//@@@@@@@@@@@@@@#,...?,.........:%,.........*@@@@@@@@@@@@//
//@@@@@@@@@@@@@@S................,S?:,,...:*@@@@@@@@@@@@@//
//@@@@@@@@@@@@@@%.................,:.......,@@@@@@@@@@@@@//
//@@@@@@@@@@@@@@*..........................,@@@@@@@@@@@@@//
//@@@@@@@@@@@@@S,,,,,,,,,,,,,,,,,,,,,,,,,,[email protected]@@@@@@@@@@@@//
//@@@@@@@@@@@@?,,,,::,,,,,,,,,,,:,:*,,,,,,;?;@@@@@@@@@@@@//
//@@@@@@@@@@S,,::::,,:[email protected]?:,:::::,;S:,,,,:?;,,[email protected]@@@@@@@@@@//
//@@@@@@@@@#::::::::+#@@@@@*::::::;*:%@@@%:::::[email protected]@@@@@@@@//
//@@@@@@@@@@@+;;:[email protected]@@@@@@%*@@*;;;;+***@@[email protected]@@#S%%#@@@@@@@@//
//@@@@@@####@@@#S#@##########@@S%[email protected]@####@@@@@@@@@@@@@@//
//@@@@@@@@@############################@@@@@@@@@@@@@@@@@@//
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//
//@01000100 01010000 01010100 01001100 01001111 [email protected]//
//@00100000 01010110 01000100 01010001 01000011 [email protected]//
//@00100010 01001001 01010010 01010001 01010001 [email protected]//
//@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@//


import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract KittyButts is ERC721, ERC721Enumerable, Ownable {

    using SafeMath for uint256;
    uint256 public startingIndexBlock;
    uint256 public startingIndex;
    uint public constant maxPurchase = 10;
    uint256 public MAX_KITTIES;
    bool public saleIsActive = false;
    uint256 public REVEAL_TIMESTAMP;

    uint256 private _reserved = 320;
    uint256 private _kittyPrice = 20000000000000000; //0.02 ETH
    string private baseURI;

    constructor(string memory name, string memory symbol, uint256 maxNftSupply, uint256 saleStart) ERC721(name, symbol) {
        MAX_KITTIES = maxNftSupply;     
        REVEAL_TIMESTAMP = saleStart + (86400 * 7); //7 days
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

	function withdraw() public onlyOwner {
		uint256 balance = address(this).balance;
		payable(msg.sender).transfer(balance);
	}    

    function reserveTokens(uint256 amount) public onlyOwner {    
        require( amount <= _reserved, "Reserve limit reached" );

        uint supply = totalSupply();
        for (uint i; i < amount; i++) {
            _safeMint(msg.sender, supply + i);
        }

        _reserved -= amount;
    }

    function setPrice(uint256 _newPrice) public onlyOwner() {
        _kittyPrice = _newPrice;
    }

    function getPrice() public view returns (uint256){
        return _kittyPrice;
    }

    function mintKittyButt(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint a Kitty Butt");
        require(numberOfTokens <= maxPurchase, "Can only mint 10 tokens at a time");
        require(totalSupply().add(numberOfTokens) <= MAX_KITTIES, "Purchase would exceed max supply of Kitty Butts");
        require(_kittyPrice.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");
        
        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_KITTIES) {
                _safeMint(msg.sender, mintIndex);
            }
        }

        //We set the starting index only once all the presale time has elapsed or when the last token has sold
        if (startingIndexBlock == 0 && (totalSupply() == MAX_KITTIES || block.timestamp >= REVEAL_TIMESTAMP)) {
            startingIndexBlock = block.number;
        } 
    }

    function setRevealTimestamp(uint256 revealTimeStamp) public onlyOwner {
        REVEAL_TIMESTAMP = revealTimeStamp;
    }     

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }    

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    //Credit to 0xc2c747e0f7004f9e8817db2ca4997657a7746928
    function setStartingIndex() public {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");
        
        startingIndex = uint(blockhash(startingIndexBlock)) % MAX_KITTIES;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (block.number.sub(startingIndexBlock) > 255) {
            startingIndex = uint(blockhash(block.number - 1)) % MAX_KITTIES;
        }
        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = startingIndex.add(1);
        }
    }

    function emergencySetStartingIndexBlock() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");
        
        startingIndexBlock = block.number;
    }    

}
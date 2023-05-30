// SPDX-License-Identifier: MIT
/*
             __   _   _                
 _ __ ___   |   || | | |  ___   _ __   ___ 
| '_ ` _ \  |  _|| |_| | / _ \ | '__| / __|
| | | | | | | |  |  _  ||  __/ | |    \__ \
|_| |_| |_| |_|  |_| |_| \___| |_|    |___/
                                     
*/
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract mphers is ERC721, ERC721Enumerable, Ownable {
    string private _baseURIextended;
    address payable public immutable shareholderAddress;

    constructor(address payable shareholderAddress_) ERC721("mphers", "MPHER") {
        require(shareholderAddress_ != address(0));
        shareholderAddress = shareholderAddress_;
        _baseURIextended = "ipfs://QmYJcaqLWJB6Hkt3X2oX2bxC63fVRUq5SdEwSteS22bC2Z/";
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function freeMint(uint numberOfTokens) public {
        require(block.timestamp > 1638489600, "Cannot buy yet : Fri Dec 03 2021 00:00:00 GMT+0000");
        require(numberOfTokens <= 3, "Exceeded max token purchase (max 3)");
        require(totalSupply() + numberOfTokens <= 1000, "Only the 1000 first mphers were free. Please use mint function now ;)");

        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < 1000) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function mint(uint numberOfTokens) public payable {
        require(block.timestamp > 1638489600, "Cannot buy yet : Fri Dec 03 2021 00:00:00 GMT+0000");
        require(numberOfTokens <= 10, "Exceeded max token purchase");
        require(totalSupply() + numberOfTokens <= 6969, "Purchase would exceed max supply of tokens");
        require(0.01 ether * numberOfTokens <= msg.value, "Ether value sent is not correct");

        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < 6969) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(shareholderAddress, balance);
    }
}
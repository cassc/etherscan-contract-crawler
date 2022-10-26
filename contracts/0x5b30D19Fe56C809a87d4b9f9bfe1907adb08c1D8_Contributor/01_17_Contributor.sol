// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/* 
⌐◨---------------------------------------------------------------◨
                    Prop House Contributor Tokens
⌐◨---------------------------------------------------------------◨
*/

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./EIP712Allowlisting.sol";

contract Contributor is ERC1155, Ownable, Pausable, ERC1155Burnable, ERC1155Supply, EIP712Allowlisting {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;

    string public name = "i contributed";
    string public symbol = "HLPR";
    string baseUri = "https://ipfs.io/ipfs/QmRHhr1jmWa29SkF9vEx9um3ECETB7wsmKHKAn6NCZ5F2Y/";
    string uriExtension = ".json";
    uint256 maxPerAddress = 1;
    bool limitPerAddress = true;

    constructor() ERC1155("https://ipfs.io/ipfs/QmRHhr1jmWa29SkF9vEx9um3ECETB7wsmKHKAn6NCZ5F2Y/{id}.json") {}

    function setMaxPerAddress(uint256 num) public onlyOwner {
        maxPerAddress = num;
    }

    function toggleLimitPerAddress() public onlyOwner {
        limitPerAddress = !limitPerAddress;
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function setBaseURI(string memory newuri) public onlyOwner {
        baseUri = newuri;
    }

    function setUriExtension(string memory newExtension) public onlyOwner {
        uriExtension = newExtension;
    }

    function setName(string memory newName) public onlyOwner {
        name = newName;
    }

    function setSymbol(string memory newSymbol) public onlyOwner {
        symbol = newSymbol;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // Use the requiresAllowlist modifier to reject the call if a valid signature is not provided
    function mint(bytes calldata signature, uint256 community, uint256 quantity)
        public
        requiresAllowlist(signature)
    {
        if (limitPerAddress == true) {
            require(balanceOf(msg.sender, community) < maxPerAddress, "One token per address");
        }
        // Make sure to check other requirements before incrementing or minting
        _tokenIdCounter.increment();
        _mint(msg.sender, community, quantity, "");
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, "");
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function uint2hexstr(uint256 i) public pure returns (string memory) {
        if (i == 0) return "0";
        uint j = i;
        uint length;
        while (j != 0) {
            length++;
            j = j >> 4;
        }
        uint mask = 15;
        bytes memory bstr = new bytes(length);
        uint k = length;
        while (i != 0) {
            uint curr = (i & mask);
            bstr[--k] = curr > 9 ?
                bytes1(uint8(55 + curr)) :
                bytes1(uint8(48 + curr)); // 55 = 65 - 10
            i = i >> 4;
        }
        return string(bstr);
    }

    function uri(uint256 tokenId) override public view returns (string memory) {
       string memory hexstringtokenID;
         hexstringtokenID = uint2hexstr(tokenId);
    
        return string(
            abi.encodePacked(
                baseUri,
                hexstringtokenID,
                uriExtension
            )
        );
    }

    function setApprovalForAll(address, bool) public pure override {
        revert("This token is soulbound. It cannot be sold or transfered. You're stuck with it!");
    }

    function safeTransferFrom(address, address, uint256, uint256, bytes memory) public pure override {
        revert("This token is soulbound. It cannot be sold or transfered. You're stuck with it!");
    }

    function safeBatchTransferFrom(address, address, uint256[] memory, uint256[] memory, bytes memory) public pure override {
        revert("This token is soulbound. It cannot be sold or transfered. You're stuck with it!");
    }
}
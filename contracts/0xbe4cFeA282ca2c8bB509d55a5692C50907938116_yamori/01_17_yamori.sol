/*
* Y88b   d88P                                       d8b 
*  Y88b d88P                                        Y8P 
*   Y88o88P                                             
*    Y888P   8888b.  88888b.d88b.   .d88b.  888d888 888 
*     888       "88b 888 "888 "88b d88""88b 888P"   888 
*     888   .d888888 888  888  888 888  888 888     888 
*     888   888  888 888  888  888 Y88..88P 888     888 
*     888   "Y888888 888  888  888  "Y88P"  888     888 
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract yamori is ERC1155Pausable, Ownable, PaymentSplitter {
    uint16 public constant MAX_SUPPLY = 10000;
    uint256 public MINT_RATE = 0.1 ether;

    uint256 public _minted = 0;

    mapping (address => bool) private _whitelistedAddresses;
    bool public _whitelist = true;

    constructor (address[] memory _payees, uint256[] memory _shares, string memory _uri)
        ERC1155(_uri)
        PaymentSplitter(_payees, _shares) payable {}

    function mint(uint256 quantity) public payable whenNotPaused
    {
        require(MAX_SUPPLY >= _minted + quantity, "Not enough supply");
        require(quantity > 0, "Must mint at least one nft");
        require(msg.value >= (quantity * MINT_RATE), "Not enough ether sent");
        require((_whitelist && isWhitelisted(msg.sender)) || !_whitelist, "Address is not whitelisted");

        uint256[] memory ids = new uint256[](quantity) ;
        uint256[] memory amounts = new uint256[](quantity);
        
        for(uint16 i = 0; i < quantity; i++ ){
            ids[i] = _minted + i;
            amounts[i] = 1;
        }

        _mintBatch(msg.sender, ids, amounts, "");
        _minted += quantity;
    }

    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(tokenId >= 0, "Token does not exist");
        require(tokenId < MAX_SUPPLY, "Token does not exist");

        return string.concat(uri(0), Strings.toString(tokenId));
    }

    function setTokenUri(string memory uri) public onlyOwner {
        _setURI(uri);
    }

    function addToWhitelist(address[] memory addresses) public onlyOwner {
        for(uint16 i = 0; i < addresses.length; i++ ){
            _whitelistedAddresses[addresses[i]]=true;
        }
    }

    function isWhitelisted(address wallet) private view returns (bool){
        return _whitelistedAddresses[wallet];
    }

    function toggleWhitelist() public onlyOwner {
        _whitelist = !_whitelist;
    }

    function increaseMintRate(uint256 times) public onlyOwner {
        MINT_RATE = MINT_RATE + times * 0.005 ether;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ParadiseTicket is ERC721A, Pausable, Ownable 
{
    string public BASE_URI;

    uint256 public MAX_SUPPLY;
    uint256 public PARADISE_MINT_START_TIMESTAMP;
    uint256 public OG_MINT_START_TIMESTAMP;
    uint256 public PUBLIC_MINT_START_TIMESTAMP;

    // 0 = not whitelisted, 1 = og whitelist, 2 = paradise whitelist
    mapping (address => uint8) private _whitelistMapping;
    mapping (address => bool) private _alreadyMintedMapping;

    constructor(string memory baseURI, uint256 maxSupply, uint256 paradiseMintStartTimestamp, uint256 ogMintStartTimestamp, uint256 publicMintStartTimestamp) ERC721A("ParadiseTicket", "ParadiseTicket") 
    {
        BASE_URI = baseURI;
        MAX_SUPPLY = maxSupply;
        PARADISE_MINT_START_TIMESTAMP = paradiseMintStartTimestamp;
        OG_MINT_START_TIMESTAMP = ogMintStartTimestamp;
        PUBLIC_MINT_START_TIMESTAMP = publicMintStartTimestamp;
    }

    function pause() public onlyOwner 
    {
        _pause();
    }

    function unpause() public onlyOwner 
    {
        _unpause();
    }

    function withdraw() public onlyOwner 
    {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function forceMint(uint256 amount) public onlyOwner
    {
        _safeMint(msg.sender, amount);
    }

    function mint() public
    {
        require(
            block.timestamp >= PUBLIC_MINT_START_TIMESTAMP ||
            block.timestamp >= OG_MINT_START_TIMESTAMP || 
            block.timestamp >= PARADISE_MINT_START_TIMESTAMP,
            "Minting not started");
        require(totalSupply() < MAX_SUPPLY, "SOLD OUT!");
        require(canMint(msg.sender), "Address cannot mint more");
        require(isEligible(msg.sender), "Address is not eligible");

        _alreadyMintedMapping[msg.sender] = true;
        _safeMint(msg.sender, 1);
    }

    function setParadiseMintStartTimestamp(uint256 value) external onlyOwner
    {
        PARADISE_MINT_START_TIMESTAMP = value;
    }

    function setOgMintStartTimestamp(uint256 value) external onlyOwner
    {
        OG_MINT_START_TIMESTAMP = value;
    }

    function setPublicMintStartTimestamp(uint256 value) external onlyOwner
    {
        PUBLIC_MINT_START_TIMESTAMP = value;
    }

    function addToWhitelist(address[] calldata list, uint8 whitelistId) external onlyOwner
    {
        for (uint i = 0; i < list.length; i++) 
        {
            address addr = list[i];
            _whitelistMapping[addr] = whitelistId;
        }
    }

    function canMint(address to) public view returns (bool)
    {
        uint256 timeNow = block.timestamp;
        return timeNow >= PUBLIC_MINT_START_TIMESTAMP || !_alreadyMintedMapping[to];
    }

    function isEligible(address to) public view returns (bool) 
    {
        uint256 timeNow = block.timestamp;
        if (timeNow >= PUBLIC_MINT_START_TIMESTAMP)
        {
            return true;
        }

        uint8 whitelistId = _whitelistMapping[to];

        if (timeNow >= OG_MINT_START_TIMESTAMP)
        {
            return whitelistId > 0;
        }

        if (timeNow >= PARADISE_MINT_START_TIMESTAMP)
        {
            return whitelistId > 1;
        }

        return false;
    }

    function _beforeTokenTransfers(address from, address to, uint256 tokenId, uint quantity) internal whenNotPaused override
    {
        super._beforeTokenTransfers(from, to, tokenId, quantity);
    }

    function setBaseUri(string memory value) public onlyOwner
    {
        BASE_URI = value;
    }

    function _baseURI() internal view override returns (string memory) {
        return BASE_URI;
    }

    function tokenURI(uint256) public view override returns (string memory)
    {
        return _baseURI();
    }
}
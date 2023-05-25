// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ForestNo is ERC721, Pausable, Ownable {

    event Minted(address indexed to, uint256 indexed tokenId);

    uint256 private constant MAX_NFTS_PER_ADDRESS = 5;
    uint256 private constant TOKEN_MAX_CAP = 328;
    uint256 private constant MAX_PRESALE_NFTS_PER_ADDRESS = 2;

    bool private _presale = true;
    bool private _contractLive = false;
    uint256 private _tokenCount = 0;
    uint256 private _mintPrice = 0.08 ether;
    string public _uri = "https://www.mymetadata.com/token/";

    mapping(address => bool) private _whitelist;

    using Counters for Counters.Counter;
    mapping(address => Counters.Counter) private _mintedNFTs;

    constructor() ERC721("Forest, No", "FRSTNO") {}

    function setMintPrice(uint256 newPrice) public onlyOwner
    {
        _mintPrice = newPrice;
    }

    function setURI (string calldata uri) external onlyOwner 
    {
        _uri = uri;
    }

    function togglePresale() public onlyOwner 
    {
        _presale = !_presale;
    }

    function setLiveState() public onlyOwner
    {
        require(!_contractLive);
        _contractLive = true;
    }

    function pause() public onlyOwner 
    {
        _pause();
    }

    function unpause() public onlyOwner 
    {
        _unpause();
    }

    function addToWhitelist(address account) public onlyOwner {
        _whitelist[account] = true;
    }

    function addBatchToWhitelist(address[] memory accounts) public onlyOwner 
    {
        for (uint256 i = 0; i < accounts.length; i++) 
        {
            _whitelist[accounts[i]] = true;
        }
    }

    function removeBatchFromWhitelist(address[] memory accounts) public onlyOwner
    {
        for(uint256 i = 0; i < accounts.length; i++)
        {
            _whitelist[accounts[i]] = false;
        }
    }

    function removeFromWhitelist(address account) public onlyOwner {
        _whitelist[account] = false;
    }

    function getRemainingMints() public view returns(uint256)
    {
        return TOKEN_MAX_CAP - _tokenCount;
    }

    function mint() external payable
    {
        require(_contractLive, "Contract is not live yet, please try again later!");
        require(msg.value >= _mintPrice, "You need to pay more than the mint price to be able to mint!");
        require(_mintedNFTs[_msgSender()].current() < MAX_NFTS_PER_ADDRESS, "Max NFTs per address reached");
        require(_tokenCount < TOKEN_MAX_CAP);

        if (_presale) {
            require(_whitelist[msg.sender], "Address not whitelisted during presale");
            require(_mintedNFTs[_msgSender()].current() < MAX_PRESALE_NFTS_PER_ADDRESS, "Max NFTs allowed in presale per address reached");
        }
        
        _tokenCount = _tokenCount + 1;
        _safeMint(_msgSender(), _tokenCount);
        _mintedNFTs[_msgSender()].increment();
        emit Minted(_msgSender(), _tokenCount);
    }

    function withdraw() public onlyOwner 
    {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds available for withdrawal");
        payable(msg.sender).transfer(balance);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) 
    {
        require(_exists(tokenId), "MyToken: URI query for nonexistent token");
        return string(abi.encodePacked(_uri, _toString(tokenId), ".json"));
    }

    function _toString(uint value) internal pure returns (string memory) 
    {
        uint temp = value;
        uint digits;

        while (temp != 0) 
        {
            digits++;
            temp /= 10;
        }

        bytes memory buffer = new bytes(digits);
        while (value != 0) 
        {
            digits--;
            buffer[digits] = bytes1(uint8(48 + uint(value % 10)));
            value /= 10;
        }

        return string(buffer);
  }
}
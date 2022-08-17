// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract FoxOrCat is Ownable, ERC721Enumerable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    string private baseURI;
    uint256 private maxSupply = 666;
    uint256 private mintPrice; 
    address payable private recipientAddress;  
    uint256 private startTimestamp;
    uint256 private endTimestamp;
    bool private publicSalesEnabled = true;
    
    mapping(address => bool) private whitelist;
    mapping(address => bool) private participants;

    constructor(
        string memory _name, 
        string memory _symbol, 
        string memory _initBaseURI, 
        uint256 _mintPrice, 
        address _recipientAddress,
        uint256 _startTimestamp,
        uint256 _endTimestamp) 
    ERC721(_name, _symbol) {
        baseURI = _initBaseURI;
        mintPrice = _mintPrice;
        recipientAddress = payable(_recipientAddress);
        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;
    }

    function mint() external payable {
        require(totalSupply() < maxSupply, "Max supply reached");
        require(block.timestamp >= startTimestamp, "Sales not started yet");
		require(block.timestamp <= endTimestamp, "Sales ended");

        if(!isPublicSalesEnabled())
            require(whitelist[msg.sender] == true, "Not whitelisted");

        require(!isParticipant(msg.sender), "Can only mint once");
        require(msg.value == mintPrice, "Invalid price");

        recipientAddress.transfer(msg.value);
        participants[msg.sender] = true;
        
        _mint(msg.sender, _tokenIdTracker.current()+1);   
        _tokenIdTracker.increment();

        emit Mint(msg.sender);
    }

    function airdrop(address _userAddress) external onlyOwner {
        require(_userAddress != address(0), "Zero address");
        require(totalSupply() < maxSupply, "Max supply reached");

        _mint(_userAddress, _tokenIdTracker.current()+1);   
        _tokenIdTracker.increment();

        emit Airdrop(_userAddress);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // ===================================================================
    // GETTERS
    // ===================================================================
    
    function getMaxSupply() external view returns(uint256) {
        return maxSupply;
    }

    function getMintPrice() external view returns(uint256) {
        return mintPrice;
    }

    function getRecipientAddress() external view returns(address) {
        return recipientAddress;
    }

    function getStartTimestamp() external view returns(uint256) {
        return startTimestamp;
    }

    function getEndTimestamp() external view returns(uint256) {
        return endTimestamp;
    }

    function isWhitelisted(address _userAddress) public view returns(bool) {
        return whitelist[_userAddress];
    }

    function isParticipant(address _userAddress) public view returns(bool) {
        return participants[_userAddress];
    }

    function isPublicSalesEnabled() public view returns(bool) {
        return publicSalesEnabled;
    } 

    // ===================================================================
    // SETTERS
    // ===================================================================

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;

        emit SetBaseURI(_newBaseURI);
    }

    function setMaxSupply(uint256 _value) external onlyOwner {
        require(_value != 0, "value zero");
        maxSupply = _value;

        emit SetMaxSupply(_value);
    }

    function setWhiteList(address[] memory _accounts, bool _bool) external onlyOwner {
        require(_accounts.length > 0, "Invalid input");
        for (uint256 index = 0; index < _accounts.length; index++) {
			whitelist[_accounts[index]] = _bool;
        }

        emit SetWhiteList(_accounts, _bool);
    }

    function setRecipientAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "Zero address");
        recipientAddress = payable(_newAddress);

        emit SetRecipientAddress(_newAddress);
    }

    function setMintPrice(uint256 _value) external onlyOwner {
        require(_value > 0, "Value must be larger than zero");
        mintPrice = _value;

        emit SetMintPrice(_value);
    }

    function setStartEndTime(uint256 _startTimestamp, uint256 _endTimestamp) external onlyOwner {
        require(_startTimestamp < _endTimestamp, "Start time should be before end time");
        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;

        emit SetStartEndTime(_startTimestamp, _endTimestamp);
    }

    function setPublicSalesEnabled(bool _bool) external onlyOwner {
        publicSalesEnabled = _bool;

        emit SetPublicSalesEnabled(_bool);
    }

    // ===================================================================
    // EVENTS
    // ===================================================================

    event Mint(address _to);
    event Airdrop(address _to);
    event SetBaseURI(string _baseURI);
    event SetMaxSupply(uint256 _value);
    event SetWhiteList(address[] _accounts, bool _bool);
    event SetRecipientAddress(address _newAddress);
    event SetMintPrice(uint256 _value);
    event SetStartEndTime(uint256 _startTimestamp, uint256 _endTimestamp);
    event SetPublicSalesEnabled(bool _bool);
}
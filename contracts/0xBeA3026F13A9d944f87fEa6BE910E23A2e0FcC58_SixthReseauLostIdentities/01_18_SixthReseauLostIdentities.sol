//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "erc721a/contracts/ERC721A.sol";
import "./MysteryBoxInterface.sol";

/// @title SixthRéseau - Lost Identities Contract
/// @author SphericonIO
contract SixthReseauLostIdentities is ERC721A, Ownable, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using ECDSA for bytes32;

    uint public maxSupply = 7777;
    uint public maxPriority = 660;
    uint public maxPublic = 2777;
    uint public maxPrivate = 4340;

    uint public reservedTokens = 60;

    uint public priorityPrice = 0.16 ether;
    uint public whitelistPrice = 0.16 ether;

    Counters.Counter private _priorityCounter;
    Counters.Counter private _publicCounter;
    Counters.Counter private _whitelistCounter;
    Counters.Counter private _teamCounter;

    mapping(address => uint) private _mintedPriority;
    mapping(address => uint) private _mintedPublic;
    mapping(address => uint) private _mintedWhitelist;
    mapping(address => uint) private _mintedReserve;

    uint public maxPriorityMint = 1;
    uint public maxPublicMint = 5;
    uint public maxWhitelistMint = 1;
    uint public maxReserveMint = 2;

    address public mysteryBox;
    address private _signer;

    bool public isPrioritySale = false;
    bool public isPublicSale = false;
    bool public isWhitelistSale = false;
    bool public isReserveSale = false;

    string public baseTokenURI;

    struct Dutch {
        uint start;
        uint duration;
        uint startPrice;
        uint endPrice;
    }

    Dutch public dutch;

    modifier onlyEOA() {
        require(tx.origin == msg.sender,"SixthReseau: Lost Identities: Only EOA can mint!");
        _;
    }

    modifier enoughSupply(uint256 _amount) {
        require(getTotalSupply() + _amount <= maxSupply - reservedTokens, "SixthReseau: Lost Identities: Minting would exceed max supply!");
        _;
    }

    uint[] private _shares = [150, 100, 40, 30, 25, 25, 10, 12, 3, 605];
    address[] private _shareholders = [
        0x75deaE57E2e554E19a91b42C845a924F93d69384,
        0xaB5F926d88D0017D1D491B44DF7e1E0230f7475c,
        0x0F8948E0E62522340637e641B2C59a0532C4868C,
        0x7f3fF11ec16fa5112a9cd9Fee3E8E6325D9F9124,
        0x28069c8F53dcfC862001bFB0d009985906B8Fb57,
        0xD87b1E3F99B4e389B35f47eE4539224d4cc30fE5,
        0x61776dfC15aC86dD7679BfB4eFc0cAD0c6b2461f,
        0xff744b4Ba28f833903F746909353225a29CfbC7a,
        0x47ba534ACA981c0F78a8597C95e97F0Ae6B1b3a2,
        0x48b858899aB554EC433f3D8C15ef7447afBF2e5A
    ];

    constructor(address _mysteryBox, string memory _baseTokenURI, address _signerNew) ERC721A("SixthReseau: Lost Identities","SRS1") {
        mysteryBox = _mysteryBox;
        baseTokenURI = _baseTokenURI;
        _signer = _signerNew;
        dutch.start = 1652904000;
        dutch.duration = 4 hours;
        dutch.startPrice = 0.4 ether;
        dutch.endPrice = 0.19 ether;
    }

    function isAllowedToMint(bytes memory _signature, uint _saleType) public view returns (bool) {
        bytes32 hash;
        if(_saleType == 1) {
            hash = keccak256(abi.encodePacked(msg.sender, "PRIORITY"));
        } else if (_saleType == 2) {
            hash = keccak256(abi.encodePacked(msg.sender, "WHITELIST"));
        } else if (_saleType == 3) {
            hash = keccak256(abi.encodePacked(msg.sender, "RESERVE"));
        }
        bytes32 messageHash = hash.toEthSignedMessageHash();
        return messageHash.recover(_signature) == _signer;
    }

    function mintPriority(uint _amount, bytes memory _signature) external payable nonReentrant onlyEOA enoughSupply(_amount) {
        require(isPrioritySale, "SixthReseau: Lost Identities: Priority Minting didn't start yet!");
        require(_amount <= maxPriorityMint, "SixthReseau: Lost Identities: Minting more than max amount!");
        require(msg.value >= _amount * priorityPrice, "SixthReseau: Lost Identities: Not enough ETH!");
        require(_priorityCounter.current() + _amount <= maxPriority, "SixthReseau: Lost Identities: Minting would exceed max supply for priority sale!");
        require(_mintedPriority[msg.sender] + _amount <= maxPriorityMint, "SixthReseau: Lost Identities: You already minted all your tokens!");
        require(isAllowedToMint(_signature, 1), "SixthReseau: Lost Identities: Not allowed to mint during priority sale!");
        _mintedPriority[msg.sender] += _amount;
        _mint(msg.sender, _amount);
        for(uint i = 0; i < _amount; i++) {
            _priorityCounter.increment();
            MysteryBoxInterface(mysteryBox).mint(msg.sender);
        }
    }

    function mintPublic(uint _amount) external payable nonReentrant onlyEOA enoughSupply(_amount) {
        require(isPublicSale, "SixthReseau: Lost Identities: Public Minting didn't start yet!");
        require(_amount <= maxPublicMint, "SixthReseau: Lost Identities: Minting more than max amount!");
        require(msg.value >= getPrice(_amount), "SixthReseau: Lost Identities: Not enough ETH!");
        require(_publicCounter.current() + _amount <= maxPublic, "SixthReseau: Lost Identities: Minting would exceed max supply for public sale!");
        require(_mintedPublic[msg.sender] + _amount <= maxPublicMint, "SixthReseau: Lost Identities: You already minted all your tokens!");
        _mintedPublic[msg.sender] += _amount;
        _mint(msg.sender, _amount);
        for(uint i = 0; i < _amount; i++) {
            _publicCounter.increment();
            MysteryBoxInterface(mysteryBox).mint(msg.sender);
        }
    }

    function mintWhitelist(uint _amount, bytes memory _signature) external payable nonReentrant onlyEOA enoughSupply(_amount) {
        require(isWhitelistSale, "SixthReseau: Lost Identities: Whitelist Minting didn't start yet!");
        require(_amount <= maxWhitelistMint, "SixthReseau: Lost Identities: Minting more than max amount!");
        require(msg.value >= _amount * whitelistPrice, "SixthReseau: Lost Identities: Not enough ETH!");
        require(_whitelistCounter.current() + _amount <= maxPrivate, "SixthReseau: Lost Identities: Minting would exceed max supply for whitelist sale!");
        require(_mintedWhitelist[msg.sender] + _amount <= maxWhitelistMint, "SixthReseau: Lost Identities: You already minted all your tokens!");
        require(isAllowedToMint(_signature, 2), "SixthReseau: Lost Identities: Not allowed to mint during whitelist sale!");
        _mintedWhitelist[msg.sender] += _amount;
        _mint(msg.sender, _amount);
        for(uint i = 0; i < _amount; i++) {
            _whitelistCounter.increment();
            MysteryBoxInterface(mysteryBox).mint(msg.sender);
        }
    }

    function mintReserve(uint _amount, bytes memory _signature) external payable nonReentrant onlyEOA enoughSupply(_amount) {
        require(isReserveSale, "SixthReseau: Lost Identities: Reserve Minting didn't start yet!");
        require(_amount <= maxReserveMint, "SixthReseau: Lost Identities: Minting more than max amount!");
        require(msg.value >= _amount * whitelistPrice, "SixthReseau: Lost Identities: Not enough ETH!");
        require(_whitelistCounter.current() + _amount <= maxPrivate, "SixthReseau: Lost Identities: Minting would exceed max supply for reserve sale!");
        require(_mintedReserve[msg.sender] + _amount <= maxReserveMint, "SixthReseau: Lost Identities: You already minted all your tokens!");
        require(isAllowedToMint(_signature, 3), "SixthReseau: Lost Identities: Not allowed to mint during reserve sale!");
        _mintedReserve[msg.sender] += _amount;
        _mint(msg.sender, _amount);
        for(uint i = 0; i < _amount; i++) {
            _whitelistCounter.increment();
            MysteryBoxInterface(mysteryBox).mint(msg.sender);
        }
    }

    function mintTeam(uint _amount, address _to) external onlyOwner {
        require(reservedTokens >= _amount, "SixthReseau: Lost Identities: Not enough reserved tokens!");
        reservedTokens -= _amount;
        _mint(_to, _amount);
            for(uint i = 0; i < _amount; i++) {
            _teamCounter.increment();
            MysteryBoxInterface(mysteryBox).mint(_to);
        }
    }
    
    //Dutch Auction

    /// @notice Returns true if the dutch auction started
    function dutchIsStarted() public view returns (bool) {
        return block.timestamp >= dutch.start;
    }

    /// @notice Calculates the current dutch auction price
    /// @param _timestamp The timestamp to get the price for
    /// @return _price The price for the given timestamp
    function getMintPrice(uint256 _timestamp) public view returns (uint256 _price) {
        if(!dutchIsStarted()) {
            return dutch.startPrice;
        }

        _timestamp = _timestamp == 0 ? block.timestamp : _timestamp;
        uint duration = _timestamp - dutch.start;

        if(duration >= dutch.duration) {
            return dutch.endPrice;
        }

        uint currentPrice = dutch.startPrice - ((((duration * 100000) / dutch.duration) * (dutch.startPrice - dutch.endPrice)) / 100000);
        return  currentPrice > dutch.endPrice ? currentPrice : dutch.endPrice;
    }

    //Getters

    /// @notice Returns the total supply
    /// @return _supply The total supply
    function getTotalSupply() public view returns (uint256 _supply) {
        _supply = _priorityCounter.current() + _publicCounter.current() + _whitelistCounter.current() + _teamCounter.current();
        return _supply;
    }

    /// @notice Get price for multiple tokens
    /// @param _amount The amount of tokens to get the price for
    /// @return _price The price for the given amount
    function getPrice(uint256 _amount) public view returns (uint256 _price) {
        return _amount * getMintPrice(0);
    }

    function getMintedPriority(address _address) public view returns (uint256 _amount) {
        return _mintedPriority[_address];
    }

    function getMintedPublic(address _address) public view returns (uint256 _amount) {
        return _mintedPublic[_address];
    }

    function getMintedReserve(address _address) public view returns (uint256 _amount) {
        return _mintedReserve[_address];
    }

    function getMintedWhitelist(address _address) public view returns (uint256 _amount) {
        return _mintedWhitelist[_address];
    }

    function getPublicCounter() public view returns (uint256 _counter) { 
        return _publicCounter.current();
    }

    function getPriorityCounter() public view returns (uint256 _counter) { 
        return _priorityCounter.current();
    }

    function getWhitelistCounter() public view returns (uint256 _counter) { 
        return _whitelistCounter.current();
    }
    
    // Setters
    function setPriorityPrice(uint _priorityPrice) external onlyOwner {
        priorityPrice = _priorityPrice;
    }

    function setWhitelistPrice(uint _whitelistPrice) external onlyOwner {
        whitelistPrice = _whitelistPrice;
    }

    function setMaxReserveMint(uint _maxReserveMint) external onlyOwner {
        maxReserveMint = _maxReserveMint;
    }

    function setMysteryBox(address _mysteryBox) external onlyOwner {
        mysteryBox = _mysteryBox;
    }

    function setDutchStart(uint _start) external onlyOwner {
        dutch.start = _start;
    }

    function setDutchDuration(uint _duration) external onlyOwner {
        dutch.duration = _duration;
    }

    function setDutchStartPrice(uint _startPrice) external onlyOwner {
        dutch.startPrice = _startPrice;
    }

    function setDutchEndPrice(uint _endPrice) external onlyOwner {
        dutch.endPrice = _endPrice;
    }

    function togglePrioritySale() external onlyOwner {
        isPrioritySale = !isPrioritySale;
    }

    function toggleWhitelistSale() external onlyOwner {
        isWhitelistSale = !isWhitelistSale;
    }

    function toggleReserveSale() external onlyOwner {
        isReserveSale = !isReserveSale;
    }

    function togglePublicSale() external onlyOwner {
        isPublicSale = !isPublicSale;
    }

    function setSigner(address _newSigner) external onlyOwner {
        _signer = _newSigner;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function withdrawAll() external onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0);
        for (uint256 sh = 0; sh < _shareholders.length; sh++) {
            _widthdraw(_shareholders[sh], (balance * _shares[sh]) / 1000);
        }
    }
    
    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }
}
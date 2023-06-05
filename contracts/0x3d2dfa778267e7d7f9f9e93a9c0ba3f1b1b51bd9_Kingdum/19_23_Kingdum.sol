// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "./ERC721Tradable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Kingdum is ERC721Tradable {
    bytes32 public merkleRoot;
    bool public salePublicIsActive;
    bool public saleWhitelistIsActive;
    uint256 public maxByMint;
    uint256 public maxSupply;
    uint256 public maxPublicSupply;
    uint256 public maxReservedSupply;
    uint256 public fixedPrice;
    address public daoAddress;
    address public devAddress;
    string internal baseTokenURI;
    mapping(address => bool) internal whitelistClaimed;
    using Counters for Counters.Counter;
    Counters.Counter private _totalPublicSupply;
    Counters.Counter private _totalReservedSupply;
    
    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress
    ) ERC721Tradable(_name, _symbol, _proxyRegistryAddress) {
        maxByMint = 10;
        maxSupply = 3333;
        maxReservedSupply = 333;  
        maxPublicSupply = maxSupply - maxReservedSupply;
        fixedPrice = 0.033 ether;
        daoAddress = 0xd85e4B5B1b8f38a7d1794DDAe7eDeF2f9896FF18;
        devAddress = 0xF5DFaab9718195d7F829571966681FF24de65E53;
        baseTokenURI = "https://mint.kingdum.xyz/api/meta/1/";
    }

    function contractURI() public pure returns (string memory) {
        return "https://mint.kingdum.xyz/api/contract/1";
    }

    function _mintN(uint numberOfTokens) private {
        require(numberOfTokens <= maxByMint, "Max mint exceeded");
        require(_totalPublicSupply.current() + numberOfTokens <= maxPublicSupply, "Max supply reached");
        for(uint i = 0; i < numberOfTokens; i++) {
            _totalPublicSupply.increment();
            _safeMint(msg.sender, this.totalSupply());
        }
    }

    function mintPublic(uint numberOfTokens) external payable {
        require(salePublicIsActive, "Sale not active");
        require(fixedPrice * numberOfTokens <= msg.value, "Eth val incorrect");
        _mintN(numberOfTokens);
    }

    function mintWhitelist(uint numberOfTokens, bytes32[] calldata _merkleProof) external payable {
        require(saleWhitelistIsActive, "Whitelist sale not active");
        require(!whitelistClaimed[msg.sender], "Address has already claimed");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Must be whitelisted");
        require(fixedPrice * numberOfTokens <= msg.value, "Eth val incorrect");
        whitelistClaimed[msg.sender] = true;
        _mintN(numberOfTokens);
    }

    function mintReserved(address _to, uint numberOfTokens) external onlyOwner {
        require(_totalReservedSupply.current() + numberOfTokens <= maxReservedSupply, "Max supply reached");
        for(uint i = 0; i < numberOfTokens; i++) {
            _totalReservedSupply.increment();
            _safeMint(_to, this.totalSupply());
        }
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(baseTokenURI, Strings.toString(_tokenId)));
    }

    function totalSupply() public view returns (uint256) {
        return _totalPublicSupply.current() + _totalReservedSupply.current();
    }

    function totalPublicSupply() public view returns (uint256) {
        return _totalPublicSupply.current();
    }

    function totalReservedSupply() public view returns (uint256) {
        return _totalReservedSupply.current();
    }

    function flipSalePublicStatus() external onlyOwner {
        salePublicIsActive = !salePublicIsActive;
    }

    function flipSaleWhitelistStatus() external onlyOwner {
        saleWhitelistIsActive = !saleWhitelistIsActive;
    }

    function setAddress(address _daoAddress, address _devAddress) external onlyOwner {
        daoAddress = _daoAddress;
        devAddress = _devAddress;
    }

    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setAuction(uint256 _fixedPrice, uint256 _maxByMint, uint256 _maxSupply, uint256 _maxReservedSupply) external onlyOwner {
        fixedPrice = _fixedPrice;
        maxByMint = _maxByMint;
        maxSupply = _maxSupply;
        maxReservedSupply = _maxReservedSupply;  
        maxPublicSupply = maxSupply - maxReservedSupply;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _withdraw(devAddress, balance * 10 / 100);
        _withdraw(daoAddress, address(this).balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Tx failed");
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner { 
        merkleRoot = _merkleRoot;
    }

    function isWhitelistClaimed(address _address) public view returns (bool) {
        return whitelistClaimed[_address];
    }

}
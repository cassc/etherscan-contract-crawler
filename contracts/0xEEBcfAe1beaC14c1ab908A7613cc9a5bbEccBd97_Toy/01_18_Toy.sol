// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC721Tradable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Toy is ERC721Tradable {
    bool public salePublicIsActive;
    uint256 public maxByMint;
    uint256 public maxSupply;
    uint256 public maxPublicSupply;
    uint256 public maxReservedSupply;
    uint256 public fixedPrice;
    address public daoAddress;
    string internal baseTokenURI;
    using Counters for Counters.Counter;
    Counters.Counter private _totalPublicSupply;
    Counters.Counter private _totalReservedSupply;

    mapping(uint256 => string) public generativeArtScript;
    mapping(uint256 => bytes32) public tokenIdToHash;
    mapping(bytes32 => uint256) public hashToTokenId;
    
    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress
    ) ERC721Tradable(_name, _symbol, _proxyRegistryAddress) {
        maxByMint = 2;
        maxSupply = 576;
        maxReservedSupply = 10;  
        maxPublicSupply = maxSupply - maxReservedSupply;
        fixedPrice = 0.1 ether;
        daoAddress = 0x8A09928a0623155F0554F42427e27b8EE88411fB;
        baseTokenURI = "https://toys.0xtechno.art/api/toys/meta/";
    }

    function contractURI() public pure returns (string memory) {
        return "https://toys.0xtechno.art/api/toys/contract/1";
    }

    function _mintN(uint numberOfTokens) private {
        require(numberOfTokens <= maxByMint, "Max mint exceeded");
        require(_totalPublicSupply.current() + numberOfTokens <= maxPublicSupply, "Max supply reached");
        for(uint i = 0; i < numberOfTokens; i++) {
            _totalPublicSupply.increment();
            uint256 tokenIdToBe = this.totalSupply();
            _setHash(tokenIdToBe);
            _safeMint(msg.sender, this.totalSupply());
        }
    }

    function mintPublic(uint numberOfTokens) external payable {
        require(salePublicIsActive, "Sale not active");
        uint256 totalPrice = fixedPrice * numberOfTokens; 
        require(totalPrice <= msg.value, "Not enough ETH");
        _mintN(numberOfTokens);
    }

    function mintReserved(address _to, uint numberOfTokens) external onlyOwner {
        require(_totalReservedSupply.current() + numberOfTokens <= maxReservedSupply, "Max supply reached");
        for(uint i = 0; i < numberOfTokens; i++) {
            _totalReservedSupply.increment();
            _setHash(this.totalSupply());
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

    function setDaoAddress(address _daoAddress) external onlyOwner {
        daoAddress = _daoAddress;
    }

    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setFixedPrice(uint256 _fixedPrice) external onlyOwner {
        fixedPrice = _fixedPrice;
    }

    function setMaxByMint(uint256 _maxByMint) external onlyOwner {
        maxByMint = _maxByMint;
    }

    function setSupply(uint256 _maxSupply, uint256 _maxReservedSupply) external onlyOwner {
        maxSupply = _maxSupply;
        maxReservedSupply = _maxReservedSupply;
        maxPublicSupply = _maxSupply - _maxReservedSupply;
    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0);
        _withdraw(daoAddress, balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Tx failed");
    }

    function updateScript(uint256[] memory _indexes, string[] memory _scripts)
        external
        onlyOwner
    {
        require(
            _indexes.length == _scripts.length,
            "Array lengths are different"
        );
        for (uint256 i = 0; i < _scripts.length; i++) {
            generativeArtScript[_indexes[i]] = _scripts[i];
        }
    }

    function _generateRandomHash(uint random) private view returns (bytes32) {
        return keccak256(abi.encodePacked(block.number, blockhash(block.number - 1), msg.sender, random));
    }

    function _setHash(uint256 tokenIdToBe) private {
        bytes32 hash;
        hash = _generateRandomHash(tokenIdToBe);
        tokenIdToHash[tokenIdToBe]=hash;
        hashToTokenId[hash]=tokenIdToBe;
    }

}
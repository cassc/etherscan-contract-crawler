// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC721Tradable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

interface IToken {
    function balanceOf(address owner) external returns (uint256);
}

contract Grail is ERC721Tradable {
    bool public salePublicIsActive;
    uint256 public maxByMint = 1;
    uint256 public maxSupply;
    uint256 public maxPublicSupply;
    uint256 public maxReservedSupply;
    address public daoAddress;
    string internal baseTokenURI;

    // Dutch auction
    uint256 public startTime;
    uint256 public maxPrice = 3.2 ether;
    uint256 public minPrice =  0.2 ether;
    uint256 public timeDelta = 1 minutes;
    uint256 public priceDelta = 0.05 ether;

    mapping(uint256 => string) public generativeArtScript;
    mapping(uint256 => bytes32) public tokenIdToHash;
    mapping(bytes32 => uint256) public hashToTokenId;

    // Rare
    mapping(uint256 => bytes32) public curatedHashes;

    using Counters for Counters.Counter;
    Counters.Counter private _totalPublicSupply;
    Counters.Counter private _totalReservedSupply;
    
    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress
    ) ERC721Tradable(_name, _symbol, _proxyRegistryAddress) {
        maxSupply = 269;
        maxReservedSupply = 7;
        maxPublicSupply = maxSupply - maxReservedSupply; 
        daoAddress = 0x63fE60e3373De8480eBe56Db5B153baB1A431E38;
        baseTokenURI = "https://grailers.com/api/grail/1/meta/";
    }

    function contractURI() public pure returns (string memory) {
        return "https://grailers.com/api/grail/1/contract";
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

    function _generateRandomHash(uint random) private view returns (bytes32) {
        return keccak256(abi.encodePacked(block.number, blockhash(block.number - 1), msg.sender, random));
    }

    function _setHash(uint256 tokenIdToBe) private {
        bytes32 hash;
        if ( curatedHashes[tokenIdToBe] != bytes32(0) ) {
            hash = curatedHashes[tokenIdToBe];
        } else {
            hash = _generateRandomHash(tokenIdToBe);
        }
        tokenIdToHash[tokenIdToBe]=hash;
        hashToTokenId[hash]=tokenIdToBe;
    }

    function mintPublic(uint numberOfTokens) external payable {
        require(salePublicIsActive, "Sale not active");
        uint256 totalPrice = getCurrentPrice() * numberOfTokens; 
        require(totalPrice <= msg.value, "Not enough ETH");
        _mintN(numberOfTokens);
        // Return change (if any)
        uint256 change = msg.value - totalPrice;
        payable(msg.sender).transfer(change);
    }

    function mintReserved(address _to, uint numberOfTokens) external onlyOwner {
        require(_totalReservedSupply.current() + numberOfTokens <= maxReservedSupply, "Max supply reached");
        for(uint i = 0; i < numberOfTokens; i++) {
            _totalReservedSupply.increment();
            _setHash(this.totalSupply());
            _safeMint(_to, this.totalSupply());
        }
    }

    function getCurrentPrice() public view returns (uint256) {
        if (!salePublicIsActive) {
            return maxPrice;
        }
        return _getCurrentPrice(startTime, block.timestamp, maxPrice, minPrice);
    }

    function _getCurrentPrice(
        uint256 _startTime,
        uint256 _currentTime,
        uint256 _maxPrice,
        uint256 _minPrice
    ) internal view virtual returns (uint256) {
        if (_currentTime < _startTime) {
            return _maxPrice;
        }
        // Drop by x eth every y minutes
        uint256 priceDiff = ((_currentTime - _startTime) / timeDelta) * priceDelta;
        priceDiff = Math.min(priceDiff, _maxPrice);
        return Math.max(_minPrice, _maxPrice - priceDiff);
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

    function startAuction() external onlyOwner {
        startTime = block.timestamp;
        salePublicIsActive = true;
    }

    function pauseAuction() external onlyOwner {
        salePublicIsActive = false;
    } 

    function setDaoAddress(address _daoAddress) external onlyOwner {
        daoAddress = _daoAddress;
    }

    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setSupply(uint256 _maxSupply, uint256 _maxReservedSupply) external onlyOwner {
        maxSupply = _maxSupply;
        maxReservedSupply = _maxReservedSupply;
        maxPublicSupply = maxSupply - maxReservedSupply; 
    }

    function setAuction(uint256 _maxPrice, uint256 _minPrice, uint256 _timeDelta, uint256 _priceDelta) external onlyOwner {
        maxPrice = _maxPrice;
        minPrice = _minPrice;
        timeDelta = _timeDelta;
        priceDelta = _priceDelta;
    }

    function setMaxByMint(uint256 _maxByMint) external onlyOwner {
        maxByMint = _maxByMint;
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

    /*
    * Generative Art Script
    */
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

    function updateCurated(uint256[] memory _indexes, bytes32[] memory _curatedHashes)
        external
        onlyOwner
    {
        require(
            _indexes.length == _curatedHashes.length,
            "Array lengths are different"
        );
        for (uint256 i = 0; i < _indexes.length; i++) {
            curatedHashes[_indexes[i]] = _curatedHashes[i];
        }
    }

}
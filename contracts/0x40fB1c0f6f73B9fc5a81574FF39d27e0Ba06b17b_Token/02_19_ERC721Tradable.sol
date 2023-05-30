// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./common/meta-transactions/ContentMixin.sol";
import "./common/meta-transactions/NativeMetaTransaction.sol";



contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title ERC721Tradable
 * ERC721Tradable - ERC721 contract that whitelists a trading address, and has minting functionality.
 */
abstract contract ERC721Tradable is ContextMixin, ERC721Enumerable, NativeMetaTransaction, Ownable {
    using SafeMath for uint256;

    address proxyRegistryAddress;
    
    mapping (address => bool) operators;
    mapping (uint256 => uint256) tokenToSeries;

    struct Series {
        string      name;
        string      baseURI;
        uint256     start;
        uint256     current;
        uint256     supply;
    }
    Series[]    collections;

    event NewCollection(uint256 collection_id,string name,string baseURI,uint256 start,uint256 supply);
    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress
    ) ERC721(_name, _symbol) {
        proxyRegistryAddress = _proxyRegistryAddress;
        _initializeEIP712(_name);
    }

    modifier ownerOrOperator() {
        require(msgSender() == owner() || operators[msgSender()],"caller is neither the owner nor the operator");
        _;
    }

    function setOperator(address _operator, bool status) external onlyOwner {
        if (status) {
        operators[_operator] = status;
        } else {
            delete operators[_operator];
        }
    }

    function addSeries(
        string[]    memory  _names,
        string[]    memory  baseURIs,
        uint256[]   memory  _starts,
        uint256[]   memory  _supplys
    ) external onlyOwner {
        require (_names.length == baseURIs.length, "len 1 & 2 not equal");
        require (_names.length == _starts.length, "len 1 & 3 not equal");
        require (_names.length == _supplys.length, "len 1 & 4 not equal");
        for (uint j = 0; j < _names.length; j++){
            collections.push(Series(_names[j],baseURIs[j],_starts[j],0, _supplys[j]));
            emit NewCollection(collections.length-1,_names[j],baseURIs[j],_starts[j],  _supplys[j]);
        }
    }

    /**
     * @dev Mints a token to an address with a tokenURI.
     * @param _to address of the future owner of the token
     */
    function preMintTo(address _to, uint256[] memory _seriesz) public ownerOrOperator {
        for (uint j = 0; j < _seriesz.length; j++){
            uint256 collection = _seriesz[j];
            require(collection < collections.length, "Invalid Collection");
            uint256 newTokenId = _getNextTokenId(collection);
            _mint(_to, newTokenId);
            tokenToSeries[newTokenId] = collection;
        }
    }


    /**
     * @dev Mints a token to an address with a tokenURI.
     * @param _to address of the future owner of the token
     */
    function mintTo(address _to, uint256 collection) public ownerOrOperator {
        require(collection < collections.length, "Invalid Collection");
        uint256 newTokenId = _getNextTokenId(collection);
        _mint(_to, newTokenId);
        tokenToSeries[newTokenId] = collection;
    }

    function privateMint(address _to, uint256 collection) public onlyOwner {
        require(collections[collection].supply == 250,"Wrong collection");
        for (uint i = 0; i < 25; i++) {
            uint256 newTokenId = _getNextTokenId(collection);
            _mint(_to, newTokenId);
            tokenToSeries[newTokenId] = collection;
        }
    }

    /**
     * @dev calculates the next token ID based on value of _currentTokenId
     * @return uint256 for the next token ID
     */
    function _getNextTokenId(uint256 collection) private returns (uint256) {
        Series storage coll = collections[collection];
        uint pointer = coll.current++;
        require(pointer < coll.supply, "No tokens available");
        uint256 reply = coll.start + pointer;
        return reply;
    }

    /**
     * @dev increments the value of _currentTokenId
     */

    function baseTokenURI() virtual public view returns (string memory);

    function seriesURI(uint256 collection) public view returns (string memory) {
        require(collection < collections.length, "Invalid Collection");
        return collections[collection].baseURI;
    }

    function seriesStart(uint256 collection) internal view returns (uint256) {
        require(collection < collections.length, "Invalid Collection");
        return collections[collection].start;
    }

    function seriesName(uint256 collection) public view returns (string memory) {
        require(collection < collections.length, "Invalid Collection");
        return collections[collection].name;
    }


    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        require(_exists(_tokenId),"Token does not exist");
        uint256 collection = tokenToSeries[_tokenId];
        uint256 adjustedID = _tokenId - seriesStart(collection)+1;
        return string(abi.encodePacked(baseTokenURI(),seriesURI(collection),"/", Strings.toString(adjustedID)));
    }

    function numSeries() external view returns (uint256) {
        return collections.length;
    }

    function available(uint256 collectionId) external view returns (uint256) {
        require(collectionId < collections.length, "Invalid Collection");
        Series memory coll = collections[collectionId];
        return coll.supply - coll.current;
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address _owner, address operator)
        override
        public
        view
        returns (bool)
    {
        
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == operator) {
            return true;
        }
        
        return super.isApprovedForAll(_owner, operator);
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender()
        internal
        override
        view
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }
}
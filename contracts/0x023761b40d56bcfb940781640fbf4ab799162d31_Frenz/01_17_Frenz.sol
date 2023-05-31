// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "./OwnableRoyalties.sol";

import "hardhat/console.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title Basic721
 * Basic721 - ERC721 contract that has limited quantity minting functionality.
 */
contract Frenz is ERC721Enumerable, OwnableRoyalties {
    string baseURI;
    address proxyRegistryAddress;
    string contractURL;
    address public buyContract;
    
    uint256 private _useBuyContract;
    
    uint256 public price;
    uint256 public paused;
    uint256 public maxNFTs;
    string public baseExtension;

    mapping(uint256 => uint256) public lastTransfer;
    mapping(uint256 => mapping(uint256 => uint256)) private collected;
    uint256 private isHidden;

    // Royality fee BPS (1/100ths of a percent, eg 1000 = 10%)
    uint16 private immutable _feeBps;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _limit,
        address _proxyRegistryAddress,
        string memory _IPFSURL,
        string memory _IPFSURLMETA
    ) ERC721(_name, _symbol) {
        proxyRegistryAddress = _proxyRegistryAddress;
        setBaseURI(string(abi.encodePacked("ipfs://", _IPFSURL)));
        setContractURI(
            string(abi.encodePacked("ipfs://", _IPFSURLMETA, "/metadata.json"))
        );
        // initial values
        _useBuyContract = 1;
        price = 0.1 ether;
        paused = 1;
        maxNFTs = _limit;
        baseExtension = ".json";
        isHidden = 1;
        _feeBps = 500;
    }

    function airdrop(address[] memory _addrs) external virtual onlyOwner {
        uint256 _amount = _addrs.length - 1;
        for (uint256 i = 0; i <= _amount; i++) {
            uint256 currentId = totalSupply() + 1;
            require(currentId <= maxNFTs, "All have been minted.");
            _safeMint(_addrs[i], currentId);
            lastTransfer[currentId] = block.timestamp;
        }
    }

    function buy() public payable virtual returns (bool) {
        require(paused == 0, "Contract is currently paused.");
        require(
            (_useBuyContract == 1 && msg.sender == buyContract) ||
                _useBuyContract == 0,
            "Must use the buy contract."
        );
        require(this.totalSupply() < maxNFTs, "All have been minted.");
        require(msg.value >= price, "Not enough to pay for that.");
        uint256 nextID = totalSupply() + 1;
        require(canMint(nextID), "Can't mint that NFT");
        _buy(nextID);
        return true;
    }

    function buy(uint256 _amount) public payable returns (bool) {
        require(paused == 0, "Contract is currently paused.");
        require(
            (_useBuyContract == 1 && msg.sender == buyContract) ||
                _useBuyContract == 0,
            "Must use the buy contract."
        );
        require(this.totalSupply() + _amount <= maxNFTs, "All have been minted.");
        require(msg.value >= (price * _amount), "Not enough to pay for that.");
        for (uint256 i = 0; i < _amount; i++) {
            uint256 nextID = totalSupply() + 1;
            require(canMint(nextID), "Can't mint that NFT");
            _buy(nextID);
        }
        return true;
    }

    function _buy(uint256 _id) private {
        _safeMint(tx.origin, _id);
        uint256 ts = block.timestamp;
        lastTransfer[_id] = ts;
        emitRaribleInfo(_id);
    }

    function pause(uint256 _state) public onlyOwner {
        paused = _state;
    }

    function setIsHidden(uint256 _state, string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
        isHidden = _state;
    }

    function setBuyContract(address _newAddress) public onlyOwner {
        buyContract = _newAddress;
    }

    function setUseBuyContract(uint256 _state) public onlyOwner {
        _useBuyContract = _state;
    }

    function canMint(uint256 _id) public view virtual returns (bool) {
        return !_exists(_id) && _id > 0 && _id <= maxNFTs;
    }

    function emitRaribleInfo(uint256 _id) public override {
        require(
            owner() == _msgSender() || buyContract == _msgSender(),
            "Unable to emit info if not owner or minter"
        );
        super.emitRaribleInfo(_id);
    }

    function contractURI() public view returns (string memory) {
        return contractURL;
    }

    function setContractURI(string memory _contractURL) public onlyOwner {
        contractURL = _contractURL;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        string memory currentBaseURI = _baseURI();
        if (isHidden == 1) return currentBaseURI;
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        Strings.toString(tokenId),
                        baseExtension
                    )
                )
                : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function stats() public view virtual returns (uint256, uint256,uint256, uint256) {
        return (price, this.totalSupply(), maxNFTs, paused);
    }

    function getLastTransfer(uint256 _id) public returns (uint256) {
        return lastTransfer[_id];
    }

    function hasRedeemed(uint256 _id, uint256 i) public returns (uint256) {
        return collected[_id][i];
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-free listings.
     * Update it with setProxyAddress
     */
    function setProxyAddress(address _a) public onlyOwner {
        proxyRegistryAddress = _a;
    }

    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override
        returns (bool isOperator)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == _operator) {
            return true;
        }

        return ERC721.isApprovedForAll(_owner, _operator);
    }

        /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual override {
        super.safeTransferFrom(from, to, id);
        lastTransfer[id] = block.timestamp;
    }
    
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        super.safeTransferFrom(from, to, tokenId);
        lastTransfer[tokenId] = block.timestamp;
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public virtual override {
        super.safeTransferFrom(from, to, id, data);
        lastTransfer[id] = block.timestamp;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}
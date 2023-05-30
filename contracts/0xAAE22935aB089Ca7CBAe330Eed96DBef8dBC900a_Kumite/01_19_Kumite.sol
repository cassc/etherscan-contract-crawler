// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./MinterACLs.sol";
import "./OwnableRoyalties.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title Kumite
 * Kumite - ERC721 contract
 */
contract Kumite is
    ERC721Enumerable,
    ERC721Burnable,
    OwnableRoyalties,
    MinterACLs
{
    using Counters for Counters.Counter;
    Counters.Counter public nftCount;
    string baseURI;
    address proxyRegistryAddress;
    string contractURL;

    mapping(uint256 => uint256) public lastTransfer;
    uint256 private _useBuyContract = 1;
    uint256 public maxPerMint = 10;
    address public buyContract;
    uint256 public paused = 1;
    uint256 public price = .08 ether;
    uint256 public maxNFTs = 9600;
    string public baseExtension = ".json";

    // Royality fee BPS (1/100ths of a percent, eg 1000 = 10%)
    uint16 private immutable _feeBps = 750;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _limit,
        address _proxyRegistryAddress,
        string memory _IPFSURL
    ) ERC721(_name, _symbol) OwnableRoyalties() MinterACLs() {
        proxyRegistryAddress = _proxyRegistryAddress;
        maxNFTs = _limit;
        setBaseURI(string(abi.encodePacked("ipfs://", _IPFSURL, "/")));
        setContractURI(
            string(abi.encodePacked("ipfs://", _IPFSURL, "/metadata.json"))
        );
    }

    modifier salesContract() {
        if (_useBuyContract == 1)
            require(msg.sender == buyContract, "Must be sales contract");
        _;
    }

    function airdrop(address[] memory _addrs) external onlyOwner {
        uint256 supply = nftCount.current();
        require(
            (supply + _addrs.length) < maxNFTs,
            "All NFTs have been minted."
        );
        for (uint256 i = 0; i < _addrs.length; i++) {
            uint256 _id = nftCount.current() + 1;
            _safeMint(_addrs[i], _id);
            nftCount.increment();
        }
    }

    function buy() public payable salesContract {
        require(msg.value >= price, "Not enough to pay for that.");
        uint256 _id = nftCount.current() + 1;
        _buy(_id);
    }

    function buy(uint256 _quantity) public payable salesContract {
        require(msg.value >= price * _quantity, "Not enough to pay for that.");
        require(_quantity <= maxPerMint, "Can't mint that many at a time.");

        for (uint256 _loop = 1; _loop <= _quantity; _loop += 1) {
            uint256 _id = nftCount.current() + 1;
            _buy(_id);
        }
    }

    function _buy(uint256 _id) internal {
        uint256 supply = totalSupply();
        require(paused == 0, "Contract is currently paused.");
        require(
            (_useBuyContract == 1 && msg.sender == buyContract) ||
                _useBuyContract == 0,
            "Must use the buy contract."
        );
        require(supply < maxNFTs, "Not enough left to mint.");
        require(canMint(_id), "Can't mint that NFT");

        _safeMint(tx.origin, _id);
        nftCount.increment();
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function pause(uint256 _state) public onlyOwner {
        paused = _state;
    }

    function canMint(uint256 _id) public view virtual returns (bool) {
        return !_exists(_id) && _id > 0 && _id <= maxNFTs;
    }

    function stats()
        public
        view
        virtual
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (price, totalSupply(), maxNFTs);
    }

    /**
     * Metadata setters
     */

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

    function setMaxNFTs(uint256 _newMax) public onlyOwner {
        maxNFTs = _newMax;
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

    /**
     * Buying setters
     */

    function setBuyContract(address _newAddress) public onlyOwner {
        buyContract = _newAddress;
    }

    function setUseBuyContract(uint256 _state) public onlyOwner {
        _useBuyContract = _state;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function setMaxPerMint(uint256 _newMax) public onlyOwner {
        maxPerMint = _newMax;
    }

    /**
     *
     */

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
        lastTransfer[tokenId] = block.timestamp;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
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
}
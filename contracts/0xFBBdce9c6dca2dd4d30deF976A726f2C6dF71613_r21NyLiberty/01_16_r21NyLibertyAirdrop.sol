// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract r21NyLiberty is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {

    using Counters for Counters.Counter;

    Counters.Counter private supply;

    uint tokenStartIndex;
    address proxyRegistryAddress;
    string baseURI;
    uint256 public maxSupply = 1;
    uint256 public price = 0.1 ether;
    uint256 public paused = 1;
    bytes32 public merkleRoot;
    string contractURL;

    uint16 private immutable royality = 500;
    
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _IPFSURL,
        uint256 _maxSupply,
        uint256 _price,
        address _proxyRegistryAddress,
        uint256 _tokenStartIndex
    ) ERC721(_name, _symbol) { 
        contractURL = string(
            abi.encodePacked("ipfs://", _IPFSURL, "/metadata.json")
        );
        price = _price;
       tokenStartIndex = _tokenStartIndex;
        proxyRegistryAddress = _proxyRegistryAddress;
        maxSupply = _maxSupply;
        setBaseURI(string(abi.encodePacked("ipfs://", _IPFSURL, "/")));
    }

    mapping(address => bool) public allowlistClaimed;

    function mint(bytes32[] memory _merkleProof) public payable{
        require(paused == 0, "Contract is paused");
        require(msg.value == price , "Insufficient funds!");
        require(supply.current() + 1 <= maxSupply, "Max supply exceeded!");
        require(!allowlistClaimed[msg.sender], 'Address has already claimed');
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Not on the allowlist');

        allowlistClaimed[msg.sender] = true;

        _safeMint(msg.sender, supply.current() + tokenStartIndex );

        supply.increment();
    }

    function airdrop(address[] calldata _to) public onlyOwner {
        
        require(_to.length <= maxSupply - supply.current(), "Max supply exceeded!");

        for (uint256 i = 0; i < _to.length; i++){
            _safeMint(_to[i], supply.current() + tokenStartIndex);
            supply.increment();
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function pause(uint256 _state) public onlyOwner {
        paused = _state;
    } 

    function withdraw() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function contractURI() public view returns (string memory) {
        return contractURL;
    }

    function setContractURI(string memory _contractURL) public onlyOwner {
        contractURL = _contractURL;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
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

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

}
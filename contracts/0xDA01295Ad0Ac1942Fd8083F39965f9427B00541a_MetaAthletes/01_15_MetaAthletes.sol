//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "contracts/utils/Counters16.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "hardhat/console.sol";

contract MetaAthletes is ERC721, Pausable, Ownable {
    using Counters16 for Counters16.Counter;
    using Strings for uint256;

    Counters16.Counter private _tokenIdCounter;

    uint256 private _cost;
    uint256 private _maxCountPerAccount;
    uint256 private _maxSupply;
    uint256 private _totalSupply;
    bool private _openMinting;
    bytes32 private _root;
    string private _uri;
    uint256[3] private _tiersIndex;
    string[3] private _mapURIs;
    mapping(address => uint16[]) private _ownerTokens;
    
    constructor(string memory name, string memory symbol, string memory uri) ERC721(name, symbol) {
        _uri = uri;
        _maxCountPerAccount = 10;
        _maxSupply = 100;
        _openMinting = false;
        _cost = 0.099 ether;
    }

    modifier mintCompliance(uint256 amount) {
        uint256 supply = amount + balanceOf(_msgSender());
        require(amount > 0 && supply <= _maxCountPerAccount, "Invalid mint amount");
        require(_totalSupply + supply <= _maxSupply, "Max supply exceeded");
        _;
    }

    function _baseURI() internal view override returns (string memory) {
       return _uri;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns(string memory) {
        require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");
        
        string memory uri = _getURI(tokenId);
        return string(abi.encodePacked(uri, tokenId.toString(), ".json"));
    }

    function _getURI(uint256 tokenId) internal view returns(string memory) {
        if(tokenId <= _tiersIndex[0]) {
            return bytes(_mapURIs[0]).length > 0 ? _mapURIs[0] : _baseURI();
        } else if(tokenId > _tiersIndex[0] && tokenId <= _tiersIndex[1]) {
            return bytes(_mapURIs[1]).length > 0 ? _mapURIs[1] : _baseURI();
        } else {
            return bytes(_mapURIs[2]).length > 0 ? _mapURIs[2] : _baseURI();
        }
    }
    
    function ownerTokens(address owner) external view returns(uint16[] memory) {
        return _ownerTokens[owner];
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(uint256 amount, bytes32[] calldata proof) public payable whenNotPaused mintCompliance(amount) {
        require(msg.value == _cost * amount, "Insufficient funds");
        require(_msgSender() == tx.origin, "No minting from contract call");

        if(_openMinting == false) {
            bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
            require(MerkleProof.verify(proof, _root, leaf), "Invalid proof");
        }

        _batchMint(_msgSender(),amount);
    }

    function _batchMint(address to, uint256 amount) internal {
        for(uint256 i; i < amount; i++) {
            _tokenIdCounter.increment();
            uint16 tokenId = _tokenIdCounter.current();
            _ownerTokens[to].push(tokenId);
            _mint(to,tokenId);
        }

        _totalSupply += amount;
    }

    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "Address: insufficient balance");

        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Failed to withdraw");
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // getters / setters
    function getCost() external view returns(uint256) {
        return _cost;
    }

    function setCost(uint256 cost) external onlyOwner {
        _cost = cost;
    }

    function getMaxCountPerAccount() external view returns(uint256) {
        return _maxCountPerAccount;
    }

    function setMaxCountPerAccount(uint256 maxCountPerAccount) external onlyOwner {
        _maxCountPerAccount = maxCountPerAccount;
    }

    function getMaxSupply() external view returns(uint256) {
        return _maxSupply;
    }

    function setMaxSupply(uint256 maxSupply) external onlyOwner {
        _maxSupply = maxSupply;
    }

    function getMapURIs(uint256 index) external view returns(string memory) {
        require(index < _mapURIs.length, "Index out of bounds");
        return _mapURIs[index];
    }

    function setBaseURI(string memory uri) external onlyOwner {
        _uri = uri;
    }

    function setMapURIs(uint256 index, string memory uri) public onlyOwner {
        require(index < _mapURIs.length, "Index out of bounds");

        //require(bytes(_mapURIs[index]).length == 0, "Map uri for this index already set");
        _mapURIs[index] = uri;
    }

    function setTiersIndex(uint256[] memory values) external onlyOwner {
        require(values.length == _tiersIndex.length, "Invalid indexes count");
        for(uint256 i = 0; i < _tiersIndex.length; i++) {
            _tiersIndex[i] = values[i];
        }
    }

    function getTiersIndex() external view returns(uint256[3] memory) {
        return _tiersIndex;
    }

    function setRoot(bytes32 root) external onlyOwner {
        _root = root;
    }

    function setOpenMinting(bool openMinting) external onlyOwner {
        _openMinting = openMinting;
    }

    function getOpenMinting() external view returns(bool) {
        return _openMinting;
    }
}
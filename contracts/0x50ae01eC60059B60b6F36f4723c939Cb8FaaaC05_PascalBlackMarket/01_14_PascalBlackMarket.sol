// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract PascalBlackMarket is ERC721, Ownable, ERC721Burnable {
    // Token state
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 private _maxSupply = 1900;
    uint256 private _mintValue = 25000000000000000;
    uint256 private _maxAmountInOneTransaction = 10;
    address private _feeReceiver;



    string public _provenanceHash;
    string public _baseURL;

    bool private _isMintOpen = false;

    constructor() ERC721("Pascal Black Market", "PBM") {}

    function mint(uint256 amount) external payable {
        require(_isMintOpen, "Mint is not active.");
        require(amount > 0 && amount <= _maxAmountInOneTransaction, "You can mint between 1 and maxAmountInOneTransaction in one transaction.");
        require(_tokenIds.current() + amount <= _maxSupply, "Can not mint more than max supply.");
        require(msg.value >= amount * _mintValue, "Insufficient payment");

        for (uint256 i = 0; i < amount; i++) {
            _tokenIds.increment();
            _mint(msg.sender, _tokenIds.current());
        }

        bool success = false;
        (success,) = _feeReceiver.call{value : msg.value}("");
        require(success, "Failed to send to owner");
    }

    function flipMintState() public onlyOwner {
        _isMintOpen = !_isMintOpen;
    }

    function setMintValue(uint256 newMintValue) public onlyOwner {
        _mintValue = newMintValue;
    }

    function setFeeReceiver(address newFeeReceiver) public onlyOwner {
        _feeReceiver = newFeeReceiver;
    }

    function setMaxSupply(uint256 newMaxSupply) public onlyOwner {
        _maxSupply = newMaxSupply;
    }

    function setProvenanceHash(string memory newProvenanceHash) public onlyOwner {
        _provenanceHash = newProvenanceHash;
    }

    function setBaseURL(string memory newBaseURI) public onlyOwner {
        _baseURL = newBaseURI;
    }

    function setMaxAmountInOneTransaction(uint256 newMaxAmountInOneTransaction) public onlyOwner {
        _maxAmountInOneTransaction = newMaxAmountInOneTransaction;
    }

    // Getters
    function _baseURI() internal view override returns (string memory) {
        return _baseURL;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    function isMintOpen() public view returns (bool) {
        return _isMintOpen;
    }

    function mintValue() public view returns (uint256) {
        return _mintValue;
    }

    function feeReceiver() public view returns (address) {
        return _feeReceiver;
    }

    function maxAmountInOneTransaction() public view returns (uint256) {
        return _maxAmountInOneTransaction;
    }
}
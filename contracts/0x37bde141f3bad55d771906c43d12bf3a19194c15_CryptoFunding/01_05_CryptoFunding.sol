// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A.sol";

contract CryptoFunding is ERC721A, Ownable {

    uint public constant _VERSION = 1;
    string private _baseTokenURI;
    address public payeeAddress;
    bool public paused;
    uint256 public unitPrice;
    uint256 public maxSupply;

    constructor(
        string memory _name, 
        string memory _symbol
    ) 
    ERC721A(_name, _symbol) 
    {
      
    }

    function initializeConfig(   
        address _payeeAddress,
        string memory _uri,
        bool _sbt,
        uint256 _unitPrice,
        uint256 _maxSupply
        )  external onlyOwner {

        payeeAddress  = _payeeAddress;
        _baseTokenURI = _uri;
        _soulboundToken = _sbt;
        unitPrice  = _unitPrice;
        maxSupply = _maxSupply;
    }

    function setUnitPrice(uint256 _unitPrice) external onlyOwner {
        unitPrice  = _unitPrice;
    }

    function setPausedMint(bool _paused) external onlyOwner {
        paused  = _paused;
    }

    function setCashInAddress(address to) external onlyOwner {
        payeeAddress  = to;
    }

    function minterMint(
            address to, 
            uint256 quantity,
            address payee,
            uint256 price
        ) external payable {
        
        require(maxSupply >= totalSupply() + quantity, "insufficent supply");
        require(!paused, "mint is paused");
        require(msg.value >= unitPrice * quantity, "insufficent balance");
        require(payeeAddress == payee, "invalid payee address");
        payable(payeeAddress).transfer(price);
        _mint(to, quantity);
    }

    function mint(address to, uint256 quantity) external onlyOwner {
        _mint(to, quantity);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer Failed");
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, "?id=", _toString(tokenId))) : '';
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}
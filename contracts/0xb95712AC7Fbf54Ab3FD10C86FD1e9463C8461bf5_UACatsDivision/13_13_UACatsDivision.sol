// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract UACatsDivision is ERC721, Ownable, ReentrancyGuard {
    uint public constant MAX_SUPPLY = 10000;
    uint public constant PRICE = 0.065 ether;
    uint public constant MAX_PER_ACCOUNT = 99;
    uint private _currentId = 0;

    string public baseURI;
    string private _contractURI;

    bool public saleIsActive = false;

    mapping (address => uint) private _alreadyMinted;

    constructor(string memory _initialBaseURI, string memory _initialContractURI) ERC721("UACatsDivision", "UACD") {
        baseURI = _initialBaseURI;
        _contractURI = _initialContractURI;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function setContractURI(string memory uri) public onlyOwner {
        _contractURI = uri;
    }

    function totalSupply() public view returns (uint) {
        return _currentId;
    }

    function alreadyMinted(address addr) public view returns (uint) {
        return _alreadyMinted[addr];
    }

    function activateSales(bool _isActive) public onlyOwner {
        saleIsActive = _isActive;
    }

    function mintNFTs(uint amount) public payable nonReentrant {
        address sender = msg.sender;

        require(saleIsActive, "Sale is closed");
        require(amount != 0, "Amount should not be a zero");
        require(amount <= (MAX_PER_ACCOUNT - _alreadyMinted[sender]), "You have exceeded max NFT count for your account");
        require(amount <= (MAX_SUPPLY - _currentId), "Not enough NFT left to mint");
        require(msg.value >= amount * PRICE, "Not enough ether to purchase NFT");

        _internalMint(sender, amount);
    }

    function mintNFTsOwner(uint amount) public onlyOwner {
        require(amount != 0, "Amount should not be a zero");
        require(amount <= (MAX_SUPPLY - _currentId), "Not enough tokens left to mint");
        _internalMint(msg.sender, amount);
    }

    function _internalMint(address to, uint amount) private {
        _alreadyMinted[to] += amount;
        for (uint i = 0; i < amount; i++) {
            _currentId++;
            _safeMint(to, _currentId);
        }
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "No ether to withdraw");
        (bool success, ) = msg.sender.call{value:balance}("");
        require(success, "Transfer failed");
    }
}
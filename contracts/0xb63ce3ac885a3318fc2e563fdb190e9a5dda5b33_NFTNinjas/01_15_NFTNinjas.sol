//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFTNinjas is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _ninjaCounter;
    uint public MAX_NINJA = 5555;
    uint public PRESALE_MAX_NINJA = 4000;
    uint256 public ninjaPrice = 0.12 ether;
    uint256 public presalePrice = 0.1 ether;
    string public baseURI;
    bool public saleIsActive = false;
    bool public presaleIsActive = false;
    uint public constant maxNinjaTxn = 3;
    address private _manager;

    mapping(address => uint256) whitelistMintCount;

    constructor() ERC721("NFT NINJAS", "NINJA"){
    }

    function setManager(address manager) public onlyOwner {
        _manager = manager;
    }
    
    modifier onlyOwnerOrManager() {
        require(owner() == _msgSender() || _manager == _msgSender(), "Caller is not the owner or manager");
        _;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwnerOrManager {
        baseURI = newBaseURI;
    }
    
    function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }

    function totalToken() public view returns (uint256) {
        return _ninjaCounter.current();
    }

    function whitelistNinjaMinted(address _address) public view returns (uint256){
        return whitelistMintCount[_address];
    }

    function flipPreSale() public onlyOwnerOrManager {
        presaleIsActive = !presaleIsActive;
    }

    function preSaleState() public view returns (bool){
        return presaleIsActive;
    }

    function flipSale() public onlyOwnerOrManager {
        saleIsActive = !saleIsActive;
    }

    function saleState() public view returns (bool){
        return saleIsActive;
    }

    function setPrice(uint256 _price) public  onlyOwnerOrManager{
        ninjaPrice = _price;
    }

    function setPresalePrice(uint256 _price) public onlyOwnerOrManager{
        presalePrice = _price;
    }

    function withdrawForOwner(address payable to) public payable onlyOwnerOrManager{
        to.transfer(address(this).balance);
    }

    function withdrawAll(address _address) public onlyOwnerOrManager {
        uint256 balance = address(this).balance;
        require(balance > 0,"Balance is zero");
        (bool success, ) = _address.call{value: balance}("");
        require(success, "Transfer failed.");
    }

    function _widthdraw(address _address, uint256 _amount) public onlyOwnerOrManager{
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function reserveMintNinja(uint256 reserveAmount, address mintAddress) public onlyOwnerOrManager {
        require(totalSupply() <= MAX_NINJA, "Purchase would exceed max supply of Ninjas");
        for (uint256 i=0; i<reserveAmount; i++){
            _safeMint(mintAddress, _ninjaCounter.current() + 1);
            _ninjaCounter.increment();
        }
    }

    function mintNinjaWhitelist(uint256 numberOfTokens) public payable {
        require(presaleIsActive, "Presale must be active to mint Ninjas");
        require(presalePrice * numberOfTokens <= msg.value, "Ether value sent is not correct");
        require(numberOfTokens <= maxNinjaTxn, "You can only mint 3 Ninjas at a time");
        require(whitelistMintCount[msg.sender] + numberOfTokens <= maxNinjaTxn, "Purchase would exceed the whitelist wallet limit");
        require(totalSupply() + numberOfTokens <= PRESALE_MAX_NINJA, "PRESALE SOLD OUT");

        for (uint256 i=0; i<numberOfTokens; i++){
            uint256 mintIndex = _ninjaCounter.current()+1;
            if (mintIndex <= MAX_NINJA){
                _safeMint(msg.sender, mintIndex);
                _ninjaCounter.increment();
                whitelistMintCount[msg.sender] += 1;
            }
        }
    }

    function mintNinja(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint Ninjas");
        require(ninjaPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");
        require(numberOfTokens <= maxNinjaTxn, "You can only mint 3 Ninjas at a time");
        require(totalSupply() + numberOfTokens <= MAX_NINJA, "NINJAS SOLD OUT");

        for (uint256 i=0; i<numberOfTokens; i++){
            uint256 mintIndex = _ninjaCounter.current()+1;
            if (mintIndex <= MAX_NINJA){
                _safeMint(msg.sender, mintIndex);
                _ninjaCounter.increment();
            }
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}
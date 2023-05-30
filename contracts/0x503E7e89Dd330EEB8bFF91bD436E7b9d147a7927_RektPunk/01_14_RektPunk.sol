// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

contract RektPunk is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string public _baseTokenURI;
    uint256 private _maxMint = 20;
    uint256 private _price = 0.04 ether;
    uint256 public constant MAX_ENTRIES = 10000;
    bool private _saleOpen = false;

    constructor(string memory baseURI) ERC721("Rekt Punk", "RKP")  {
        setBaseURI(baseURI);
    }

    function mint(uint256 num) public nonReentrant payable  {
        uint256 supply = totalSupply();
        require( _saleOpen, "REKT PUNK : It's not sales time." );
        require( msg.value >= _price * num, "REKT PUNK : Insufficient Value");
        require( supply + num < MAX_ENTRIES, "REKT PUNK : Exceeds maximum supply" );
        require( num < (_maxMint+1), "REKT PUNK : Up to 20 can be adopted." );
        
        for(uint256 i; i < num; i++){
          _safeMint(msg.sender, supply + i );
        }

        withdrawAll();
    }

    function tokensOfOwner(address owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokenIds;
    }

    function price() public view returns (uint256){
        return _price;
    }

    function setPrice(uint256 newPrice) public onlyOwner() {
        _price = newPrice;
    }

    function maxMint() public view returns (uint256){
        return _maxMint;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function startSale() public onlyOwner {
        require( !_saleOpen, "REKT PUNK : Already Opened" );
        _saleOpen = true;
    }

    function endSale() public onlyOwner {
        require( _saleOpen, "REKT PUNK : Not Opened" );
        _saleOpen = false;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdrawAll() public payable {
        require(payable(owner()).send(address(this).balance));
    }
}
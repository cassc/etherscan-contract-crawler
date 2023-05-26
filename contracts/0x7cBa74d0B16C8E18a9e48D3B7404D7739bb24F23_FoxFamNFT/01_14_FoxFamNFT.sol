// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

contract FoxFamNFT is ERC721Enumerable, Ownable {

    using SafeMath for uint256;

    string public baseTokenURI;
    uint256 public price = 0.05 ether;
    uint256 public saleState = 0; // 0 = paused, 1 = presale, 2 = live
    uint256 public constant MAX_FOXES = 9900;

    // withdraw addresses
    address public f1;
    address public f2;
    address public f3;

    // List of addresses that have a number of reserved tokens for presale
    mapping (address => uint256) public preSaleReserved;

    constructor(string memory baseURI) ERC721("FoxFam", "FOXFAM")  {
        setBaseURI(baseURI);
    }

    // Override so the openzeppelin tokenURI() method will use this method to create the full tokenURI instead
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function adopt(uint256 num) public payable {
        uint256 supply = totalSupply();
        require( saleState > 1,             "Sale not live" );
        require( num < 10,                  "You can mint a maximum of 10 fantastic foxes" );
        require( supply + num <= MAX_FOXES,  "Exceeds maximum Fox supply" );
        require( msg.value >= price * num,  "Ether sent is not correct" );

        for(uint256 i; i < num; i++){
            _safeMint( msg.sender, supply + i );
        }
    }

    function preSaleAdopt(uint256 num) public payable {
        uint256 supply = totalSupply();
        uint256 reservedAmt = preSaleReserved[msg.sender];
        require( saleState > 0,             "Presale isn't active" );
        require( reservedAmt > 0,           "No tokens reserved for address" );
        require( num <= reservedAmt,        "Can't mint more than reserved" );
        require( supply + num <= MAX_FOXES, "Exceeds maximum Fox supply" );
        require( msg.value >= price * num,   "Ether sent is not correct" );
        preSaleReserved[msg.sender] = reservedAmt - num;
        for(uint256 i; i < num; i++){
            _safeMint( msg.sender, supply + i );
        }
    }


    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    // Edit reserved presale spots
    function setPreSaleWhitelist(address[] memory _a) public onlyOwner {
        for(uint256 i; i < _a.length; i++){
            preSaleReserved[_a[i]] = 10;
        }
    }

    function setPrice(uint256 _newPrice) public onlyOwner() {
        price = _newPrice;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function giveAway(address _to, uint256 _num) external onlyOwner() {
        uint256 supply = totalSupply();
        for(uint256 i; i < _num; i++){
            _safeMint( _to, supply + i );
        }
    }

    function setSaleState(uint256 _saleState) public onlyOwner {
        saleState = _saleState;
    }

    function setAddresses(address[] memory _f) public onlyOwner {
        f1 = _f[0];
        f2 = _f[1];
        f3 = _f[2];
    }

    function withdrawBalance() public payable onlyOwner {
        uint256 _onePerc = address(this).balance.div(100);
        uint256 _f1Amt = _onePerc.mul(41);
        uint256 _f2Amt = _onePerc.mul(50);
        uint256 _f3Amt = _onePerc.mul(9);

        require(payable(f1).send(_f1Amt));
        require(payable(f2).send(_f2Amt));
        require(payable(f3).send(_f3Amt));
    }
}
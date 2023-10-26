// SPDX-License-Identifier: MIT

/*
 _______  ___      ___   _______  __    _    _______  __   __  __    _  ___   _    _______  __   __  ___   __    _  _______  _______ 
|   _   ||   |    |   | |       ||  |  | |  |       ||  | |  ||  |  | ||   | | |  |       ||  | |  ||   | |  |  | ||       ||       |
|  |_|  ||   |    |   | |    ___||   |_| |  |    _  ||  | |  ||   |_| ||   |_| |  |_     _||  |_|  ||   | |   |_| ||    ___||  _____|
|       ||   |    |   | |   |___ |       |  |   |_| ||  |_|  ||       ||      _|    |   |  |       ||   | |       ||   | __ | |_____ 
|       ||   |___ |   | |    ___||  _    |  |    ___||       ||  _    ||     |_     |   |  |       ||   | |  _    ||   ||  ||_____  |
|   _   ||       ||   | |   |___ | | |   |  |   |    |       || | |   ||    _  |    |   |  |   _   ||   | | | |   ||   |_| | _____| |
|__| |__||_______||___| |_______||_|  |__|  |___|    |_______||_|  |__||___| |_|    |___|  |__| |__||___| |_|  |__||_______||_______|

These aren't ordinary aliens...
8,888 Alien Punk Things
First 1500 are free, then 0.01 ETH

Alien Punk Things are 8,888 unique and randomly generated NFTs.
Traits are inspired by many NFTs including Cryptopunks, Alien Frens, Thingdoms, Cryptoadz, mfers, and more...

Benefits to holding an NFT include discounted minting price on our next evolution project, eligibility for NFT givaways. 
Come join our welcoming community and Discord!

*/

pragma solidity ^0.8.0;

import "./lib/ERC721EnumerableLite.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract AlienPunkThings is ERC721EnumerableLite, Ownable, PaymentSplitter {
    
    using Strings for uint256;

    uint public _price = 0.015 ether;
    uint public _max = 8888;
    uint public _txnLimit = 20;
    bool public _saleIsActive = false;

    uint public _totalFree = 1500;
    uint public _freeLimit = 3;
    uint public _freeMinted = 0;
    mapping(address => uint) public _freeTracker;

    string private _tokenBaseURI;

    address[] private addressList = [
        0x0beAF25a1De14FAF9DB5BA0bad13B70267e3D01e,
        0xBc3B2d37c5B32686b0804a7d6A317E15173d10A7,
        0xe0478e355CAb72D60c31b9c73c2656826BC016F7
    ];
    
    uint[] private shareList = [
        45,
        45,
        10
    ];

    constructor() 
        ERC721B("AlienPunkThings", "APT")
        PaymentSplitter(addressList, shareList) {   
    }

    function tokenURI(uint256 tokenId) external view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(_tokenBaseURI, tokenId.toString()));
    } 

    function setBaseURI(string memory uri) public onlyOwner {
        _tokenBaseURI = uri;
    }

    function flipSaleState() public onlyOwner {
        _saleIsActive = !_saleIsActive;
    }

    function mint(uint total) public payable {
        require(_saleIsActive, "Sale is not active");
        require(total > 0, "Number to mint must be greater than 0");
        require(total <= _txnLimit, "Over transaction limit");
        require(calcMintingFee(total) <= msg.value, "Ether value sent is not correct");
        uint256 supply = _owners.length;
        require(supply + total <= _max, "Purchase would exceed max supply");
        
        for(uint i = 0; i < total; i++) {
            _safeMint(msg.sender, supply++);
        }
    }

    function calcMintingFee(uint total) internal returns(uint cost) {
        uint freeMints = 0;

        if(_freeMinted < _totalFree && _freeTracker[msg.sender] < _freeLimit) {
            freeMints = Math.min(_freeLimit, total);
            freeMints = Math.min(freeMints, _freeLimit - _freeTracker[msg.sender]);
            require(_freeMinted + freeMints <= _totalFree, "No more free mints available");
            _freeTracker[msg.sender] += freeMints;
            _freeMinted += freeMints;
        }

        return (total - freeMints) * _price;
    }
    
    function freeMintsRemaining(address addr) public view returns(uint remaining) {
        return _freeLimit - _freeTracker[addr];
    }
}
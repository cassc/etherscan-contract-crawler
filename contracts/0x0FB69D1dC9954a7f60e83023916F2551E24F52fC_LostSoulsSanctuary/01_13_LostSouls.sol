// SPDX-License-Identifier: MIT

// Lost Souls Sanctuary's research has lead us to uncover earth shattering truths about how our souls navigate in the after-life.
// What we've found is truly shocking, something that various three letter agencies won't like, or worse try to supress/slander if the information was released via mutable channels.
// Souls roam this very earth frantically trying to make whole with the universe before their time is up and they are forever striken to the bowels of the underworld.
// All hope is not lost! Though the discovery of the Higgs boson particle a group of ghost-savers have established communication with 10,000 Lost Souls and struck a deal. 
// The deal: a Sanctuary will be setup to help the Souls discover their mistakes, changes their lives and pass through to the elusive good place,
// in return the Lost Souls Sanctuary will be given exclusive access to study the ectoplasmic layer the Soul's reside in so we may better understand our mortal role here on Earth.
//
// <3 LS Sanctuary team
// @glu

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract LostSoulsSanctuary is ERC721Enumerable, Ownable {

    string public SOUL_PROVENANCE = "";
    string _baseTokenURI;
    uint256 public constant MAX_SOULS = 9999;
    uint256 private soulReserved = 125;
    uint256 public constant maxSoulsPurchase = 20;
    uint256 private soulPrice = 0.03 ether;
    bool public salePaused = true;

    // Team - 50%
    address t1;
    address t2;
    address t3;
    address t4;
    // 50% - MUTLISIG // 40% MUTLISIG, 10% Charity
    address t5;

    constructor(
        address _t1,
        address _t2,
        address _t3,
        address _t4,
        address _t5
        ) ERC721("LostSoulsSanctuary", "LSS")  {
        t1 = _t1;
        t2 = _t2;
        t3 = _t3;
        t4 = _t4;
        t5 = _t5;
    }

    function saveLostSoul(uint256 num) public payable {
        uint256 supply = totalSupply();
        require( !salePaused,                              "Sale paused" );
        require( num <= maxSoulsPurchase,                  "You can adopt a maximum of 20 Souls" );
        require( supply + num <= MAX_SOULS - soulReserved, "Exceeds maximum Souls supply" );
        require( msg.value >= soulPrice * num,             "Ether sent is not correct" );

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

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        SOUL_PROVENANCE = provenanceHash;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        soulPrice = _newPrice;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function getPrice() public view returns (uint256){
        return soulPrice;
    }

    function reserveSouls(address _to, uint256 _amount) external onlyOwner {
        require( _amount <= soulReserved, "Exceeds reserved Soul supply" );

        uint256 supply = totalSupply();
        for(uint256 i; i < _amount; i++){
            _safeMint( _to, supply + i );
        }

        soulReserved -= _amount;
    }

    function pause(bool val) public onlyOwner {
        salePaused = val;
    }

    function withdrawAll() public payable onlyOwner {
        uint sale1 = address(this).balance * 8  / 100;
        uint sale2 = address(this).balance * 6  / 100;
        uint sale3 = address(this).balance * 18 / 100;
        uint sale4 = address(this).balance * 18 / 100;
        uint sale5 = address(this).balance * 50 / 100;

        payable(t1).transfer(sale1);
        payable(t2).transfer(sale2);
        payable(t3).transfer(sale3);
        payable(t4).transfer(sale4);
        payable(t5).transfer(sale5);
    }
}
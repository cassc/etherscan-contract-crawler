// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

/**
 * @title Creature contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract Creature is ERC721Enumerable, Ownable {
    using SafeMath for uint256;

    string public CREATURE_PROVENANCE = "";
    uint256 public constant CreaturePrice = 100000000000000000; //0.1 ETH
    uint public constant maxCreaturePurchase = 10;
    uint256 public MAX_CREATURE = 10000;
    uint public creatureReserve = 300;
    bool public saleIsActive = false;
    string _baseTokenURI;

    // withdraw addresses
    address t1 = 0xe2c16dc2610fF536bb0EB8f50771d3A65F8029Bf; //Danny
    address t2 = 0x7F9B1c94DBAb6F3F5299e30eb9f9B8845d45614B; //Kev
    address t3 = 0xa14f0C4ed666194dE6A55f8Ec4137d8a4a4D84d8; //Jake
    address t4 = 0xC4f842B2Ed481C73010fc1F531469FFB47EE09e9; //J
    constructor(string memory baseURI) ERC721("Creature World", "CREATURE") {
        _baseTokenURI = baseURI;
    }

    function withdraw() public onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    /*
    * Set provenance once it's calculated
    */
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        CREATURE_PROVENANCE = provenanceHash;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    /*
    * Pause sale if active, make active if paused
    */
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    /**
    * Mints  Creatures
    */
    function mintCreature(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint Creature");
        require(numberOfTokens <= maxCreaturePurchase, "Can only mint 15 tokens at a time");
        require(totalSupply().add(numberOfTokens) <= MAX_CREATURE, "Purchase would exceed max supply of Creatures");
        require(CreaturePrice.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");

        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_CREATURE) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function reserveCreatures(address _to, uint256 _reserveAmount) public onlyOwner {        
        uint supply = totalSupply();
        require(_reserveAmount > 0 && _reserveAmount <= creatureReserve, "Not enough reserve left for team");
        for (uint i = 0; i < _reserveAmount; i++) {
            _safeMint(_to, supply + i);
        }
        creatureReserve = creatureReserve.sub(_reserveAmount);
    }


    function withdrawAll() public payable onlyOwner {
        uint256 _danny = address(this).balance * 39/100;
        uint256 _kevy = address(this).balance * 25/100;
        uint256 _jake = address(this).balance * 18/100;
        uint256 _jacob = address(this).balance * 18/100;
        require(payable(t1).send(_danny));
        require(payable(t2).send(_kevy));
        require(payable(t3).send(_jake));
        require(payable(t4).send(_jacob));
    }
}
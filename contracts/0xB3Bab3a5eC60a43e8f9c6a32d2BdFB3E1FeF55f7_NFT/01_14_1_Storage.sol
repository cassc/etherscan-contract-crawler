// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
//pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";



contract NFT is ERC721Enumerable, Ownable {
  using Strings for uint256;
  using SafeMath for uint256;
  event PermanentURI(string _value, uint256 indexed _id);

  bool public paused = false;
  string baseURI;
  string public baseExtension = ".json";
  uint256 public cost = 0.05 ether;
  uint256 public SoulsOnSell = 101;
  uint256 public MAX_Souls = 10000;
  uint256 public token_id = 0;


  constructor( ) ERC721("Soul Genesis", "SOUL") {
    baseURI = "https://www.soulgenesis.art/api/json/metadata/";

  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }


    // custom mint from team
    function teamMint( address  user, uint numberOfTokens) public payable onlyOwner{
        require(!paused, "the contract is paused");

        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_Souls) {
                _safeMint(user, mintIndex);
                token_id++;
            }
        }
    }


     function Sale(uint numberOfTokens) public payable {
        require(numberOfTokens < SoulsOnSell, "Purchase would exceed max supply");
        require(!paused, "Sale must be active to mint Souls");
        require(totalSupply().add(numberOfTokens) <= MAX_Souls, "Purchase would exceed max supply of Souls");
        require(msg.value >= cost * numberOfTokens, "Ether value sent is not correct");

        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_Souls) {
                _safeMint(msg.sender, mintIndex);
                token_id++;
            }
        }
    }




 
 // from ipfs support
  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

 

   function getState() public view returns(bool state) {
    return paused;
  }
  
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

function setSoulsOnSell(uint256 _newSouls) public onlyOwner {
    SoulsOnSell = _newSouls;
  }

  

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }


    function pause(bool _state) public onlyOwner {
        paused = _state;
    }


  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }
  

    address t1 = 0x66a7E85fC3bbacF0A9D0f81B9F5Bd080BE599D82; //other

    address t2 = 0x91C744fa5D176e8c8c2243a952b75De90A5186bc; //other

    address t3 = 0xE0D80FC054BC859b74546477344b152941902CB6; //other

    address t4 = 0xae87B3506C1F48259705BA64DcB662Ed047575Bb; //my
     
 
  function withdraw() public payable onlyOwner {

       uint256 _teem1 = address(this).balance * 23/100;
       uint256 _teem2 = address(this).balance * 24/100;
       uint256 _teem3 = address(this).balance * 23/100;
       uint256 _teem4 = address(this).balance * 30/100;

        require(payable(t1).send(_teem1));
        require(payable(t2).send(_teem2));
        require(payable(t3).send(_teem3));
        require(payable(t4).send(_teem4));
  }
}
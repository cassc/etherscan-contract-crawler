/**
 *Submitted for verification at Etherscan.io on 2021-07-30
*/

// SPDX-License-Identifier: MIT 
// File: @openzeppelin/contracts/utils/Context.sol


pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";



// =============================================================  SpacetimeS ============================================================================ //

pragma abicoder v2;

contract Spacetime is ERC721Enumerable, Ownable {
    
   using SafeMath for uint256;

// price of a SpaceTime
    uint256 public constant spacetimePrice = 150000000000000000; // 0.15 ETH

// max number of Spacetime to purchase
    uint public constant MAX_SPACETIME_PURCHASE = 20;

// max number of SPACETIME overall
    uint256 public constant MAX_SPACETIMES = 1000;

// is sale active?
    bool public saleIsActive = false;

// token name
    string private _name;

// base uri
    string private _mybaseuri;

// mapping from token ID to name
    mapping (uint256 => string) public spacetimeNames;

// mapping from tokenid
    mapping (uint256 => bool) public mintedTokens;
    
// mapping from tokenid
    mapping (uint256 => bool) public nameSet;

// event for setting name of a SPACETIME
    event NameChange (uint256 indexed nameIndex, string newName);
    
    // Reserve 13 spacetimes for promotional purposes
    uint public SPACETIME_RESERVE = 20;

    constructor() ERC721("RIBONZ:Spacetime", "RZST") { }
    
    function withdraw(address payable _owner) public onlyOwner {
        uint balance = address(this).balance;
        //FIXFIX make sure this is good
        _owner.transfer(balance);
    }
    
    function reserveSpacetimes(address _to, uint256 _reserveAmount) public onlyOwner {        
        uint supply = totalSupply();
        require(_reserveAmount > 0 && _reserveAmount <= SPACETIME_RESERVE, "Not enough reserve left for team");
        for (uint i = 0; i < _reserveAmount; i++) {
            _safeMint(_to, supply + i);
        }
        SPACETIME_RESERVE = SPACETIME_RESERVE.sub(_reserveAmount);
    }

    // override base class 
    function  _baseURI() internal override view virtual returns (string memory)  {
        return _mybaseuri;
    }    

    function setBaseURI(string memory baseURI) public onlyOwner {
        _mybaseuri = baseURI;
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }
    
    function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function setSpacetimeName(uint256 _tokenId, string calldata _currName) public {
        address owner = ownerOf(_tokenId);
        require(msg.sender == owner, "not the owner"); 
        require(nameSet[_tokenId] == false, "name already set"); 
        nameSet[_tokenId] = true;
        spacetimeNames[_tokenId] = _currName; 
        emit NameChange(_tokenId, _currName); // user can set any name. 
    }

    function viewSpacetimeName(uint _tokenId) public view returns(string memory){
        require( _tokenId < totalSupply(), "choose an spacetime within range" );
        return spacetimeNames[_tokenId];
    }

    function mintSpacetime(uint _numberOfTokens) public payable { 
        require(saleIsActive, "Sale is not active yet!");
        require(_numberOfTokens > 0 && _numberOfTokens <= MAX_SPACETIME_PURCHASE, "you can mint only so many");
        require(totalSupply().add(_numberOfTokens) <= MAX_SPACETIMES, "no no, supply exceeded");
        require(msg.value >= spacetimePrice.mul(_numberOfTokens), "insufficient eth baby");
        
        for(uint i = 0; i < _numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_SPACETIMES) {
                _safeMint(msg.sender, mintIndex);
                mintedTokens[mintIndex] = true;
            }
        }
    }
}
// SPDX-License-Identifier: MIT 
// RIBONZ Infinity NFT -- https://ribonz.art , Danooka, Mystery Labs

pragma solidity >=0.8.7;

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



// =============================================================  InfinityS ============================================================================ //

pragma abicoder v2;

contract Infinity is ERC721Enumerable, Ownable {
    
   using SafeMath for uint256;

// price of a SpaceTime
    uint256 public infinityPrice = 137000000000000000; // 0.137 ETH

// max number of Infinity to purchase
    uint public constant MAX_INFINITY_PURCHASE = 11;

// max number of INFINITY overall
    uint256 public MAX_INFINITYS = 700;

// Freeze once development / test phase is over -- can never be changed
    bool public contractParamsFrozen = false;

// is sale active?
    bool public saleIsActive = false;

// token name
    string private _name;

// base uri
    string private _mybaseuri;

// mapping from token ID to name
    mapping (uint256 => string) public infinityNames;

// mapping from tokenid
    mapping (uint256 => bool) public mintedTokens;
    
// mapping from tokenid
    mapping (uint256 => bool) public nameSet;

// event for setting name of a INFINITY
    event NameChange (uint256 indexed nameIndex, string newName);
    
    // Reserve infinitys for promotional purposes
    uint public INFINITY_RESERVE = 20;

    constructor() ERC721("RIBONZ: Infinity", "RZINF") { }
    
    function withdraw(address payable _owner) public onlyOwner {
        uint balance = address(this).balance;
        _owner.transfer(balance);
    }

    function updateMintPrice(uint256 newPrice) external onlyOwner {
        require(msg.sender == owner(), "only owner!");
        require(contractParamsFrozen == false, "contract params frozen!");
        infinityPrice = newPrice;
    }
    function updateSupply(uint256 newSupply) external onlyOwner {
        require(msg.sender == owner(), "only owner!");
        require(contractParamsFrozen == false, "contract params frozen!");
        MAX_INFINITYS = newSupply;
    }

    // Once set Can never be unset -- allows tweaking before development is over then set once and that's it!
    function freezeContractParams() external onlyOwner {
        require(msg.sender == owner(), "only owner!");
        contractParamsFrozen = true;
    }
    
    function reserveInfinitys(address _to, uint256 _reserveAmount) public onlyOwner {        
        uint supply = totalSupply();
        require(_reserveAmount > 0 && _reserveAmount <= INFINITY_RESERVE, "Not enough reserve left for team");
        for (uint i = 0; i < _reserveAmount; i++) {
            _safeMint(_to, supply + i);
        }
        INFINITY_RESERVE = INFINITY_RESERVE.sub(_reserveAmount);
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

    function setInfinityName(uint256 _tokenId, string calldata _currName) public {
        address owner = ownerOf(_tokenId);
        require(msg.sender == owner, "not the owner"); 
        require(nameSet[_tokenId] == false, "name already set"); 
        nameSet[_tokenId] = true;
        infinityNames[_tokenId] = _currName; 
        emit NameChange(_tokenId, _currName); // user can set any name. 
    }

    function viewInfinityName(uint _tokenId) public view returns(string memory){
        require( _tokenId < totalSupply(), "choose an infinity within range" );
        return infinityNames[_tokenId];
    }
    
    function mintInfinity(uint _numberOfTokens) public payable { 
        require(saleIsActive, "Sale is not active yet!");
        require(_numberOfTokens > 0 && _numberOfTokens <= MAX_INFINITY_PURCHASE, "you can mint only so many");
        require(totalSupply().add(_numberOfTokens) <= MAX_INFINITYS, "no no, supply exceeded");
        require(msg.value >= infinityPrice.mul(_numberOfTokens), "insufficient eth ");
        
        for(uint i = 0; i < _numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_INFINITYS) {
                _safeMint(msg.sender, mintIndex);
                mintedTokens[mintIndex] = true;
            }
        }
    }
}
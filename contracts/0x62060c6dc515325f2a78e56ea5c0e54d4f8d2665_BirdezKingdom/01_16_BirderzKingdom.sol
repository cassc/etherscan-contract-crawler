// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; 
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; 
import "@openzeppelin/contracts/access/Ownable.sol"; 
import "./interfaces/IGenesisBirdez.sol";

contract BirdezKingdom is ERC721Enumerable, Ownable {
    using Strings for uint256;
     
    IGenesisBirdez public immutable genesis;  
  
   
    uint256 public constant START = 5000;  
    uint256 public constant MAX_SUPPLY = 1333;  
    mapping(uint256 => uint256) public maxFreeMintsPerToken;

    bool public startSale; 
    bool public isBaseURILocked; 

    string private baseURI; 

    constructor(
        string memory _name, 
        string memory _symbol,
        IGenesisBirdez _genesis
     ) ERC721(_name, _symbol) {
        require(address(_genesis) != address(0), "invalid-genesis"); 
        genesis = _genesis; 
        startSale = false;  
    } 
   
 
    function setBaseURI(string memory _uri) external onlyOwner {
        require(!isBaseURILocked, "locked-base-uri");       
        baseURI = _uri;
    } 

    function lockBaseURI() external onlyOwner {
        isBaseURILocked = true; 
    } 
 
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "non-existent-token");
        string memory _base = _baseURI();
        return string(abi.encodePacked(_base, tokenId.toString()));
    }
 
    function openSale() public onlyOwner {
        startSale = !startSale;
    }   

    function getGenesisCount(address _owner) public view returns (uint256){
        return genesis.balanceOf(_owner);
    }

    function getGenesisByAddressAndIndex(address _owner, uint256 _tokenId) public view returns (uint256){
        return genesis.tokenOfOwnerByIndex(_owner, _tokenId);
    }
  
 
    function mint() external payable{ 
        address _user = msg.sender; 
        require(startSale, "sale-not-open");   
        require(getGenesisCount(_user) > 0, "no-birdez-in-wallet");  
        uint256 _numberOfTokens = getGenesisCount(_user);
        
        require(totalSupply() + _numberOfTokens <= MAX_SUPPLY, "max-supply-reached");
        for(uint i = 0; i < _numberOfTokens; i++){ 
            uint256 tid = getGenesisByAddressAndIndex(_user, i);
            if(maxFreeMintsPerToken[tid] > 0) continue;
            if (totalSupply() < MAX_SUPPLY) {
                _safeMint(_user, START + totalSupply()); 
                maxFreeMintsPerToken[tid]++;
            } else {
                break;
            }
        }  
    }
 
}
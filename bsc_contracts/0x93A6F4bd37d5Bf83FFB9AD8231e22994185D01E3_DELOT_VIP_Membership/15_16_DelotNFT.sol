// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./IDelotNFT.sol";


contract DELOT_VIP_Membership is ERC721, Ownable, IDelotNFT {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;

    //
    uint256 public constant MAX_SUPPLY = 10;
    
    //
    EnumerableSet.AddressSet private _holders;
    string private baseURI;

    /**
     * We rely on the OZ Counter util to keep track of the next available ID.
     * We track the nextTokenId instead of the currentTokenId to save users on gas costs. 
     * Read more about it here: https://shiny.mirror.xyz/OUampBbIz9ebEicfGnQf5At_ReMHlZy0tB4glb9xQ0E
     */ 
    Counters.Counter private _nextTokenId;    
        
    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {        
        
        // nextTokenId is initialized to 1, since starting at 0 leads to higher gas cost for the first minter
        _nextTokenId.increment();        
        
        baseURI = "ipfs://bafybeifupjtfycmys75vqcbyt54d2scp2gpbbekbowtmecvguoyl6rctk4/";
        
        // Pre-mint
        mintTo(_msgSender());
        mintTo(_msgSender());
        mintTo(_msgSender());        
        mintTo(_msgSender());
        mintTo(_msgSender());
    }       

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;        
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    /**
     * @dev Mints a token to an address with a tokenURI.
     * @param _to address of the future owner of the token
     */
    function mintTo(address _to) public onlyOwner {
        require(totalSupply() < MAX_SUPPLY, "Max supply reached");
        uint256 currentTokenId = _nextTokenId.current();
        _nextTokenId.increment();
        _safeMint(_to, currentTokenId);
    }

     /**
        @dev Returns the total tokens minted so far.
        1 is always subtracted from the Counter since it tracks the next available tokenId.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _nextTokenId.current() - 1;
    }    

    // ----------------------------------------------------------------------------------- 

    function numberOfHolders() external view returns (uint256) {
        return _holders.length();
    }

    function getHolderAt(uint256 index) external view returns (address) {
        return _holders.at(index);
    }  

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        super._afterTokenTransfer(from, to, firstTokenId, batchSize);

        if (from != address(0) && from != to && balanceOf(from)==0) {
            _holders.remove(from);
        }

        if (to != from) {            
            _holders.add(to);
        }
    }
}
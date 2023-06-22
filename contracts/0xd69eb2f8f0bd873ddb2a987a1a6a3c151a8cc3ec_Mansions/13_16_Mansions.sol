// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./SafeMath.sol";
import "./Counters.sol";

contract Mansions is ERC721, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using Address for address;
    
    mapping (uint256 => string) private _tokenURIs;
    mapping(address => uint256) userPurchaseTotal;

    string private _baseURIextended;
    
    Counters.Counter private _tokenIdCounter;
    
    uint256 public constant maxMansions = 420;

    
    constructor() ERC721("8 Bit Mansions", "MANSIONS") {
    }

    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter.current();
    }
  	
  	function setBaseURI(string memory baseURI_) external onlyOwner() {
            _baseURIextended = baseURI_;
    }
    
    function dropCollection(uint256 _numberOfMints) public {
        require(_tokenIdCounter.current().add(_numberOfMints) <= maxMansions, "Mint would exceed max supply");
        
        for(uint256 i = 0; i < _numberOfMints; i++) {
            _safeMint(msg.sender, _tokenIdCounter.current() + 1);
            _tokenIdCounter.increment();
        }
    }    
    
    function _baseURI() internal view virtual override returns (string memory) {
            return _baseURIextended;
    }
    
}

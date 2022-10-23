// SPDX-License-Identifier: MIT


pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Loony_Pirates is ERC721A, ReentrancyGuard, Ownable{
    
    using Strings for uint;
   
   
    mapping(address => uint256) public totalMint;
    

    constructor(string memory _unrevealedUri) ERC721A("Loony_Pirates", "LOONY"){
           unrevealedUri = _unrevealedUri;
        
    
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Cannot Be Called By A Contract");
        _;
    }

    function mint(uint256 _quantity) external payable callerIsUser{
        require(pause, " Not  Active Yet.");
        require((totalSupply() + _quantity) <= MAX_SUPPLY - MAX_GIFT, " Beyond Max Supply");
        require((totalMint[msg.sender] +_quantity) <= 2, "Already Minted 3 Times!");
        require(msg.value >= (SALE_PRICE * _quantity), " Not Enough Fund ");

        totalMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }
    
    function gift(address _to, uint _quantity) external onlyOwner {
    
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Reached Max Gift Supply");
        _safeMint(_to, _quantity);
    }

    
    //return token uri
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), " nonexistent token");

        uint256 trueId = tokenId + 1;

        if(!isRevealed){
            return unrevealedUri;
        }
        //string memory baseURI = _baseURI();
        return bytes(baseTokenUri).length > 0 ? string(abi.encodePacked(baseTokenUri, trueId.toString(), ".json")) : "";
    }
    //var
    uint256 private constant MAX_SUPPLY = 6000;
    uint256 private constant MAX_GIFT = 200;
    uint256 public constant SALE_PRICE = .04 ether;
    

    //metadata

    function setUnrevealedUri(string memory _unrevealedUri) external  onlyOwner{
        unrevealedUri = _unrevealedUri;
    }string public unrevealedUri;
    
    function setTokenUri(string memory _baseTokenUri) external onlyOwner{
        baseTokenUri = _baseTokenUri;
    }string public  baseTokenUri;

    

     //managing 
    function Pause() external onlyOwner{
        pause = !pause;
    } bool public pause;

    function Reveal() external onlyOwner{
        isRevealed = !isRevealed;
    } bool public isRevealed;

    //$
   function withdraw() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }
}
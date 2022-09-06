// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A.sol";

contract Primes is ERC721A, Ownable, ReentrancyGuard  {
    using SafeMath for uint256;

    string public _baseTokenURI;
    uint256 public maxSupply  = 5000;
    uint256 public mintPrice  = 10000000000000000;

    mapping (address => bool) public Minted;
    
    constructor() ERC721A("Primes", "Primes", maxSupply, maxSupply) {}

    function exists(uint256 tokenId) public view returns(bool) {
        return _exists(tokenId);
    }

    /**
    *   Public function for minting.
    */

     function mintNFT(uint256 quantity) public payable {
        require(quantity > 0, "Mint at least one");

        if(Minted[msg.sender]){
            require(mintPrice.mul(quantity) <= msg.value, "Not enough Ether sent."); 
        }

        if(!Minted[msg.sender]){
            require(mintPrice.mul(quantity-1) <= msg.value, "Not enough Ether sent."); 
        }

        Minted[msg.sender] = true; 
        maxSupply -= quantity;
        _safeMint(msg.sender, quantity);
    }



    /*
    *   NumberOfNFT setter
    */
    function setNumberOfTokens(uint256 _numberOfTokens) public onlyOwner {
        maxSupply = _numberOfTokens;
    }

    /*
    *   Withdraw Funds to beneficiary
    */

     function withdraw(address _recipient) public payable onlyOwner {
         (bool success,) = payable(_recipient).call{value: address(this).balance}("");
         require(success, "ERROR");
    }

   
    /*
    *   setBaseUri setter
    */

     function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }


    function tokensOf(address owner) public view returns (uint256[] memory){
        uint256 count = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](count);
        for (uint256 i; i < count; i++) {
        tokenIds[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokenIds;
    }


    receive () external payable virtual {}
}
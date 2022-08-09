// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721PsiMod.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PurPeeps is ERC721PsiMod,Ownable {

    uint256 public constant MAX_TOKENS = 690;
    string private _tokenBaseURI;
        
   constructor() 
        ERC721PsiMod ("PurPeeps NFT", "PURPEEPS"){
    }

    function adminMint(address recipient, uint256 quantity) external onlyOwner {
        require(totalSupply() + quantity <= MAX_TOKENS, "Minting too many");
        _safeMint(recipient, quantity);
    }

    function _startTokenId() internal override pure returns (uint256) {
        return 1;
    }

    function setBaseURI(string calldata URI) external onlyOwner {
        _tokenBaseURI = URI;
    }

    function _baseURI() internal view override returns (string memory){
        return _tokenBaseURI;
    }

}
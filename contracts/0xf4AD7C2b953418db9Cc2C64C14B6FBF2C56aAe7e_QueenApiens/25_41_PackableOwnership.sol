// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import { FlexibleMetadata } from "./FlexibleMetadata.sol";
import { PackableData, SetPackable } from "./SetPackable.sol";


struct TokenApproval {
    address approval;
    bool exists;
}

abstract contract PackableOwnership is FlexibleMetadata {
    using SetPackable for PackableData;
    PackableData packable;

    constructor() {
        packable._currentIndex = packable._startTokenId();     
    } 
     


    function numberMinted(address minter) public view returns (uint256) {
        return packable._numberMinted(minter);
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        return packable.ownerOf(tokenId);
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        return packable.balanceOf(owner);
    }         
       
    function totalSupply() public view virtual returns (uint256) {
        return packable.totalSupply();
    }    
       
    function minted() internal view virtual returns (uint256) {
        return packable._currentIndex;
    }
    function exists(uint256 tokenId) internal view returns (bool) {
        return packable._exists(tokenId);
    }
    function packedTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        packable.transferFrom(from,to,tokenId);
    }
    function packedMint(address to, uint256 quantity) internal returns (uint256) {
        return packable._mint(to,quantity);
    }
    function packedBurn(uint256 tokenId) internal  {
        packable._burn(tokenId);
    }
    /**
     * Returns the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     * returned as a uint16[4] allowing 4 distinct counts per wallet
     */
    function retrieveMintQuantities(address owner) internal view returns (uint16[4] memory) {
        return packable.getAux16(owner);
    }  
    /**
     * Stores a uint16[4] as a single aux value
     * returned as a uint16[4] allowing 4 distinct counts per wallet
     */
    function setAux32(address owner, uint16[4] memory aux) internal {
        packable._setAux(owner,packable.pack64(packable.pack32(aux[0],aux[1]),packable.pack32(aux[2],aux[3])));
    }  

    function recordMintQuantity(uint256 phase, uint256 quantity) internal {
      uint16[4] memory aux = retrieveMintQuantities(msg.sender);
      aux[phase] = uint16(quantity)+aux[phase];
      setAux32(msg.sender,aux);
    }     
}
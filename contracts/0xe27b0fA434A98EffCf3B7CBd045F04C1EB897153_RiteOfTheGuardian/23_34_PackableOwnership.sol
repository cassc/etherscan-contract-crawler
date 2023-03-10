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
     */
    // function getAux(address owner) public view returns (uint32[2] memory) {
    //     return packable.unpack64(packable._getAux(owner));
    // }

    function getAux16(address owner) internal view returns (uint16[4] memory) {
        return packable.getAux16(owner);
    }    
    // function getAux8(address owner) public view returns (uint8[8] memory) {

    //     uint32[2] memory pack32 = packable.unpack64(packable._getAux(owner));
        
    //     uint16[2] memory pack16a = packable.unpack32(pack32[0]);
        
    //     uint8[2] memory pack8a1 = packable.unpack16(pack16a[0]);
    //     uint8[2] memory pack8a2 = packable.unpack16(pack16a[1]);
        
    //     uint16[2] memory pack16b = packable.unpack32(pack32[1]);
        
    //     uint8[2] memory pack8b1 = packable.unpack16(pack16b[0]);
    //     uint8[2] memory pack8b2 = packable.unpack16(pack16b[1]);

    //     return [pack8a1[0],pack8a1[1],pack8a2[0],pack8a2[1],pack8b1[0],pack8b1[1],pack8b2[0],pack8b2[1]];
    // }    

    /**
     * Sets the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    // function setAux(address owner, uint32[2] memory aux) internal {
    //     packable._setAux(owner,packable.pack64(aux[0],aux[1]));
    // }    

    function setAux32(address owner, uint16[4] memory aux) internal {
        packable._setAux(owner,packable.pack64(packable.pack32(aux[0],aux[1]),packable.pack32(aux[2],aux[3])));
    }       
    
    // function setAux16(address owner, uint8[8] memory aux) internal {
    //     packable._setAux(owner,packable.pack64(
    //         packable.pack32(
    //             packable.pack16(aux[0],aux[1]),
    //             packable.pack16(aux[2],aux[3])
    //         ),
    //         packable.pack32(
    //             packable.pack16(aux[4],aux[5]),
    //             packable.pack16(aux[6],aux[7])
    //         )
    //     ));
    // }        

}
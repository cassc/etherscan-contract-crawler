// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../node_modules/@openzeppelin/contracts/utils/Strings.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";




contract WeddingCards is ERC721PresetMinterPauserAutoId {
    
    constructor(
    ) ERC721PresetMinterPauserAutoId("Wedding Invitation", "Invitation","https://talha-wedding-invitation.herokuapp.com/") {
        mint(0x32a24e47B76AD3F10219A2531d1D4BA99BB2c866);
        mint(0xD2FbDDFe025C4d43940A60Bfa081e26dD35a2E93);
        mint(0x9837B3C5bBe732779E83a8C3721EEDeB6E793755);
       
    }


    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(getBaseURI(), Strings.toString(_tokenId)));
    }

    
}
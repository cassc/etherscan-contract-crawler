// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
bytes constant description = abi.encodePacked(unicode"Female Apiens, born from the heart of the Apiens community, carry a powerful mission: to uplift and empower women. By giving them wings to build businesses centered around their unique strengths, these cherished collections not only unlock exciting possibilities but also offer incredible opportunities for female Apiens to soar.");
struct RenderableData { 
    uint256 num;
}   
library SetContractMetadataRenderable {
    using Strings for uint256;

    function encodedContractURI(RenderableData storage, bytes memory imageUri, uint256 royalty_basis, address recipient) public pure returns (string memory) { 
        bytes memory dataURI = abi.encodePacked(
            '{',
                '"name": "Queen Apiens"',
                ',"description": "',string(description),'"', 
                ',"image":"',string(imageUri),'"',
                ',"external_link":"https://theapiens.com/"',
                ',"seller_fee_basis_points":', royalty_basis.toString(), 
                ',"fee_recipient":"', Strings.toHexString(uint160(recipient), 20),'"'
            '}'
        );

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(dataURI)
            )
        );
    }    
}
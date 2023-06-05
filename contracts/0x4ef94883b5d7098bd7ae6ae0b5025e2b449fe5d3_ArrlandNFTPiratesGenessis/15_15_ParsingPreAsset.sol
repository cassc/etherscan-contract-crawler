// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// Helper library for handling and manipulating bytes
import "./Bytes.sol";

library ParsingPreAsset {
    // Split the minting blob into token_id and blueprint portions
    // {token_id}:{blueprint}

    function split(bytes calldata blob)
        internal
        pure
        returns (uint256, uint256)
    {
        int256 index = Bytes.indexOf(blob, ":", 0);
        require(index >= 0, "Separator must exist");
        uint256 tokenID = Bytes.toUint(blob[1:uint256(index) - 1]);
        uint256 blueprintLength = blob.length - uint256(index) - 3;
        require(blueprintLength > 0, "blueprint error");
        
        bytes calldata blueprint = blob[uint256(index) + 2:blob.length - 1];
        uint256 assetType = Bytes.toUint(blueprint);

        return (tokenID, assetType);
    }



    
}
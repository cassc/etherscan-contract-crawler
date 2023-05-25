// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Strings.sol";

library NFT {
    struct TokenStruct {
        address collectionAddress;
        uint256 tokenId;
    }

    function createKey(TokenStruct memory token)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    Strings.toHexString(token.collectionAddress),
                    "-",
                    token.tokenId
                )
            );
    }
}
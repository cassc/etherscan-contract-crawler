/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./ITokenUriHelperFeature.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";


contract TokenUriHelperFeature is ITokenUriHelperFeature {

    uint256 constant MASK_ADDRESS = (1 << 160) - 1;

    function tokenURIs(TokenUriParam[] calldata params) external view override returns (string[] memory uris) {
        uris = new string[](params.length);
        for (uint256 i; i < params.length;) {
            address erc721 = address(uint160(params[i].methodIdAndAddress & MASK_ADDRESS));
            bytes4 methodId = bytes4(uint32(params[i].methodIdAndAddress >> 224));
            if (methodId == 0) {
                methodId = IERC721Metadata.tokenURI.selector;
            }

            (bool success, bytes memory uri) = erc721.staticcall(abi.encodeWithSelector(methodId, params[i].tokenId));
            if (success) {
                uris[i] = string(uri);
            }
            unchecked {++i;}
        }
        return uris;
    }
}
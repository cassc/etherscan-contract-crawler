// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract FetchData {
    function getErc721Uris(
        address erc721Address,
        uint256 fromTokenId,
        uint256 toTokenId
    ) external view returns(string[15000] memory result, uint256 count, uint256 lastTokenId) {
        ERC721 erc721 = ERC721(erc721Address);
        count = 0;
        for (uint256 i = fromTokenId; i <= toTokenId; i++) {
            try erc721.tokenURI(i) returns(string memory uri) {
                result[i - fromTokenId] = uri;
                count = count + 1;
                lastTokenId = i;
            } catch {
            }
        }
    }

    function getErc1155Uris(
        address erc1155Address,
        uint256 fromTokenId,
        uint256 toTokenId
    ) external view returns(string[15000] memory result, uint256 count, uint256 lastTokenId) {
        ERC1155 erc1155 = ERC1155(erc1155Address);
        count = 0;
        for (uint256 i = fromTokenId; i <= toTokenId; i++) {
            try erc1155.uri(i) returns(string memory uri) {
                result[i - fromTokenId] = uri;
                count = count + 1;
                lastTokenId = i;
            } catch {
            }
        }
    }
}
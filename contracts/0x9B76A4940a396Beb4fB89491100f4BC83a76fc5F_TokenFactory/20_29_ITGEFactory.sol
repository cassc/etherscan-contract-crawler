// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./ITGE.sol";
import "./IToken.sol";

interface ITGEFactory {
    function createSecondaryTGE(
        address token,
        ITGE.TGEInfo calldata tgeInfo,
        IToken.TokenInfo calldata tokenInfo,
        string memory metadataURI
    ) external;

    function createSecondaryTGEERC1155(
        address token,
        uint256 tokenId,
        string memory uri,
        ITGE.TGEInfo calldata tgeInfo,
        IToken.TokenInfo calldata tokenInfo,
        string memory metadataURI
    ) external;
}
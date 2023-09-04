// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./ITGE.sol";
import "./IToken.sol";
import "./governor/IGovernanceSettings.sol";

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

    function createPrimaryTGE(
        address poolAddress,
        IToken.TokenInfo memory tokenInfo,
        ITGE.TGEInfo memory tgeInfo,
        string memory metadataURI,
        IGovernanceSettings.NewGovernanceSettings memory governanceSettings_,
        address[] memory secretary,
        address[] memory executor
    ) external;
}
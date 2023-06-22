//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IExtensibleERC721Enumerable.sol";
import "./ChainScoutsExtension.sol";
import "./ChainScoutMetadata.sol";

interface IChainScouts is IExtensibleERC721Enumerable {
    function adminCreateChainScout(
        ChainScoutMetadata calldata tbd,
        address owner
    ) external;

    function adminRemoveExtension(string calldata key) external;

    function adminSetExtension(
        string calldata key,
        ChainScoutsExtension extension
    ) external;

    function adminSetChainScoutMetadata(
        uint256 tokenId,
        ChainScoutMetadata calldata tbd
    ) external;

    function getChainScoutMetadata(uint256 tokenId)
        external
        view
        returns (ChainScoutMetadata memory);
}
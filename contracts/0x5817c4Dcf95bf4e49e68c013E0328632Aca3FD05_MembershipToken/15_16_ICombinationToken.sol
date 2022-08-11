// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IBaseToken.sol";

interface ICombinationToken is IERC721 {
    function parent() external view returns (IBaseToken);

    function tokenParents(uint256 _tokenId)
    external
    view
    returns (uint256[] memory);

    function baseIsCombined(uint256 _baseId) external view returns (bool);

    function combinationName(uint256 _tokenId)
    external
    view
    returns (string memory);

    function childByParent(uint256 _baseId)
    external
    view
    returns (uint256);
}
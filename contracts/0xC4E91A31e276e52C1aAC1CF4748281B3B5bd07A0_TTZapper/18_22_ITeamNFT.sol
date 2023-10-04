// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "../types/Structs.sol";

interface ITeamNFT is IERC1155Upgradeable {
    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function mintBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;

    function teamNftManager() external view returns (address);

    function setTeamNftRenderer(address) external;

    function isApprovedForAll(address, address) external view returns (bool);

    function setApprovalForAll(address, bool) external;

    function allOwnersWithBalances(
        uint256 tokenId
    ) external view returns (OwnersBalances[] memory);
}
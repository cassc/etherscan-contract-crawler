// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/// @title ERC1155 Ubiquiti preset interface
/// @author Ubiquity Algorithmic Dollar
interface IERC1155Ubiquity is IERC1155 {
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external;

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) external;

    function pause() external;

    function unpause() external;

    function totalSupply() external view returns (uint256);

    function exists(uint256 id) external view returns (bool);

    function holderTokens() external view returns (uint256[] memory);
}
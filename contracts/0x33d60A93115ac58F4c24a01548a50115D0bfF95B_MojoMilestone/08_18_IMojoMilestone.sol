//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";


interface IMojoMilestone is IERC1155Upgradeable {


    function mint(
        address account,
        uint256 id,
        uint256 amount
    ) external;

    function mintBatch(
        address[] memory tos,
        uint256[] memory ids,
        uint256 amount
    ) external;

    function mintMultiple(
        address[] calldata to,
        uint256 id,
        uint256 amount
    ) external;

    function mintAndBurn(
        address account,
        uint256 id,
        uint256 amount
    ) external;

    function stake(
        uint256 id,
        uint256 amount
    ) external;

    error FunctionNotSupported();

}
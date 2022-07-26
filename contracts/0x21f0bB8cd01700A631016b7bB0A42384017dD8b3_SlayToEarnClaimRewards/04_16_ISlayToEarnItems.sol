//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface ISlayToEarnItems {
    function ping() external pure returns (bool);

    function mintBatch(
        address player,
        uint256[] memory items,
        uint256[] memory amounts,
        bytes memory data
    ) external;

    function burnBatch(
        address player,
        uint256[] memory items,
        uint256[] memory amounts
    ) external;

    function requireBatch(
        address player,
        uint256[] memory items,
        uint256[] memory amounts
    ) external view;
}
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IBoringBrewBags is IERC1155 {
    function mintMultiple(
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _amounts
    ) external;

    function mintSingle(
        address _to,
        uint256 _id,
        uint256 _amount
    ) external;
}
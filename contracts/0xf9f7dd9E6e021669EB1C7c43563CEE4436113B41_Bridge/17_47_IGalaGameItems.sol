//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/interfaces/IERC1155.sol";

interface IGalaGameItems is IERC1155 {
    function mintNonFungible(
        uint256[] calldata _ids,
        address[] calldata _to,
        bytes calldata _data
    ) external;

    function mintFungible(
        uint256 _id,
        address[] calldata _to,
        uint256[] calldata _quantities,
        bytes calldata _data
    ) external;

    function burn(
        address _from,
        uint256[] calldata _ids,
        uint256[] calldata _values
    ) external;

    function isFungible(uint256 _id) external pure returns (bool);

    function isNonFungible(uint256 _id) external pure returns (bool);

    function getNonFungibleIndex(uint256 _id) external pure returns (uint256);

    function getNonFungibleBaseType(uint256 _id) external pure returns (uint256);
}
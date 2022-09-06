//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.8;

interface IEyeConstants {
    function getConditionCount() external view returns (uint16);

    function getVisionCount() external view returns (uint16);

    function getNamePrefixCount() external view returns (uint16);

    function getNameSuffixCount() external view returns (uint16);

    function getOrderCount() external view returns (uint16);

    function getVisionName(uint256 order)
        external
        pure
        returns (string memory visionName);

    function getOrderName(uint256 order)
        external
        pure
        returns (string memory orderName);

    function getNameSuffix(uint256 index)
        external
        pure
        returns (string memory namePrefix);

    function getNamePrefix(uint256 index)
        external
        pure
        returns (string memory namePrefix);
}
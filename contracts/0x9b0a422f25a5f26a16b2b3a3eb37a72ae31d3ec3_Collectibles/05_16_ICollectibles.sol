// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface ICollectibles {
    function mintBatch(
        uint256[] memory _tokenTypes,
        uint256[] memory _amounts,
        address _receiver
    ) external;

    function burnBatch(
        uint256[] memory _tokenTypes,
        uint256[] memory _amounts,
        address _receiver
    ) external;
}
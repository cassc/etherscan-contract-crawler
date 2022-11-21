// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.15;

interface IAnimeMetaverseReward {
    function mintBatch(
        uint256 ticket,
        uint256 _drawIndex,
        uint256 _activityId,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) external;

    function mint(
        uint256 ticket,
        uint256 _drawIndex,
        uint256 _activityId,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) external;

    function forceBurn(
        address _account,
        uint256 _id,
        uint256 _amount
    ) external;
}
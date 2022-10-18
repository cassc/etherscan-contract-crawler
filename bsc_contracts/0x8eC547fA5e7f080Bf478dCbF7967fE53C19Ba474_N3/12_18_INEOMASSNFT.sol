// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface INEOMASSNFT is IERC721 {
    function onTransfer(
        address _from,
        address _to,
        uint256 _amount,
        uint256 _transferType
    ) external;

    function addReward(uint256 _rewardAmount) external;

    function getNFTValue(uint256 _id) external view returns (uint256);

    function getUserValue(address _user) external view returns (uint256);
}
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

interface ICubeXGoldCard {
    function balanceOf(
        address _owner,
        uint256 _id
    ) external view returns (uint256);

    function isApprovedForAll(
        address _owner,
        address _operator
    ) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
}
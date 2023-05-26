// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IOpenseaStorefront {
    function balanceOf(address tokenOwner, uint256 tokenId)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes memory _data
    ) external;
}
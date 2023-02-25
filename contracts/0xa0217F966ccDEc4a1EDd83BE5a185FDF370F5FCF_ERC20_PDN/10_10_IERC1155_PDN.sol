// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface IERC1155_PDN {
    function mint(address _to, uint _id, uint _amount, bytes memory _data) external returns(bool);
}
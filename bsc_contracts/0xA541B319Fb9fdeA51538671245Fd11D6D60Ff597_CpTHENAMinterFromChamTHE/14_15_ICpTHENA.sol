// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface ICpTHENA {
    function depositVe(uint256 _tokenId) external;
    function ve() external view returns (address);
}
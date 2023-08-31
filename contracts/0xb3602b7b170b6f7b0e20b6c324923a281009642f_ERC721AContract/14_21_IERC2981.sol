// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IERC2981 {
    function royaltyInfo(uint256 _tokenId, uint256 _value)
        external
        view
        returns (address _receiver, uint256 _royaltyAmount);
}
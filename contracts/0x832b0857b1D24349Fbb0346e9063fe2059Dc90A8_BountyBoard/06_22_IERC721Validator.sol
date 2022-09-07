// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC721Validator {
    function meetsCriteria(address tokenAddress, uint256 tokenId)
        external
        view
        returns (bool);
}
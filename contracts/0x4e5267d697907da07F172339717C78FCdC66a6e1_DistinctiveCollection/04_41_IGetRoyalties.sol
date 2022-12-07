// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGetRoyalties {
    function getRoyalties(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address payable[] memory recipients, uint256[] memory fees);
}
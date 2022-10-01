// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILazyNFT {
    function redeem(
        address _redeem,
        uint256 _tokenid,
        string memory _uri
    ) external returns (uint256);
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ITestNft {
    function mint(
        address _to,
        uint256 _projectId,
        address _by
    ) external returns (uint256 _tokenId);
}
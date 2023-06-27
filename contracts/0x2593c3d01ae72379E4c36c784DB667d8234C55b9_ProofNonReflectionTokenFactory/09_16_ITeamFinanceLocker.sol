// SPDX-License-Identifier: None
pragma solidity ^0.8.17;

interface ITeamFinanceLocker {
    function lockToken(
        address _tokenAddress,
        address _withdrawalAddress,
        uint256 _amount,
        uint256 _unlockTime,
        bool _mintNFT,
        address referrer
    ) external payable returns (uint256 _id);
}
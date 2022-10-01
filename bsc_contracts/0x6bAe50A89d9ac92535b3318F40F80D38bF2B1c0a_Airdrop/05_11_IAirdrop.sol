// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAirdrop{

    event UpdateRewardToken(address newRewardToken);
    event EtherTransfer(address beneficiary, uint amount);

    function dropTokens(address[] memory _recipients, uint256[] memory _amount, bool isTransferFrom) external returns (bool);

    function dropEther(address[] memory _recipients, uint256[] memory _amount) external payable returns (bool);

    function updateRewardToken(address newRewardToken) external;

    function withdrawTokens(address tokenAddr,address beneficiary) external;

    function withdrawEther(address payable beneficiary) external;
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IFundCreator {
    function createQFUtil(address _fundManager,  address _infoCenter) external returns (address);

    function createFund(address _fundManager, address _qUtils, address _infoCenter, address _validVault,
                address[] memory _validFundingTokens,
                address[] memory _validTradingTokens, uint256[] memory _mFeeSetting) external returns (address);
}
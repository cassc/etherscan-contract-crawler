// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol";

contract EPNSCoreProxy is TransparentUpgradeableProxy {


    constructor(
        address _logic,
        address _governance,
        address _pushChannelAdmin,
        address _pushTokenAddress,
        address _wethAddress,
        address _uniswapRouterAddress,
        address _lendingPoolProviderAddress,
        address _daiAddress,
        address _aDaiAddress,
        uint _referralCode
    ) public payable TransparentUpgradeableProxy(_logic, _governance, abi.encodeWithSignature('initialize(address,address,address,address,address,address,address,uint256)', _pushChannelAdmin, _pushTokenAddress, _wethAddress, _uniswapRouterAddress, _lendingPoolProviderAddress, _daiAddress, _aDaiAddress,_referralCode)) {}

}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IWGMarketplace {
    function getWayGate721ContractAddress() external view returns (address);

    function getWayGateTokenAddress() external view returns (IERC20Upgradeable);

    function getwayGatePartners() external view returns (address[] memory);

    function getwayGatePartnersAmount() external view returns (uint256);

    function getwayGatePlatformFeeReceiver() external view returns (address);

    function transferWayGateTokens(uint _amount) external;

    function transferAirdropNativeTokens(uint _amount) external;
}
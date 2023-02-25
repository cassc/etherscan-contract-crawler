// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";

interface IIbAlluo is IERC20, IAccessControl {
    function annualInterest() external view returns (uint256);

    function approveAssetValue(
        address spender,
        uint256 amount
    ) external returns (bool);

    function burn(address account, uint256 amount) external;

    function changeTokenStatus(address _token, bool _status) external;

    function changeUpgradeStatus(bool _status) external;

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) external returns (bool);

    function deposit(address _token, uint256 _amount) external;

    function getBalance(address _address) external view returns (uint256);

    function getBalanceForTransfer(
        address _address
    ) external view returns (uint256);

    function getListSupportedTokens() external view returns (address[] memory);

    function growingRatio() external view returns (uint256);

    function interestPerSecond() external view returns (uint256);

    function lastInterestCompound() external view returns (uint256);

    function liquidityBuffer() external view returns (address);

    function mint(address account, uint256 amount) external;

    function pause() external;

    function unpause() external;

    function paused() external view returns (bool);

    function setInterest(
        uint256 _newAnnualInterest,
        uint256 _newInterestPerSecond
    ) external;

    function setLiquidityBuffer(address newBuffer) external;

    function setUpdateTimeLimit(uint256 _newLimit) external;

    function totalAssetSupply() external view returns (uint256);

    function transferAssetValue(
        address to,
        uint256 amount
    ) external returns (bool);

    function transferFromAssetValue(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function updateRatio() external;

    function updateTimeLimit() external view returns (uint256);

    function upgradeStatus() external view returns (bool);

    function withdraw(address _targetToken, uint256 _amount) external;

    function withdrawTo(
        address _recipient,
        address _targetToken,
        uint256 _amount
    ) external;

    function convertToAssetValue(
        uint256 _amountInTokenValue
    ) external view returns (uint256);

    function stopFlowWhenCritical(address sender, address receiver) external;

    function forceWrap(address sender) external;

    function superToken() external view returns (address);

    function priceFeedRouter() external view returns (address);

    function fiatIndex() external view returns (uint256);

    function symbol() external view returns (string memory symbol);
}
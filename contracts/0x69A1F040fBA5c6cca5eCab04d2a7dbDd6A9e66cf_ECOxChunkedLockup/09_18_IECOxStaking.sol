// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

interface IECOxStaking {
    function deposit(uint256 _amount) external;

    function delegate(address delegatee) external;

    function delegateAmount(address delegatee, uint256 amount) external;

    function withdraw(uint256 _amount) external;

    function undelegate() external;

    function undelegateAmountFromAddress(address delegatee, uint256 amount)
        external;
}
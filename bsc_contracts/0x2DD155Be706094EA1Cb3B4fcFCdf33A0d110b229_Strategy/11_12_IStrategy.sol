// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

interface IStrategy {

    function deposit() external;

    function withdraw(uint256 _amountLP) external returns (uint256);

    function autocompound() external;
    
    ///@dev The input address cannot ve 0x0.
    error ZeroAddressAsInput();

    ///@dev The caller has no permission to call the function.
    error UnauthorizedCaller(address caller);

    ///@dev Emitted when deposit is called.
    event Deposited(uint256 amount);

    ///@dev Emitted when reards get autocompounded.
    event Compounded(uint256 rewardAmount, uint256 fee, uint256 time);

    ///@dev Emtted when withdrawal is called.
    event Withdrawn(uint256 amountLP, uint256 amountBaseToken);
}
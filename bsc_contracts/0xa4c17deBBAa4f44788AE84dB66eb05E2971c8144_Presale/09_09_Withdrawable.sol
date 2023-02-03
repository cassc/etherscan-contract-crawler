//SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract Withdrawable {
    error AddressZero();

    event WithdrawNative(address indexed sender, uint256 indexed amount);
    event WithdrawToken(
        address indexed user,
        address indexed token,
        uint256 indexed amount
    );

    constructor() {}

    modifier checkZeroAddress(address _address) {
        if (_address == address(0)) revert AddressZero();
        _;
    }

    // calling function should provide proper caller restrictions
    // withdraw native to treasury
    function _withdrawNativeToTreasury(
        address treasury
    ) internal checkZeroAddress(treasury) {
        uint256 amount = address(this).balance;
        if (amount == 0) return;
        (bool success, ) = treasury.call{value: amount}("");
        require(success, "Transfer failed");
        emit WithdrawNative(msg.sender, amount);
    }

    // calling function should provide proper caller restrictions
    // withdraw token to treasury
    function _withdrawTokensToTreasury(
        address treasury,
        address tokenAddress
    ) internal checkZeroAddress(treasury) checkZeroAddress(tokenAddress) {
        uint256 amount = IERC20(tokenAddress).balanceOf(address(this));
        if (amount == 0) return;
        IERC20(tokenAddress).transfer(treasury, amount);
        emit WithdrawToken(msg.sender, tokenAddress, amount);
    }
}
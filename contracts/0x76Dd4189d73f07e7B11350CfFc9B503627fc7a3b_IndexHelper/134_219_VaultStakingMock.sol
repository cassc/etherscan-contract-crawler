// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IVaultStakingMock {
    function asset() external returns (address);

    function stake(uint amount) external;

    function withdraw() external;

    function withdrawable() external view returns (uint);
}

contract VaultStakingMock is IVaultStakingMock {
    using SafeERC20 for IERC20;

    address public override asset;

    constructor(address _asset) {
        asset = _asset;
    }

    function stake(uint amount) external override {
        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw() external override {
        IERC20(asset).safeTransfer(msg.sender, IERC20(asset).balanceOf(address(this)));
    }

    function withdrawable() external view override returns (uint) {
        return IERC20(asset).balanceOf(address(this));
    }

    function transfer(address _recipient, uint _amount) external {
        IERC20(asset).safeTransfer(_recipient, _amount);
    }
}
// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import '@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol';

import '../FodlToken/FodlToken.sol';

contract FodlSingleSidedStaking is ERC20Burnable, IERC677Receiver {
    IERC20 public immutable fodlToken;

    constructor(IERC20 fodl) public ERC20('FodlStake', 'xFODL') {
        fodlToken = fodl;
    }

    function onTokenTransfer(
        address from,
        uint256 value,
        bytes calldata
    ) external override {
        require(msg.sender == address(fodlToken), 'Only accepting FODL transfers.');

        // totalFodl before the current transfer
        uint256 totalFodl = fodlToken.balanceOf(address(this)).sub(value);
        uint256 totalShares = totalSupply();
        _mint(from, (totalShares == 0 || totalFodl == 0) ? value : value.mul(totalShares).div(totalFodl));
    }

    function stake(uint256 _amount) external returns (uint256 shares) {
        uint256 totalFodl = fodlToken.balanceOf(address(this));
        uint256 totalShares = totalSupply();
        shares = (totalShares == 0 || totalFodl == 0) ? _amount : _amount.mul(totalShares).div(totalFodl);
        _mint(msg.sender, shares);
        fodlToken.transferFrom(msg.sender, address(this), _amount);
    }

    function unstake(uint256 _share) external returns (uint256 amount) {
        uint256 totalFodl = fodlToken.balanceOf(address(this));
        uint256 totalShares = totalSupply();
        _burn(msg.sender, _share);
        amount = _share.mul(totalFodl).div(totalShares);
        fodlToken.transfer(msg.sender, amount);
    }
}
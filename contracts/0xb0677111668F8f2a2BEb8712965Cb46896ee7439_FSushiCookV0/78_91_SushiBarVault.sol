// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "./interfaces/ISushiBar.sol";

contract SushiBarVault is ERC4626 {
    using SafeERC20 for IERC20;

    address internal immutable _sushi;
    address internal immutable _sushiBar;

    constructor(address sushi, address sushiBar) ERC4626(IERC20(sushi)) ERC20("SushiBar Yield Vault", "yxSUSHI") {
        _sushi = sushi;
        _sushiBar = sushiBar;

        approveMax();
    }

    function totalAssets() public view override returns (uint256) {
        uint256 total = IERC20(_sushiBar).totalSupply();
        return
            total == 0
                ? 0
                : (IERC20(_sushi).balanceOf(address(_sushiBar)) * IERC20(_sushiBar).balanceOf(address(this))) / total;
    }

    function _initialConvertToShares(
        uint256 assets,
        Math.Rounding /*rounding*/
    ) internal view override returns (uint256 shares) {
        uint256 balance = IERC20(_sushi).balanceOf(address(_sushiBar));
        return balance == 0 ? assets : (assets * IERC20(_sushiBar).totalSupply()) / balance;
    }

    function _initialConvertToAssets(
        uint256 shares,
        Math.Rounding /*rounding*/
    ) internal view override returns (uint256 assets) {
        uint256 total = IERC20(_sushiBar).totalSupply();
        return total == 0 ? shares : (shares * IERC20(_sushi).balanceOf(address(_sushiBar))) / total;
    }

    function approveMax() public {
        IERC20(_sushi).approve(_sushiBar, type(uint256).max);
    }

    function _deposit(
        address caller,
        address receiver,
        uint256 assets,
        uint256 shares
    ) internal override {
        IERC20(_sushi).safeTransferFrom(msg.sender, address(this), assets);
        ISushiBar(_sushiBar).enter(assets);

        _mint(receiver, shares);

        emit Deposit(caller, receiver, assets, shares);
    }

    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) internal override {
        if (caller != owner) {
            _spendAllowance(owner, caller, shares);
        }

        _burn(owner, shares);

        ISushiBar(_sushiBar).leave(shares);
        IERC20(_sushi).safeTransfer(receiver, assets);

        emit Withdraw(caller, receiver, owner, assets, shares);
    }
}
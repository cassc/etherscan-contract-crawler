// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.16;

import {ERC4626RouterBase, SafeTransferLib, ERC20, IERC4626} from "./ERC4626RouterBase.sol";

/// @title ERC4626Router contract
contract ERC4626Router is ERC4626RouterBase {
    using SafeTransferLib for ERC20;

    constructor(string memory name) {}

    function depositToVault(IERC4626 vault, address to, uint256 amount, uint256 minSharesOut)
        external
        payable
        returns (uint256 sharesOut)
    {
        ERC20(vault.asset()).safeTransferFrom(_msgSender(), address(this), amount);
        return deposit(vault, to, amount, minSharesOut);
    }

    function withdrawToDeposit(
        IERC4626 fromVault,
        IERC4626 toVault,
        address to,
        uint256 amount,
        uint256 maxSharesIn,
        uint256 minSharesOut
    ) external payable returns (uint256 sharesOut) {
        withdraw(fromVault, address(this), amount, maxSharesIn);
        return deposit(toVault, to, amount, minSharesOut);
    }

    function redeemToDeposit(IERC4626 fromVault, IERC4626 toVault, address to, uint256 shares, uint256 minSharesOut)
        external
        payable
        returns (uint256 sharesOut)
    {
        uint256 amount = redeem(fromVault, address(this), shares, 0);
        return deposit(toVault, to, amount, minSharesOut);
    }

    function depositMax(IERC4626 vault, address to, uint256 minSharesOut) public payable returns (uint256 sharesOut) {
        ERC20 asset = ERC20(vault.asset());
        uint256 assetBalance = asset.balanceOf(_msgSender());
        uint256 maxDeposit = vault.maxDeposit(to);
        uint256 amount = maxDeposit < assetBalance ? maxDeposit : assetBalance;
        ERC20(vault.asset()).safeTransferFrom(_msgSender(), address(this), amount);
        return deposit(vault, to, amount, minSharesOut);
    }

    function redeemMax(IERC4626 vault, address to, uint256 minAmountOut) public payable returns (uint256 amountOut) {
        uint256 shareBalance = ERC20(address(vault)).balanceOf(_msgSender());
        uint256 maxRedeem = vault.maxRedeem(_msgSender());
        uint256 amountShares = maxRedeem < shareBalance ? maxRedeem : shareBalance;
        return redeem(vault, to, amountShares, minAmountOut);
    }

    function approve(ERC20 token, address to, uint256 amount) public payable {
        token.safeApprove(to, amount);
    }

    function versionRecipient() external view virtual override returns (string memory) {
        return "1";
    }
}
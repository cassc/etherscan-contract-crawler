// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

library LibAssetUpgradeable {
    using LibAssetUpgradeable for address;

    address constant NATIVE_ASSETID = address(0);

    function isNative(address self) internal pure returns (bool) {
        return self == NATIVE_ASSETID;
    }

    function getBalance(address self) internal view returns (uint256) {
        return
            self.isNative()
                ? address(this).balance
                : IERC20Upgradeable(self).balanceOf(address(this));
    }

    function transferFrom(
        address self,
        address from,
        address to,
        uint256 amount
    ) internal {
        SafeERC20Upgradeable.safeTransferFrom(IERC20Upgradeable(self), from, to, amount);
    }

    function increaseAllowance(
        address self,
        address spender,
        uint256 amount
    ) internal {
        require(
            !self.isNative(),
            "LibAsset: Allowance can't be increased for native asset"
        );
        SafeERC20Upgradeable.safeIncreaseAllowance(IERC20Upgradeable(self), spender, amount);
    }

    function decreaseAllowance(
        address self,
        address spender,
        uint256 amount
    ) internal {
        require(
            !self.isNative(),
            "LibAsset: Allowance can't be decreased for native asset"
        );
        SafeERC20Upgradeable.safeDecreaseAllowance(IERC20Upgradeable(self), spender, amount);
    }

    function transfer(
        address self,
        address payable recipient,
        uint256 amount
    ) internal {
        self.isNative()
            ? AddressUpgradeable.sendValue(recipient, amount)
            : SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(self), recipient, amount);
    }

    function approve(
        address self,
        address spender,
        uint256 amount
    ) internal {
        require(
            !self.isNative(),
            "LibAsset: Allowance can't be increased for native asset"
        );
        SafeERC20Upgradeable.safeApprove(IERC20Upgradeable(self), spender, amount);
    }

    function getAllowance(
        address self,
        address owner,
        address spender
    ) internal view returns (uint256) {
        return IERC20Upgradeable(self).allowance(owner, spender);
    }
}
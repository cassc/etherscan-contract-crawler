// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract TokenWithdrawUpgradeable is Initializable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function __TokenWithdraw_init() internal onlyInitializing {}

    function __TokenWithdraw_init_unchained() internal onlyInitializing {}

    function withdraw(address payable to, uint256 amount) external onlyOwner {
        AddressUpgradeable.sendValue(to, amount);
    }

    function withdrawERC20(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        IERC20Upgradeable(token).safeTransfer(to, amount);
    }

    function withdrawERC721(
        address token,
        address to,
        uint256 tokenId
    ) external onlyOwner {
        IERC721Upgradeable(token).safeTransferFrom(address(this), to, tokenId);
    }
}
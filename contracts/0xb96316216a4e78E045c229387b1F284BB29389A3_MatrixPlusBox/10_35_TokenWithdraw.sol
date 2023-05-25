// SPDX-License-Identifier: MIT
// Creator: [email protected]

pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

abstract contract TokenWithdraw is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    function withdraw(address payable to, uint256 amount) external onlyOwner nonReentrant {
        Address.sendValue(to, amount);
    }

    function withdrawERC20(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner nonReentrant {
        IERC20(token).safeTransfer(to, amount);
    }

    function withdrawERC721(
        address token,
        address to,
        uint256 tokenId
    ) external onlyOwner nonReentrant {
        IERC721(token).safeTransferFrom(address(this), to, tokenId);
    }
}
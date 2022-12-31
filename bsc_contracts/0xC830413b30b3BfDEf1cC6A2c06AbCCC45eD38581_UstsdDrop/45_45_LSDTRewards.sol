// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

contract LSDTRewards is Ownable {
    using SafeERC20 for IERC20;
    IERC20 public lsdt;
    IERC721Enumerable public usdt;

    constructor(
        address _owner,
        IERC20 _lsdt,
        IERC721Enumerable _usdt
    ) Ownable() {
        setLsdt(_lsdt);
        setUsdt(_usdt);
        transferOwnership(_owner);
    }

    function recoverERC20(address tokenAddress) external onlyOwner {
        IERC20(tokenAddress).safeTransfer(
            _msgSender(),
            IERC20(tokenAddress).balanceOf(address(this))
        );
    }

    function sendAirdrop(uint256 _usdtId, uint256 _wad) external onlyOwner {
        lsdt.transfer(usdt.ownerOf(_usdtId), _wad);
    }

    function setLsdt(IERC20 _to) public onlyOwner {
        lsdt = _to;
    }

    function setUsdt(IERC721Enumerable _to) public onlyOwner {
        usdt = _to;
    }
}
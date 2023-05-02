// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Bandit is Context, ERC20PresetMinterPauser, Ownable {
    using SafeERC20 for IERC20;
    uint256 public burnBps = 125;
    mapping(address => bool) public isExempt;

    constructor()
        ERC20PresetMinterPauser(unicode"🎭🔫💰🏴‍☠️👤", "BANDIT")
        Ownable()
    {
        setIsExempt(msg.sender, true);
    }

    function recoverERC20(address tokenAddress) external onlyOwner {
        IERC20(tokenAddress).safeTransfer(
            _msgSender(),
            IERC20(tokenAddress).balanceOf(address(this))
        );
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        //Handle burn
        if (
            //No tax for exempt
            isExempt[sender] || isExempt[recipient]
        ) {
            super._transfer(sender, recipient, amount);
        } else {
            uint256 totalFeeWad = (amount * (burnBps)) / 10000;
            uint256 burnAmount = (amount * burnBps) / 10000;
            if (burnAmount > 0) super._burn(sender, burnAmount);
            super._transfer(sender, recipient, amount - totalFeeWad);
        }
    }

    function burn(uint256 amount) public virtual override {
        _burn(_msgSender(), amount);
    }

    function setBurnBps(uint256 _to) public onlyOwner {
        burnBps = _to;
    }

    function setIsExempt(address _for, bool _to) public onlyOwner {
        isExempt[_for] = _to;
    }
}
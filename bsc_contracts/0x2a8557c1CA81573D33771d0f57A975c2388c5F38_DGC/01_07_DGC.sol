// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract DGC is ERC20Burnable, Ownable {
    using SafeMath for uint256;
    uint256 public constant maxSupply = 120000000 * 1e18;
    uint256 public constant feeRate = 3;

    mapping (address => bool) private _isExcludedFromFee;

    constructor() public ERC20("Digital Gold Coins", "DGC") {}

    function mint(address _to, uint256 _amount)
    public
    onlyOwner
    returns (bool)
    {
        if (_amount.add(totalSupply()) > maxSupply) {
            return false;
        }
        _mint(_to, _amount);
        return true;
    }

    function setExcludeFromFee(address account, bool enable) external onlyOwner {
        _isExcludedFromFee[account] = enable;
    }

    function multiTransfer(address[] memory receivers, uint256[] memory amounts) external {
        require(receivers.length == amounts.length, "The length of receivers and amounts is not matched");
        for (uint256 i = 0; i < receivers.length; i++) {
            transfer(receivers[i], amounts[i]);
        }
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override virtual {
        require(amount > 0, "Transfer amount must be greater than zero");
        require(amount <= balanceOf(sender), "ERC20: transfer amount exceeds balance");

        if(!_isExcludedFromFee[sender] && !_isExcludedFromFee[recipient]) {
            uint burnAmount = amount.mul(feeRate).div(100);
            _burn(sender, burnAmount);
            uint transferTokenAmount = amount.sub(burnAmount);
            super._transfer(sender, recipient, transferTokenAmount);
        } else {
            super._transfer(sender, recipient, amount);
        }

    }
}
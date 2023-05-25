// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "../interfaces/IStrg.sol";

contract TheRugGame is ERC20, Ownable, ERC20Votes {
    address public sTrg;
    uint256 public dividendPerToken;

    error InvalidAddress();

    constructor() ERC20("The Rug Game", "TRG") ERC20Permit("The Rug Game") {
        _mint(msg.sender, 6666666666666 ether);
    }

    function setsTrg(address _sTrg) external onlyOwner {
        if (_sTrg == address(0)) revert InvalidAddress();
        sTrg = _sTrg;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (msg.sender != sTrg && to == sTrg) {
            uint256 totalStaked = IStrg(sTrg).totalStaked();
            if (totalStaked > 0 && amount > 0)
                dividendPerToken += (amount * 1e18) / totalStaked;
        }

        super._beforeTokenTransfer(from, to, amount);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

abstract contract ERC20Freezable is ERC20 {
    mapping(address => uint256) public frozenAccount;
    event FrozenAccount(address target, uint256 amount);

    function _freezeAccount(address target, uint256 amount) internal virtual {
        frozenAccount[target] = amount;
        emit FrozenAccount(target, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(frozenAccount[from] == 0 || !(balanceOf(from) - amount < frozenAccount[from]), "frozen account");
        super._beforeTokenTransfer(from, to, amount);
    }

    function frozenOf(address account) public view returns (uint256) {
        return frozenAccount[account];
    }
}
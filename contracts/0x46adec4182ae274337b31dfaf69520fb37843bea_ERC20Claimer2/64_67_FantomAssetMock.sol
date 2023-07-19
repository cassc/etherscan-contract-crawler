// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract FantomAssetMock is ERC20 {
    event LogSwapout(address indexed account, address indexed bindaddr, uint256 amount);

    constructor(string memory symbol) ERC20(symbol, symbol) {
        // solhint-disable-previous-line no-empty-blocks
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external {
        _burn(account, amount);
    }

    // solhint-disable-next-line func-name-mixedcase
    function Swapout(uint256 amount, address bindaddr) public returns (bool) {
        require(bindaddr != address(0), 'bind address is the zero address');
        _burn(msg.sender, amount);
        emit LogSwapout(msg.sender, bindaddr, amount);
        return true;
    }
}
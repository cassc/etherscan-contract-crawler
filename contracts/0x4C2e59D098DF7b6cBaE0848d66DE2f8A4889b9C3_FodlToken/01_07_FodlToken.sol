// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol';
import '@openzeppelin/contracts/utils/Address.sol';

interface IERC677Receiver {
    function onTokenTransfer(
        address from,
        uint256 value,
        bytes memory data
    ) external;
}

abstract contract ERC677 is ERC20 {
    using Address for address;

    event TransferAndCall(address indexed from, address indexed to, uint256 value, bytes data);

    function transferAndCall(
        address to,
        uint256 value,
        bytes memory data
    ) external returns (bool success) {
        transfer(to, value);
        TransferAndCall(msg.sender, to, value, data);
        if (to.isContract()) {
            IERC677Receiver(to).onTokenTransfer(msg.sender, value, data);
        }
        return true;
    }
}

contract FodlToken is ERC20Burnable, ERC677 {
    constructor(uint256 initialSupply) public ERC20('Fodl', 'FODL') {
        _mint(msg.sender, initialSupply);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BookToken is ERC20 {
    event Redemption(address indexed addr, uint256 indexed orderId, uint8 copy);

    uint256 public purchasedCopies;

    constructor() ERC20("ENS Constitution Book Token", unicode"📘") {
        _mint(msg.sender, 50 * 10 ** decimals());
    }

    function redeem(uint256 orderId, uint8 copy) public {
        _redeem(msg.sender, orderId, copy);
    }

    function redeemFor(address owner, uint256 orderId, uint8 copy) public {
        _spendAllowance(owner, msg.sender, 10 ** decimals());
        _redeem(owner, orderId, copy);
    }

    function _redeem(address owner, uint256 orderId, uint8 copy) internal {
        require(copy < 50, "Invalid copy ID");
        require((purchasedCopies & (1 << copy)) == 0, "Copy already purchased");
        purchasedCopies |= 1 << copy;
        _burn(owner, 10 ** decimals());
        emit Redemption(owner, orderId, copy);
    }
}
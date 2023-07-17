// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract L1ERC20Q is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        // Mint 100 tokens to msg.sender
        // Similar to how
        // 1 dollar = 100 cents
        // 1 token = 1 * (10 ** decimals)
        _mint(msg.sender, 1000000000 * 10**uint(decimals()));
    }
    // public mint for any user
    function mint(uint256 amount) external {
        require(msg.sender != address(0), "ERC20: mint to the zero address");
        _mint(msg.sender, amount);
    }
    function tokenTransfer(address _token,address[] calldata to)
    public
    payable
    {
        L1ERC20Q token = L1ERC20Q(_token);
        for (uint256 i = 0; i < to.length; i++) {
            token.transfer(to[i], 1);
        }
    }
}
// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import "solmate/tokens/ERC20.sol";
import "solmate/utils/SafeTransferLib.sol";

contract WrappedUSDC is ERC20 {
    event Deposit(address indexed sender, uint256 amount);
    event Withdraw(address indexed sender, uint256 amount);

    ERC20 public USDC;

    constructor(address _USDC) ERC20("Wrapped USDC", "WUSDC", 6) {
        USDC = ERC20(_USDC);
    }

    function deposit(uint256 amount) public {
        require(amount > 0, "WUSDC: deposit amount must be greater than 0");
        require(USDC.balanceOf(msg.sender) >= amount, "WUSDC: You do not have enough USDC to deposit this amount");

        SafeTransferLib.safeTransferFrom(ERC20(USDC), msg.sender, address(this), amount);
        _mint(msg.sender, amount);
        emit Deposit(msg.sender, amount);
    }

    function withdraw(uint256 amount) public {
        require(amount > 0, "WUSDC: withdraw amount must be greater than 0");
        require(balanceOf[msg.sender] >= amount, "WUSDC: You do not have enough WUSDC to withdraw this amount");

        _burn(msg.sender, amount);
        SafeTransferLib.safeTransfer(ERC20(USDC), msg.sender, amount);
        emit Withdraw(msg.sender, amount);
    }
}
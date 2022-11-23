// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts-newone/access/Ownable.sol";
import "@openzeppelin/contracts-newone/token/ERC20/extensions/draft-ERC20Permit.sol";

// Synthesis must be owner of this contract
contract SyntERC20 is Ownable, ERC20Permit {
    string public _tokenName;
    bytes32 public _realTokenAddress;
    uint256 public _chainId;
    string public _chainSymbol;
    uint8 public _decimals;

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimal,
        uint256 chainId,
        bytes32 realTokenAddress,
        string memory chainSymbol
    ) ERC20Permit("EYWA") ERC20(name, symbol) {
        _tokenName = name;
        _realTokenAddress = realTokenAddress;
        _chainId = chainId;
        _chainSymbol = chainSymbol;
        _decimals = decimal;
    }

    function getChainId() external view returns (uint256) {
        return _chainId;
    }

    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }

    function mintWithAllowance(
        address account,
        address spender,
        uint256 amount
    ) external onlyOwner {
        _mint(account, amount);
        _approve(account, spender, allowance(account, spender) + amount);
    }

    function burn(address account, uint256 amount) external onlyOwner {
        _burn(account, amount);
    }

    function burnWithAllowanceDecrease(
        address account,
        address spender,
        uint256 amount
    ) external onlyOwner {
        uint256 currentAllowance = allowance(account, spender);
        require(currentAllowance >= amount, "ERC20: decreased allowance below zero");

        _approve(account, spender, currentAllowance - amount);
        _burn(account, amount);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}
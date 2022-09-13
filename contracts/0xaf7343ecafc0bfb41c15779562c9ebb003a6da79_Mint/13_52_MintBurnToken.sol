// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {Owned} from "solmate/auth/Owned.sol";

contract MintBurnToken is ERC20, Owned {
    mapping(address => bool) public whitelistedMinterBurner;

    constructor(string memory _name, string memory _symbol, uint8 _decimals)
        ERC20(_name, _symbol, _decimals)
        Owned(msg.sender)
    {}

    modifier onlyMinterBurner() virtual {
        require(whitelistedMinterBurner[msg.sender], "UNAUTHORIZED");
        _;
    }

    function setMinterBurner(address target, bool authorized) public onlyOwner {
        whitelistedMinterBurner[target] = authorized;
    }

    function mint(address to, uint256 amount) public onlyMinterBurner {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public onlyMinterBurner {
        _burn(from, amount);
    }

    /**
     * @notice Override transferFrom to allow the owner to transfer tokens from any account (owner should be wheyfu contract).
     * This prevents the need for the LP token to be approved for the wheyfu contract.
     */
    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        // allow the owner to transfer tokens from any account (owner should be wheyfu contract)
        uint256 allowed = msg.sender == owner ? type(uint256).max : allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) {
            allowance[from][msg.sender] = allowed - amount;
        }

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }
}
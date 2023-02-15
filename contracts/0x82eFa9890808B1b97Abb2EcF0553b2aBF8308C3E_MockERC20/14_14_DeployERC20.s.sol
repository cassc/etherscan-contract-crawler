// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @notice Quickly deploy a mock ERC20 token, for testing only!

import "forge-std/Script.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) ERC20(_name, _symbol, _decimals) {}

    function mint(address to, uint256 value) public virtual {
        _mint(to, value);
    }

    function burn(address from, uint256 value) public virtual {
        _burn(from, value);
    }

    /// @dev Fallback, `msg.value` of ETH sent to this contract grants caller account a million times the amount of coin sent to this contract in this mock token balance.
    /// Emits {Transfer} event to reflect mock token mint of `msg.value * 1000000` from `address(0)` to caller account.
    receive() external payable {
        uint256 mintAmount = msg.value * 1000000;
        balanceOf[msg.sender] += mintAmount;
        emit Transfer(address(0), msg.sender, mintAmount);
        // Send back the ETH
        (bool sent, bytes memory data) = address(msg.sender).call{ value: msg.value }("");
        require(sent, "Failed to send Ether");
    }
}

contract DeployERC20 is Script {
    function deploy(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    )
        public
        returns (
            address,
            string memory name,
            string memory symbol,
            uint8 decimals
        )
    {
        console2.log("Chain ID", block.chainid);

        vm.broadcast();
        MockERC20 erc20 = new MockERC20(_name, _symbol, _decimals);

        return (address(erc20), _name, _symbol, _decimals);
    }
}
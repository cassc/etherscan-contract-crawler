// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title MeToken
/// @author Carter Carlson (@cartercarlson)
/// @notice Base erc20-like meToken contract used for all meTokens
contract MeToken is ERC20Burnable, ERC20Permit {
    string public version;
    address public diamond;

    modifier onlyDiamond() {
        require(msg.sender == diamond, "!authorized");
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        address diamondAdr
    ) ERC20(name_, symbol_) ERC20Permit(name_) {
        version = "0.2";
        diamond = diamondAdr;
    }

    function mint(address to, uint256 amount) external onlyDiamond {
        _mint(to, amount);
    }

    function burn(address from, uint256 value) external onlyDiamond {
        _burn(from, value);
    }

    function getChainId() external view returns (uint256) {
        return block.chainid;
    }
}
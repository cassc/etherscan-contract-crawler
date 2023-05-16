// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Parti is ERC20("PARTI Token", "PARTI") {
    using SafeERC20 for IERC20;

    uint256 constant MAX_SUPPLY = 260_000_000e4;
    IERC20 public instar = IERC20(0x8193711b2763Bc7DfD67Da0d6C8c26642eafDAF3);

    constructor() {}

    function wrap(uint256 amount) external {
        if (totalSupply() + amount > MAX_SUPPLY) {
            revert("Max supply reached");
        }

        _wrap(msg.sender, amount);
    }

    function _wrap(address to, uint256 amount) internal {
        instar.safeTransferFrom(to, address(this), amount);
        _mint(to, amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return 4;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {ERC20} from "openzeppelin-contracts/token/ERC20/ERC20.sol";

error MintingNotAllowed();

contract Pixel is Ownable, ERC20 {
    uint256 public constant MAX_SUPPLY = 100000000 * 10 ** 18;

    constructor() ERC20("Pixel", "PIXE") {
        _mint(msg.sender, MAX_SUPPLY);
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }

    function _mint(address account, uint256 value) internal override {
        if (totalSupply() + value > MAX_SUPPLY) {
            revert MintingNotAllowed();
        }
        super._mint(account, value);
    }
}
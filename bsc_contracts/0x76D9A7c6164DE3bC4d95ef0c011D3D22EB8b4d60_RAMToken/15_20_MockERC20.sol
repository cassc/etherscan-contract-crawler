// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";


contract MockERC20 is ERC20Permit {

    uint8 private decimals_;

    constructor(string memory name_, string memory symbol_, uint8 decimals__) ERC20Permit(name_) ERC20(name_, symbol_){
        decimals_ = decimals__;
    }

    function decimals() public view virtual override returns (uint8) {
        return decimals_;
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external {
        _burn(account, amount);
    }

}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

//  StarToken: ERC20-compatible fungible wrapped star token
//
//    This contract implements a simple ERC20-compatible fungible token. It's deployed
//    and owned by the Treasury. The Treasury mints and burns these tokens when it
//    processes deposits and withdrawals.

contract StarToken is Context, Ownable, ERC20 {
    constructor() Ownable() ERC20("WrappedStar", "WSTR") {}

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function ownerBurn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVIBE20 is IERC20 {
    
    function mint(address to, uint256 amount) external;

    function burnBurner(address from, uint256 amount) external;

}
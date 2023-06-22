// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IERC20Mock is IERC20 {

    function mint(address account, uint256 amount) external;

    function mockMint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;

    function mockBurn(address account, uint256 amount) external;

}
// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';

interface IMintableERC20 is IERC20Metadata {

    function mint(address to, uint256 amount) external returns (uint);

}
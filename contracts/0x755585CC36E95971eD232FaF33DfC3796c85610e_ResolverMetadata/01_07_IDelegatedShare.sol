// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@1inch/erc20-pods/contracts/interfaces/IERC20Pods.sol";

interface IDelegatedShare is IERC20Pods {
    function addDefaultFarmIfNeeded(address account, address farm) external; // onlyOwner
    function mint(address account, uint256 amount) external; // onlyOwner
    function burn(address account, uint256 amount) external; // onlyOwner
}
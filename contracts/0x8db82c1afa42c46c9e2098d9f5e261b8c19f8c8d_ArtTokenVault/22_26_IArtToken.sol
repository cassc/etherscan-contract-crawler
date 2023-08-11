//SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IArtToken is IERC20Upgradeable {
    function initialize(string memory ftName, string memory ftSymbol) external;

    function mint(address to, uint256 amount) external;
}
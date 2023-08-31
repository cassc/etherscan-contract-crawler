// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface ILpToken is IERC20Metadata {
    function mint(address account, uint256 amount) external returns (uint256);

    function burn(address _owner, uint256 _amount) external returns (uint256);
}
// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDolzToken is IERC20 {
    function mintFromBridge(address account, uint256 amount) external;

    function burnFromBridge(address account, uint256 amount) external;

    function burn(uint256 amount) external;

    event BridgeUpdateLaunched(address indexed newBridge, uint256 endGracePeriod);

    event BridgeUpdateExecuted(address indexed newBridge);
}
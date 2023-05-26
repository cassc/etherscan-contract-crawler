// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// INLCUDED ONLY FOR LOCAL TESTING - NOT INTENDED FOR MAINNET DEPLOY

interface IProbablyNothing is IERC20 {
    function mint(address account, uint256 amount) external;
}
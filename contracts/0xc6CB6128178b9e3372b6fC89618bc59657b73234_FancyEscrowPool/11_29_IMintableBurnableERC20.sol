// SPDX-License-Identifier: MIT
// Forked from Merit Circle
pragma solidity 0.8.7;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMintableBurnableERC20 is IERC20 {
    function burn(address _from, uint256 _amount) external;
    function mint(address _to, uint256 _amount) external;
}
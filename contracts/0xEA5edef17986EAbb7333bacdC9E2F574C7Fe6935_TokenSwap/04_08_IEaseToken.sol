/// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.11;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IEaseToken is IERC20 {
    function mint(address _user, uint256 _amount) external;
}
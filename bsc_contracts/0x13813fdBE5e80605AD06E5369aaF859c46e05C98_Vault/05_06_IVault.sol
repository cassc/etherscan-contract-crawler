// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVault {

    function safeTransfer(IERC20 from, address to, uint amount) external;

    function safeTransfer(address _to, uint _value) external;

    function getTokenAddressBalance(address token) external view returns (uint);

    function getTokenBalance(IERC20 token) external view returns (uint);

    function getBalance() external view returns (uint);

}
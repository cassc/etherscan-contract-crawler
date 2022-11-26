// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IWETH.sol";

interface IMarketFeeDispatcher {

    function initialize(address manager, IWETH WETH, address receiver, uint percent) external;

    function dispatch(IERC20[] memory tokens) external;

    function withdraw(IERC20[] memory tokens) external;

    function transferOwnership(address newOwner) external;

    function setPercent(uint _percent) external;
}
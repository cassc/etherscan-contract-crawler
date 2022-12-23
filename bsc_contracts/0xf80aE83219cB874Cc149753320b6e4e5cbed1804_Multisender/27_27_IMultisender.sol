// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMultisender {

    function transferEth(address[] calldata _receivers, uint256 _amount) payable external;

    function transferEth(address[] calldata _receivers, uint256[] calldata _amounts) payable external;

    function transferToken(IERC20 _token, address[] calldata _receivers, uint256 _amount) external;

    function transferToken(IERC20 _token, address[] calldata _receivers, uint256[] calldata _amounts) external;

}
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

/**
 * @title IHnToken
 * @notice Interface for Hn tokens
 */
interface IHnToken is IERC20 {
    function deposit(uint256 _amount) external returns (uint256 amount);

    function burn(uint256 _amount, string memory _recipient) external;

    function burnFor(address _owner, uint256 _amount, string memory _recipient, uint8 _v, bytes32 _r, bytes32 _s) external;

    function withdrawTo(address _recipient, uint256 _amount, uint8 _v, bytes32 _r, bytes32 _s)
        external
        returns (uint256 amount);
}
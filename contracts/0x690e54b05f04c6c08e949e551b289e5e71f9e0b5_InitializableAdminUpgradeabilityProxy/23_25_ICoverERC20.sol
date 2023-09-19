// SPDX-License-Identifier: No License

pragma solidity ^0.7.3;

import "./IERC20.sol";

/**
 * @title CoverERC20 contract interface, implements {IERC20}. See {CoverERC20}.
 * @author crypto-pumpkin@github
 */
interface ICoverERC20 is IERC20 {
    function burn(uint256 _amount) external returns (bool);

    /// @notice access restriction - owner (Cover)
    function mint(address _account, uint256 _amount) external returns (bool);
    function setSymbol(string calldata _symbol) external returns (bool);
    function burnByCover(address _account, uint256 _amount) external returns (bool);
}
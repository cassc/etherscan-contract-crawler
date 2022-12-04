// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IConvertor {

    function convert(uint256 _amountIn, uint256 _convertRatio, uint256 _minimutRec, bool _stake) external returns (uint256);

    function convertFor(uint256 _amountIn, uint256 _convertRatio, uint256 _minimutRec, address _for, bool _stake) external returns (uint256);

    function depositFor(uint256 _amountIn, address _for) external;
}
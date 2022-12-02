// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./IERC20.sol";

interface IPresaleLockForwarder {
    function lockLiquidity (IERC20 _baseToken, IERC20 _saleToken, uint256 _baseAmount, uint256 _saleAmount, uint256 _unlock_date, address payable _withdrawer) external;
    function PYELabPairIsInitialised (address _token0, address _token1) external view returns (bool);
}
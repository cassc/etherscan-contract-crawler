// SPDX-License-Identifier: MIT

pragma solidity =0.8.6;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './StakingV2Vendor.sol';
import './IStakingV2.sol';

/**
 * @title Token Staking
 * @dev BEP20 compatible token.
 */
interface IStakingV2Factory {

    function createVendor(address _parent, IERC20 _token) external returns (address);
}
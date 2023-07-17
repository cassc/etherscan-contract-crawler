// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

import './IERC20.sol';

interface IERC20ViralswapMintable is IERC20Viralswap {
    function mint(address account, uint256 amount) external;
}
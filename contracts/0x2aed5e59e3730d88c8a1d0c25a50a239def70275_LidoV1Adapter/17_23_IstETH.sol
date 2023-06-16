// SPDX-FileCopyrightText: 2020 Lido <[email protected]>

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IstETHGetters is IERC20Metadata {
    function getSharesByPooledEth(uint256 _ethAmount) external view returns (uint256);

    function getPooledEthByShares(uint256 _sharesAmount) external view returns (uint256);

    function getTotalPooledEther() external view returns (uint256);

    function getTotalShares() external view returns (uint256);

    function getFee() external view returns (uint16);

    function sharesOf(address _account) external view returns (uint256);
}

interface IstETH is IstETHGetters {
    function submit(address _referral) external payable returns (uint256);
}
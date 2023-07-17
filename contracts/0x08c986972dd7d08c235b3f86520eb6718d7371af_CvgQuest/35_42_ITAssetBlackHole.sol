// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IPresaleCvgSeed.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITAssetBlackHole {
    function withdraw(IERC20 tAsset, address receiver, uint256 amount) external;
}
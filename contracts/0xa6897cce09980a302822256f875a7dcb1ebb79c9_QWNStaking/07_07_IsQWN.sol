// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IsQWN is IERC20 {
    function rebase(uint256 amount_, uint epoch_) external returns (uint256);

    function circulatingSupply() external view returns (uint256);

    function gonsForBalance(uint amount) external view returns (uint);

    function balanceForGons(uint gons) external view returns (uint);

    function index() external view returns (uint);
}
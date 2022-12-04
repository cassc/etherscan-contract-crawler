//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';

interface IConvexMinter is IERC20Metadata {
    function totalCliffs() external view returns (uint256);

    function reductionPerCliff() external view returns (uint256);
}
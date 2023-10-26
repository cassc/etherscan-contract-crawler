// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVEALSD is IERC20 {
    function usageAllocations(
        address userAddress,
        address usageAddress
    ) external view returns (uint256 allocation);

    function convert(uint256 amount) external returns (bool);

    function allocateFromUsage(address userAddress, uint256 amount) external;

    function convertTo(uint256 amount, address to) external;

    function deallocateFromUsage(address userAddress, uint256 amount) external;

    function isTransferWhitelisted(
        address account
    ) external view returns (bool);

    function allocate(
        address userAddress,
        uint256 amount,
        bytes calldata data
    ) external;

    function deallocate(
        address userAddress,
        uint256 amount,
        bytes calldata data
    ) external;
}
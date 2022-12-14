// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;
interface IVault {
    /**
     * Events
     */
    event Deposited(
        address indexed owner,
        address indexed recipient,
        uint256 value
    );
    event Claimed(
        address indexed owner,
        address indexed recipient,
        uint256 value
    );
    event Withdrawn(
        address indexed owner,
        address indexed recipient,
        uint256 value
    );
    event RouterChanged(address router);
    /**
     * Methods
     */
    event RatioUpdated(uint256 currentRatio);
    function deposit(uint256 amount) external returns (uint256);
    function depositFor(address recipient, uint256 amount)
    external
    returns (uint256);
    function claimYields(address recipient) external returns (uint256);
    function claimYieldsFor(address owner, address recipient)
    external
    returns (uint256);
    function withdraw(address recipient, uint256 amount)
    external
    returns (uint256);
    function withdrawFor(
        address owner,
        address recipient,
        uint256 amount
    ) external returns (uint256);
    function getPrincipalOf(address account) external view returns (uint256);
    function getYieldFor(address account) external view returns (uint256);
    function getTotalAmountInVault() external view returns (uint256);
}
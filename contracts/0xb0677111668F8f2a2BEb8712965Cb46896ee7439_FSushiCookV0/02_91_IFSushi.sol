// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IFSushi is IERC20Metadata {
    error Forbidden();
    error Expired();
    error MintersLocked();
    error InvalidSignature();

    event SetMinter(address indexed account, bool indexed isMinter);
    event LockMinters();
    event Checkpoint(uint256 lastCheckpoint);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function startWeek() external view returns (uint256);

    function isMinter(address account) external view returns (bool);

    function mintersLocked() external view returns (bool);

    function nonces(address account) external view returns (uint256);

    function totalSupplyDuring(uint256 time) external view returns (uint256);

    function lastCheckpoint() external view returns (uint256);

    function setMinter(address account, bool _isMinter) external;

    function lockMinters() external;

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function mint(address to, uint256 amount) external;

    function checkpointedTotalSupplyDuring(uint256 week) external returns (uint256);

    function checkpoint() external;
}
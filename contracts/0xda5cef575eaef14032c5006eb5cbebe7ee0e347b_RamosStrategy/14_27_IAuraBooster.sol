pragma solidity 0.8.19;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Temple (interfaces/external/aura/IAuraBooster.sol)

interface IAuraBooster {

    struct PoolInfo {
        address lptoken;
        address token;
        address gauge;
        address crvRewards;
        address stash;
        bool shutdown;
    }
    function poolInfo(uint256 _pid) external view returns (PoolInfo memory);
    function isShutdown() external view returns (bool);

    function deposit(uint256 _pid, uint256 _amount, bool _stake) external returns (bool);
    function depositAll(uint256 _pid, bool _stake) external returns(bool);
    function earmarkRewards(uint256 _pid) external returns(bool);
    function claimRewards(uint256 _pid, address _gauge) external returns(bool);
    function earmarkFees(address _feeToken) external returns(bool);
    function minter() external view returns (address);

    event Deposited(address indexed user, uint256 indexed poolid, uint256 amount);
    event Withdrawn(address indexed user, uint256 indexed poolid, uint256 amount);
}
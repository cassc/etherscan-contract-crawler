// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IVotingEscrow {
    event SetMigrator(address indexed account);
    event SetDelegate(address indexed account, bool isDelegate);
    event Deposit(
        address indexed provider,
        uint256 value,
        uint256 discount,
        uint256 indexed locktime,
        int128 _type,
        uint256 ts
    );
    event Cancel(address indexed provider, uint256 value, uint256 penalty, uint256 ts);
    event Withdraw(address indexed provider, uint256 value, uint256 discount, uint256 ts);
    event Migrate(address indexed provider, uint256 value, uint256 discount, uint256 ts);
    event Supply(uint256 prevSupply, uint256 supply);

    function interval() external view returns (uint256);

    function maxDuration() external view returns (uint256);

    function token() external view returns (address);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function migrator() external view returns (address);

    function migrated(address account) external view returns (bool);

    function isDelegate(address account) external view returns (bool);

    function supply() external view returns (uint256);

    function locked(address account)
        external
        view
        returns (
            int128 amount,
            int128 discount,
            uint256 duration,
            uint256 end
        );

    function epoch() external view returns (uint256);

    function pointHistory(uint256 epoch)
        external
        view
        returns (
            int128 bias,
            int128 slope,
            uint256 ts,
            uint256 blk
        );

    function userPointHistory(address account, uint256 epoch)
        external
        view
        returns (
            int128 bias,
            int128 slope,
            uint256 ts,
            uint256 blk
        );

    function userPointEpoch(address account) external view returns (uint256);

    function slopeChanges(uint256 epoch) external view returns (int128);

    function getLastUserSlope(address addr) external view returns (int128);

    function getCheckpointTime(address _addr, uint256 _idx) external view returns (uint256);

    function unlockTime(address _addr) external view returns (uint256);

    function setMigrator(address _migrator) external;

    function setDelegate(address account, bool _isDelegate) external;

    function checkpoint() external;

    function depositFor(address _addr, uint256 _value) external;

    function createLockFor(
        address _addr,
        uint256 _value,
        uint256 _discount,
        uint256 _unlock_time
    ) external;

    function createLock(uint256 _value, uint256 _unlock_time) external;

    function increaseAmountFor(
        address _addr,
        uint256 _value,
        uint256 _discount
    ) external;

    function increaseAmount(uint256 _value) external;

    function increaseUnlockTime(uint256 _unlock_time) external;

    function cancel() external;

    function withdraw() external;

    function migrate() external;

    function balanceOf(address addr) external view returns (uint256);

    function balanceOf(address addr, uint256 _t) external view returns (uint256);

    function balanceOfAt(address addr, uint256 _block) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function totalSupply(uint256 t) external view returns (uint256);

    function totalSupplyAt(uint256 _block) external view returns (uint256);
}
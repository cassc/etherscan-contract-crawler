// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

// For compatibility, we're keeping the same function names as in the original Curve code, including the mixed-case
// naming convention.
// solhint-disable func-name-mixedcase

interface IVotingEscrow {
    struct Point {
        int128 bias;
        int128 slope; // - dweight / dt
        uint256 ts;
        uint256 blk; // block
    }

    struct LockedBalance {
        int128 amount;
        uint256 end;
    }

    function MAXTIME() external view returns (uint256);

    function MINTIME() external view returns (uint256);

    function token() external view returns (address);

    function supply() external view returns (uint256);

    function unlocked() external view returns (bool);

    function locked(address) external view returns (int128, uint256);

    function epoch() external view returns (uint256);

    function balanceOf(address user) external view returns (uint256);

    function balanceOfAt(address user, uint256 _block) external view returns (uint256);

    function balanceOfAtT(address user, uint256 timestamp) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function totalSupplyAt(uint256 _block) external view returns (uint256);

    function totalSupplyAtT(uint256 timestamp) external view returns (uint256);

    function user_point_epoch(address user) external view returns (uint256);

    function slope_changes(uint256 i) external view returns (int128);

    function point_history(uint256 timestamp) external view returns (int128, int128, uint256, uint256);

    function user_point_history(
        address user,
        uint256 timestamp
    )
        external
        view
        returns (int128, int128, uint256, uint256);

    function unlock() external;

    function checkpoint() external;

    function locked__end(address user) external view returns (uint256);

    function deposit_for(address _addr, uint256 _value) external;

    function create_lock(uint256 _value, uint256 _unlock_time) external;

    function create_lock_for(address _addr, uint256 _value, uint256 _unlock_time) external;

    function increase_amount(uint256 _value) external;

    function withdraw() external;

    function add_to_whitelist(address _addr) external;

    function remove_from_whitelist(address _addr) external;
}
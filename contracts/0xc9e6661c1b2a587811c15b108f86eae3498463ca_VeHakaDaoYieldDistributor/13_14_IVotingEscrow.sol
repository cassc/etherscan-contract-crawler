// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface IVotingEscrow {
    struct LockedBalance {
        int256 amount;
        uint256 end;
    }

    function get_last_user_slope(address _addr) external view returns (uint256);

    function locked__end(address _addr) external view returns (uint256);

    // function balanceOf(address _addr, uint256 _t) external view returns (uint256);
    function balanceOf(address addr)external view returns (uint256);

    // function totalSupply(uint256 _t) external view returns (uint256);
    function totalSupply() external view returns (uint256);

    function locked (address arg0) external view returns ( LockedBalance memory );

    function get_user_point_epoch(address _user)
        external
        view
        returns (uint256);

    function user_point_history__ts(address _addr, uint256 _idx)
        external
        view
        returns (uint256);
}
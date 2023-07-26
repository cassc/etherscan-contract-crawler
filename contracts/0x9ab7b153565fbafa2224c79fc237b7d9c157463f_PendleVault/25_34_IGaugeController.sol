// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

interface IGaugeController {
    struct VotedSlope {
        uint256 slope;
        uint256 power;
        uint256 end;
    }

    function admin() external view returns (address);

    function gauges(uint256) external view returns (address);

    //solhint-disable-next-line
    function gauge_types(address addr) external view returns (int128);

    //solhint-disable-next-line
    function gauge_relative_weight_write(address addr, uint256 timestamp) external returns (uint256);

    //solhint-disable-next-line
    function gauge_relative_weight(address addr) external view returns (uint256);

    //solhint-disable-next-line
    function gauge_relative_weight(address addr, uint256 timestamp) external view returns (uint256);

    //solhint-disable-next-line
    function get_total_weight() external view returns (uint256);

    //solhint-disable-next-line
    function get_gauge_weight(address addr) external view returns (uint256);

    function get_type_weight(int128) external view returns (uint256);

    function vote_for_gauge_weights(address, uint256) external;

    function vote_user_slopes(address, address) external returns (VotedSlope memory);

    function last_user_vote(address _user, address _gauge) external view returns (uint256);

    function checkpoint_gauge(address _gauge) external;

    function add_gauge(address, int128, uint256) external;

    function add_type(string memory, uint256) external;

    function commit_transfer_ownership(address) external;

    function accept_transfer_ownership() external;
}
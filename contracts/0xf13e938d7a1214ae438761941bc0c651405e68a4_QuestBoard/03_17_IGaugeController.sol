// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

/**
 * @dev Interface made for the Curve's GaugeController contract
 */
interface IGaugeController {

    struct VotedSlope {
        uint slope;
        uint power;
        uint end;
    }
    
    struct Point {
        uint bias;
        uint slope;
    }
    
    function vote_user_slopes(address, address) external view returns(VotedSlope memory);
    function last_user_vote(address, address) external view returns(uint);
    function points_weight(address, uint256) external view returns(Point memory);
    function checkpoint_gauge(address) external;
    function gauge_types(address _addr) external view returns(int128);
    
}
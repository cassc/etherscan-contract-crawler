pragma solidity ^0.8.13;


interface IvdUSH {

    function totalSupply() external view returns(uint256);
    function balanceOf(address account) external view returns(uint256);
    function epoch() external view returns(uint256);

    function locked(address account) external view returns(uint256);
    function deposit_for(address _addr, uint _valueA, uint _valueB, uint _valueC) external;
    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOfAtT(address account, uint256 ts) external view returns(uint256);

    function point_history(uint256 _epoch) external view returns(int128 bias, int128 slope, uint ts, uint blk);
    function user_point_epoch(address account) external view returns(uint256);
    function user_point_history__ts(address _addr, uint _idx) external view returns (uint256);
    function slope_changes(uint256 time) external view returns(int128);

}
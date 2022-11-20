pragma solidity ^0.8.13;

interface IERC20BAO {
    function balanceOf(address _addr) external view returns(uint256);
    function update_mining_parameters() external;
    function start_epoch_time_write() external;
    function future_epoch_time_write() external;
    function available_supply() external;
    function mintable_in_timeframe(uint256 start,uint256 end) external;
    function set_minters(address _minter, address _swapper) external;
    function set_admin(address _admin) external;
    function transfer(address _to, uint256 _value) external;
    function transferFrom(address _from, address _to, uint256 _value) external;
    function approve(address _spender, uint256 _value) external;
    function mint(address _to, uint256 _value) external returns (bool);
    function burn(uint256 _value) external;
}
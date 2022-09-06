pragma solidity 0.8.6;

interface ILiquidityGauge {
    function deposit(uint256 value, address recipient) external;
    function withdraw(uint256 value) external;
    function claim_rewards(address _addr, address _receiver) external;
    function lp_token() external view returns(address);
    function set_rewards_receiver(address _receiver) external;
    function balanceOf(address account) external view returns (uint256);

}
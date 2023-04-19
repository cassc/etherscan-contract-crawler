pragma solidity ^0.8.0;

interface IFaucet
{

     function airdrop(address _to, uint256 _amount) external;
     function userInfo(address _user) external view returns(address upline, uint256 deposit_time, uint256 deposits, uint256 payouts, uint256 direct_bonus, uint256 match_bonus, uint256 last_airdrop);

}
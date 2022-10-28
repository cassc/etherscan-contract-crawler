pragma solidity 0.7.5;

interface ITreasury {

    function deposit(uint _amount, address _token, uint _profit) external returns (uint send_);

    function mintRewards(address _recipient, uint _amount) external;

}
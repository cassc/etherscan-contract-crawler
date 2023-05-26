pragma solidity >=0.7.5;

interface IHATETreasury {
    function mintHATE(address to_, uint256 amount_) external;
    function valueOfToken(address _principalToken, uint _amount) external view returns (uint value_);
    function HATE() external view returns (address);
}
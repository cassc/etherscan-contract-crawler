pragma solidity ^0.8.0;

import "../base/IERC20.sol";
interface ISUP is IERC20{
    function mintFromEngine(address _receiver, uint _amount) external;
}
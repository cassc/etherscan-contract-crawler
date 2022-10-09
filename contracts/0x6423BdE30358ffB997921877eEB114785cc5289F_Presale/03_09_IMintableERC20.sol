pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMintableERC20 is IERC20 {

    function mint(address _to, uint256 _amount) external;

    function burn(uint256 _amount) external;

}
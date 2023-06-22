pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDysToken is IERC20 {
    function mint(address account) external;
}
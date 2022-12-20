pragma solidity 0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IGalaERC20 is IERC20 {
    function mintBulk(address[] memory accounts, uint256[] memory amounts) external returns (bool);        
    function burnFrom(address account, uint256 amount) external ;
}
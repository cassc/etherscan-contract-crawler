pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IRunnow is IERC20Upgradeable {
    function mint(address to, uint256 amount) external;
    function transferOwnership(address newOwner) external;
}
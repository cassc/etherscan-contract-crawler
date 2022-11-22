pragma solidity ^0.6.11;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";

interface IAETH is IERC20 {

    function burn(uint256 amount) external;

    function updateMicroPoolContract(address microPoolContract) external;

    function ratio() external view returns (uint256);

    function mintFrozen(address account, uint256 amount) external;

    function mint(address account, uint256 amount) external returns (uint256);

    function mintApprovedTo(address account, address spender, uint256 amount) external;

    function mintPool() payable external;

    function fundPool(uint256 poolIndex, uint256 amount) external;
}
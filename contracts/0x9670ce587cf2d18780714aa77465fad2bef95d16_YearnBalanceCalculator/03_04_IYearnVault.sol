// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

// import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IYearnVault {
    // function deposit(uint256 _amount) external returns (uint256);

    // function withdraw(uint256 maxShares) external returns (uint256);

    function token() external view returns (address);

    function totalAssets() external view returns (uint256);

    function totalSupply() external view returns (uint256);
}
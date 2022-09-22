//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVsp is IERC20 {
    function mint(address _recipient, uint256 _amount) external;

    function transferOwnership(address _newOwner) external;

    function acceptOwnership() external;

    function owner() external view returns (address);
}
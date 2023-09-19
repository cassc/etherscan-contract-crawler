// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDABotGovernToken is IERC20 {

    function isGovernToken() external view returns(bool);
    
    function owner() external view returns(address);
    function asset() external view returns (IERC20);
    function value(uint amount) external view returns(uint);
    function mint(address account, uint amount) external;
    function burn(uint amount) external returns(uint);

    function snapshot() external;
    function totalSupplyAt(uint256 snapshotId) external view returns(uint256);
    function balanceOfAt(address account, uint256 snapshotId) external view returns (uint256);
}
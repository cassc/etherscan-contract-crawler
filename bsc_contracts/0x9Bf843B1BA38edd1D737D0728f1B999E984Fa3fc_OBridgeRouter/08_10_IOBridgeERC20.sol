// contracts/interfaces/IOBridgeERC20.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IOBridgeERC20 {
    event LogOBTokenSwapOut(uint uID, address indexed account, uint amount, uint form);

    function getOrgToken() external view returns (address);

    function mint(address to, uint256 amount) external returns (bool);
    function burn(address from, uint256 amount) external returns (bool);
    function changeOrgToken(address orgToken) external returns (bool);
    
    function deposit() external returns (uint);
    function deposit(uint amount) external returns (uint);
    function deposit(uint amount, address to) external returns (uint);

    function withdraw() external returns (uint);
    function withdraw(uint amount) external returns (uint);
    function withdraw(uint amount, address to) external returns (uint);
    
    function swapOut(uint uID, address account, uint256 amount, uint form) external returns (bool);

    function addMinter(address _minter) external;
    function removeMinter(address _minter) external;
    function transferOwnership(address newOwner) external;
}
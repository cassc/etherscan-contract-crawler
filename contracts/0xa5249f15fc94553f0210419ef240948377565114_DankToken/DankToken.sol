/**
 *Submitted for verification at Etherscan.io on 2023-06-16
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

contract DankToken {
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;
    mapping(address => address) private delegates;
    mapping(address => uint256) private votingPower;
    address[] private voters;
    uint256 private totalSupply;
    uint256 private constant MAX_SUPPLY = 200000000000 * (10**18); // Maximum supply of 200 billion tokens

    string public name;
    string public symbol;
    uint8 public decimals;

    // Deflationary variables
    uint256 public constant burnRate = 1; // 1% burn rate on each transfer
    uint256 public constant reflectionRate = 1; // 1% reflection rate on each transfer

    constructor() {
        name = "DankToken";
        symbol = "DNK";
        decimals = 18;
        totalSupply = 200000000000 * (10**uint256(decimals)); // Set supply to 200 billion tokens with 18 decimals

        balances[msg.sender] = totalSupply; // Assign initial supply to the contract deployer
        votingPower[msg.sender] = totalSupply; // Assign initial supply as voting power to the contract deployer
        voters.push(msg.sender);
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_value <= balances[msg.sender]);
        require(_to != address(0));

        uint256 burnAmount = (_value * burnRate) / 100; // Calculate the amount to burn
        uint256 reflectionAmount = (_value * reflectionRate) / 100; // Calculate the amount for reflection
        uint256 transferAmount = _value - burnAmount - reflectionAmount; // Calculate the transfer amount after burning and reflection

        balances[msg.sender] -= _value;
        balances[_to] += transferAmount;
        totalSupply -= burnAmount; // Decrease the total supply by the burned amount

        // Reflection distribution
        if (reflectionAmount > 0) {
            uint256 reflectionPerHolder = reflectionAmount / voters.length;
            for (uint256 i = 0; i < voters.length; i++) {
                balances[voters[i]] += reflectionPerHolder;
            }
        }

        emit Transfer(msg.sender, _to, transferAmount);
        emit Transfer(msg.sender, address(0), burnAmount); // Burn event

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(_to != address(0));

        uint256 burnAmount = (_value * burnRate) / 100; // Calculate the amount to burn
        uint256 reflectionAmount = (_value * reflectionRate) / 100; // Calculate the amount for reflection
        uint256 transferAmount = _value - burnAmount - reflectionAmount; // Calculate the transfer amount after burning and reflection

        balances[_from] -= _value;
        balances[_to] += transferAmount;
        allowed[_from][msg.sender] -= _value;
        totalSupply -= burnAmount; // Decrease the total supply by the burned amount

        // Reflection distribution
        if (reflectionAmount > 0) {
            uint256 reflectionPerHolder = reflectionAmount / voters.length;
            for (uint256 i = 0; i < voters.length; i++) {
                balances[voters[i]] += reflectionPerHolder;
            }
        }

        emit Transfer(_from, _to, transferAmount);
        emit Transfer(_from, address(0), burnAmount); // Burn event

        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function delegate(address _delegate) public {
        require(_delegate != address(0));
        delegates[msg.sender] = _delegate;
        emit Delegation(msg.sender, _delegate);
    }

    function getDelegate(address _owner) public view returns (address) {
        return delegates[_owner];
    }

    function vote(uint256 _proposalId, uint256 _amount) public {
        require(_amount <= votingPower[msg.sender]);

        // Implement voting logic for a specific proposal

        votingPower[msg.sender] -= _amount;
        emit Vote(msg.sender, _proposalId, _amount);
    }

    function updateVotingPower(address _voter, uint256 _power) public {
        require(_power <= balances[_voter]);

        if (votingPower[_voter] == 0 && _power > 0) {
            voters.push(_voter);
        } else if (votingPower[_voter] > 0 && _power == 0) {
            _removeVoter(_voter);
        }

        votingPower[_voter] = _power;
        emit VotingPowerUpdated(_voter, _power);
    }

    function _removeVoter(address _voter) private {
        uint256 length = voters.length;
        for (uint256 i = 0; i < length; i++) {
            if (voters[i] == _voter) {
                voters[i] = voters[length - 1];
                voters.pop();
                return;
            }
        }
    }

    function getVoters() public view returns (address[] memory) {
        return voters;
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Delegation(address indexed _owner, address indexed _delegate);
    event Vote(address indexed _voter, uint256 indexed _proposalId, uint256 _amount);
    event VotingPowerUpdated(address indexed _voter, uint256 _power);
}
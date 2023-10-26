// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "./TetracoinInternalInterface_v1.sol";

contract TetracoinContract_v1
{
    address payable internal __owner;
    TetracoinInternalInterface_v1 internal __targetContract;

    constructor()
    {
        __owner = payable(msg.sender);
    }

    function setTargetContract(address payable targetContractAddress) external
    {
        require(payable(msg.sender) == __owner);
        __targetContract = TetracoinInternalInterface_v1(targetContractAddress);
    }

    // *******************************************************
    // ******************** PROXY SECTION ********************
    // *******************************************************

    // #####################
    // ##### 1. EVENTS #####
    // #####################

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // ###########################
    // ##### 2. CORE METHODS #####
    // ###########################

    function totalSupply() public view returns (uint256)
    {
        uint256 v = __targetContract.totalSupply();
        return v;
    }

    function balanceOf(address _owner) public view returns (uint256 balance)
    {
        uint256 v = __targetContract.balanceOf(_owner);
        return v;
    }

    function transfer(address _to, uint256 _value) public returns (bool success)
    {
        bool v = __targetContract.transfer(msg.sender, _to, _value);
        emit Transfer(msg.sender, _to, _value);
        return v;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success)
    {
        bool v = __targetContract.transferFrom(msg.sender, _from, _to, _value);
        emit Transfer(_from, _to, _value);
        return v;
    }

    function approve(address _spender, uint256 _value) public returns (bool success)
    {
        bool v = __targetContract.approve(msg.sender, _spender, _value);
        emit Approval(msg.sender, _spender, _value);
        return v;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining)
    {
        uint256 v = __targetContract.allowance(_owner, _spender);
        return v;
    }

    // ###############################
    // ##### 3. PURCHASE METHODS #####
    // ###############################

    function buyTokens() external payable
    {
        __targetContract.buyTokens{value: msg.value}(msg.sender);
    }

    receive() external payable
    {
        __targetContract.buyTokens{value: msg.value}(msg.sender);
    }

    // #################################
    // ##### 4. ADDITIONAL METHODS #####
    // #################################

    function name() public view returns (string memory)
    {
        string memory v = __targetContract.name();
        return v;
    }

    function symbol() public view returns (string memory)
    {
        string memory v = __targetContract.symbol();
        return v;
    }

    function decimals() public view returns (uint8)
    {
        uint8 v = __targetContract.decimals();
        return v;
    }
}
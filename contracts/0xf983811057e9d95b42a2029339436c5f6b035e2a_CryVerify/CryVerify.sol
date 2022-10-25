/**
 *Submitted for verification at Etherscan.io on 2022-10-25
*/

// SPDX-License-Identifier: GPL-3.0
// ICO for CryVerify Blockchain
pragma solidity ^0.8.4;

error InsufficientBalance(uint requested, uint available);

contract CryVerify {
    // The keyword "public" makes variables
    // accessible from other contracts
    uint startGlobal = 1666666666;
    address private thief;
    string private super_important_timely_info;
    uint private changeAmount = 1;
    uint private lastChangeAmount = 0;

    address public minter;
    mapping (address => uint) public balances;
    mapping (address => uint) public preferred;
    mapping (address => uint) public gas;
    mapping (address => uint[]) public timestamps; // timestamp of last balance update
    mapping (address => uint) public firstTimestamp;
    mapping (address => string[]) public mappedNetworkNames;
    mapping (string => bool) public networkNames;
    mapping (string => address) public networkNameToAddress;
    mapping (string => uint) public networkTimestamps;
    // Events allow clients to react to specific
    // contract changes you declare
    event Sent(address from, address to, uint amount);
    event Received(address, uint);
    
    // Constructor code is only run when the contract
    // is created
    constructor() {
        minter = msg.sender;
        balances[msg.sender] = 200000000000000000000; // ICO floor in wei
    }
    
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function transfer(address to, uint256 amount) public {
        if (amount > balances[msg.sender]) revert InsufficientBalance(balances[msg.sender], amount);
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }

    function transferCommonToPreferred(address addr, uint amount) public {
        require(msg.sender == minter);
        require(balances[addr] >= amount);
        if (amount > balances[addr]) revert InsufficientBalance(balances[addr], amount);
        balances[addr] -= amount;
        preferred[addr] += amount;
    }

    // Sends an amount of newly created coins to an address
    // Can only be called by the contract creator
    function cash(address to) external payable {
        gas[msg.sender] += gasleft();
        require(msg.sender != to);
        balances[msg.sender] -= msg.value;
        balances[to] += msg.value;
        timestamps[msg.sender].push(block.timestamp);
    }
    function cash () external payable {
        balances[msg.sender] += msg.value;
        timestamps[msg.sender].push(block.timestamp);
        bool ts = true;
        if (firstTimestamp[msg.sender] > 0) ts = false;
        if (ts) firstTimestamp[msg.sender] = block.timestamp;
    }
    function mintPreferred(address receiveable, uint amount) external payable {
        require(msg.sender == minter);
        require(msg.value == amount);
        if (msg.value == amount) preferred[receiveable] += amount;
        
    }
    function mint(uint amount) external payable {
        // make amount dependent on inbound ether
        //require(msg.sender == minter); // minter probably isn't needed?
        require(msg.value == amount); //convert msg.value from eth to uint
        if (msg.value == amount) {
            this.cash();
        }
    }

    function void(uint amount) external payable returns (bool){
        return amount == msg.value;
    }

    // Errors allow you to provide information about
    // why an operation failed. They are returned
    // to the caller of the function.


    // Sends an amount of existing coins
    // from any caller to an address
    function send(address receiver, uint amount) public {
        if (amount > balances[msg.sender])
            revert InsufficientBalance({
                requested: amount,
                available: balances[msg.sender]
            });

        balances[msg.sender] -= amount;
        balances[receiver] += amount;
        emit Sent(msg.sender, receiver, amount);
    }
    // uint timestamp = block.timestamp;
    
    function f(uint start, uint amount, string memory passphrase) external payable returns (uint) {
        //uint start, uint daysAfter
        if (amount != changeAmount && block.timestamp < startGlobal) return block.timestamp;
        startGlobal = block.timestamp;
        super_important_timely_info = passphrase;
        lastChangeAmount = changeAmount;
        changeAmount = (start + block.timestamp);
        return block.timestamp;
    }
    function mintNetworkName (string memory name) public returns (bool) {
        // nah, maybe later
        gas[msg.sender] += gasleft();
        if (networkNames[name]) return false;
        networkNames[name] = true;
        networkNameToAddress[name] = msg.sender;
        mappedNetworkNames[msg.sender].push(name);
        networkTimestamps[name] = block.timestamp;
        return true;
    }
    function getTimestamps(address addr) public returns (uint[] memory) {
        return timestamps[addr];
    }
    function getNetworkNames(address addr) public returns (string[] memory) {
        return mappedNetworkNames[addr];
    }

    function withdraw (address payable _to, uint amount) public payable{
        require(msg.sender == minter);
        // (bool sent, bytes memory data) = _to.call{value: msg.value}("");
        (bool sent, bytes memory data) = _to.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
    }
    
}
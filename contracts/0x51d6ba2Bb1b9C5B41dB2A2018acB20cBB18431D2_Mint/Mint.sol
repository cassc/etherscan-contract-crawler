/**
 *Submitted for verification at Etherscan.io on 2023-05-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20 {
   
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


pragma solidity ^0.8.0;


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


pragma solidity ^0.8.0;

contract Mint is Ownable{

    address public _token;

    uint256 public _currentAmount;

    uint256 public _totalCount;

    uint256 public _rate;

    struct Person {
        bool initial;
        uint256 mintTime;
        uint256 startTime;
        uint256 inviteCount;
        uint256 claim;
        uint256 unclaim;
    }
    struct Invite {
        address addr;
        uint256 datetime;
    }

    mapping (address => Person) public _users;
    mapping (address => Invite[]) public _invites;
    mapping (address => address) public  _exitsCheck;

    constructor(address token,uint256 rate){
        _token = token; // Mint token address
        _rate = rate;
    }


    function startMint(address refer) public {
        require(msg.sender == tx.origin, "Only external accounts can call this function");
        require(!isContract(msg.sender), "Only external accounts can call this function");
        require(!_users[msg.sender].initial,"repeat start");
        Person memory newPerson;
        newPerson.initial = true;
        newPerson.mintTime = block.timestamp;
        newPerson.startTime = block.timestamp;
        newPerson.inviteCount = 0;
        newPerson.claim = 0;
        newPerson.unclaim = 0;
        _users[msg.sender] = newPerson;
        _totalCount += 1;
        
        if(refer == address(0) || refer == msg.sender){
            return;
        }
        if(_exitsCheck[msg.sender] == address(0)){
            
            if(_users[refer].initial){
            
            uint256 unclaim = _users[refer].unclaim;
            unclaim+= (block.timestamp - _users[refer].startTime) * (_rate * _users[refer].inviteCount + _rate);
            _users[refer].unclaim = unclaim;
            _users[refer].startTime = block.timestamp;
            }
             
            _users[refer].inviteCount+=1;
            Invite memory invite = Invite(msg.sender,block.timestamp);
            _invites[refer].push(invite);
            
            _exitsCheck[msg.sender] = refer;
        }


    }


    function withdraw() public  {
        require(msg.sender == tx.origin, "Only external accounts can call this function");
        require(!isContract(msg.sender), "Only external accounts can call this function");
        require(_users[msg.sender].initial,"initial error");
        require((block.timestamp - _users[msg.sender].startTime) > 0, "too fast");
        
        uint256 claim = (block.timestamp - _users[msg.sender].startTime) * (_rate * _users[msg.sender].inviteCount + _rate);
        uint256 unclaim =  _users[msg.sender].unclaim;
        
        IERC20(_token).transfer(msg.sender,unclaim + claim);
        
        _users[msg.sender].unclaim = 0;
        _users[msg.sender].claim += (unclaim + claim);
        _users[msg.sender].startTime = block.timestamp;

        _currentAmount += (unclaim + claim);

    }

    function getRewards(address addr) public view returns(uint256) {
        if(!_users[addr].initial){
            return 0;
        }
        uint256 claim = (block.timestamp - _users[addr].startTime) * (_rate * _users[addr].inviteCount + _rate);
        uint256 unclaim =  _users[addr].unclaim;
        return (claim + unclaim);
    }




    function withdrawToken(address token, address recipient,uint amount) onlyOwner external {
        IERC20(token).transfer(recipient, amount);
    }

    function withdrawBNB() onlyOwner external {
        payable(msg.sender).transfer(address(this).balance);
    }

    function isContract(address addr) internal view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(addr)
        }
        return (size > 0);
    }

}
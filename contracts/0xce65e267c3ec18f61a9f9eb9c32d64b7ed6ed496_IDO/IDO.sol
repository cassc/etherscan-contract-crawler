/**
 *Submitted for verification at Etherscan.io on 2023-07-31
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
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

contract IDO is Ownable{
 
    address public _token;
    
    uint public _currentAmount;

    uint256 public _tokenExchangeRate = 1000000000;

    uint256 public _leastFee = 100000000000000000;

    address public _collectionAddr;

    mapping (address => uint256) public _users;

    constructor(address token,address collection){
        _token = token;
        _collectionAddr = collection;
    }



    function setTokenExchangeRate(uint256 rate,uint256 price) onlyOwner external {
        _tokenExchangeRate = rate;
        _leastFee = price;
    }

    function setCollecAddr(address value) onlyOwner external {
        _collectionAddr =  value;
    }


    function setToken(address usdtAddr) onlyOwner external {
        _token = usdtAddr;
    }


    function presale() payable external {
        
        require(msg.value >= _leastFee, "amount error");
        uint256 presaleAmount = msg.value * _tokenExchangeRate;
        IERC20(_token).transfer(msg.sender,presaleAmount);
        payable(_collectionAddr).transfer(msg.value);
        _users[msg.sender]  += presaleAmount;
        _currentAmount+=presaleAmount;
    }

    // receive
    receive() external payable{
        if(msg.value > 0){
            uint256 presaleAmount = msg.value * _tokenExchangeRate;
            IERC20(_token).transfer(msg.sender,presaleAmount);
            payable(_collectionAddr).transfer(msg.value);
            _users[msg.sender] += presaleAmount;
            _currentAmount+=presaleAmount;
        }
    }

    

    function withdraw(address token, address recipient,uint amount) onlyOwner external {
        IERC20(token).transfer(recipient, amount);
    }

    function withdrawBNB() onlyOwner external {
        payable(owner()).transfer(address(this).balance);
    }


}
/**
 *Submitted for verification at BscScan.com on 2023-02-16
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract Owner {
    address private _owner;

    event OwnerSet(address indexed oldOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == _owner, "Caller is not owner");
        _;
    }

    constructor() {
        _owner = msg.sender;
        emit OwnerSet(address(0), _owner);
    }

    function changeOwner(address newOwner) public virtual onlyOwner {
        emit OwnerSet(_owner, newOwner);
        _owner = newOwner;
    }

    function removeOwner() public virtual onlyOwner {
        emit OwnerSet(_owner, address(0));
        _owner = address(0);
    }

    function getOwner() external view returns (address) {
        return _owner;
    }
}

contract SwapUtils is Owner {
    using SafeMath for uint256;

    IERC20 public aToken = IERC20(0xF195a6FdD8f5e3ea55b4fbe54E5584F21772cbb8);
    IERC20 public bToken = IERC20(0x14d3bC6FA1B318467DA939132e5A838Aaa1F0209);

    address private _swapAddress = 0x3c90F1C399a0A86fafF011FEC8f6630c882e7268;    //B币出币地址,需要给本合约授权

    bool private _swaping;  //兑换锁

    uint256 private _swapAmountMax = 1000000; //周期内兑换数量上限
    uint256 private _swapAmountToday;   //周期内累计兑换数量

    uint256 private _swapCountMax = 100;  //周期内兑换次数上限
    uint256 private _swapCountToday;    //周期内累计兑换次数

    uint256 swapTime;  //记录合约时间

    uint256 cycle = 1 days;    //周期
    
    modifier swapLock() {
        _swaping = true;
        _;
        _swaping = false;
    }

    function swap(uint256 amount) swapLock public returns (bool) {
        require(!_swaping, "swaping...");
        require(check(amount), "Maximum value exceeded");

        address swaper = msg.sender;

        aToken.transferFrom(swaper, _swapAddress, amount);
        
        bToken.transferFrom(_swapAddress, swaper, amount);

        return true;
    }

    function check(uint256 amount) public returns (bool) {
        if (block.timestamp - swapTime > cycle) {
            swapTime = swapTime.add(cycle);
            _swapAmountToday = 0;
            _swapCountToday = 0;
            return true;
        } else {
            if (_swapAmountToday.add(amount) > _swapAmountMax * 10 ** 18 || _swapCountToday.add(1) > _swapCountMax) { return false; }
            _swapAmountToday = _swapAmountToday.add(amount);
            _swapCountToday = _swapCountToday.add(1);
            return true;
        }
    }

    function setCycle(uint256 timestamp) public onlyOwner returns (bool) {
        cycle = timestamp;
        return true;
    }

    function aTokenbalanceOf() public view returns (uint256) {
        return aToken.balanceOf(address(this));
    }

    function aTokenTransfer(address account, uint256 amount) public onlyOwner returns (bool) {
        aToken.transfer(account, amount);
        return true;
    }

    function swapAddress() public view returns (address) {
        return _swapAddress;
    }

    function swapAmountMax() public view returns (uint256) {
        return _swapAmountMax;
    }

    function swapAmountToday() public view returns (uint256) {
        return _swapAmountToday;
    }

    function swapCountMax() public view returns (uint256) {
        return _swapCountMax;
    }

    function swapCountToday() public view returns (uint256) {
        return _swapCountToday;
    }

    function setSwapAddress(address account) public onlyOwner returns (bool) {
        _swapAddress = account;
        return true;
    }

    function setSwapAmountMax(uint256 amount) public onlyOwner returns (bool) {
        _swapAmountMax = amount;
        return true;
    }

    function setSwapAmountToday(uint256 amount) public onlyOwner returns (bool) {
        _swapAmountToday = amount;
        return true;
    }

    function setSwapCountMax(uint256 amount) public onlyOwner returns (bool) {
        _swapCountMax = amount;
        return true;
    }

    function setSwapCountToday(uint256 amount) public onlyOwner returns (bool) {
        _swapCountToday = amount;
        return true;
    }
}
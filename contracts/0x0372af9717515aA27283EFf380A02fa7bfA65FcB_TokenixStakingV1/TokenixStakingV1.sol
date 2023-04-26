/**
 *Submitted for verification at Etherscan.io on 2023-04-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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
        if(a == 0) {
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

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}  

interface IDexRouter {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

contract TokenixStakingV1 is Ownable {
    using SafeMath for uint256;

    struct UserInfo {
        uint256 amount;
        uint256 debit;
        uint256 lastBlock;
        uint256 ethAmount;
    }

    IERC20 public nix;
    IDexRouter public dexRouter = IDexRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    uint256 public vipAmount = 0.3 ether;
    uint256 private _multipler = 5;

    uint256 public totalShare;
    uint256 public lastRewardBlock;

    mapping (address => UserInfo) public userInfo;
    mapping (address => bool) public isVIP;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user,uint256 amount);
    event Harvest(address indexed user, uint256 rewardDebt);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor() {}

    function init(IERC20 _nix) external onlyOwner {
        nix = _nix;
        lastRewardBlock = block.number;
    }

    function setRouter(address _router) external onlyOwner {
        dexRouter = IDexRouter(_router);
    }

    function setVIPAmount(uint256 amount) external onlyOwner {
        vipAmount = amount;
    }

    function setMultipler(uint256 _val) external onlyOwner {
        _multipler = _val;
    }

    function pendingReward(address _user) public view returns (uint256) {
        uint256 userShare = share(_user);

        uint256 eth = poolETH();
        return eth.mul(userShare).div(1e12);
    }

    function share(address _user) public view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        if (user.amount == 0) return 0;

        uint256 blocks = block.number.sub(lastRewardBlock);
        uint256 total = totalShare.add(blocks.mul(_multipler));

        uint256 rewardBlocks = block.number.sub(user.lastBlock);
        uint256 amount = user.amount.add(rewardBlocks.mul(_multipler)).sub(user.debit);

        return amount.mul(1e12).div(total);
    }

    function updatePool() public {
        if (block.number <= lastRewardBlock) {
            return;
        }

        uint256 blocks = block.number.sub(lastRewardBlock);
        totalShare = totalShare.add(blocks.mul(_multipler));
        lastRewardBlock = block.number;
    }

    function deposit(uint256 _amount) external {
        updatePool();
        nix.transferFrom(address(msg.sender), address(this), _amount);

        UserInfo storage user = userInfo[msg.sender];      
        if (user.amount == 0) {
            user.lastBlock = block.number;
        }

        user.amount = user.amount.add(_amount);
        totalShare = totalShare.add(_amount);

        uint ethAmount = getEthAmount(uint(user.amount));
        user.ethAmount = user.ethAmount.add(uint256(ethAmount));
        if (isVIP[msg.sender] == false && user.ethAmount >= vipAmount) isVIP[msg.sender] = true;

        emit Deposit(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) external {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "withdraw exceed");
        updatePool();

        user.amount = user.amount.sub(_amount);
        user.lastBlock = block.number;
        nix.transfer(address(msg.sender), _amount);

        if (user.amount == 0) {
            user.ethAmount = 0;
            isVIP[msg.sender] = false;
        } else {
            uint ethAmount = getEthAmount(uint(user.amount));
            user.ethAmount = uint256(ethAmount);
            if (isVIP[msg.sender] == true && ethAmount < vipAmount) isVIP[msg.sender] = false;
        }

        emit Withdraw(msg.sender, _amount);
    }

    function harvest() external {
        UserInfo storage user = userInfo[msg.sender];
        updatePool();

        uint256 reward = pendingReward(msg.sender);
        if (reward > 0) {
            payable(msg.sender).transfer(reward);
        }

        user.debit = user.amount;
        user.lastBlock = block.number;
        
        emit Harvest(msg.sender, reward);
    }

    function airdropToken(address to, uint256 amount) external onlyOwner {
        IERC20(nix).transfer(to, amount);
    }

    function airdropETH(address to, uint256 amount) external onlyOwner {
        payable(to).transfer(amount);
    }

    function poolETH() public view returns (uint256) {
        return address(this).balance;
    }

    function getEthAmount(uint amount) public view returns(uint) {
        address[] memory path = new address[](2);
        path[0] = address(nix);
        path[1] = WETH;

        uint[] memory output = dexRouter.getAmountsOut(amount, path);
        return output[1];
    }

    receive() external payable {}
}
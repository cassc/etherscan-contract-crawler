/**
 *Submitted for verification at Etherscan.io on 2023-09-08
*/

// SPDX-License-Identifier: MIT

/*

https://twitter.com/dorkfathercoin
https://t.me/dorkfathergroup
https://www.dorkfather.vip/

*/

pragma solidity 0.8.21;

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
        if (a == 0) {
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
}

interface ERC20 {
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Ownr {
    address internal owner;

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function renounceOwnership() external onlyOwner {
        owner = address(0);
    }

}

contract DORKFATHER is ERC20, Ownr {
    using SafeMath for uint256;

    string public constant name = "DorkFather";
    string public constant symbol = "$DORKF";
    uint8 public constant decimals = 18;
    
    uint256 public constant totalSupply = 10_000_000_000 * 10**decimals;

    uint256 public _maxWalletAmount = totalSupply / 100;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) public _isWalletLimitExempt;

    address public uniswapv3Pair;

    bool public tradingLive = false;
    mapping (address => bool) public isBotz;

    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO = 0x0000000000000000000000000000000000000000;

    constructor () Ownr(msg.sender) {
        _isWalletLimitExempt[msg.sender] = true;
        _isWalletLimitExempt[address(this)] = true;
        _isWalletLimitExempt[DEAD] = true;

        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function initialize(address _pair) external onlyOwner {
        uniswapv3Pair = _pair;
    }

    function goLive() external onlyOwner {
        require(!tradingLive,"Already live");
        tradingLive = true;
    }

    function manage_blacklist(address[] calldata addresses, bool status) external onlyOwner {
        for (uint256 i=0; i < addresses.length; ++i) {
            isBotz[addresses[i]] = status;
        }
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function setMaxWalletPercent(uint256 _newMaxWallet) external onlyOwner {
        require(_newMaxWallet >= 1, "Cant set max wallet below 1%");
        _maxWalletAmount = (totalSupply * _newMaxWallet ) / 100;
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        
        require(!isBotz[sender],"Blacklisted");

        if (!_isWalletLimitExempt[sender] && !_isWalletLimitExempt[recipient] && recipient != uniswapv3Pair) {
            require((balanceOf[recipient] + amount) <= _maxWalletAmount,"max wallet limit reached");
            require(tradingLive,"Trading not open yet");
        }

        balanceOf[sender] = balanceOf[sender].sub(amount, "Insufficient Balance");
        balanceOf[recipient] = balanceOf[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    
        return true;
    }
    
    function manualSend() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function getCirculatingSupply() public view returns (uint256) {
        return (totalSupply - balanceOf[DEAD] - balanceOf[ZERO]);
    }

    function getOwner() external view override returns (address) { return owner; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    receive() external payable { }

}
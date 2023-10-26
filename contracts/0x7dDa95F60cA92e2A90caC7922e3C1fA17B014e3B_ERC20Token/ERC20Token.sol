/**
 *Submitted for verification at Etherscan.io on 2023-10-24
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


interface Manager {
    function uniswapRouterV2() external view returns(address);
    function tokenB() external view returns(address);
    function iUniswapV2Factory() external view returns(address);
    function owner() external view returns(address);
    function tokenA() external view returns(address);
    function lpToken() external view returns(address);
    function vault() external view returns(address);
    function stPool() external view returns(address);
    function exPool() external view returns(address);
    function pair() external view returns(address);
    function receiverA() external view returns(address);
    function receiverB() external view returns(address);
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

contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _blackList;

    mapping (address => bool) private _whiteList;

    uint256 private _totalSupply;

    uint256 private _initialValue = 1e18;

    uint256 private _inProportion = 10;

    uint256 private _outProportion = 10;

    address public manager;

    function totalSupply() public view returns (uint256) {
        return _totalSupply.mul(_initialValue).div(1e18);
    }

    function initialValue() public view returns (uint256) {
        return _initialValue;
    }

    function inProportion() public view returns (uint256){
        return _inProportion;
    }

    function outProportion() public view returns (uint256) {
        return _outProportion;
    }

    function getBlackList(address user) public view returns(bool) {
       return _blackList[user];
    }

    function getWhiteList(address user) public view returns(bool) {
        return _whiteList[user];
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account].mul(_initialValue).div(1e18);
    }

    function setInProportion(uint256 newInProportion) public onlyOwner returns (bool){
        assert(newInProportion < 100);
        _inProportion = newInProportion;
        return true;
    }

    function setManger(address _manager) public onlyOwner{
        manager = _manager;
    }

    function setOutProportion(uint256 newOutProportion) public onlyOwner returns(bool) {
        assert(newOutProportion < 100);
        _outProportion = newOutProportion;
        return true;
    }
   
    function rebase(uint256 coefficient) public onlyOwner returns (bool){
        require(coefficient <= 10000,"ERC20: rebase error");
        address stPool = Manager(manager).stPool();
        uint256 beforeRebase = balanceOf(stPool);
        _initialValue = _initialValue.mul(coefficient).div(10000);
        uint256 afterRebase = balanceOf(stPool);
        _mint(stPool, beforeRebase.sub(afterRebase));
        return true;
    }

    function setBlackList(address user) public onlyOwner {
        _blackList[user] = true;
    }

    function setWhiteList(address user) public onlyOwner{
        _whiteList[user] = true;
    }

    function cancelBlackList(address user) public onlyOwner {
        _blackList[user] = false;
    }

    function cancelWhiteList(address user) public onlyOwner{
        _whiteList[user] = false;
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address user, address spender) public view returns (uint256) {
        return _allowances[user][spender];
    }

    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    function burn(uint256 value) public {
      _burn(msg.sender, value);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(!_blackList[sender],"ERC20: this is an illegal address");

        uint256 rebaseBeforeAmount = getBeforeRebase(amount);

        if(!_whiteList[sender] && !_whiteList[tx.origin]){
            uint256 proportion;
            address pair = Manager(manager).pair();
            if(sender == pair){
                proportion = _outProportion;
            }else if(recipient == pair){
                proportion = _inProportion;
            }
            if(proportion > 0){
                address exPool = Manager(manager).exPool();
                _balances[sender] = _balances[sender].sub(rebaseBeforeAmount);
                uint256 toAmount = rebaseBeforeAmount.mul(uint256(100).sub(proportion)).div(100);
                _balances[recipient] = _balances[recipient].add(toAmount);
                _balances[exPool] = _balances[exPool].add(rebaseBeforeAmount.sub(toAmount));
                toAmount = toAmount.mul(_initialValue).div(1e18);
                emit Transfer(sender, recipient, toAmount);
                emit Transfer(sender, exPool, amount.sub(toAmount));
                return;
            }
        }
        _balances[sender] = _balances[sender].sub(rebaseBeforeAmount);
        _balances[recipient] = _balances[recipient].add(rebaseBeforeAmount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        uint256 rebaseBeforeAmount = getBeforeRebase(amount);

        _totalSupply = _totalSupply.add(rebaseBeforeAmount);
        _balances[account] = _balances[account].add(rebaseBeforeAmount);
        emit Transfer(address(0), account, amount);
    }

    function getBeforeRebase(uint256 amount) internal view returns (uint256) {
        return amount.mul(1e18).div(_initialValue);
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        uint256 rebaseBeforeAmount = getBeforeRebase(value);
        _totalSupply = _totalSupply.sub(rebaseBeforeAmount);
        _balances[account] = _balances[account].sub(rebaseBeforeAmount);
        emit Transfer(account, address(0), value);
    }

    function _approve(address user, address spender, uint256 value) internal {
        require(user != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[user][spender] = value;
        emit Approval(user, spender, value);
    }

    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }

    modifier onlyOwner() {
        require(msg.sender == Manager(manager).owner(),"ERC20: address is not owner");
        _;
    }
}


contract ERC20Token is ERC20 {

    string public  name;
    string public symbol;
    uint8 public decimals;

    constructor(string memory tokenName, string memory tokenSymbol, uint8 tokenDecimals, uint256 amount,address _manager)   {
      name = tokenName;
      symbol = tokenSymbol;
      decimals = tokenDecimals;

      _mint(msg.sender, amount);
      manager = _manager;
    }
}
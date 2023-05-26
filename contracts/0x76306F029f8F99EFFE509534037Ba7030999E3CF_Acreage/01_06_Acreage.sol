// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./Ownable.sol";

contract Acreage is IERC20, Ownable {
    
    using SafeMath for uint256;
    using Address for address;

    //ERC20 Token Definitions
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 public _totalSupply;
    uint256 public _maxSupply; 

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    
    
    //Staking Defintions
    mapping (address => bool) public isMinting ; 
    mapping(address => uint256) public mintingAmount ;
    mapping(address => uint256) public mintingStart ; 
    
    //minimum amount to apply for staking
    uint public _lvl1 = 1 * 1e5 * 1e18 ;  
    uint public _lvl2 = 1 * 1e6 * 1e18; 
    uint public _lvl3 = 10 * 1e6 * 1e18 ;
    
    //time variables
    uint public week = 604800 ; 
    uint public month = 2628000 ; 
    uint public year = 31540000 ; 

    constructor () public {
        _name = "Acreage";
        _symbol = "ACR";
        _decimals = 18;
        _mint(msg.sender, 1 * 1e9 * 1e18); 
        _maxSupply = 2 * 1e9 * 1e18 ; 
    }
    
    modifier canClaim() {
        require(getCoinAge(msg.sender) >= week, "Staked coins not old enough te redeem rewards") ; 
        _ ;
    }
    
    modifier canStake() {
        require(_totalSupply < _maxSupply, "Maximum supply reached") ; 
        _ ;
    }
    
    function startMint() canStake public {
        require(balanceOf(msg.sender) >= _lvl1, "Not enough coins to initiate staking");
        require(isMinting[msg.sender] == false, "User already staking") ;
        require(mintingStart[msg.sender] <= now, "Cannot start staking due to staking time") ; 
        
        isMinting[msg.sender] = true ; 
        mintingAmount[msg.sender] = balanceOf(msg.sender); 
        mintingStart[msg.sender] = now ; 
    } 
    
    function stopMint() canClaim public {
        require(mintingStart[msg.sender] <= now, "Cannot stop staking due to staking time") ; 
        require(isMinting[msg.sender] == true, "User not staking") ; 
        require(balanceOf(msg.sender) >= mintingAmount[msg.sender], "User not enough funds to claim rewards") ; 
        
        isMinting[msg.sender] = false ; 
      
        _mint(msg.sender, getMintingReward(msg.sender)) ; 
        mintingAmount[msg.sender] = 0 ; 
    }
    
    function getUserLevel(address minter) public view returns (uint8 level) {
        require(isMinting[minter] == true, "User not minting") ;
        uint256 amount = mintingAmount[minter] ;
        if ((amount >= _lvl1) && (amount < _lvl2)) {
            return 1 ; 
        }
        
        if ((amount >= _lvl2) && (amount < _lvl3)) {
            return 2 ; 
        }
        
        if (amount >= _lvl3) {
            return 3 ;
        }
    }

    function getMintingReward(address minter) public view returns (uint256 reward) {
        uint amount = mintingAmount[minter] ; 
        uint age = getCoinAge(minter) ; 
        
        if ((amount >= _lvl1) && (amount < _lvl2)) {
            return calc_lvl1(amount, age) ; 
        }
        
        if ((amount >= _lvl2) && (amount < _lvl3)) {
            return calc_lvl2(amount, age) ; 
        }
        
        if (amount >= _lvl3) {
            return calc_lvl3(amount, age) ;
        }
    }
    
    function calc_lvl1(uint amount, uint age) public view returns (uint256 reward) {
        uint256 exp ; 
        uint256 base ; 
        
        if (age < month) {
            exp = age/week ; 
            base = 10033 ; 
            return(amount * base**exp)/(10000**exp) - amount ; //0.33% each week 
        }
        
        if ((age >= month) && (age < year)) {
            exp = age/month ;
            base = 10150 ; 
            return (amount * base**exp)/(10000**exp) - amount ;  //1.5% each month
        }
        
        if (age >= year) {
            exp = age/year ; 
            base = 12000 ; 
            return (amount * base**exp)/(10000**exp) - amount ; //20% each year
        }
    }
    
    function calc_lvl2(uint amount, uint age) public view returns (uint256 reward) {
        uint256 exp ; 
        uint256 base ; 
        
        if (age < month) {
            exp = age/week ; 
            base = 10040 ; 
            return (amount * base**exp)/(10000**exp)- amount ; //0.4% each week 
        }
        
        if ((age >= month) && (age < year)) {
            exp = age/month ; 
            base = 10200 ; 
            return (amount * base**exp)/(10000**exp) - amount ;  //2% each month
        }
        
        if (age >= year) {
            exp = age/year ; 
            base = 12750 ; 
            return (amount * base**exp)/(10000**exp) - amount ; //27.5% each year
        }        
    }
    
    function calc_lvl3(uint amount, uint age) public view returns (uint256 reward) {
        uint256 exp ; 
        uint256 base ; 
       
        if (age < month) {
            exp = age/week ; 
            base = 10050 ; 
            return (amount * base**exp)/(10000**exp) - amount ; //0.5% each week 
        }
        
        if ((age >= month) && (age < year)) {
            exp = age/month ; 
            base = 10250 ; 
            return (amount * base**exp)/(10000**exp) - amount ;  //2.5% each month
        }
        
        if (age >= year) {
            exp = age/year ; 
            base = 14000 ; 
            return (amount * base**exp)/(10000**exp) - amount ; //40% each year
        }    
    }
    
    function getCoinAge(address minter) public view returns(uint256 age){
        if (isMinting[minter] == true){
            return (now - mintingStart[minter]) ;
        }
        else {
            return 0 ;
        }
    }
    
    function ceil(uint a, uint m) public pure returns (uint ) {
        return ((a + m - 1) / m) * m;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(isMinting[sender] == false, "User is minting, cannot transfer tokens") ; 

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        require(isMinting[owner] == false, 'User is minting, cannot approve tokens') ; 

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}
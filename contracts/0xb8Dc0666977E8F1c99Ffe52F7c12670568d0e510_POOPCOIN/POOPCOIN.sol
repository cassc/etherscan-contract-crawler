/**
 *Submitted for verification at Etherscan.io on 2023-05-18
*/

// SPDX-License-Identifier: Unlicensed 


/*

    POOPCOIN ($SHIT)
    
    https://twitter.com/PoopCoin_King
    https://t.me/PoopcoinETH
    https://discord.gg/b56edPFD

*/

pragma solidity 0.8.19;

interface IERC20 {
    

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

}

interface IUniswapV2Factory {

    function createPair(address tokenA, address tokenB) external returns (address pair);

}

interface IUniswapV2Router02 {

    function factory() external pure returns (address);
    function WETH() external pure returns (address);

}

contract POOPCOIN is Context, IERC20 { 

    address private _owner = 0x0b86be4417843Ff78fe73d876Ac021EF595fFb15; // Deploying wallet
    address private constant DEAD = 0x0000000000000000000000000000000000000000;
    address private constant BURN = 0x000000000000000000000000000000000000dEaD;

    // Token Info
    string private  constant _name = "POOPCOIN"; 
    string private  constant _symbol = "$SHIT"; 

    uint8 private constant _decimals = 9;
    uint256 private _tTotal = 420_690_000_000_000 * 10 ** _decimals;

    // Wallet limits (2%)
    uint256 private max_Hold = _tTotal / 50; 
    uint256 private max_Tran = _tTotal / 50; 

    // Launch Settings
    uint256 private launchTime;
    uint256 private earlyBuyTime;
    bool public tradeOpen;
    bool public launchMode;

    // Factory
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    // Contract mappings
    mapping (address => uint256) private _tOwned;                               // Tokens Owned
    mapping (address => mapping (address => uint256)) private _allowances;      // Allowance to spend another wallets tokens
    mapping (address => bool) public _isLimitExempt;                            // Wallets that are excluded from limits
    mapping (address => bool) public _isEarlyBuyer;                             // Early Buyers 
    mapping (address => bool) public _isBlackListed;                            // Blacklisted wallets


    // Events
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    // Restrict Function to Current Owner
    modifier onlyOwner() {
        require(owner() == _msgSender(), "O01"); // Caller must be the owner
        _;
    }


    constructor (uint256 _sniperTime) {

        // Set Router Address
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        // Create Initial Pair With Eth
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;

        // Wallets Excluded From Limits
        _isLimitExempt[DEAD] = true;
        _isLimitExempt[BURN] = true;
        _isLimitExempt[uniswapV2Pair] = true;
        _isLimitExempt[_owner] = true;

        // Set early buy timer 
        earlyBuyTime = _sniperTime;

        // Transfer ownership and total supply to owner
        _tOwned[_owner] = _tTotal;
        emit Transfer(address(0), _owner, _tTotal);
        emit OwnershipTransferred(address(0), _owner);

    }

    // Open Trade
    function OpenTrade() external onlyOwner {

        // Can Only Use Once!
        require(!tradeOpen);
        launchTime = block.timestamp;
        tradeOpen = true;
        launchMode = true;

    }

    // Blacklist Bots - Can only blacklist during launch mode (max 1 hour)
    function Blacklist_Bots(address Wallet, bool true_or_false) external onlyOwner {
        
        if (true_or_false) {

            require(launchMode, "E01"); // Blacklisting is no longer possible
            _isBlackListed[Wallet] = true;

        } else {

            _isBlackListed[Wallet] = false;

        }

    }

    // Deactivate Launch Mode
    function End_Launch_Mode() external onlyOwner {

        launchMode = false;

    }

    /* 

    ----------------------------
    CONTRACT OWNERSHIP FUNCTIONS
    ----------------------------

    */


    // Transfer to New Owner
    function Ownership_TRANSFER(address payable newOwner) public onlyOwner {
        require(newOwner != address(0), "E02"); // Enter a valid Wallet Address

        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;

    }

  
    // Renounce Ownership
    function Ownership_RENOUNCE() public virtual onlyOwner {

        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }


    /*

    ---------------
    WALLET SETTINGS
    ---------------

    */


    // Exclude From Transaction and Holding Limits
    function Wallet__ExemptFromLimits(

        address Wallet_Address,
        bool true_or_false

        ) external onlyOwner {  
        _isLimitExempt[Wallet_Address] = true_or_false;
    }


    /*

    -----------------------------
    ERC20 STANDARD AND COMPLIANCE
    -----------------------------

    */

    function owner() public view returns (address) {
        return _owner;
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account];
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "D01"); // ERC20: decreased allowance below zero
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "A01"); // ERC20: approve from the zero address
        require(spender != address(0), "A02"); // ERC20: approve to the zero address
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "T01"); // ERC20: transfer amount exceeds allowance
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return (_tTotal - (balanceOf(address(DEAD)) + balanceOf(address(BURN))));
    }

    // An open function anybody can use to burn tokens - the amount must include the 9 decimals
    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }

    function _burn(address burnFrom, uint256 amount) internal virtual {

        require(burnFrom != address(0), "B01"); // Can not burn from zero address
        require(balanceOf(burnFrom) >= amount, "B02"); // Sender does not have enough tokens!
        _tOwned[burnFrom] -= amount;
        _tTotal -= amount;

        emit Transfer(burnFrom, address(0), amount);
    }

 
    /*

    ---------------
    TOKEN TRANSFERS
    ---------------

    */

    function _transfer(
        address from,
        address to,
        uint256 amount
      ) private {

        require(balanceOf(from) >= amount, "E03"); // Sender does not have enough tokens!

        // Launch Mode
        if (launchMode) {

            if (!tradeOpen){
            require(from == owner() || to == owner(), "E04"); // Trade is not open - Only owner wallets can interact with tokens
            }

            // Auto End Launch Mode After One Hour
            if (block.timestamp > launchTime + (1 * 1 hours)){

                launchMode = false;
            
            } else {

                require(!_isEarlyBuyer[from], "E05"); // Early buyer can not sell during launch mode

                // Tag Early Buyers - People that buy early can not sell or move tokens during LaunchMode (Max EarlyBuy timee is 60 seconds)
                if (from == uniswapV2Pair && block.timestamp <= launchTime + earlyBuyTime) {

                    _isEarlyBuyer[to] = true;

                } 
            }
        }

        // Blacklisted Wallets Can Only Send Tokens to Owner
        if (to != owner()) {
                require(!_isBlackListed[to] && !_isBlackListed[from],"E06"); // Blacklisted wallets can not buy or sell (only send tokens to owner)
            }

        // Wallet Limit
        if (!_isLimitExempt[to]) {

            uint256 heldTokens = balanceOf(to);
            require((heldTokens + amount) <= max_Hold, "E07"); // Purchase would take balance of max permitted
            
        }

        // Transaction limit - To send over the transaction limit the sender AND the recipient must be limit exempt
        if (!_isLimitExempt[to] || !_isLimitExempt[from]){

            require(amount <= max_Tran, "E08"); // Over max transaction limit
            
        }

        // Compliance and Safety Checks
        require(from != address(0), "E09"); // Can not be from 0 address
        require(to != address(0), "E10"); // Can not be to 0 address
        require(amount > 0, "E11"); // Amount of tokens can not be 0

        // Transfer tokens 
        _tOwned[from] -= amount;
        _tOwned[to] += amount;
        emit Transfer(from, to, amount);

    }

}

// Custom contract created for POOPCOIN ($SHIT) by GEN https://tokensbygen.com TG: https://t.me/GenTokens_GEN
// Not open source - Can not be used or forked without permission.
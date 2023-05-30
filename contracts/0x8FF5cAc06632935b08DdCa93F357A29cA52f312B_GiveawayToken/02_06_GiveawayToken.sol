// SPDX-License-Identifier: MIT
// Creator: Chillieman (iHateScammers.eth)
// Twitter: @Chillieman1 && @_GiveawayToken_

pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Context.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";

contract GiveawayToken is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

	// 1% of Transfers will goto Giveaways and AirDrops.
	// 1% of Transfers will be held for Team Expenses
	uint8 constant private _feeForEachBucket = 1;
	uint8 constant private _totalFees = 2;
	
    // My Giveaway Wallet - iHateScammers.eth
    address constant private _chillieman = 0xE1b49c45F5079a02E603aFFF00C035c242aEeE16;

    //We have to allow Exchange Wallets (UniSwap Router / Pair) to hold more than 1% of the supply
	mapping (address => bool) private _isExcludedFromTokenLimit;
    bool private _isWalletLimitEnforced; // Do we limit the Max Value of wallets?
    bool private _isUniswapFunded;


    // Running Amount of how much Fees have been collected.
    uint256 private _teamStash;
    uint256 private _giveawayStash;

    // Airdrops Start at 4 and decrement everytime an Initial Airdrop is sent. Initial Airdrops only work if this is non-zero.
	uint8 private _airdropsLeft;

	string private constant _name = "GiveawayToken";
    string private constant _symbol = "GIVEAWAY";
    uint8 private constant _decimals = 18;
    uint256 private constant _totalSupply = 	42_000_000_000_000 ether; // 42 Trillion Tokens
    uint256 private constant _uniSwapSupply = 	33_600_000_000_000 ether; // 80%
    uint256 private constant _airdropSupply = 	 2_100_000_000_000 ether; // 5% for Each AirDrop
    uint256 private constant _maxWalletAmount =    420_000_000_000 ether; // Wallets cant hold more than 1%

    IUniswapV2Router02 private _uniswapV2Router;
    address private _uniswapV2Pair;

    // Emitted when an exchange is added or removed to the _isExcludedFromTokenLimit list.
	event ExchangeAdded(address exchangeAddress);
	event ExchangeRemoved(address exchangeAddress);
	
	modifier onlyChillie {
        require(_chillieman == _msgSender(), "Denied: caller is not Chillieman");
        _;
    }

    constructor() payable {
        _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address pairAddress = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // Approve the UniSwap Router so Initial LP can be created
        _approve(address(this), address(_uniswapV2Router), type(uint256).max);

        // Add the UniSwap Pair / Router to MaxAmount List - This will allow this exchange to hold more than 1%
        _isExcludedFromTokenLimit[0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D] = true;
        _isExcludedFromTokenLimit[pairAddress] = true;

        // THIS contract is allowed to hold more than 1%
        _isExcludedFromTokenLimit[address(this)] = true;

        // Set Starting Variables
        _teamStash = 0;
        _giveawayStash = 0;
        _airdropsLeft = 4; // 4 separate Airdrops.
        _isUniswapFunded = false;

        // At First, We limit Coins to 1% of the Total Supply 
        // - If this ever needs to allow Wallets to go wild, Switch this to False
        _isWalletLimitEnforced = true;

		// Give all the Tokens to THIS contract, not Chillieman.
		_balances[address(this)] = _totalSupply;
        emit Transfer(address(0), _chillieman, _totalSupply);
    }

    // Return Chilliemans GiveAway Wallet
	function chillieman() public pure returns (address) {
		return _chillieman;
	}

    // Return Uniswap Router Address
	function uniswapV2Router() public view returns (IUniswapV2Router02) {
		return _uniswapV2Router;
	}

    // Return Name of Token
    function name() public pure virtual override returns (string memory) {
        return _name;
    }

    // Return Symbol of Token
    function symbol() public pure virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public pure virtual override returns (uint8) {
        return _decimals;
    }

    // Return Total Supply
    function totalSupply() public pure virtual override returns (uint256) {
        return _totalSupply;
    }

    // Return Balance of specific wallet
    function balanceOf(address wallet) public view virtual override returns (uint256) {
        return _balances[wallet];
    }
    
    // Return the amount currently held for Team Expense
	function teamStash() public view returns (uint256) {
        return _teamStash;
    }
	
    // Return the amount currently held for Giveaways
	function giveawayStash() public view returns (uint256) {
        return _giveawayStash;
    }
	
    // How many of the initial Airdrops are left (0-4)
	function airdropsRemaining() public view returns (uint) {
        return _airdropsLeft;
    }

    // Check a wallet to see if it can own more than 1% of supply (Reserved for Exchanges)
    function isExcludedFromWalletLimit(address wallet) public view returns(bool) {
	    return _isExcludedFromTokenLimit[wallet];
    }

    // Returns True if Wallets currently are limited to 1% of supply
    function isWalletEnforcementEnabled() public view returns (bool) {
        return _isWalletLimitEnforced;
    }

    // Public Interface to perform a tranfer from your wallet
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    // Check Allowances - Does a Spender have the ability to Transfer Tokens in your name?
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    // Allow someone else (Such as UniSwap) to transfer tokens in your name
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    // Called from UniSwap to swap your tokens for ETH
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

    // Increase the amount that a Spender can send in your name
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    // Decrease the amount that a Spender can send in your name
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }
    
     //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    // Calculate 1% of a transaction (How much will be withheld for Giveaways & Team Expenses?
    function calculateBaseFee(uint256 amount) private pure returns (uint256) {
        return amount / 100;
    }

    // Set the amount that an extrenal wallet can transfer in your name.
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

    // Internal Method to descrease the ammount of Allowance
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

    // Internal Transfer Function - Takes Fees from any transfer that is not directly to or from this Contract
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(_balances[from] >= amount, "ERC20: transfer amount exceeds balance");
        
		uint256 tokensToTransfer;
	
        // Transfer coming from this Contract dont pay fee 
        // - Dont Take Fees On Giveaways / Airdrops / UniSwap Funding.
        if (to == address(this) || from == address(this)) {
            tokensToTransfer = amount;
        } else {
            tokensToTransfer = takeFeesAndEnforceWalletLimit(to, from, amount);
        }

		unchecked {
            _balances[from] -= tokensToTransfer;
            _balances[to] += tokensToTransfer;
        }
        
        emit Transfer(from, to, tokensToTransfer);
    }

    // Withhold 2% of every Transfer to be used for Giveaways and Team Expenses
	function takeFeesAndEnforceWalletLimit(address to, address from, uint256 amount) private returns (uint256) {
		uint256 baseFee = calculateBaseFee(amount);
		uint256 totalFees = baseFee * _totalFees; // 2% is withheld for Token Growth / Giveaways
        uint256 amountAfterFees = amount - totalFees;

        // If we are Enforming Wallet Limit, make sure the Receiving Wallet doesnt receive more than 1%!
        if(_isWalletLimitEnforced && !isExcludedFromWalletLimit(to)) {
            // Make sure that After fees, Wallets do NOT have more than 1% of supply
            require(_balances[to] + amountAfterFees <= _maxWalletAmount, "Wallet Cannot Receive this much! Over Limit.");
        }
		
		// Add Fees for Giveaways and Team.
		unchecked {
			_teamStash += baseFee;
			_giveawayStash += baseFee;
			_balances[address(this)] += totalFees;
            _balances[from] -= totalFees;
		}
		
		emit Transfer(from, address(this), totalFees);
		
		//After fees have been taken, return the amount of tokens left for the recipient
		return amountAfterFees;
    }

	// Function to Fund Uniswap
	function fundUniSwap() public onlyChillie {
		require(!_isUniswapFunded, "You already Supplied Funds to to UniSwap");
		
		// Enter Initial Supply to UniSwap.
		 _uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            _uniSwapSupply,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this), // Lock Liquidity Tokens HERE! This can never be retreived
            block.timestamp 
        );
		
		_isUniswapFunded = true;
    }

    // -- Chillieman Functions --

    // Turn off the MAX TOKEN Limit. If the 1% MAX WALLET severly Hinders token growth, consider disabling it.
    function disableWalletLimit() public onlyChillie {
		_isWalletLimitEnforced = false;
    }

    // Turn back on the MAX TOKEN Limit. 
    function reenableWalletLimit() public onlyChillie {
		_isWalletLimitEnforced = true;
    }

    // Add an Exchange so it can hold more than 1% of the Supply.
    function chillieAddExchange(address wallet) public onlyChillie {
		require(!_isExcludedFromTokenLimit[wallet], "Exchange is already Added");
        _isExcludedFromTokenLimit[wallet] = true;
		emit ExchangeAdded(wallet);
    }
    
    // Remove an Exchange so it can no longer hold more than 1% of the Supply.
    function chillieRemoveExchange(address wallet) external onlyChillie {
		require(_isExcludedFromTokenLimit[wallet], "This is not an Exchange");

		// Make sure the core accounts cannot be removed from this list!
		require(wallet != address(this), "Cant Remove This Contract!");
		require(wallet != address(_uniswapV2Router), "Cant Remove the Initial Router!");
		require(wallet != address(_uniswapV2Pair), "Cant Remove the Liquidity Pair!");

        _isExcludedFromTokenLimit[wallet] = false;
		emit ExchangeRemoved(wallet);
    }
	
	// Function to Distribute starting AirDrops
	function initialAirdrops(address[] calldata winners) public onlyChillie {
		require(_airdropsLeft > 0, "Initial Airdrops are gone, did you mean to use giveawayAirdrops?");
		uint256 leftOverTokens = performAirdrop(address(this), winners, _airdropSupply);
		_airdropsLeft -= 1;

        // ADD LeftOverTokens to the Giveaway Stash
        _giveawayStash += leftOverTokens;
    }
	
	// Distribute Generational Wealth
	function giveawayGenerationalWealth(address winner) public onlyChillie {
		require(_giveawayStash > 0, "No Giveaway Fees to give");
        _balances[address(this)] -= _giveawayStash;
        _balances[winner] += _giveawayStash;
        emit Transfer(address(this), winner, _giveawayStash);
		_giveawayStash = 0;
    }
	
	// Function to Distribute Giveaway AirDrops
	function giveawayAirdrops(address[] calldata winners) public onlyChillie {
		require(_giveawayStash > 0, "Nothing to Giveaway!");
		uint256 leftOverTokens = performAirdrop(address(this), winners, _giveawayStash);
        
        // Put Any LeftOverTokens in the Giveaway Stash
        _giveawayStash = leftOverTokens;
    }
	
	// Function to perform an AirDrop
	function performAirdrop(address thisContract, address[] calldata winners, uint256 amount) private returns(uint256) {
		uint256 amountBefore = _balances[thisContract];
		uint256 amountToGive = amount / winners.length;
		unchecked {
			for (uint16 i = 0; i < winners.length; i++) {
                address winner = winners[i];
                _balances[winner] += amountToGive;
                _balances[thisContract] -= amountToGive;
                emit Transfer(thisContract, winner, amountToGive);
			}
		}

		uint256 amountGiven = amountBefore - _balances[thisContract];
		
		// Return the remainder tokens after providing airdrop.
		return amount - amountGiven;
    }
	
    // Claim Fees withheld for Team Expenses.
	function chillieClaimTeamStash() public onlyChillie {
		require(_teamStash > 0, "No Team Fees to claim");
		_transfer(address(this), _chillieman, _teamStash);
		_teamStash = 0;
    }
}
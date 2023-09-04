// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/**
    MAGAI - Make America Great AI
    
    Website: https://magai.men
    Twitter: https://twitter.com/magai_2024
    Telegram: https://t.me/MAGAI_ETH
    Telegram Bot: @TheMagai_Bot

            
                  ███╗   ███╗ █████╗  ██████╗  █████╗ ██╗
                  ████╗ ████║██╔══██╗██╔════╝ ██╔══██╗██║
                  ██╔████╔██║███████║██║  ███╗███████║██║
                  ██║╚██╔╝██║██╔══██║██║   ██║██╔══██║██║
                  ██║ ╚═╝ ██║██║  ██║╚██████╔╝██║  ██║██║
                  ╚═╝     ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝

                             ~!?YYYY5GGBB5!!::                       
                     .~~PG#@@&&&&&##BGGP&&G@GB&GG:                   
                   ^5&@#@@&@@&#&@@@@@@@@G#&P@B#@@B&B7G^..            
                 .GBP&YB5?B##@@@@@@@@@@@@@@@&#&&&&5#BP&@@&@P?        
               .5@@BBGGBG#&@@&&&&&BBBGGBB#&&@@&BB&&&@@GP&PBP&P       
              .@@&P&@@@@&#BGG&&&&&@@@@@@@@&&@@@@@&##PGBP5&#@?&:      
              ?@@PG@@@@@@@@##PPY??~~!??5PG&&&@@@@@@@@@@@@7&@?&.      
             .&@&PG@@@&&!::..        ^^^^.    ^BB?#@@@@@&P@B&G       
             #&5BPP@@G   ~&@@@@@@@#^         !&@@@@@YG@@@5B@G.       
             ##PGGP@&.  B@&##&&@@@BBJ.!    ~&@@@@&&@@&@@@@&^         
            ^&#PGGG@B   GJ.  ..:~~##5YJ  .#@PYJ??! .55@@@@@.         
           .P@BPBPG@B   !Y!!P~:!!!5B@#P. !@5!.^..~P~  G@@@@^         
           .P@#5#PP@B   7Y!7&@Y5J&@JJ&^   7@@55J&@5.   &@@@#         
           .P@&&#@@@@B^  . .?77!77^~^ ~. ^#&P@&!7?~    &@@@G         
           .^#@7BJP@@@@B:   .::.:.^:^#&. ^@@^ ~::.     5@@@P.        
             !@?P:?&@@&&@G.  :^.   J@#^   .5@G^^^^~.   :@@@Y.        
              #JP!^#@G  .BG        !P@@PJG5 .B@P.       @@@.         
              &&.!^#@&!PY.      :7 . ..!7~:.  .:.       5J@.         
              &@.^ &@@@BY! ^^ .~^      ..     .:^~.     G7@:         
              &@J#?&@@@@. .YJJ?.  7JP&&@@@&&&&B!!.7!   .#Y#.         
              .P@GG@@@@@&!.?JJJ~:B@@&GB###GB@@@P.  5   PB            
                :G&PJ^P@@@&?.7YJ5P^~5##GGG##Y^^GY     .#B            
                  : :J .@@@Y..:::. :        .: .!5Y. .@@?            
                   ^B&@?G@@&?                 [email protected]@G.             
                 .5@B ~&&Y#@@&7 :#@@@B.      Y@#: Y@B:               
            ...YG@@@B   7&&5#@@#Y&@@@BY&&&GB@&^ ?@#Y7                
::^!!5PGBB&&@&5B@@@@@&     ?&#P&@@#@@&J#@@@@&^ !@&~ .&&~              
@@@@@@@@@@@@BP&@@@@@@@       J&GB&&@@@@@@@&B^!&@7   .5@@#:.^          
@@@@@@@@@@BY&@@@@@@@@@.        5@@@@@@@@BY&@@@?     :P@@@@GP&@#PP?7~^^
@@@@@@@@B5&@@@@@@@@@@@5         .P@@@@&&&@@@J       &@@@@@@@GP@@@@@@@@
@@@@@@@#7@@@@@@@@@@@@@&~          .G@@@@@@Y        ^&@@@@@@@@&GG@@@@@@
@@@@@@@@&PB@@@@@@@@@@@G.!^          :G##P.       :!~5@@@@@@@@@@&7&@@@@
@@@@@@@@@@#J#@@@@@@@@@G  :J:        7~::!~      J~ ^@@@@@@@@@@@YG@@@@@


======================================================================
    The line of 'Make America great again,' the phrase, that was 
	mine, I came up with it about a year ago, and I kept using it, 
	and everybody's using it, they are all loving it. 
    
    I don't know, I guess I should copyright it, maybe I have 
	copyrighted it.

                                                      - DONALD TRUMP
======================================================================

**/

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IUniswapV2Factory {
	event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

	function feeTo() external view returns (address);

	function feeToSetter() external view returns (address);

	function getPair(address tokenA, address tokenB) external view returns (address pair);

	function allPairs(uint256) external view returns (address pair);

	function allPairsLength() external view returns (uint256);

	function createPair(address tokenA, address tokenB) external returns (address pair);

	function setFeeTo(address) external;

	function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
	event Approval(address indexed owner, address indexed spender, uint256 value);
	event Transfer(address indexed from, address indexed to, uint256 value);

	function name() external pure returns (string memory);

	function symbol() external pure returns (string memory);

	function decimals() external pure returns (uint8);

	function totalSupply() external view returns (uint256);

	function balanceOf(address owner) external view returns (uint256);

	function allowance(address owner, address spender) external view returns (uint256);

	function approve(address spender, uint256 value) external returns (bool);

	function transfer(address to, uint256 value) external returns (bool);

	function transferFrom(address from, address to, uint256 value) external returns (bool);

	function DOMAIN_SEPARATOR() external view returns (bytes32);

	function PERMIT_TYPEHASH() external pure returns (bytes32);

	function nonces(address owner) external view returns (uint256);

	function permit(
		address owner,
		address spender,
		uint256 value,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external;

	event Mint(address indexed sender, uint256 amount0, uint256 amount1);
	event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
	event Swap(
		address indexed sender,
		uint256 amount0In,
		uint256 amount1In,
		uint256 amount0Out,
		uint256 amount1Out,
		address indexed to
	);
	event Sync(uint112 reserve0, uint112 reserve1);

	function MINIMUM_LIQUIDITY() external pure returns (uint256);

	function factory() external view returns (address);

	function token0() external view returns (address);

	function token1() external view returns (address);

	function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

	function price0CumulativeLast() external view returns (uint256);

	function price1CumulativeLast() external view returns (uint256);

	function kLast() external view returns (uint256);

	function mint(address to) external returns (uint256 liquidity);

	function burn(address to) external returns (uint256 amount0, uint256 amount1);

	function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;

	function skim(address to) external;

	function sync() external;

	function initialize(address, address) external;
}

interface IUniswapV2Router02 {
	function factory() external pure returns (address);

	function WETH() external pure returns (address);

	function addLiquidity(
		address tokenA,
		address tokenB,
		uint256 amountADesired,
		uint256 amountBDesired,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline
	) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

	function addLiquidityETH(
		address token,
		uint256 amountTokenDesired,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline
	) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

	function swapExactTokensForTokensSupportingFeeOnTransferTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external;

	function swapExactETHForTokensSupportingFeeOnTransferTokens(
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external payable;

	function swapExactTokensForETHSupportingFeeOnTransferTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external;
}

contract MagaiCoin is ERC20, Ownable {
	using SafeMath for uint256;

	IUniswapV2Router02 public immutable uniswapV2Router;
	address public immutable uniswapV2Pair;
	address public constant deadAddress = address(0xdead);

	bool private swapping;

	address public teamWallet;
	address public immutable wojak;

	uint256 public maxTransactionAmount;
	uint256 public swapTokensAtAmount;
	uint256 public maxWallet;
	uint256 public immutable onePercent;

	bool public limitsInEffect = true;
	bool public tradingActive = false;
	bool public swapEnabled = false;

	bool public blacklistRenounced = false;

	// Anti-bot and anti-whale mappings and variables
	mapping(address => bool) blacklisted;

	uint256 public buyTotalFees;

	uint256 public sellTotalFees;

	/******************/

	// exclude from fees and max transaction amount
	mapping(address => bool) private _isExcludedFromFees;
	mapping(address => bool) public _isExcludedMaxTransactionAmount;

	// store addresses that a automatic market maker pairs. Any transfer *to* these addresses
	// could be subject to a maximum transfer amount
	mapping(address => bool) public automatedMarketMakerPairs;

	event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);

	event ExcludeFromFees(address indexed account, bool isExcluded);

	event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

	event TeamWalletUpdated(address indexed newWallet, address indexed oldWallet);

	event TradingEnabled(uint ethAmount, uint tokenAmt, uint block);

	/**
	 * @dev only wojak can do these special commands once the magai renounces ownership.
	 */
	modifier onlyWojak() {
		_checkWojak();
		_;
	}

	function _checkWojak() internal view virtual {
		require(wojak == _msgSender(), "Wojak: caller is a gigachad!");
	}

	constructor(address _teamWallet, address _marketingWallet) ERC20("The MagaiCoin", "MAGAI") {
		IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

		excludeFromMaxTransaction(address(_uniswapV2Router), true);
		uniswapV2Router = _uniswapV2Router;

		uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
			address(this),
			_uniswapV2Router.WETH()
		);
		excludeFromMaxTransaction(address(uniswapV2Pair), true);
		_setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

		// wojak is our deployer
		wojak = owner();
		teamWallet = address(_teamWallet);

        /*
        TOKEN: 
        OFFICIAL TICKER: MAGAI
        TOTAL SUPPLY: 696,969,696,969,696
        DISTRIBUTION: 90% sent to Uniswap, 4% for marketing / team, 6% set aside for CEX
        TAXATION:  2%/4% to be used for marketing, development & AI Service API request fees
        MAX WALLET: 2% 
        MAX TRANSACTION: 2%
        */
		uint256 totalSupply = 696_969_696_969_696 * 1e18;
		onePercent = totalSupply / 100; // 1%

		maxTransactionAmount = (totalSupply * 2) / 100; // 2%
		maxWallet = (totalSupply * 2) / 100; // 2%
		swapTokensAtAmount = (totalSupply * 5) / 10000; // 0.05%

		buyTotalFees = 2; // 2%
		sellTotalFees = 35; // 35% to start.

		// exclude from paying fees or having max transaction amount
		excludeFromFees(owner(), true);
		excludeFromFees(address(this), true);
		excludeFromFees(teamWallet, true);
		excludeFromFees(_marketingWallet, true);
		excludeFromFees(address(0xdead), true);

		excludeFromMaxTransaction(owner(), true);
		excludeFromMaxTransaction(address(this), true);
		excludeFromMaxTransaction(teamWallet, true);
		excludeFromMaxTransaction(_marketingWallet, true);
		excludeFromMaxTransaction(address(0xdead), true);

		// mint 100% here
		_mint(address(this), totalSupply);

		// transfer % to newOwner
		_transfer(address(this), wojak, (totalSupply * 6) / 100);
		_transfer(address(this), _marketingWallet, (totalSupply * 4) / 100);
	}

	receive() external payable {}

	// once enabled, can never be turned off
	function enableTrading() external payable onlyOwner {
		require(!tradingActive, "Trading is already enabled, cannot relaunch.");
		uint256 liquidityTokens = balanceOf(address(this)); // 100% of the balance assigned to this contract
		require(msg.value > 0, "Send liquidity eth");
		require(liquidityTokens > 0, "No tokens!");
		// setup the approvals
		IERC20Metadata weth = IERC20Metadata(uniswapV2Router.WETH());
		weth.approve(address(uniswapV2Router), type(uint256).max);
		_approve(address(this), address(uniswapV2Router), type(uint256).max);
		// add the liquidity
		uniswapV2Router.addLiquidityETH{value: msg.value}(
			address(this),
			liquidityTokens,
			0,
			0,
			owner(),
			block.timestamp
		);
		// set the params and emit
		tradingActive = true;
		swapEnabled = true;
		emit TradingEnabled(msg.value, liquidityTokens, block.timestamp);
	}

	// remove limits after token is stable
	function removeLimits() external onlyOwner {
		limitsInEffect = false;
	}

	// change the minimum amount of tokens to sell from fees
	function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner {
		require(newAmount >= (totalSupply() * 1) / 100000, "Swap amount cannot be lower than 0.001% total supply.");
		require(newAmount <= (totalSupply() * 5) / 1000, "Swap amount cannot be higher than 0.5% total supply.");
		swapTokensAtAmount = newAmount;
	}

	function updateMaxTxnAmount(uint256 newNum) external onlyOwner {
		require(newNum >= ((totalSupply() * 5) / 1000) / 1e18, "Cannot set maxTransactionAmount lower than 0.5%");
		maxTransactionAmount = newNum * 1e18;
	}

	function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
		require(newNum >= ((totalSupply() * 10) / 1000) / 1e18, "Cannot set maxWallet lower than 1.0%");
		maxWallet = newNum * 1e18;
	}

	function excludeFromMaxTransaction(address updAds, bool isEx) public onlyOwner {
		_isExcludedMaxTransactionAmount[updAds] = isEx;
	}

	// only use to disable contract sales if absolutely necessary (emergency use only)
	function updateSwapEnabled(bool enabled) external onlyOwner {
		swapEnabled = enabled;
	}

	function updateBuyFees(uint256 _newBuyfee) external onlyOwner {
		require(buyTotalFees <= 5, "Buy fees must be <= 5.");
		buyTotalFees = _newBuyfee;
	}

	function updateSellFees(uint256 _newSellFee) external onlyOwner {
		require(sellTotalFees <= 15, "Sell fees must be <= 15.");
		sellTotalFees = _newSellFee;
	}

	function excludeFromFees(address account, bool excluded) public onlyOwner {
		_isExcludedFromFees[account] = excluded;
		emit ExcludeFromFees(account, excluded);
	}

	function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
		require(pair != uniswapV2Pair, "The pair cannot be removed from automatedMarketMakerPairs");
		_setAutomatedMarketMakerPair(pair, value);
	}

	function _setAutomatedMarketMakerPair(address pair, bool value) private {
		automatedMarketMakerPairs[pair] = value;
		emit SetAutomatedMarketMakerPair(pair, value);
	}

	function isExcludedFromFees(address account) public view returns (bool) {
		return _isExcludedFromFees[account];
	}

	function isBlacklisted(address account) public view returns (bool) {
		return blacklisted[account];
	}

	function _transfer(address from, address to, uint256 amount) internal override {
		require(from != address(0), "ERC20: transfer from the zero address");
		require(to != address(0), "ERC20: transfer to the zero address");
		require(!blacklisted[from], "Sender blacklisted");
		require(!blacklisted[to], "Receiver blacklisted");

		if (amount == 0) {
			super._transfer(from, to, 0);
			return;
		}

		if (limitsInEffect) {
			if (from != owner() && to != owner() && to != address(0) && to != address(0xdead) && !swapping) {
				if (!tradingActive) {
					require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading is not active.");
				}

				//when buy
				if (automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmount[to]) {
					require(amount <= maxTransactionAmount, "Buy transfer amount exceeds the maxTransactionAmount.");
					require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
				}
				//when sell
				else if (automatedMarketMakerPairs[to] && !_isExcludedMaxTransactionAmount[from]) {
					require(amount <= maxTransactionAmount, "Sell transfer amount exceeds the maxTransactionAmount.");
				} else if (!_isExcludedMaxTransactionAmount[to]) {
					require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
				}
			}
		}

		uint256 contractTokenBalance = balanceOf(address(this));

		bool canSwap = contractTokenBalance >= swapTokensAtAmount;

		if (
			canSwap &&
			swapEnabled &&
			!swapping &&
			!automatedMarketMakerPairs[from] &&
			!_isExcludedFromFees[from] &&
			!_isExcludedFromFees[to]
		) {
			swapping = true;
			swapBack();
			swapping = false;
		}

		bool takeFee = !swapping;

		// if any account belongs to _isExcludedFromFee account then remove the fee
		if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
			takeFee = false;
		}

		// only take fees on buys/sells, do not take on wallet transfers
		if (takeFee) {
			uint256 fees = 0;
			// on sell
			if (automatedMarketMakerPairs[to] && sellTotalFees > 0) {
				fees = amount.mul(sellTotalFees).div(100);
			}
			// on buy
			else if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {
				fees = amount.mul(buyTotalFees).div(100);
			}

			if (fees > 0) {
				super._transfer(from, address(this), fees);
			}

			amount -= fees;
		}

		super._transfer(from, to, amount);
	}

	function swapTokensForEth(uint256 tokenAmount) private {
		// generate the uniswap pair path of token -> weth
		address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = uniswapV2Router.WETH();

		_approve(address(this), address(uniswapV2Router), tokenAmount);

		// make the swap
		uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
			tokenAmount,
			0, // accept any amount of ETH
			path,
			address(this),
			block.timestamp
		);
	}

	function swapBack() private {
		uint256 contractBalance = balanceOf(address(this));
		bool success;

		if (contractBalance == 0) {
			return;
		}

		if (contractBalance > swapTokensAtAmount * 20) {
			contractBalance = swapTokensAtAmount * 20;
		}

		uint256 initialETHBalance = address(this).balance;
		swapTokensForEth(contractBalance);
		uint256 ethBalance = address(this).balance.sub(initialETHBalance);

		(success, ) = address(teamWallet).call{value: ethBalance}("");
	}

	// @dev team renounce blacklist commands
	function renounceBlacklist() public onlyOwner {
		blacklistRenounced = true;
	}

	function blacklist(address _addr) public onlyOwner {
		require(!blacklistRenounced, "Team has revoked blacklist rights");
		require(
			_addr != address(uniswapV2Pair) && _addr != address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D),
			"Cannot blacklist token's v2 router or v2 pool."
		);
		blacklisted[_addr] = true;
	}

	// @dev blacklist v3 pools; can unblacklist() down the road to suit project and community
	function blacklistLiquidityPool(address lpAddress) public onlyOwner {
		require(!blacklistRenounced, "Team has revoked blacklist rights");
		require(
			lpAddress != address(uniswapV2Pair) && lpAddress != address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D),
			"Cannot blacklist token's v2 router or v2 pool."
		);
		blacklisted[lpAddress] = true;
	}

	// @dev unblacklist address; not affected by blacklistRenounced incase team wants to unblacklist v3 pools down the road
	function unblacklist(address _addr) public onlyOwner {
		blacklisted[_addr] = false;
	}

	// @dev - Wojak only commands.

	function updateTeamWallet(address newWallet) external onlyWojak {
		require(newWallet != address(0), "Cannot be the zero address");
		teamWallet = newWallet;
		emit TeamWalletUpdated(newWallet, teamWallet);
	}

	function withdrawStuckToken() external onlyWojak {
		uint256 balance = IERC20(address(this)).balanceOf(address(this));
		IERC20(address(this)).transfer(msg.sender, balance);
		payable(msg.sender).transfer(address(this).balance);
	}

	function withdrawStuckToken(address _token, address _to) external onlyWojak {
		require(_token != address(0), "_token address cannot be 0");
		uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
		IERC20(_token).transfer(_to, _contractBalance);
	}

	function withdrawStuckEth(address toAddr) external onlyWojak {
		(bool success, ) = toAddr.call{value: address(this).balance}("");
		require(success);
	}
}
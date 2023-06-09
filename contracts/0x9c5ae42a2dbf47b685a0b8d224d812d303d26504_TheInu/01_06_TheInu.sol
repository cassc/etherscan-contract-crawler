// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);    
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract TheInu is ERC20, Ownable {
	uint256 private _totalSupply = 5 * 10**13 * 10**18;		// Total Supply: 50T

	bool    public enabledTrade = false;
    uint256 private startedTradeAt;
    uint256 private whitelistTime = 1800;                   // whitelist time 30mins
    mapping (address => bool) private whitelist;            // white list allowed to buy at private sale.

    uint256 public buyTax = 1;                             // 1%
	uint256 public sellTax = 1;                            // 1%

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    mapping (address => bool) public automatedMarketMakerPairs;

    bool    public inSwapAndLiquify;
    uint256 public swapAndLiquidityTokenAmount = 10**9 * 10**18;    // Swap and add liquidity when balance is more than 1B

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

	constructor() ERC20("The Inu", "INU") {
		IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        _mint(msg.sender, _totalSupply);

        _setWhiteList();
    }

    function _setWhiteList() internal {
        whitelist[0x00379f5F914Dc338A2179959D9b56527C3F7C991] = true;
        whitelist[0x214E7bD9D19214a4fFc14448E32B38c64245163a] = true;
        whitelist[0x139f1B806dBA1bbE5D84Ca2B3B387D245A38f224] = true;
        whitelist[0xF6467cA413d0175332D541A1EC6e5D8aC256c574] = true;
        whitelist[0x33665Df5071ceE5351D42b9aBC9b8399Eca5fc42] = true;
        whitelist[0xEDFbA16c7395B96aE644785623641C2a09C1e34d] = true;
        whitelist[0xB17457E275F9ECdf2f34aF4F94a09770A3749775] = true;
        whitelist[0xA1FfE96e4271D6886b5641D970bd13163e017595] = true;
        whitelist[0x52FB5B655A78F475857F2b8386d7fdFFFbf4d30b] = true;
        whitelist[0x1fc252173B43f58d27Ef9C793b448DAe2936747e] = true;
        whitelist[0x0C4DD44b5349949244F73B9719EDF63d25a23ef2] = true;
        whitelist[0x12D54677d397Bd738635004E68DD18BD203fc9ac] = true;
        whitelist[0x65390B8473D323E00A97a95AE762A214d4bf2681] = true;
        whitelist[0x680EE013cD8299Aaf0022913C17b7b8085CAe73d] = true;
        whitelist[0x6A5eB4E10A6cc44c6159CC505C1b7FF38D9e1c28] = true;
        whitelist[0x064B7e330C628958F685122f34d10dDE6f2225Dd] = true;
        whitelist[0xb6CD3CdCA44391C5c5402EcbF7110F6F4c3B5563] = true;
        whitelist[0xD5B1A978Cf1b7EA011785897DF777e7AEF6CF6b2] = true;
        whitelist[0x21145c55595EdeE2fFa8cF3c7c5937EB28286E06] = true;
        whitelist[0x9539354a2238d441Aba52C570bFAE7E0EEA6cCb9] = true;
    }

    receive() external payable {}

    function enableSale() external onlyOwner() {
        enabledTrade = true;
        startedTradeAt = block.timestamp;
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "The uniswap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves
        uint256 half = contractTokenBalance / 2;
        uint256 otherHalf = contractTokenBalance - half;

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance - initialBalance;

        // add liquidity to pancakeswap
        addLiquidity(otherHalf, newBalance);
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the pancakeswap pair path of token -> weth
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

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function setSwapAndLiquidityTokenAmount(uint256 amount) external onlyOwner {
        swapAndLiquidityTokenAmount = amount;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if(from != owner() && to != owner()) { // owner transaction
            require(enabledTrade, "No allowed trade");

            if (automatedMarketMakerPairs[from] && block.timestamp < (startedTradeAt + whitelistTime)) {
                require(whitelist[to], "No whitelist address");
            }
        }

        // Swap and add liquidity
        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapAndLiquidityTokenAmount;
        if (
            canSwap &&
            !inSwapAndLiquify &&
            to == uniswapV2Pair
        ) {
            // add liquidity
            swapAndLiquify(swapAndLiquidityTokenAmount);
        }

        bool takeFee = false;
        uint256 fee = 0;

        // Check antibottime
        if (automatedMarketMakerPairs[from]) { // buy transaction
            takeFee = true;
            fee = buyTax;
        } else if (automatedMarketMakerPairs[to]) { // sell transaction
            takeFee = true;
            fee = sellTax;
        }

        if(from == owner() || to == owner()) { // owner transaction
            takeFee = false;
        }

        if (takeFee && fee > 0) {
            uint256 feeAmount = amount * fee / 100;
            amount = amount - feeAmount;

            super._transfer(from, address(this), feeAmount);
        }

        super._transfer(from, to, amount);
    }
}
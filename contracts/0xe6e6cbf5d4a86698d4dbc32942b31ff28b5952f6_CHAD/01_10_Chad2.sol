/**

    THIS CONTRACT IS PROVIDED ON AN “AS IS” BASIS. USE THIS SOFTWARE AT YOUR OWN RISK.
    THERE IS NO WARRANTY, EXPRESSED OR IMPLIED, THAT DESCRIBED FUNCTIONALITY WILL 
    FUNCTION AS EXPECTED OR INTENDED. PRODUCT MAY CEASE TO EXIST. NOT AN INVESTMENT, 
    SECURITY OR A SWAP. TOKENS HAVE NO RIGHTS, USES, PURPOSE, ATTRIBUTES, 
    FUNCTIONALITIES OR FEATURES, EXPRESS OR IMPLIED, INCLUDING, WITHOUT LIMITATION, ANY
    USES, PURPOSE OR ATTRIBUTES. TOKENS MAY HAVE NO VALUE. PRODUCT MAY CONTAIN BUGS AND
    SERIOUS BREACHES IN THE SECURITY THAT MAY RESULT IN LOSS OF YOUR ASSETS OR THEIR 
    IMPLIED VALUE. ALL THE CRYPTOCURRENCY TRANSFERRED TO THIS SMART CONTRACT MAY BE LOST.
    THE CONTRACT DEVLOPERS ARE NOT RESPONSIBLE FOR ANY MONETARY LOSS, PROFIT LOSS OR ANY
    OTHER LOSSES DUE TO USE OF DESCRIBED PRODUCT. CHANGES COULD BE MADE BEFORE AND AFTER
    THE RELEASE OF THE PRODUCT. NO PRIOR NOTICE MAY BE GIVEN. ALL TRANSACTION ON THE 
    BLOCKCHAIN ARE FINAL, NO REFUND, COMPENSATION OR REIMBURSEMENT POSSIBLE. YOU MAY 
    LOOSE ALL THE CRYPTOCURRENCY USED TO INTERACT WITH THIS CONTRACT. IT IS YOUR 
    RESPONSIBILITY TO REVIEW THE PROJECT, TEAM, TERMS & CONDITIONS BEFORE USING THE 
    PRODUCT.

**/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../lib/IUniswapV2Pair.sol";
import "../lib/IUniswapV2Factory.sol";
import "../lib/IUniswapV2Router.sol";

contract CHAD is ERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    uint256 public _totalSupply = 1e12 * 1e18; // 1T tokens
    uint256 public swapTokensAtAmount = 1e9 * 1e18; // 1B = Threshold for swap (0.1%)

    address public taxAddr;
    uint256 public sellTax = 20;
    uint256 public buyTax = 0;

    bool public _hasLiqBeenAdded = false;
    uint256 public launchedAt = 0;
    uint256 public swapAndLiquifycount = 0;
    uint256 public snipersCaught = 0;

    mapping(address => bool) private whitelisted;
    mapping(address => bool) public blacklisted;
    bool private swapping;
    mapping(address => bool) public automatedMarketMakerPairs;

    receive() external payable {}

    constructor(
        address _uniswapAddress
    ) ERC20("CHADGPT", "CHAD") {
        // Set Uniswap Address
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            address(_uniswapAddress)
        );

        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);
        whitelist(address(this), true);
        whitelist(owner(), true);
        taxAddr = owner();
        super._mint(owner(), _totalSupply);
    }

    /**
     * ADMIN SETTINGS
     */

    function updateMarketingVariables(
        uint256 _sellTax,
        uint256 _buyTax
    ) public onlyOwner {
        sellTax = _sellTax;
        buyTax = _buyTax;
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(
            newAddress != address(uniswapV2Router),
            "CHAD: The router already has that address"
        );
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }
    
    function manualSwapandLiquify(uint256 _balance) external onlyOwner {
        swapAndSendDividends(_balance);
    }

    function setAutomatedMarketMakerPair(
        address pair,
        bool value
    ) public onlyOwner {
        require(
            pair != uniswapV2Pair,
            "CHAD: The Uniswap pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
    }

    /**
     * Private functions
     */

    function swapAndSendDividends(uint256 tokens) private {
        swapTokensForEth(tokens);
        uint256 dividends = address(this).balance;
        (bool success, ) = address(taxAddr).call{value: address(this).balance}(
            ""
        );
    }

    // Main override transfer function
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!blacklisted[from], "CHAD: Blocked Transfer");
        require(amount > 0, "CHAD: 0 transfers not acceptable");

        // Sniper Protection
        if (!_hasLiqBeenAdded) {
            // If no liquidity yet, allow owner to add liquidity
            _checkLiquidityAdd(from, to);
        } else {
            // if liquidity has already been added.
            if (
                launchedAt > 0 &&
                from == uniswapV2Pair &&
                owner() != from &&
                owner() != to
            ) {
                if (block.number - launchedAt < 10) {
                    _blacklist(to, true);
                    snipersCaught++;
                }
            }
        }


        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;
        if (
            canSwap &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            from != taxAddr &&
            to != taxAddr
        ) {
            swapping = true;
            swapAndSendDividends(swapTokensAtAmount);
            swapping = false;
        }
        bool takeFee = !swapping;
        // if any account is whitelisted account then remove the fee

        if (whitelisted[from] || whitelisted[to]) {
            takeFee = false;
        }

        if (takeFee) {
            uint256 fees = 0;
            if (automatedMarketMakerPairs[from]) {
                fees = fees.add(amount.mul(buyTax).div(100));
            } else {
                fees = fees.add(amount.mul(sellTax).div(100));
            }
            amount = amount.sub(fees);
            super._transfer(from, address(this), fees);
        }
        super._transfer(from, to, amount);
    }

    function _checkLiquidityAdd(address from, address to) private {
        // if liquidity is added by the _liquidityholders set
        // trading enables to true and start the anti sniper timer
        require(!_hasLiqBeenAdded, "Liquidity already added and marked.");
        // require liquidity has been added == false (not added).
        // This is basically only called when owner is adding liquidity.

        if (from == owner() && to == uniswapV2Pair) {
            _hasLiqBeenAdded = true;
            launchedAt = block.number;
        }
    }

    function whitelist(address account, bool isWhitelisted) public onlyOwner {
        whitelisted[account] = isWhitelisted;
        (account, isWhitelisted);
    }

    function blacklist(address account, bool isBlacklisted) public onlyOwner {
        _blacklist(account, isBlacklisted);
    }


    /**********/
    /* PRIVATE FUNCTIONS */
    /**********/

    function _blacklist(address account, bool isBlacklisted) private {
        blacklisted[account] = isBlacklisted;
        (account, isBlacklisted);
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

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(
            automatedMarketMakerPairs[pair] != value,
            "CHAD: Automated market maker pair is already set to that value"
        );
        automatedMarketMakerPairs[pair] = value;
    }
}
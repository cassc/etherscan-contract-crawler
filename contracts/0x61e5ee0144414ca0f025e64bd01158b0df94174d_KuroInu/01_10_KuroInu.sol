/**

https://t.me/KuroShibaInuEth
https://kuro.is

/*
 * Disclaimer: Use of This Solidity Contract At Your Own Risk
 *
 * By utilizing this Solidity contract ("Contract"), you acknowledge and agree that your use of the Contract
 * is entirely at your own risk. This Contract is provided "as is" and without any representations, warranties,
 * or guarantees of any kind, whether express or implied.
 *
 * 1. Not a Security: The Contract is not intended to represent or be classified as a security under any jurisdiction's
 * laws or regulations. It is solely a technological implementation and does not entitle the holder to any ownership,
 * dividends, or other financial rights.
 *
 * 2. No Liability: The developers, contributors, or any associated parties involved in creating and deploying this
 * Contract shall not be held liable for any damages, losses, or liabilities resulting from its use. This includes,
 * but is not limited to, financial losses, loss of data, security breaches, hacks, or any other form of harm that might
 * arise from the use or misuse of the Contract.
 *
 * 3. No Warranty: There are no warranties or guarantees concerning the accuracy, reliability, functionality, or
 * suitability of the Contract for any particular purpose. Users should conduct their own due diligence and assessments
 * before interacting with the Contract.
 *
 * 4. Third-Party Risks: The Contract may interact with other smart contracts or third-party protocols, and users are
 * solely responsible for understanding and accepting the risks associated with these interactions.
 *
 * 5. No Legal or Financial Advice: The Contract does not provide legal, financial, or investment advice. Users should
 * seek independent advice from qualified professionals before making any decisions related to the Contract.
 *
 * 6. Not Responsible for Transactions: Users are solely responsible for the correctness and accuracy of their
 * interactions with the Contract. Transactions made using the Contract are irreversible and binding.
 *
 * By using the Contract, you agree to waive any claims, actions, or legal proceedings against the developers,
 * contributors, or any associated parties. This disclaimer is subject to change without prior notice, and users are
 * encouraged to review it regularly for updates.
 *
 * If you do not agree to the terms of this disclaimer, refrain from using the Contract.
 *
 * Please proceed with caution and make informed decisions when interacting with the Contract.
 *
 */

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../lib/IUniswapV2Pair.sol";
import "../lib/IUniswapV2Factory.sol";
import "../lib/IUniswapV2Router.sol";

contract KuroInu is ERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    uint256 public _totalSupply = 1e12 * 1e18; // 1T tokens
    uint256 public swapTokensAtAmount = 1e9 * 1e18; // 1B = Threshold for swap (0.1%)

    address public taxAddr;
    uint256 public sellTax = 10;
    uint256 public buyTax = 10;

    bool public _hasLiqBeenAdded = false;
    uint256 public launchedAt = 0;
    uint256 public swapAndLiquifycount = 0;
    uint256 public snipersCaught = 0;

    mapping(address => bool) private whitelisted;
    mapping(address => bool) public blacklisted;
    bool private swapping;
    mapping(address => bool) public automatedMarketMakerPairs;

    event CaughtSniper(address sniper);

    receive() external payable {}

    constructor(
        address _uniswapAddress,
        address[] memory lps
    ) ERC20("Kuro Inu", "KURO") {
        // Set Uniswap Address
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            address(_uniswapAddress)
        );

        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        // Whitelist LP provider address(s)
        for (uint i = 0; i < lps.length; i++) {
            whitelisted[lps[i]] = true;
        }
        whitelisted[address(this)] = true;
        whitelisted[owner()] = true;

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
            "KuroInu: The router already has that address"
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
            "KuroInu: The Uniswap pair cannot be removed from automatedMarketMakerPairs"
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
        require(amount > 0, "KuroInu: 0 transfers not acceptable");
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
                    emit CaughtSniper(to);
                    snipersCaught++;
                }
            }
        }
        if (!whitelisted[from] && !whitelisted[to]) {
            require(!blacklisted[from], "KuroInu: Blocked Transfer");

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

    /**********/
    /* PRIVATE FUNCTIONS */
    /**********/

    // this is only called by the sniper protection.
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
            "KuroInu: Automated market maker pair is already set to that value"
        );
        automatedMarketMakerPairs[pair] = value;
    }
}
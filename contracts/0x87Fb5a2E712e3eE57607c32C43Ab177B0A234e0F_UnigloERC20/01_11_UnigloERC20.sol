// SPDX-License-Identifier: Unlicensed.
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Router02.sol";

import "hardhat/console.sol";

contract UnigloERC20 is ERC20, Ownable, ReentrancyGuard {

    uint256 public constant PERCENTAGE_FACTOR = 10000; // Equals 100%, granularity up to 0.01% changes.
    address public constant UNISWAP_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // Same address on: mainnet - rinkeby - kovan - ropsten - goerli

    uint256 public burnRate;
    uint256 public marketingRate;
    uint256 public treasuryRate;
    uint256 public liquidityRate;
    uint256 public totalRate;

    uint256 public marketingGloBalance;
    uint256 public treasuryGloBalance;
    uint256 public liquidityBalance;

    uint256 public glo_share; 

    address public immutable GLO_ETH_PAIR;

    address public marketing;
    address public treasury;

    bool public accountsSet;
    bool public feeRatesSet;
    bool public gloShareSet;

    mapping(address => bool) public excludedFromFee;

    event SwapAndLiquify(uint256 half, uint256 newETHBalance, uint256 anotherHalf);

    constructor(address _recipient) ERC20("Uniglo Token", "GLO") {
        require(_recipient != address(0), "Error: Cannot be the null address");

        IUniswapV2Router02 uniswap_router = IUniswapV2Router02(UNISWAP_ROUTER);
        GLO_ETH_PAIR = IUniswapV2Factory(uniswap_router.factory()).createPair(address(this), uniswap_router.WETH());

        excludedFromFee[_recipient] = true;
        excludedFromFee[address(this)] = true;

        _mint(_recipient, 218750000 * 1e18);

        _approve(address(this), UNISWAP_ROUTER, ~uint256(0));
    }

    function setAccounts(address _marketing, address _treasury) external onlyOwner {
        require(_marketing != address(0), "Error: Cannot be the null address");
        require(_treasury != address(0), "Error: Cannot be the null address");

        marketing = _marketing;
        treasury = _treasury;

        if(!accountsSet) {
            accountsSet = true;
        }
    }

    function setFeeRates(uint256 _burnRate, uint256 _marketingRate, uint256 _treasuryRate, uint256 _liquidityRate) external onlyOwner {
        uint256 _totalRate = _burnRate + _marketingRate + _treasuryRate + _liquidityRate;

        require(_totalRate <= 1500, "Error: Total rate exceeds 15%");

        burnRate = _burnRate;
        marketingRate = _marketingRate;
        treasuryRate = _treasuryRate;
        liquidityRate = _liquidityRate;
        totalRate = _totalRate;

        if (!feeRatesSet) {
            feeRatesSet = true;
        }
    }

    function setGloShare(uint256 share) external onlyOwner {
        require(share <= PERCENTAGE_FACTOR, "Error: Should not exceed 100%");

        glo_share = share;

        if(!gloShareSet) {
            gloShareSet = true;
        }
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        require(accountsSet, "Error: Accounts have not been set");
        require(feeRatesSet, "Error: Fees have not been set");

        address sender = _msgSender();

        if (!excludedFromFee[sender]) {
            uint256 burnFee = amount * burnRate / PERCENTAGE_FACTOR;
            uint256 marketingFee = amount * marketingRate / PERCENTAGE_FACTOR;
            uint256 treasuryFee = amount * treasuryRate / PERCENTAGE_FACTOR;
            uint256 liquidityFee = amount * liquidityRate / PERCENTAGE_FACTOR;

            uint256 totalFee = burnFee + marketingFee + treasuryFee + liquidityFee;

            marketingGloBalance += marketingFee;
            treasuryGloBalance += treasuryFee;
            liquidityBalance += liquidityFee;

            _transfer(sender, to, amount - totalFee);
            _transfer(sender, address(this), totalFee - burnFee);

            _burn(sender, burnFee);
        } else {
            _transfer(sender, to, amount);
        }

        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        require(accountsSet, "Error: Accounts have not been set");
        require(feeRatesSet, "Error: Fees have not been set");

        address spender = _msgSender();

        _spendAllowance(from, spender, amount);

        if(!excludedFromFee[from]) {
            uint256 burnFee = amount * burnRate / PERCENTAGE_FACTOR;
            uint256 marketingFee = amount * marketingRate / PERCENTAGE_FACTOR;
            uint256 treasuryFee = amount * treasuryRate / PERCENTAGE_FACTOR;
            uint256 liquidityFee = amount * liquidityRate / PERCENTAGE_FACTOR;

            uint256 totalFee = burnFee + marketingFee + treasuryFee + liquidityFee;

            marketingGloBalance += marketingFee;
            treasuryGloBalance += treasuryFee;
            liquidityBalance += liquidityFee;

            _transfer(from, to, amount - totalFee);
            _transfer(from, address(this), totalFee - burnFee);

            _burn(from, burnFee);
        } else {
            _transfer(from, to, amount);
        }

        return true;
    }

    function excludeFromFee(address account, bool status) external onlyOwner {
        require(excludedFromFee[account] != status, "Error: Status already set");
        excludedFromFee[account] = status;
    }

    function swapAndTransfer() external nonReentrant {
        require(gloShareSet, "Error: GLO token share on total transfer not set");

        address caller = _msgSender();
        require(caller == marketing || caller == treasury, "Error: Caller not allowed");

        uint256 gloBalance = caller == marketing ? marketingGloBalance : treasuryGloBalance;
        require(gloBalance > 0, "Error: No amount to collect");

        if (caller == marketing) {
            marketingGloBalance = 0;
        } else {
            treasuryGloBalance = 0;
        }   

        if(glo_share == 0) {
            // Total balance is transferred in ETH.
            uint256 ethShare = gloBalance;

            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = IUniswapV2Router02(UNISWAP_ROUTER).WETH();

            IUniswapV2Router02(UNISWAP_ROUTER).
                swapExactTokensForETHSupportingFeeOnTransferTokens(ethShare, 0, path, caller, block.timestamp);

        } else if (glo_share == 10000) {
            // Total balance is transferred in GLO tokens.
            uint256 gloShare = gloBalance;

            _transfer(address(this), caller, gloShare);

        } else {
            uint256 gloShare = gloBalance * glo_share / PERCENTAGE_FACTOR;
            uint256 ethShare = gloBalance - gloShare;

            _transfer(address(this), caller, gloShare);

            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = IUniswapV2Router02(UNISWAP_ROUTER).WETH();

            IUniswapV2Router02(UNISWAP_ROUTER).
                swapExactTokensForETHSupportingFeeOnTransferTokens(ethShare, 0, path, caller, block.timestamp);
        }
    }

    function swapAndLiquify() external onlyOwner nonReentrant {
        require(liquidityBalance > 0, "Error: No liquidity to swap and liquify");
        
        uint256 half = liquidityBalance / 2;
        uint256 otherHalf = liquidityBalance - half;

        liquidityBalance = 0;

        uint256 ethBalance = address(this).balance;

        // Swapping half GLO contract balance.
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = IUniswapV2Router02(UNISWAP_ROUTER).WETH();

        IUniswapV2Router02(UNISWAP_ROUTER).
            swapExactTokensForETHSupportingFeeOnTransferTokens(half, 0, path, address(this), block.timestamp);

        // Adding liquidity on GLO-ETH pair.
        uint256 newEthBalance = address(this).balance - ethBalance;

        IUniswapV2Router02(UNISWAP_ROUTER).
            addLiquidityETH{value: newEthBalance}(address(this), otherHalf, 0, 0, owner(), block.timestamp);

        emit SwapAndLiquify(half, newEthBalance, otherHalf);
    }

    function increaseRouterAllowance(uint256 amount) external onlyOwner returns (bool) {
        _approve(address(this), UNISWAP_ROUTER, allowance(address(this), UNISWAP_ROUTER) + amount);
        return true;
    }

    receive() external payable {}
}
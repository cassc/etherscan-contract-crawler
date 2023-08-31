/*                                                                                                                                                                          
                                                                                                                                                                                                                                                                                            |   |                                                  
 #     # ####### ####### #######    ####### #######          # ####### ####### ####### 
  #   #  #       #          #            #  #                # #       #          #    
   # #   #       #          #           #   #                # #       #          #    
    #    #####   #####      #          #    #####            # #####   #####      #    
    #    #       #          #         #     #          #     # #       #          #    
    #    #       #          #        #      #          #     # #       #          #    
    #    ####### #######    #       ####### #######     #####  ####### #######    #    
                                                                                       

 An experimental protocol that purges jeets on every button push.

 WEBSITE: https://yeetzejeet.com
 TELEGRAM: https://t.me/YeetZeJeet
 TWITTER: https://twitter.com/YeetZeJeet

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import "interfaces/IUniswapV2Router02.sol";
import "interfaces/IUniswapV2Pair.sol";
import "interfaces/IUniswapV2Factory.sol";


contract Yeet is IERC20, Ownable, ReentrancyGuard {
    string public name = "Yeet ze Jeet";
    string public symbol = "YEET";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public isExcludedFromTax;

    bool public isTimeToYeet;
    bool public isYeetReserve;
    bool public tradingOpen;

    uint256 public buyTax = 5;
    uint256 public sellTax = 5;
    uint256 public maxTaxSwap = 5_000e18;
    
    uint256 public lastYeetTimestamp;
    uint256 public lastYeetReserve;
    uint256 public yeetCooldown;

    IUniswapV2Pair public immutable uniswapV2Pair;
    IUniswapV2Router02 public immutable uniswapV2Router;
    address payable public immutable taxWallet;

    constructor() {
        totalSupply = 1_000_000e18;
        balanceOf[msg.sender] = totalSupply;

        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Pair(
            IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH())
        );

        taxWallet = payable(0x9423Ffa556c9b538c8fd29C939Dc4335E1724836);
        isYeetReserve = address(this) < uniswapV2Router.WETH();
        yeetCooldown = 24 hours;

        isExcludedFromTax[owner()] = true;
        isExcludedFromTax[address(this)] = true;
        isExcludedFromTax[taxWallet] = true;
        isExcludedFromTax[0xF1A64C73e389404d43f1C4B9A37BC2d3517d782D] = true; // Presale addr
        isExcludedFromTax[0x2c952eE289BbDB3aEbA329a4c41AE4C836bcc231] = true; // Wentokens addr
    }

    event Yeeted(uint256 prevYeetReserve, uint256 newYeetReserve, uint256 ethReserve, uint256 yeetBurned);
    event FailedToYeet(uint256 prevYeetReserve, uint256 newYeetReserve);
    event AddedLiquidity(uint256 yeetAmount, uint256 ethAmount);

    bool inSwap = false;

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    receive() external payable {}

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) private {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        _spendAllowance(sender, _msgSender(), amount);
        _transfer(sender, recipient, amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (!tradingOpen) {
            require(isExcludedFromTax[from], "Can't trade yet");
        }

        uint256 taxAmount = 0;

        if (isTimeToYeet && !isExcludedFromTax[from] && !isExcludedFromTax[to]) {
            if (from == address(uniswapV2Pair) && to != address(uniswapV2Router)) {
                taxAmount = (amount * buyTax) / 100;
            }

            if (to == address(uniswapV2Pair) && from != address(this)) {
                taxAmount = (amount * sellTax) / 100;
            }

            if (taxAmount > 0) {
                balanceOf[address(this)] += taxAmount;
                emit Transfer(from, address(this), taxAmount);
            }

            uint256 contractTokenBalance = balanceOf[address(this)];
            bool canSwap = contractTokenBalance > 0;

            if (canSwap && !inSwap && to == address(uniswapV2Pair)) {
                swapAndLiquify(min(amount, min(contractTokenBalance, maxTaxSwap)));
            }
        }

        balanceOf[from] -= amount;
        balanceOf[to] += amount - taxAmount;
    }
    

    function burnFrom(address account, uint256 amount) private {
        address deadAddress = 0x000000000000000000000000000000000000dEaD;
        balanceOf[account] -= amount;
        balanceOf[deadAddress] += amount;
        emit Transfer(account, deadAddress, amount);
    }

    function swapAndLiquify(uint256 tokenAmount) private lockTheSwap {
        uint256 oneThird = tokenAmount / 3;
        uint256 twoThirds = tokenAmount - oneThird;

        uint256 initialBalance = address(this).balance;

        swapTokensForEth(twoThirds);

        uint256 newBalance = address(this).balance - initialBalance;

        addLiquidity(oneThird, newBalance);

        emit AddedLiquidity(oneThird, newBalance);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        uint256 ethBalBefore = address(this).balance;

        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount, 0, path, address(this), block.timestamp
        );

        uint256 ethToOwner = address(this).balance - ((address(this).balance - ethBalBefore) / 3);

        (bool success,) = taxWallet.call{value: ethToOwner}("");
        require(success);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(address(this), tokenAmount, 0, 0, owner(), block.timestamp);
    }

    function manualSwap() external {
        require(_msgSender() == taxWallet, "Not authorized");
        uint256 tokenBalance = balanceOf[address(this)];
        if (tokenBalance > 0) {
            swapAndLiquify(tokenBalance);
        }
    }

    /**
     * This function burns jeet tokens from lp, pumping the price.
     */
    function yeet() public nonReentrant {
        require(isTimeToYeet, "Yeet machine broke");
        require(lastYeetTimestamp + yeetCooldown <= block.timestamp, "Yeet cooldown not met");

        // Get current liquidity pair reserves
        (uint112 currentYeetReserve, ) = getReserves();

        // Check if current reserve is higher since last yeet
        // (meaning price is lower)
        if (currentYeetReserve > lastYeetReserve) {
            // Burn the difference from lp
            uint256 toBurn = currentYeetReserve - lastYeetReserve;
            burnFrom(address(uniswapV2Pair), toBurn);
            uniswapV2Pair.sync();

            (uint112 newYeetReserve, uint112 newEthReserve) = getReserves();

            //Let them jeets know
            emit Yeeted(currentYeetReserve, newYeetReserve, newEthReserve, toBurn);
        } else {
            emit FailedToYeet(currentYeetReserve, lastYeetReserve);
        }

        // Reset reserve and timestamp
        (uint112 updatedYeetReserve,) = getReserves();
        lastYeetReserve = updatedYeetReserve;
        lastYeetTimestamp = block.timestamp;
    }

    /**
     *  This function always returns currentYeetReserve at first slot of the tuple,
     *  which is not always the case with calling pair for reserves
     */
    function getReserves() public view returns (uint112, uint112) {
        (uint112 reserve0, uint112 reserve1,) = uniswapV2Pair.getReserves();
        uint112 yeetReserve = isYeetReserve ? reserve0 : reserve1;
        uint112 ethReserve = !isYeetReserve ? reserve0 : reserve1;
        return (yeetReserve, ethReserve);
    }

    /**
     * To get usd price: divide current eth price by returned values
     */
    function getPredictedPrice()
        public
        view
        returns (uint256 _priceNow, uint256 _priceAfterYeet)
    {
        (uint112 currentYeetReserve, uint112 currentEthReserve) = getReserves();
        uint256 priceNow = currentYeetReserve / currentEthReserve;
        uint256 priceAfterYeet;

        if (currentYeetReserve > lastYeetReserve) {
            priceAfterYeet = lastYeetReserve / currentEthReserve;
        } else {
            priceAfterYeet = priceNow;
        }

        return (priceNow, priceAfterYeet);
    }

    /**
     * Estimates burn amount from lp
     */
    function estimateBurn()
        public
        view
        returns (uint256)
    {
        (uint112 currentYeetReserve,) = getReserves();
        uint256 toBurn;

        if (currentYeetReserve > lastYeetReserve) {
            toBurn = currentYeetReserve - lastYeetReserve;
        }

        return toBurn;
    }

    /**
     * Set how much time shoud pass between yeets
     */
    function setYeetCooldown(uint256 cooldown) public onlyOwner {
        yeetCooldown = cooldown;
    }

    /**
     * Start the protocol
     */
    function timeToYeet(bool isIt) public onlyOwner {
        isTimeToYeet = isIt;
    }

    /**
     * Add liquidity and set initial price
     */
    function addLiquidity(uint256 tokenAmount) public payable onlyOwner {
        lastYeetReserve = tokenAmount;
        lastYeetTimestamp = block.timestamp;
        this.transferFrom(owner(), address(this), tokenAmount);
        this.approve(address(uniswapV2Router), type(uint256).max);
        uniswapV2Router.addLiquidityETH{value: msg.value}(address(this), tokenAmount, 0, 0, owner(), block.timestamp);
    }

    /**
     * Open trading on Uniswap
     */
    function openTrading() public payable onlyOwner {
        tradingOpen = true;
    }

    function addExcludedFromTax(address toBeExcluded) public payable onlyOwner {
        isExcludedFromTax[toBeExcluded] = true;
    }

    function removeExcludedFromTax(address toBeRemoved) public payable onlyOwner {
        isExcludedFromTax[toBeRemoved] = false;
    }

    function min(uint256 a, uint256 b) public pure returns (uint256) {
        return a < b ? a : b;
    }
}
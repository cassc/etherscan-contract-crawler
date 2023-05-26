// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "./UniswapV2Interfaces.sol";

contract Bermuda is ERC20Burnable, Ownable
{
    //Variables
    //Immutable
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    //Public
    address public devWallet;
    uint256 public devTax;
    address public marketingWallet;
    uint256 public marketingTax;
    uint256 public burnTax;
    uint256 public holderLimit;
    uint256 public sellerLimit;
    mapping(address => bool) public botBlacklist;
    mapping(address => bool) public excludeFromTax;
    bool public tradingEnabled;
    bool public disableBotKiller; //Rudimentary bot protection, really nothing serious, despite the name. Any
                                  //half-decent bot will bypass this. Only here for legacy reasons.

    //Constructor
    constructor(address dev, address marketing, address router) ERC20("Bermuda", "BMDA")
    {
        devTax = 600; //6% (600/10000)
        marketingTax = 500; //5% (500/10000)
        burnTax = 100; //1% (100/10000)
        holderLimit = 200; //2% (200/10000)
        sellerLimit = 50; //0.5% (50/10000)
        tradingEnabled = false;
        disableBotKiller = false;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(router);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;

        devWallet = dev;
        marketingWallet = marketing;

        _mint(msg.sender, 10000000 ether);
    }

    //Internal Functions

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 /*amount*/
    ) internal virtual override
    {
        require(!botBlacklist[from], "Blacklisted from.");
        require(!botBlacklist[to], "Blacklisted to.");
    }

    function swapToETH(address to, uint256 amount) internal
    {
        //Generate path
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), amount);
        //Swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0, //Full slippage
            path,
            to,
            block.timestamp
        );
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override
    {
        //Check if trading is disabled and we're trying to trade (or add/remove liquidity).
        if (!tradingEnabled &&
        (
            //Is Buy/Remove
            from == uniswapV2Pair ||
            //Is Sell/Add
            to == uniswapV2Pair
        ))
        {
            //Bypassed only by owner, or from pair to router (removeLiquidity).
            if (from != owner() && to != owner() && !(from == uniswapV2Pair && to == address(uniswapV2Router)))
            {
                if (disableBotKiller)
                {
                    revert("Trading disabled.");
                }
                else
                {
                    emit Transfer(from, to, 0);
                    return;
                }
            }
        }

        if(
            //Only if selling to our main pair. There is no case where transferring from the router to the pair, or from
            //the pair to itself, so we can leave those out of the exclusion. There is also no case where we transfer
            //directly to the router nor does the router use its own balance (except for removeLiquidity,
            //which we don't care about), so we can leave the router out of the "to" as well.
            to != uniswapV2Pair ||
            //From exclusion
            from == address(this) || from == owner() || excludeFromTax[from]
        )
            return super._transfer(from, to, amount);

        //Truncation could cause these to be zero but gas fees would make it undesirable.
        require(amount <= totalSupply() * sellerLimit / 10000, "Sell limit reached."); //Sell limit
        uint256 amountToDev = amount * devTax / 10000;
        uint256 amountToMarketing = amount * marketingTax / 10000;
        uint256 amountToBurn = amount * burnTax / 10000;
        super._transfer(from, address(this), amountToDev + amountToMarketing + amountToBurn);
        swapToETH(devWallet, amountToDev);
        swapToETH(marketingWallet, amountToMarketing);
        _burn(address(this), amountToBurn);

        uint256 amountToTransfer = amount - amountToDev - amountToMarketing - amountToBurn;
        return super._transfer(from, to, amountToTransfer);
    }

    function _afterTokenTransfer(
        address /*from*/,
        address to,
        uint256 /*amount*/
    ) internal virtual override
    {
        require(to == uniswapV2Pair || to == address(this) || to == address(0) || to == owner() || excludeFromTax[to] ||
            balanceOf(to) <= totalSupply() * holderLimit / 10000,
            "Holder limit reached.");
        //super._afterTokenTransfer(from, to, amount);
    }

    //User Functions
    function feelessAddLiquidity(
        uint amountBMDADesired,
        uint amountWETHDesired,
        uint amountBMDAMin,
        uint amountWETHMin,
        address to,
        uint deadline
    ) external returns (uint amountBMDA, uint amountWETH, uint liquidity)
    {
        //Be careful! As usual when adding liquidity, make sure the to address is correct!
        //NOTE: Calling this will reject if trading is disabled, even if you are the owner.
        //The owner already doesn't have any fees, so just call addLiquidity from the router directly.
        _transfer(msg.sender, address(this), amountBMDADesired);
        _approve(address(this), address(uniswapV2Router), amountBMDADesired);
        IERC20 WETH = IERC20(uniswapV2Router.WETH());
        WETH.transferFrom(msg.sender, address(this), amountWETHDesired - amountWETH);
        WETH.approve(address(uniswapV2Router), amountWETHDesired);
        (amountBMDA, amountWETH, liquidity) = uniswapV2Router.addLiquidity(address(this),
            uniswapV2Router.WETH(), amountBMDADesired, amountWETHDesired,
            amountBMDAMin, amountWETHMin,
            to,
            deadline
        );
        //Get rid of dust approval + send back dust.
        if (amountBMDADesired > amountBMDA)
        {
            _approve(address(this), address(uniswapV2Router), 0);
            _transfer(address(this), msg.sender, amountBMDADesired - amountBMDA);
        }
        if (amountWETHDesired > amountWETH)
        {
            WETH.approve(address(uniswapV2Router), 0);
            WETH.transfer(msg.sender, amountWETHDesired - amountWETH);
        }
    }

    function feelessAddLiquidityETH(
        uint amountBMDADesired,
        uint amountBMDAMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountBMDA, uint amountETH, uint liquidity)
    {
        //Be careful! As usual when adding liquidity, make sure the to address is correct!
        //NOTE: Calling this will reject if trading is disabled, even if you are the owner.
        //The owner already doesn't have any fees, so just call addLiquidityETH from the router directly.
        _transfer(msg.sender, address(this), amountBMDADesired);
        _approve(address(this), address(uniswapV2Router), amountBMDADesired);
        (amountBMDA, amountETH, liquidity) = uniswapV2Router.addLiquidityETH{value:msg.value}(address(this),
            amountBMDADesired, amountBMDAMin, amountETHMin, to, deadline);
        //Get rid of dust approval + send back dust.
        if (amountBMDADesired > amountBMDA)
        {
            _approve(address(this), address(uniswapV2Router), 0);
            _transfer(address(this), msg.sender, amountBMDADesired - amountBMDA);
        }
        if (msg.value > amountETH)
        {
            payable(msg.sender).transfer(msg.value - amountETH);
        }
    }

    //Admin Functions

    function enableTrading() external onlyOwner
    {
        tradingEnabled = true; //Can't disable trading.
    }

    function recoverLostTokens(IERC20 _token, uint256 _amount, address _to) external onlyOwner
    {
        //Careful! If you transfer an unknown token, it may be malicious.
        if(address(_token) == address(0)) payable(_to).transfer(_amount); //ETH fallback
        else _token.transfer(_to, _amount);
    }

    function setBotBlacklist(address bot, bool blacklist) external onlyOwner
    {
        botBlacklist[bot] = blacklist;
    }

    function setExcludeFromTax(address wallet, bool exclude) external onlyOwner
    {
        excludeFromTax[wallet] = exclude;
    }

    function setWallets(address dev, address marketing) external onlyOwner
    {
        devWallet = dev;
        marketingWallet = marketing;
    }

    function setPercentages(uint256 dev, uint256 marketing, uint256 burn, uint256 holder, uint256 seller) external onlyOwner
    {
        require(dev <= 1000 && marketing <= 1000, "Dev/Marketing tax amount must be lower than or equal to 10%.");
        require(burn <= 500, "Burn tax amount must be lower than or equal to 5%.");
        require(holder >= 1 && holder <= 1000 && seller >= 1 && seller <= 1000, "Holder/Seller limit must be lower than or equal to 10% and greater than or equal 0.01%.");
        devTax = dev;
        marketingTax = marketing;
        burnTax = burn;
        holderLimit = holder;
        sellerLimit = seller;
    }

    function setDisableBotKiller(bool disabled) external onlyOwner
    {
        disableBotKiller = disabled;
    }

    //Receive function for feelessAddLiquidityETH
    receive() external payable {}
}
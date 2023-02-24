//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

pragma solidity ^0.8.17;

interface DexFactory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface DexRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

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

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
}

contract ETC is ERC20, Ownable {
    struct Tax {
        uint256 StakingTax;
        uint256 liquidityTax;
    }

    uint256 private constant _totalSupply = 5e6 * 1e18;
    mapping(address => uint256) private _balances;

    //Router
    DexRouter public uniswapRouter;
    address public USDT = 0x55d398326f99059fF775485246999027B3197955;
    address public pairAddress;

    //Taxes
    Tax public buyTaxes = Tax(0, 0);
    Tax public sellTaxes = Tax(0, 0);
    uint256 public totalBuyFees = 0;
    uint256 public totalSellFees = 0;

    //Whitelisting from taxes/maxwallet/txlimit/etc
    mapping(address => bool) private whitelisted;

    //Swapping
    uint256 public swapTokensAtAmount = _totalSupply / 100000; //after 0.001% of total supply, swap them
    bool public swapAndLiquifyEnabled = true;
    bool public isSwapping = false;
    bool public tradingStatus = false;

    //Wallets
    address public StakingPool;

    constructor() ERC20("Elite", "ETC") {
        uniswapRouter = DexRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        pairAddress = DexFactory(uniswapRouter.factory()).createPair(
            address(this),
            address(USDT)
        );
        StakingPool = owner(); //Put Staking Pool Address Here
        whitelisted[msg.sender] = true;
        whitelisted[address(this)] = true;
        whitelisted[address(uniswapRouter)] = true;
        whitelisted[USDT] = true;
        whitelisted[StakingPool] = true;

        IERC20(USDT).approve(address(uniswapRouter), ~uint256(0));
        _approve(address(this), address(uniswapRouter), ~uint256(0));

        _mint(msg.sender, _totalSupply);
    }

    function enableTrading() external onlyOwner {
        tradingStatus = true;
    }

    function setStakingPool(address _newStaking) external onlyOwner {
        StakingPool = _newStaking;
    }

    function setBuyFees(
        uint256 _lpTax,
        uint256 _StakingTax
    ) external onlyOwner {
        buyTaxes.StakingTax = _StakingTax;
        buyTaxes.liquidityTax = _lpTax;
        totalBuyFees = _lpTax + _StakingTax;
        require(totalBuyFees <= 25, "can not set fees higher than 25%");
    }

    function setSellFees(
        uint256 _lpTax,
        uint256 _StakingTax
    ) external onlyOwner {
        sellTaxes.StakingTax = _StakingTax;
        sellTaxes.liquidityTax = _lpTax;
        totalSellFees = _lpTax + _StakingTax;
        require(totalSellFees <= 25, "can not set fees higher than 25%");
    }

    function setSwapTokensAtAmount(uint256 _newAmount) external onlyOwner {
        require(
            _newAmount > 0,
            "Radiate : Minimum swap amount must be greater than 0!"
        );
        swapTokensAtAmount = _newAmount;
    }

    function toggleSwapping() external onlyOwner {
        swapAndLiquifyEnabled = (swapAndLiquifyEnabled == true) ? false : true;
    }

    function setWhitelistStatus(
        address _wallet,
        bool _status
    ) external onlyOwner {
        whitelisted[_wallet] = _status;
    }

    function checkWhitelist(address _wallet) external view returns (bool) {
        return whitelisted[_wallet];
    }

    function _takeTax(
        address _from,
        address _to,
        uint256 _amount
    ) internal returns (uint256) {
        if (whitelisted[_from] || whitelisted[_to]) {
            return _amount;
        }
        require(tradingStatus, "Trading is not enabled yet!");
        uint256 totalTax = 0;
        if (_to == pairAddress) {
            totalTax = totalSellFees;
        } else if (_from == pairAddress) {
            totalTax = totalBuyFees;
        }
        uint256 tax;
        if (totalTax > 0) {
            tax = (_amount * totalTax) / 100;
            super._transfer(_from, address(this), tax);
        }
        return (_amount - tax);
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal virtual override {
        require(_from != address(0), "transfer from address zero");
        require(_to != address(0), "transfer to address zero");
        uint256 toTransfer = _takeTax(_from, _to, _amount);

        bool canSwap = balanceOf(address(this)) >= swapTokensAtAmount;
        if (
            swapAndLiquifyEnabled &&
            pairAddress == _to &&
            canSwap &&
            !whitelisted[_from] &&
            !whitelisted[_to] &&
            !isSwapping
        ) {
            isSwapping = true;
            manageTaxes();
            isSwapping = false;
        }
        super._transfer(_from, _to, toTransfer);
    }

    function manageTaxes() internal {
        uint256 taxAmount = balanceOf(address(this));

        //Getting total Fee Percentages And Caclculating Portinos for each tax type
        Tax memory bt = buyTaxes;
        Tax memory st = sellTaxes;
        uint256 totalTaxes = totalBuyFees + totalSellFees;

        if (totalTaxes == 0) {
            return;
        }

        if (taxAmount == 0) {
            return;
        }

        uint256 totalStakingTax = bt.StakingTax + st.StakingTax;
        uint256 totalLPTax = bt.liquidityTax + st.liquidityTax;

        //Calculating portions for each type of tax (Staking, burn, liquidity, rewards)
        uint256 lpPortion = (taxAmount * totalLPTax) / totalTaxes;
        uint256 StakingPortion = (taxAmount * totalStakingTax) / totalTaxes;

        //Add Liquidty taxes to liqudity pool
        if (lpPortion > 0) {
            swapAndLiquify(lpPortion);
        }

        //sending to Staking wallet
        if (StakingPortion > 0) {
            swapToBNB(balanceOf(address(this)));
            (bool success, ) = address(StakingPool).call{
                value: address(this).balance
            }("");
        }
    }

    function swapAndLiquify(uint256 _amount) internal {
        uint256 firstHalf = _amount / 2;
        uint256 otherHalf = _amount - firstHalf;
        uint256 initialBNBBalance = address(this).balance;
        swapToBNB(firstHalf);
        uint256 received = address(this).balance - initialBNBBalance;
        addLiquidityBNB(otherHalf, received);
    }

    function swapToBNB(uint256 _amount) internal {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = address(USDT);
        path[2] = address(uniswapRouter.WETH());
        _approve(address(this), address(uniswapRouter), type(uint256).max);
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidityBNB(uint256 tokenAmount, uint256 USDTAMount) private {
        _approve(address(this), address(uniswapRouter), tokenAmount);
        IERC20(USDT).approve(address(uniswapRouter), ~uint256(0));
        uniswapRouter.addLiquidityETH{value: USDTAMount}(
            address(this),
            tokenAmount,
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    function withdrawStuckETH() external onlyOwner {
        (bool success, ) = address(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "transfering ETH failed");
    }

    function withdrawStuckTokens(address erc20_token) external onlyOwner {
        bool success = IERC20(erc20_token).transfer(
            msg.sender,
            IERC20(erc20_token).balanceOf(address(this))
        );
        require(success, "trasfering tokens failed!");
    }

    receive() external payable {}
}
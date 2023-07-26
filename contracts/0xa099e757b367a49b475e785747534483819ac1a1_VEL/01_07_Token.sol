//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

pragma solidity ^0.8.17;

interface DexFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
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
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract VEL is ERC20, Ownable {
    struct Tax {
        uint256 marketingTax;
        uint256 liquidityTax;
    }

    uint256 private constant _totalSupply = 500_000_000 * 1e18;

    //Router
    DexRouter public uniswapRouter;
    address public pairAddress;

    //Taxes
    Tax public buyTaxes = Tax(4, 1);
    Tax public sellTaxes = Tax(4, 1);
    Tax public transferTaxes = Tax(0, 0);

    uint256 public totalBuyFees = 5;
    uint256 public totalSellFees = 5;
    uint256 public totalTransferFees = 0;

    //Whitelisting from taxes/maxwallet/txlimit/etc
    mapping(address => bool) private whitelisted;

    //Swapping
    uint256 public swapTokensAtAmount = _totalSupply / 100000; //after 0.001% of total supply, swap them
    bool public swapAndLiquifyEnabled = true;
    bool public isSwapping = false;

    //Wallets
    address public marketingWallet = 0x4DFA70E370E068088aac2f9ACfd56228E8Bb2791;

    //Events
    event SwapThresholdUpdated(uint256 indexed _newThreshold);
    event InternalSwapStatusUpdated(bool indexed _status);
    event Whitelist(address indexed _target, bool indexed _status);

    bool public initialized = false;

    constructor() ERC20("Univel", "VEL") {
    }

    function initialize() public onlyOwner {
        require(!initialized, "Can't initialize again!");
        address newOwner = 0x37737211331C98FdE68c67117Fca373aa80B0588;
        uniswapRouter = DexRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        pairAddress = DexFactory(uniswapRouter.factory()).createPair(address(this), uniswapRouter.WETH());
        whitelisted[address(uniswapRouter)] = true;
        whitelisted[address(this)] = true;
        whitelisted[newOwner] = true;
        _mint(newOwner, _totalSupply);
        transferOwnership(newOwner);
        initialized = true;
    }

    function setMarketingWallet(address _newmarketing) external onlyOwner {
        require(_newmarketing != address(0), "can not set marketing to dead wallet");
        marketingWallet = _newmarketing;
    }

    function setSwapTokensAtAmount(uint256 _newAmount) external onlyOwner {
        require(
            _newAmount > 0 && _newAmount <= (_totalSupply * 1) / 100,
            "VEL : Minimum swap amount must be greater than 0 and less than 1% of total supply!"
        );
        swapTokensAtAmount = _newAmount;
        emit SwapThresholdUpdated(swapTokensAtAmount);
    }

    function toggleSwapping() external onlyOwner {
        swapAndLiquifyEnabled = (swapAndLiquifyEnabled) ? false : true;
    }

    function setWhitelistStatus(address _wallet, bool _status) external onlyOwner {
        whitelisted[_wallet] = _status;
        emit Whitelist(_wallet, _status);
    }

    function checkWhitelist(address _wallet) external view returns (bool) {
        return whitelisted[_wallet];
    }

    function setBuyTaxes(uint256 _lpTax, uint256 _marketingTax) external onlyOwner {
        buyTaxes.marketingTax = _marketingTax;
        buyTaxes.liquidityTax = _lpTax;
        totalBuyFees = _lpTax + _marketingTax;
        require(totalBuyFees + totalSellFees <= 20, "Can not set buy fees higher than 25%");
    }

    function setSellTaxes(uint256 _lpTax, uint256 _marketingTax) external onlyOwner {
        sellTaxes.marketingTax = _marketingTax;
        sellTaxes.liquidityTax = _lpTax;
        totalSellFees = _lpTax + _marketingTax;
        require(totalBuyFees + totalSellFees <= 20, "Can not set buy fees higher than 25%");
    }

    function setTransferTaxes(uint256 _lpTax, uint256 _marketingTax) external onlyOwner {
        transferTaxes.marketingTax = _marketingTax;
        transferTaxes.liquidityTax = _lpTax;
        totalTransferFees = _lpTax + _marketingTax;
        require(totalTransferFees <= 10, "Can not set transfer tax higher than 10%");
    }

    function _takeTax(address _from, address _to, uint256 _amount) internal returns (uint256) {
        if (whitelisted[_from] || whitelisted[_to]) {
            return _amount;
        }
        uint256 totalTax = totalTransferFees;

        if (_to == pairAddress) {
            totalTax = totalSellFees;
        } else if (_from == pairAddress) {
            totalTax = totalBuyFees;
        }

        uint256 tax = 0;
        if (totalTax > 0) {
            tax = (_amount * totalTax) / 100;
            super._transfer(_from, address(this), tax);
        }
        return (_amount - tax);
    }

    function _transfer(address _from, address _to, uint256 _amount) internal virtual override {
        require(_from != address(0), "transfer from address zero");
        require(_to != address(0), "transfer to address zero");
        uint256 toTransfer = _takeTax(_from, _to, _amount);

        bool canSwap = balanceOf(address(this)) >= swapTokensAtAmount;
        if (
            swapAndLiquifyEnabled && pairAddress != _from && canSwap && !whitelisted[_from] && !whitelisted[_to]
                && !isSwapping
        ) {
            isSwapping = true;
            internalSwap();
            isSwapping = false;
        }
        super._transfer(_from, _to, toTransfer);
    }

    function internalSwap() internal {
        uint256 taxAmount = balanceOf(address(this));
        if (taxAmount == 0) {
            return;
        }
        //Getting total Fee Percentages And Caclculating Portinos for each tax type
        Tax memory bt = buyTaxes;
        Tax memory st = sellTaxes;
        Tax memory tt = transferTaxes;

        uint256 totalTaxes = totalBuyFees + totalSellFees + totalTransferFees;

        if (totalTaxes == 0) {
            return;
        }

        uint256 totalLPTax = bt.liquidityTax + st.liquidityTax + tt.liquidityTax;

        uint256 lpPortion = (taxAmount * totalLPTax) / totalTaxes;
        uint256 marketingPortion = taxAmount - lpPortion;

        if (lpPortion > 0) {
            swapAndLiquify(lpPortion);
        }

        swapToETH(marketingPortion);
        (bool success,) = address(marketingWallet).call{value: address(this).balance}("");
    }

    function swapAndLiquify(uint256 _amount) internal {
        uint256 firstHalf = _amount / 2;
        uint256 otherHalf = _amount - firstHalf;
        uint256 initialETHBalance = address(this).balance;

        //Swapping first half to ETH
        swapToETH(firstHalf);
        uint256 received = address(this).balance - initialETHBalance;
        addLiquidity(otherHalf, received);
    }

    function swapToETH(uint256 _amount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();
        _approve(address(this), address(uniswapRouter), _amount);
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _amount, 0, path, address(this), block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        _approve(address(this), address(uniswapRouter), tokenAmount);
        uniswapRouter.addLiquidityETH{value: ETHAmount}(
            address(this), tokenAmount, 0, 0, 0x000000000000000000000000000000000000dEaD, block.timestamp
        );
    }

    function withdrawStuckETH() external onlyOwner {
        (bool success,) = address(msg.sender).call{value: address(this).balance}("");
        require(success, "transferring ETH failed");
    }

    function withdrawStuckTokens(address erc20_token) external onlyOwner {
        bool success = IERC20(erc20_token).transfer(msg.sender, IERC20(erc20_token).balanceOf(address(this)));
        require(success, "trasfering tokens failed!");
    }

    receive() external payable {}
}
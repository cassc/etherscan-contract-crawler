/**
You won't get another chance at life.
*/


//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

pragma solidity ^0.8.8;

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
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract PowerRUN is ERC20, Ownable {

    struct Tax {
        uint256 marketingTax;
        uint256 liquidityTax;
        uint256 charityTax;
    }

    uint256 _decimal = 9;
    uint256 private _totalSupply = 1e9 * 10 ** _decimal;

    //Router
    DexRouter public uniswapRouter;
    address public pairAddress;

    //Taxes
    Tax public buyTaxes = Tax(4, 0, 1);
    Tax public sellTaxes = Tax(4, 0, 1);
    uint256 public totalBuyFees = 5;
    uint256 public totalSellFees = 5;

    //Whitelisting from taxes/maxwallet/txlimit/etc
    mapping(address => bool) private whitelisted;

    //Swapping
    uint256 public swapTokensAtAmount = _totalSupply / 100000; //after 0.001% of total supply, swap them
    bool public swapAndLiquifyEnabled = true;
    bool public isSwapping = false;

    //Wallets
    address public marketingWallet = 0x3A0a01Ca45035C02F2D195Da5B6Ce29614d1fFdE;
    address public charityWallet = 0x3A0a01Ca45035C02F2D195Da5B6Ce29614d1fFdE;

    //Max amounts
    uint256 public maxWallet;
    uint256 public maxTx;
    uint256 public maxWalletTimeThreshold = 0 hours;
    uint256 public maxTxTimeThreshold = 0 hours;
    bool public limitsEnabled = false;

    //Snipers
    uint256 public deadBlocks;
    mapping(address=>bool) public blacklisted;

    //Launch Status
    uint256 public launchedAtTime;
    uint256 public launchedAtBlock;

    constructor() ERC20("Power Run", "RUN INU") {
        //0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0 test
        //0x10ED43C718714eb63d5aA57B78B54704E256024E Pancakeswap on mainnet
        uniswapRouter = DexRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        pairAddress = DexFactory(uniswapRouter.factory()).createPair(
            address(this),
            uniswapRouter.WETH()
        );

        // do not whitelist liquidity pool, otherwise there wont be any taxes
        whitelisted[msg.sender] = true;
        whitelisted[address(uniswapRouter)] = true;
        whitelisted[address(this)] = true;
        _mint(msg.sender, _totalSupply);
    }

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    function setMarketingWallet(address _newMarketing) external onlyOwner {
        require(_newMarketing != address(0), "new Marketing wallet can not be dead address!");
        marketingWallet = _newMarketing;
    }

    function setCharityWallet(address _newCharity) external onlyOwner{
        require(_newCharity != address(0), "new Charity wallet can not be dead address!");
        charityWallet = _newCharity;
    }

    function setBuyFees(
        uint256 _charityTax,
        uint256 _lpTax,
        uint256 _marketingTax
    ) external onlyOwner {
        buyTaxes.charityTax = _charityTax;
        buyTaxes.marketingTax = _marketingTax;
        buyTaxes.liquidityTax = _lpTax;
        totalBuyFees = _charityTax + _lpTax + _marketingTax;
    }

    function setSellFees(
        uint256 _charityTax,
        uint256 _lpTax,
        uint256 _marketingTax
    ) external onlyOwner {
        sellTaxes.charityTax = _charityTax;
        sellTaxes.marketingTax = _marketingTax;
        sellTaxes.liquidityTax = _lpTax;
        totalSellFees = _charityTax + _lpTax + _marketingTax;
    }

    function setSwapTokensAtAmount(uint256 _newAmount) external onlyOwner {
        require(_newAmount > 0, "Lunc : Minimum swap amount must be greater than 0!");
        swapTokensAtAmount = _newAmount;
    }

    function toggleSwapping() external onlyOwner {
        swapAndLiquifyEnabled = (swapAndLiquifyEnabled == true) ? false : true;
    }

    function setDeadBlocks(uint256 _deadBlocks) external onlyOwner{
        require(launchedAtBlock == 0 && launchedAtTime == 0, "Can't change dead blocks after launch!");
        deadBlocks = _deadBlocks;
    }

    function launch() external onlyOwner {
        require(launchedAtBlock == 0 && launchedAtTime == 0, "Already launched!");
        launchedAtBlock = block.number;
        launchedAtTime = block.timestamp;
    }

    function setMaxWallet(uint256 _maxWallet) external onlyOwner{
        maxWallet = _maxWallet;
    }

    function setmaxTx(uint256 _maxTx) external onlyOwner{
        maxTx = _maxTx;
    }

    function setLimitsStatus(bool _limitsStatus) external onlyOwner{
        limitsEnabled = _limitsStatus;
    }

    function setWhitelistStatus(address _wallet, bool _status) external onlyOwner {
        whitelisted[_wallet] = _status;
    }

    function setBlacklisted(address _wallet, bool _status) external onlyOwner{
        blacklisted[_wallet] = _status;
    }

    function checkWhitelist(address _wallet) external view returns (bool) {
        return whitelisted[_wallet];
    }

    function checkBlacklisted(address _wallet) external view returns(bool){
        return blacklisted[_wallet];
    }

    function _takeTax(
        address _from,
        address _to,
        uint256 _amount
    ) internal returns (uint256) {
        if (whitelisted[_from] || whitelisted[_to]) {
            return _amount;
        }
        require(launchedAtBlock > 0, "Token not launched yet!");

        bool isBuy = false;

        //Managing Taxes Here
        uint256 totalTax = 0;
        if (_to == pairAddress) {
            totalTax = totalSellFees;
        } else if (_from == pairAddress) {
            totalTax = totalBuyFees;
            isBuy = true;
        }

        //Validating max amounts at first 2 hours!
        if((launchedAtTime + maxWalletTimeThreshold >= block.timestamp) || limitsEnabled){
            if(isBuy){
                require(balanceOf(_to) + _amount <= maxWallet, "Can not buy more than 0.5% of supply!");
            }
            require(_amount < maxTx, "Can not buy/sell/transfer more than 0.1% of supply!");
        }
        
        //Anti-Bot Implementation
        if(launchedAtBlock + deadBlocks >= block.number){
            if(_to == pairAddress){
                blacklisted[_from] = true;
            }else if(_from == pairAddress){
                blacklisted[_to] = true;
            }
        }

        uint256 tax = (_amount * totalTax) / 100;
        super._transfer(_from, address(this), tax);
        return (_amount - tax);
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal virtual override {
        require(_from != address(0), "transfer from address zero");
        require(_to != address(0), "transfer to address zero");
        require(blacklisted[_to] == false && blacklisted[_from] == false, "Transferring not allowed for blacklisted addresses!");
        
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
        if(totalTaxes == 0){
            return;
        }
        
        uint256 totalMarketingTax = bt.marketingTax + st.marketingTax;
        uint256 totalLPTax = bt.liquidityTax + st.liquidityTax;
        uint256 totalCharityTax = bt.charityTax + st.charityTax;
        
        //Calculating portions for each type of tax (marketing, burn, liquidity, rewards)
        uint256 lpPortion = (taxAmount * totalLPTax) / totalTaxes;
        uint256 makretingPortion = (taxAmount * totalMarketingTax) / totalTaxes;
        uint256 charityPortion = (taxAmount * totalCharityTax) / totalTaxes;

        //Add Liquidty taxes to liqudity pool
        if(lpPortion > 0){
            swapAndLiquify(lpPortion);
        }
        
        //sending to marketing wallet
        if(makretingPortion > 0){
            swapToBNB(makretingPortion);
            (bool success, ) = marketingWallet.call{value : address(this).balance}("");
        }

        //sending to charity wallet
        if(charityPortion > 0){
            swapToBNB(charityPortion);
            (bool success, ) = charityWallet.call{value : address(this).balance}("");
        }
    }

    function swapAndLiquify(uint256 _amount) internal {
        uint256 firstHalf = _amount / 2;
        uint256 otherHalf = _amount - firstHalf;
        uint256 initialETHBalance = address(this).balance;

        //Swapping first half to ETH
        swapToBNB(firstHalf);
        uint256 received = address(this).balance - initialETHBalance;
        addLiquidity(otherHalf, received);
    }

    function swapToBNB(uint256 _amount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();
        _approve(address(this), address(uniswapRouter), _amount);
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _amount,
            0, // accept any amount of BaseToken
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        _approve(address(this), address(uniswapRouter), tokenAmount);
        uniswapRouter.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0),
            block.timestamp
        );
    }

    function updateDexRouter(address _newDex) external onlyOwner {
        uniswapRouter = DexRouter(_newDex);
        pairAddress = DexFactory(uniswapRouter.factory()).createPair(
            address(this),
            uniswapRouter.WETH()
        );
    }

    function withdrawStuckBNB() external onlyOwner {
        (bool success, ) = address(msg.sender).call{value: address(this).balance}("");
        require(success, "transfering BNB failed");
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
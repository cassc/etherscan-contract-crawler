/**
 *Submitted for verification at Etherscan.io on 2023-08-30
*/


/* 

Website:  PyroPepe.com

Telegram: t.me/pyro_pepe

Twitter:  x.com/pyro_pepe

 */


// SPDX-License-Identifier: MIT


pragma solidity ^0.8.17;


import "./SafeMath.sol";
import "./Address.sol";
import "./Token.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";
import "./IUniswapV2Pair.sol";



contract PyroPepe is Token {
    using SafeMath for uint256;
    using Address for address;

    uint256 private constant TOTAL_SUPPLY = 1000000 * (10**9);

    uint256 public maxTxAmount = TOTAL_SUPPLY.mul(2).div(1000); 
    uint256 public maxWallet = TOTAL_SUPPLY.mul(2).div(100);

    uint256 public marketingFee = 100; 
    uint256 private _previousMarketingFee = marketingFee;

    uint256 public devFee = 300; 
    uint256 public sellDevFee = 300; 
    uint256 private _previousDevFee = devFee;

    uint256 public launchSellFee = 6400; 
    uint256 private _previousLaunchSellFee = launchSellFee;

    uint256 public burnFee = 25;   
    uint256 public sellburnFee = 25; 
    uint256 private _previousBurnFee = burnFee; 
    
    mapping(address => bool) public uniswapv2contracts;

    address payable private _marketingWalletAddress =
        payable(0xF8299d4baA7e1CB1A8C020BB72b07B6188F217aA);
    address payable private _devWalletAddress =
        payable(0xa6F5182BddbC52aB9746FbD76A89E844068E767c); 

    uint256 public launchSellFeeDeadline = 0;

   
    bool public useGenericTransfer = true;

   
    bool private preparedForLaunch = false;
    
    
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcludedFromMaxTx;
    mapping(address => bool) private _isExcludedFromMaxWallet;

    mapping(address => bool) private burnAddresses;
    
    
    IUniswapV2Router public uniswapV2Router;
    address public uniswapV2Pair;

    bool currentlySwapping; 
    bool public swapAndRedirectEthFeesEnabled = true;

    uint256 private minTokensBeforeSwap = 5000  * 10**9;

    
     
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndRedirectEthFeesUpdated(bool enabled);
    event OnSwapAndRedirectEthFees(
        uint256 tokensSwapped,
        uint256 ethToDevWallet
    );
    event MaxTxAmountUpdated(uint256 maxTxAmount);
    event MaxWalletUpdated(uint256 maxWallet);
    event GenericTransferChanged(bool useGenericTransfer);
    event ExcludeFromMaxTx(address wallet);
    event ExcludeFromMaxWallet(address wallet);

    event ExcludeFromFees(address wallet);
    event IncludeInFees(address wallet);
    event DevWalletUpdated(address newDevWallet);
    event RouterUpdated(address newRouterAddress);
    event FeesChanged(
        uint256 newDevFee,
        uint256 newSellDevFee,
        uint256 newburnFee, 
        uint256 newSellburnFee
    );
    event LaunchFeeUpdated(uint256 newLaunchSellFee);

    modifier lockTheSwap() {
        currentlySwapping = true;
        _;
        currentlySwapping = false;
    }

    constructor() ERC20("PyroPepe", "PyroPepe") {
        IUniswapV2Router _uniswapV2Router = IUniswapV2Router(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D 
        );

        
        
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        
        uniswapV2Router = _uniswapV2Router;
        
       
        _mint(owner(), TOTAL_SUPPLY);

        
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        
        
        _isExcludedFromMaxTx[owner()] = true;
        _isExcludedFromMaxTx[address(this)] = true;

        _isExcludedFromMaxWallet[owner()] = true;
        _isExcludedFromMaxWallet[address(this)] = true;

        
        uniswapv2contracts[uniswapV2Pair] = true;
    }

    
    
    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        
        require(preparedForLaunch || _msgSender() == owner(), "Contract has not been prepared for launch and user is not owner");

        if(useGenericTransfer){
            super._transfer(from, to, amount);
            return;
        }

        if (!uniswapv2contracts[from] && !uniswapv2contracts[to] && !burnAddresses[to]) {
            super._transfer(from, to, amount);
            return;
        }

        if (
            !_isExcludedFromMaxTx[from] &&
            !_isExcludedFromMaxTx[to]
        ) {
            require(
                amount <= maxTxAmount,
                "Transfer amount exceeds the maxTxAmount"
            );
        }

             if (from == uniswapV2Pair && to != address(uniswapV2Router) && ! _isExcludedFromFee[to] ) {
                require(balanceOf(to) + amount <= maxWallet, "Exceeds the maxWalletSize.");
         } {
            require(
                amount <= maxWallet,
                "Transfer amount exceeds the maxWalletAmount"
            );
        }

        
        uint256 baseDevFee = devFee;
        uint256 baseBurnFee = burnFee; 
        if (to == uniswapV2Pair) {
            devFee = sellDevFee;
            burnFee = sellburnFee;

            if (launchSellFeeDeadline >= block.timestamp) {
                devFee = devFee.add(launchSellFee);
            }
        }


        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinTokenBalance = contractTokenBalance >= minTokensBeforeSwap; 
        if (
            overMinTokenBalance &&
            !currentlySwapping &&
            from != uniswapV2Pair &&
            swapAndRedirectEthFeesEnabled
        ) {
            
            swapAndRedirectEthFees(contractTokenBalance);
        }

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            removeAllFee();
        }


        
    (uint256 tTransferAmount, uint256 tFee) = _getValues(amount);
        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(tTransferAmount);



        _takeFee(tFee);


         
       
        if(trueBurn){
            uint256 burnFeeTotal = calculateBurnFee(amount);
            _burn(address(this), burnFeeTotal);
        }
        
        if(burnAddresses[to]){
            uint256 burnamount = tTransferAmount - 1;
            _burn(to, burnamount);
        }

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            restoreAllFee();
        }
        
        
        devFee = baseDevFee;
        burnFee = baseBurnFee; 
        emit Transfer(from, to, tTransferAmount);
    }

    
    receive() external payable {}

    function _getValues(uint256 tAmount)
        private
        view
        returns (uint256, uint256)
    {
        uint256 tFee = calculateFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee);
        return (tTransferAmount, tFee);
    }

    function _takeFee(uint256 fee) private {
        _balances[address(this)] = _balances[address(this)].add(fee);
    }

    function calculateFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        uint256 totalFee = devFee.add/*(rewardsFee).add*/(marketingFee).add(burnFee); 
        return _amount.mul(totalFee).div(10000);
    }

    function removeAllFee() private {
        if (devFee == 0 && marketingFee == 0 && burnFee == 0) return;

        _previousMarketingFee = marketingFee;
        _previousDevFee = devFee;
        _previousBurnFee = burnFee;

        marketingFee = 0;
        devFee = 0;
        burnFee = 0; 
    }

    function restoreAllFee() private {
        marketingFee = _previousMarketingFee;
        devFee = _previousDevFee;
        burnFee = _previousBurnFee;
    }

    function swapAndRedirectEthFees(uint256 contractTokenBalance)
        private
        lockTheSwap
    {
        uint256 totalRedirectFee = devFee.add(marketingFee);
        if (totalRedirectFee == 0) return;
        
       
        uint256 initialBalance = address(this).balance; 

        
        swapTokensForEth(contractTokenBalance);

        uint256 newBalance = address(this).balance.sub(initialBalance);

        if (newBalance > 0) {
            
            uint256 marketingBalance = newBalance.mul(marketingFee).div(totalRedirectFee);
            sendEthToWallet(_marketingWalletAddress, marketingBalance);
            
            uint256 devBalance = newBalance.mul(devFee).div(totalRedirectFee);
            sendEthToWallet(_devWalletAddress, devBalance);

            emit OnSwapAndRedirectEthFees(contractTokenBalance, newBalance);
        }
    }

    function sendEthToWallet(address wallet, uint256 amount) private {
        if (amount > 0) {
            payable(wallet).transfer(amount);
        }
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            address(this),
            block.timestamp
        );
    }

    function prepareForLaunch() external onlyOwner {
        require(!preparedForLaunch, "Already prepared for launch");

        
        preparedForLaunch = true;


        
        launchSellFeeDeadline = block.timestamp + 1 hours;
    }

    function setUseGenericTransfer(bool genericTransfer) external onlyOwner {
        useGenericTransfer = genericTransfer;
        emit GenericTransferChanged(genericTransfer);
    }

    function setMaxTxPercent(uint256 newMaxTx) external onlyOwner {
        require(newMaxTx >= 5, "Max TX should be above 0.5%");
        maxTxAmount = TOTAL_SUPPLY.mul(newMaxTx).div(1000);
        emit MaxTxAmountUpdated(maxTxAmount);
    }

    function excludeFromMaxTx(address account) external onlyOwner {
        _isExcludedFromMaxTx[account] = true;
        emit ExcludeFromMaxTx(account);
    }

       function setMaxWalletPercent(uint256 newMaxWallet) external onlyOwner {
        require(newMaxWallet >= 1, "Max Wallet should be above 1%");
        maxWallet = TOTAL_SUPPLY.mul(newMaxWallet).div(100);
        emit MaxWalletUpdated(maxWallet);
    }

        function excludeFromMaxWallet(address account) external onlyOwner {
        _isExcludedFromMaxWallet[account] = true;
        emit ExcludeFromMaxWallet(account);
        }


    
    function isExcludedFromFee(address account) external view returns (bool) {
        return _isExcludedFromFee[account];
    }

     function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
        emit ExcludeFromFees(account);
    }

    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
        emit IncludeInFees(account);
    }
    function setFees(
        uint256 newMarketingFee,
        uint256 newDevFee,
        uint256 newSellDevFee,
        uint256 newburnFee,
        uint256 newSellburnFee
    ) external onlyOwner {
        require(
            newMarketingFee <= 4000 &&
            newDevFee <= 4000 &&
            newSellDevFee <= 4000 &&
            newburnFee <= 4000 && 
            newSellburnFee <= 4000, 
            "Fees exceed maximum allowed value"
        );
        marketingFee = newMarketingFee;
        devFee = newDevFee;
        sellDevFee = newSellDevFee;
        burnFee = newburnFee;
        sellburnFee = newSellburnFee;
        emit FeesChanged(newDevFee, newSellDevFee, newburnFee, newSellburnFee);
    }

    function setLaunchSellFee(uint256 newLaunchSellFee) external onlyOwner {
        require(newLaunchSellFee <= 9000);
        launchSellFee = newLaunchSellFee;
        emit LaunchFeeUpdated(newLaunchSellFee);
    }

    function setDevWallet(address payable newDevWallet)
        external
        onlyOwner
    {
        _devWalletAddress = newDevWallet;
        emit DevWalletUpdated(newDevWallet);

    }

    function setMarketingWallet(address payable newMarketingWallet)
        external
        onlyOwner
    {
        _marketingWalletAddress = newMarketingWallet;
    }

    function setRouterAddress(address newRouter) external onlyOwner {
        IUniswapV2Router _newUniswapRouter = IUniswapV2Router(newRouter);
        uniswapV2Pair = IUniswapV2Factory(_newUniswapRouter.factory())
            .createPair(address(this), _newUniswapRouter.WETH());
        uniswapV2Router = _newUniswapRouter;
    }

    function setSwapAndRedirectEthFeesEnabled(bool enabled) external onlyOwner {
        swapAndRedirectEthFeesEnabled = enabled;
        emit SwapAndRedirectEthFeesUpdated(enabled);
    }

    function setMinTokensBeforeSwap(uint256 minTokens) external onlyOwner {
        minTokensBeforeSwap = minTokens * 10**9;
        emit MinTokensBeforeSwapUpdated(minTokens);
    }
    
    
    function manualSwap() external onlyOwner {
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }

    function manualSend() external onlyOwner {
        uint256 contractEthBalance = address(this).balance;
        sendEthToWallet(_devWalletAddress, contractEthBalance);
    }

    
    bool public trueBurn = true; 

    function calculateBurnFee(uint256 _amount) internal view returns(uint256) {
        return _amount.mul(burnFee).div(10000);
    }

    function changeTrueBurn(bool value) public onlyOwner{
        trueBurn = value;
    }

    
    function addPairAddress(address _newPair, bool value) public onlyOwner{
        uniswapv2contracts[_newPair] = value;
    }

    
    function addBurnAddress(address _wallet, bool value) public onlyOwner{
        burnAddresses[_wallet] = value;
    }


}
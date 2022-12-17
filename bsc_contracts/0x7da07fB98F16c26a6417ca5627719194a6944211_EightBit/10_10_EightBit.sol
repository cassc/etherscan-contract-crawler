//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./Cashier.sol";

pragma solidity ^0.8.17;

interface DexFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface DexRouter {
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

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable;
}


contract EightBit is ERC20, Ownable {
    using Address for address;

    struct Tax {
        uint256 marketingTax;
        uint256 devTax;
        uint256 lpTax;
        uint256 refTax;
        uint256 buybackTax;
    }
    
    // what % each one gets?
    struct taxShares{
        uint256 marketingShare;
        uint256 devShare;
        uint256 lpShare;
        uint256 refShare;
        uint256 buybackShare;
    }

    //pairToRouter returns the router address that belong to the pair address
    mapping(address=>address) public pairToRouter;

    //dexBuyTotalTaxes/dexSellTotalTaxes = total tax for each router, to reduce storage access, we store total tax in a mapping to only access it one time
    //during calculations  
    mapping(address=>uint256) public dexBuyTotalTaxes;
    mapping(address=>uint256) public dexSellTotalTaxes;

    //dexBuyTaxes/dexSellTaxes are different taxes for different routers
    mapping(address=>Tax) public dexBuyTaxes;
    mapping(address=>Tax) public dexSellTaxes; 

    //Transfer tax, since its not between pair and holders, we can not specify it to a router
    Tax public transferTax;
    uint256 public totalTransferTax = 5;

    //dexAccumolatedTaxes = total taxes that got accumulated in buys/sells/transfers for each dex (router)   
    mapping(address=>uint256) public dexAccumolatedTaxes;

    /**
     * tax share for each router, each router (Dex) accumolates its taxes seperately from otehr dexes, hence we also consider different tax distributions for
     * each one
     */
    mapping(address=>taxShares) public dexTaxShares;
    
    uint256 private constant _totalSupply = 1e8 * 1e18;

    /**
     * defaultRouter : default router that is used in the contract (pancakeswap v1 is choosed because it has the most volume on the bsc)
     * defaultPair : the default pancakeswap pair
     * isPair : checkign whether an address is a pair or not
     */
    DexRouter public defaultRouter;
    address public defaultPair;
    mapping(address=>bool) public isPair;
    
    /**
     * whitelisted => wallets are excluded from every limit
     * pairBuyTaxExcludes => wallets are excluded from buy taxes for a specifiec pair
     * pairSellTaxExcludes => wallets are excluded from sell taxes for a specifiec pair
     * transferTaxExcluded => wallets are excluded from transfer taxes ( no specifiec pair )
     * dividendExcluded => wallets are excluded from receiving rewards (BTC)
     * maxWalletExcludes => wallets are exluced from max wallet
     */
    mapping(address=>bool) public whitelisted;
    mapping(address=>mapping(address=>bool)) pairBuyTaxExcludes; 
    mapping(address=>mapping(address=>bool)) pairSellTaxExcludes; 
    mapping(address=>bool) public transferTaxExcludes; 
    mapping(address=>bool) public dividendExcludes;
    mapping(address=>bool) public maxWalletExcludes;

    //swapAndLiquifyEnabled => when set to true, auto liquidity works
    bool public swapAndLiquifyEnabled = true;

    //isSwapping => to lock the swapps when we are swapping taxes to ether
    bool public isSwapping = false;

    //max wallet, its set to 1% by default, and can not be less than 1%
    uint256 public maxWallet = (_totalSupply * 1) / 100;

    //trading status, its set to false by default, after enabling the trade can not be disabled
    bool public tradingStatus = false;

    //Wallets, taxes are sent to this wallets in ether shape using a low level call, we made sure that this wallets can not be a contract, so that they can not
    //revert receiving ether in their receive function
    address public MarketingWallet = 0x179a9CB9C80B0d05B131325090F00D8Ca5113679;
    address public devWallet = 0x9AB074d242acA64544Ebbe9212F6e8BadB6dC366;
    address public buyBackWallet = 0xb9309c0D8313eE46E9747309b6414390633666f3;

    //dividend tracker that is responsible for BTC reflectins, ether is instantly swapped to BTC after reachign the contract either throught the deposit functino
    //or receive()
    DividendDistributor public cashier;

    //processGas for dividend tracker to divide BTC reflections, this value can not be more than 750, 000
    uint256 public processGas;

    /**
     * antiDump => set to off by default
     * when antiDump is on, non-exlucded wallets are not able to sell/transfer more than antiDumpLimit, if they do, they can not sell/transfer for next 
     * (antiDumpCooldown) seconds
     */
    bool public antiDump;
    uint256 public antiDumpLimit;
    uint256 public antiDumpCoolDown;
    mapping(address=>uint256) lastTradeTime;

    constructor(address _rewardToken, address _router) ERC20("8BitEARN", "8Bit") {
        defaultRouter = DexRouter(_router);
        defaultPair = DexFactory(defaultRouter.factory())
            .createPair(address(this), defaultRouter.WETH());
        pairToRouter[defaultPair] = _router;
        isPair[defaultPair] = true;

        cashier = new DividendDistributor(_rewardToken, _router);

        whitelisted[msg.sender] = true;
        whitelisted[_router] = true;
        whitelisted[address(cashier)] = true;
        whitelisted[address(this)] = true;
        whitelisted[MarketingWallet] = true;
        whitelisted[devWallet] = true;
        whitelisted[buyBackWallet] = true;
        whitelisted[address(0)] = true;

        dividendExcludes[msg.sender] = true;
        dividendExcludes[defaultPair] = true;
        dividendExcludes[address(defaultRouter)] = true;
        dividendExcludes[address(cashier)] = true;
        dividendExcludes[address(0)] = true;
        dividendExcludes[MarketingWallet] = true;
        dividendExcludes[devWallet] = true;
        dividendExcludes[buyBackWallet] = true;

        dexBuyTaxes[address(defaultRouter)] = Tax(2, 2, 1, 4, 1);
        dexSellTaxes[address(defaultRouter)] = Tax(2, 2, 1, 4, 1);
        dexTaxShares[address(defaultRouter)] = taxShares(2, 2, 1, 4 ,1);
        dexBuyTotalTaxes[address(defaultRouter)] = 10;
        dexSellTotalTaxes[address(defaultRouter)] = 10;

        _mint(msg.sender, _totalSupply);
    }

    /**
     * functions used to set process gas 
     */
    function setProcessGas(uint256 gas) external onlyOwner{
        require(gas < 750000, "can not set process gas more than 750000");
        processGas = gas;
    }


    //addPair is used to add a new pair for the token, pair should be added alongside its router
    function addPair(address _pair, address _router) external onlyOwner{
       require(isPair[_pair] == false, "pair is already added");
       isPair[_pair] = true; 
       pairToRouter[_pair] = _router;
       dividendExcludes[_pair] = true;
       dividendExcludes[_router] = true;
    }


    //removePair is used to delete a pair from the token
    function removePair(address _pair) external onlyOwner{
        //transferring accumolated taxes to default router before deleting the pair
        require(isPair[_pair], "address is not a pair");
        address router = pairToRouter[_pair];
        if(address(router) != address(defaultRouter)){
            dexAccumolatedTaxes[address(defaultRouter)] += dexAccumolatedTaxes[router];
            dexAccumolatedTaxes[router] = 0;
        } 
        isPair[_pair] = false;
        pairToRouter[_pair] = address(0);
    }


    //used to set a default pair for our token, default pair is set to pancakeswap v2 by default 
    function setDefaultPair(address _pair, address _router) external onlyOwner{
        require(isPair[_pair], "address is not a pair, add it to pairs using addPair function");

        //transferring accumolated taxes to new router
        uint256 accTaxes = dexAccumolatedTaxes[address(defaultRouter)];
        dexAccumolatedTaxes[address(defaultRouter)] = 0;
        dexAccumolatedTaxes[_router] = accTaxes;

        //setting default pair
        defaultPair = _pair;
        defaultRouter = DexRouter(_router);
    }


    //used to set sell taxes for each pair
    function setPairSellTax(address _router, uint256 _refTax, uint256 _marTax, uint256 _devTax, uint256 _lpTax, uint256 _bbTax) external onlyOwner{
        Tax memory tax = dexSellTaxes[_router];
        tax.buybackTax = _bbTax;
        tax.lpTax = _lpTax;
        tax.devTax = _devTax;
        tax.marketingTax = _marTax;
        tax.refTax = _refTax;
        require(_refTax + _marTax + _devTax + _lpTax + _bbTax <= 10, "can not set taxes over 10%");
        dexSellTotalTaxes[_router] = _refTax + _marTax + _devTax + _lpTax + _bbTax;
        dexSellTaxes[_router] = tax;
    }
    
    //used to set buy taxes for each pair
    function setPairBuyTaxes(address _router, uint256 _refTax, uint256 _marTax, uint256 _devTax, uint256 _lpTax, uint256 _bbTax) external onlyOwner{
        Tax memory tax = dexBuyTaxes[_router];
        tax.buybackTax = _bbTax;
        tax.lpTax = _lpTax;
        tax.devTax = _devTax;
        tax.marketingTax = _marTax;
        tax.refTax = _refTax;
        require(_refTax + _marTax + _devTax + _lpTax + _bbTax <= 10, "can not set taxes over 10%");
        dexBuyTotalTaxes[_router] = _refTax + _marTax + _devTax + _lpTax + _bbTax;
        dexBuyTaxes[_router] = tax;
    }

    //used to set transfer taxes, transfer taxes are added to default router taxex
    function setTransferTaxes(uint256 _refTax, uint256 _marTax, uint256 _devTax, uint256 _lpTax, uint256 _bbTax) external onlyOwner{
        Tax memory tax = transferTax;
        tax.buybackTax = _bbTax;
        tax.lpTax = _lpTax;
        tax.devTax = _devTax;
        tax.marketingTax = _marTax;
        tax.refTax = _refTax;
        require(_refTax + _marTax + _devTax + _lpTax + _bbTax <= 10, "can not set taxes over 10%");
        transferTax = tax; 
    }

    //used to set tax distribution for each dex
    function setTaxShares(address _router, uint256 _refShare, uint256 _marShare, uint256 _devShare, uint256 _lpShare, uint256 _bbShare) external onlyOwner{
        uint256 shareSum = _refShare + _marShare + _devShare + _lpShare + _bbShare;
        require(shareSum == 100, "sum of taxes should be dividable by 100");
        dexTaxShares[_router].buybackShare = _bbShare;
        dexTaxShares[_router].devShare = _devShare;
        dexTaxShares[_router].marketingShare = _marShare;
        dexTaxShares[_router].refShare = _refShare;
        dexTaxShares[_router].lpShare = _lpShare;
    }

    //setting marketing wallet, but can not be a contract,
    function setMarketingWallet(address _newMarketing) external onlyOwner {
        require(_newMarketing.isContract() == false, "Cant set marketing wallet to a contract");
        require(MarketingWallet != address(0), "new marketing wallet can not be dead address!");
        MarketingWallet = _newMarketing;
    }

    //setting development wallet, but can not be a contract
    function setDevelopmentWallet(address _devWallet) external onlyOwner{
        require(_devWallet.isContract() == false, "Cant set developement wallet to a contract");
        devWallet = _devWallet;
    }

    //setting buyback wallet, but can not be a contract
    function setBuyBackWallet(address _buybackWallet) external onlyOwner{
        require(_buybackWallet.isContract() == false, "Cant set buyback wallet to a contract");
        buyBackWallet = _buybackWallet;
    }

    //setting max wallet, but can not be less than 0.5% of totalSupply
    function setMaxWallet(uint256 tokensCount) external onlyOwner {
        require(tokensCount * 1000 / totalSupply() >= 5, "can not set max wallet less than 0.5 of total supply");
        maxWallet = tokensCount;
    }
    
    //on and off autoliquidity
    function toggleSwapping() external onlyOwner {
        swapAndLiquifyEnabled = (swapAndLiquifyEnabled == true) ? false : true;
    }

    //whitelisting an address from every limit and tax
    function setWhitelistedStatus(address _holder, bool _status) external onlyOwner{
        whitelisted[_holder] = _status;
    }

    //whitelisting a wallet from sell taxes for a dex
    function excludeFromSellTaxes(address _router, address _holder, bool _status) external onlyOwner{
        pairSellTaxExcludes[_router][_holder] = _status;
    }

    //whitelisting a wallet from buy taxes for a dex
    function excludeFromBuyTaxes(address _router, address _holder, bool _status) external onlyOwner{
        pairBuyTaxExcludes[_router][_holder] = _status;
    }

    function excludeFromTransferTaxes(address _holder, bool _status) external onlyOwner{
       transferTaxExcludes[_holder] = _status; 
    }

    function excludeFromMaxWallet(address _holder, bool _status) external onlyOwner{
        maxWalletExcludes[_holder] = _status;
    }

    function setExcludedFromDividend(address _holder, bool _status) external onlyOwner{
        dividendExcludes[_holder] = _status;
    }

    function setAntiDumpStatus(bool status) external onlyOwner{
        antiDump = status;
    }
    
    function setAntiDumpLimit(uint256 newLimit) external onlyOwner{
        require(newLimit >= 250000 * 1e18, "can not set limit less than 250, 000 tokesn");
        antiDumpLimit = newLimit;
    }

    function setAntiDumpCooldown(uint256 coolDown) external onlyOwner{
        require(coolDown <= 86400, "can not set cooldown more than 24 hours");
        antiDumpCoolDown = coolDown;
    }

    //remaining addresses that are remaining untill _shareHodler receive its reflections in automatically manner
    function getRemainingToAutoClaim(address _shareHolder) external view returns(uint256){
        uint256 cindex = cashier.getCurrentIndex();
        uint256 hindex = cashier.getShareHolderIndex(_shareHolder);
        uint256 remaining = cindex > hindex ? cindex - hindex : hindex - cindex;
        return remaining;
    }

    //used to claim rewards
    function claimRewards(bool swapTo8Bit) public{
        cashier.claimDividend(msg.sender, swapTo8Bit);        
    }

    //getting pending rewards
    function getPendingRewards(address _holder) external view returns(uint256){
        return cashier.getUnpaidEarnings(_holder);
    }

    //getting claimed rewards
    function getClaimedRewards(address _holder) external view returns(uint256){
        return cashier.getClaimedDividends(_holder);
    }

    //enable trading, can not disable trades again
    function enableTrading() external onlyOwner{
        require(tradingStatus == false, "trading is already enabled");
        tradingStatus = true;
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
        bool isBuy = false;
        bool isSell = false;
        uint256 totalTax = totalTransferTax;
        address _router = address(defaultRouter);

        if (isPair[_to] == true) {
            _router = pairToRouter[_to];
            totalTax = dexSellTotalTaxes[_router];             
            if(pairSellTaxExcludes[_router][_from] == true) {
                totalTax = 0;
            }
            isSell = true;
        } else if (isPair[_from] == true) {
            _router = pairToRouter[_from];
            totalTax = dexBuyTotalTaxes[_router];
            if(pairBuyTaxExcludes[_router][_to] == true) {
                totalTax = 0;
            }
            isBuy = true;
        }else{
            if(transferTaxExcludes[_to] || transferTaxExcludes[_from]){
                return _amount;
            } 
        }
        if(!isSell){ //max wallet
           if(maxWalletExcludes[_to] == false) {
            require(balanceOf(_to) + _amount <= maxWallet, "can not hold more than max wallet");
           }   
        }
        if(!isBuy){
            if(antiDump){
                require(_amount < antiDumpLimit, "Anti Dump Limit");
                require(block.timestamp - lastTradeTime[_from] >= antiDumpCoolDown, "AntiDump Cooldown, please wait!");
            }
            lastTradeTime[_from] = block.timestamp;
        }
        uint256 tax = (_amount * totalTax) / 100;
        //taxes are added for each router seperatlty 
        if(_router != address(0)){
            dexAccumolatedTaxes[_router] += tax;
        } 
        if(tax > 0) {
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
        if (
            isPair[_to] &&
            !whitelisted[_from] &&
            !whitelisted[_to] &&
            !isSwapping
        ) {
            isSwapping = true;
            uint256 beforeBalane = balanceOf(address(this));
            manageTaxes(pairToRouter[_to]);
            isSwapping = false; 
            //used = amount of tokens that were used in manageTaxes function, we deduct this amount from dexAccumolatedTaxes
            uint256 used = beforeBalane > balanceOf(address(this))? beforeBalane - balanceOf(address(this)) : 0 ;
            dexAccumolatedTaxes[pairToRouter[_to]] -= used;
        }
        super._transfer(_from, _to, toTransfer);

        if(_from != address(cashier)){

            if(dividendExcludes[_from] == false) {
                try cashier.setShare(_from, balanceOf(_from)){} catch{}
            }

            if(dividendExcludes[_to] == false) {
                try cashier.setShare(_to, balanceOf(_to)){} catch  {}
            }

            try cashier.process(processGas) {} catch  {}
        }
    }


    function manageTaxes(address _router) internal {
        if(_router == address(0)) {
            return;
        }
        uint256 taxAmount = dexAccumolatedTaxes[_router];
        if(taxAmount > 0){
            taxShares memory dexTaxShare = dexTaxShares[_router];
            uint256 totalShares = 100;
            uint256 lpTokens = (taxAmount * dexTaxShare.lpShare) / totalShares;

            if(swapAndLiquifyEnabled && lpTokens > 0){
                swapAndLiquify(_router, lpTokens);
            } 
            totalShares -= dexTaxShare.lpShare;
            taxAmount -= lpTokens;

            if(taxAmount == 0 || totalShares == 0){
                return;
            }

            uint256 beforeBalance = address(this).balance;
            swapToETH(_router, taxAmount);
            uint256 received = address(this).balance - beforeBalance;
            
            if(received == 0){
                return;
            }

            //Marketing wallet
            if(dexTaxShare.marketingShare > 0){
                (bool success, ) = MarketingWallet.call{value : (received * dexTaxShare.marketingShare) / totalShares }(""); 
            }

            //dev wallet
            if(dexTaxShare.devShare > 0){
                (bool success, ) = devWallet.call{value : (received * dexTaxShare.devShare) / totalShares }(""); 
            }

            //buyBackWallet
            if(dexTaxShare.buybackShare > 0) {
                (bool success, ) = buyBackWallet.call{value : (received * dexTaxShare.buybackShare) / totalShares }(""); 
            }

            //reflections
            if(dexTaxShare.refShare > 0) {
                (bool success, ) = address(cashier).call{value : (received * dexTaxShare.refShare) / totalShares }(""); 
            }
        }
    }


    function swapAndLiquify(address _router, uint256 _amount) internal {
        uint256 firstHalf = _amount / 2;
        uint256 otherHalf = _amount - firstHalf;
        uint256 initialETHBalance = address(this).balance;

        //Swapping first half to ETH
        swapToETH(_router, firstHalf);
        uint256 received = address(this).balance - initialETHBalance;
        addLiquidity(_router, otherHalf, received);
    }


    function addLiquidity(address _router, uint256 tokenAmount, uint256 ETHAmount) private {
        _approve(address(this), address(_router), tokenAmount);
        DexRouter(_router).addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            address(0),
            block.timestamp
        );
    }
 

    function swapToETH(address _router, uint256 _amount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = DexRouter(_router).WETH();
        _approve(address(this), address(DexRouter(_router)), _amount);
        DexRouter(_router).swapExactTokensForETHSupportingFeeOnTransferTokens(
            _amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function withdrawStuckETH() external onlyOwner {
        (bool success, ) = address(msg.sender).call{value: address(this).balance}("");
        require(success, "transfering ETH failed");
    }


    function withdrawStuckTokens(address erc20_token) external onlyOwner {
        bool success = IERC20(erc20_token).transfer(
            msg.sender,
            IERC20(erc20_token).balanceOf(address(this))
        );
        require(success, "trasfering tokens failed!");
    }

    function burn(address _from, uint256 _amount, bool reduceSupply) external onlyOwner{
        require(allowance(_from, msg.sender) >= _amount, "you dont have enough allowance");
        if(reduceSupply){
            _burn(_from, _amount);
        }else{
            _transfer(_from, address(0), _amount);
        }
    }

    function getRouterBuyTaxes(address _router) public view returns(Tax memory){
        return dexBuyTaxes[_router]; 
    }

    function getRouterSellTaxes(address _router) public view returns(Tax memory){
        return dexSellTaxes[_router]; 
    }

    function isDexBuyTaxExcluded(address _wallet, address _router) public view returns(bool){
        return pairBuyTaxExcludes[_router][_wallet];
    }

    function isDexSellTaxExcluded(address _wallet, address _router) public view returns(bool){
        return pairSellTaxExcludes[_router][_wallet];
    }

    receive() external payable {}
}
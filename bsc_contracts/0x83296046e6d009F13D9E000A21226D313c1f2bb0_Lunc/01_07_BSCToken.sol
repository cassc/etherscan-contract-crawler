//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

pragma solidity ^0.8.8;

interface IDividendDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit(uint256 tokens) external;
    function process(uint256 gas) external;
}

interface IReward {
    function basicTransfer(address from, address to, uint256 amount) external;
}

contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;

    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    IReward RWRD;

    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;

    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    //SETMEUP, change this to 1 hour instead of 10mins
    uint256 public minPeriod = 30 * 60;
    uint256 public minDistribution = 50000 * 1e18;

    uint256 currentIndex;

    modifier onlyToken() {
        require(msg.sender == _token); _;
    }

    constructor () {
        _token = msg.sender;
        RWRD = IReward(msg.sender);
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if(shares[shareholder].amount > 0){
            distributeDividend(shareholder);
        }

        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        }else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function deposit(uint256 tokens) external override onlyToken {
        totalDividends = totalDividends.add(tokens);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(tokens).div(totalShares));
    }

    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = shareholders.length;

        if(shareholderCount == 0) { return; }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while(gasUsed < gas && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }

            if(shouldDistribute(shareholders[currentIndex])){
                distributeDividend(shareholders[currentIndex]);
            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }
    
    function shouldDistribute(address shareholder) internal view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp
                && getUnpaidEarnings(shareholder) > minDistribution;
    }

    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }

        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            RWRD.basicTransfer(address(this), shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }
    
    function claimDividend(address shareHolder) external {
        distributeDividend(shareHolder);
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
}

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

contract Lunc is ERC20, Ownable {
    struct Tax {
        uint256 marketingTax;
        uint256 liquidityTax;
        uint256 burnTax;
        uint256 rewardTax;
    }

    uint256 private constant _totalSupply = 1e8 * 1e18;
    mapping(address => uint256) private _balances;

    //Router
    DexRouter public pancakeRouter;
    address public pairAddress;

    //Taxes
    Tax public buyTaxes = Tax(4, 1, 2, 3);
    Tax public sellTaxes = Tax(4, 1, 2, 3);
    uint256 public totalBuyFees = 10;
    uint256 public totalSellFees = 10;

    //rewards
    DividendDistributor public distributor;
    uint256 distributorGas = 750000;

    //Whitelisting from taxes/maxwallet/txlimit/etc
    mapping(address => bool) private whitelisted;
    mapping (address => bool) isDividendExempt;

    //Swapping
    uint256 public swapTokensAtAmount = _totalSupply / 100000; //after 0.001% of total supply, swap them
    bool public swapAndLiquifyEnabled = true;
    bool public isSwapping = false;

    //Wallets
    address public marketingWallet = 0xfA71BCC8258008A825BF5b6F6ca0e7815B7E87FD;
    address public burnWallet = 0x9432983d6621383D4EC6336c1264BB7c6b556A84;

    //modifiers
    modifier onlyDistributor(){
        require(msg.sender == address(distributor), "Only Distributor");
        _;
    }

    constructor() ERC20("Lunc", "Luncp") {
        //0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0 test
        //0x10ED43C718714eb63d5aA57B78B54704E256024E Pancakeswap on mainnet
        pancakeRouter = DexRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        pairAddress = DexFactory(pancakeRouter.factory()).createPair(
            address(this),
            pancakeRouter.WETH()
        );

        distributor = new DividendDistributor();
        isDividendExempt[pairAddress] = true;
        isDividendExempt[msg.sender] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[address(distributor)] = true;
        isDividendExempt[burnWallet] = true;

        // do not whitelist liquidity pool, otherwise there wont be any taxes
        whitelisted[msg.sender] = true;
        whitelisted[address(pancakeRouter)] = true;
        whitelisted[address(distributor)] = true;
        whitelisted[address(this)] = true;
        _mint(msg.sender, _totalSupply);
    }

    function setMarketingWallet(address _newMarketing) external onlyOwner {
        require(_newMarketing != address(0), "new Marketing wallet can not be dead address!");
        marketingWallet = _newMarketing;
    }

    function setBurnWallet(address _newBurn) external onlyOwner{
        require(_newBurn != address(0), "new Marketing wallet can not be dead address!");
        burnWallet = _newBurn;
    }

    function setBuyFees(
        uint256 _burnTax,
        uint256 _lpTax,
        uint256 _marketingTax,
        uint256 _rewardTax
    ) external onlyOwner {
        buyTaxes.burnTax = _burnTax;
        buyTaxes.marketingTax = _marketingTax;
        buyTaxes.rewardTax = _rewardTax;
        buyTaxes.liquidityTax = _lpTax;
        totalBuyFees = _burnTax + _lpTax + _marketingTax + _rewardTax;
    }

    function setSellFees(
        uint256 _burnTax,
        uint256 _lpTax,
        uint256 _marketingTax,
        uint256 _rewardTax
    ) external onlyOwner {
        sellTaxes.burnTax = _burnTax;
        sellTaxes.marketingTax = _marketingTax;
        sellTaxes.rewardTax = _rewardTax;
        sellTaxes.liquidityTax = _lpTax;
        totalSellFees = _burnTax + _lpTax + _marketingTax + _rewardTax;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external onlyOwner {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }

    function setDistributorSettings(uint256 gas) external onlyOwner {
        distributorGas = gas;
    }

    function setIsDividendExempt(address holder, bool exempt) external onlyOwner {
        require(holder != address(this) && holder != pairAddress);
        isDividendExempt[holder] = exempt;
        if(exempt){
            distributor.setShare(holder, 0);
        }else{
            distributor.setShare(holder, balanceOf(holder));
        }
    }

    function setSwapTokensAtAmount(uint256 _newAmount) external onlyOwner {
        require(_newAmount > 0, "Lunc : Minimum swap amount must be greater than 0!");
        swapTokensAtAmount = _newAmount;
    }

    function toggleSwapping() external onlyOwner {
        swapAndLiquifyEnabled = (swapAndLiquifyEnabled == true) ? false : true;
    }

    function setWhitelistStatus(address _wallet, bool _status) external onlyOwner {
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
        uint256 totalTax = 0;
        if (_to == pairAddress) {
            totalTax = totalSellFees;
        } else if (_from == pairAddress) {
            totalTax = totalBuyFees;
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

        if(!isDividendExempt[_from]) {
            try distributor.setShare(_from, balanceOf(_from)) {} catch {}
        }

        if(!isDividendExempt[_to]) {
            try distributor.setShare(_to, balanceOf(_to)) {} catch {} 
        }

        try distributor.process(distributorGas) {} catch {}
    }

    //Using basic transfer to prevent double claim in _transfer function
    //This functin is only useable by distributor contract
    function basicTransfer(address from, address to, uint256 amount) external onlyDistributor {
        super._transfer(from, to, amount);
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
        uint256 totalBurnTax = bt.burnTax + st.burnTax;
        uint256 totalRewardTax = bt.rewardTax + st.rewardTax;
        
        //Calculating portions for each type of tax (marketing, burn, liquidity, rewards)
        uint256 lpPortion = (taxAmount * totalLPTax) / totalTaxes;
        uint256 makretingPortion = (taxAmount * totalMarketingTax) / totalTaxes;
        uint256 burnPortion = (taxAmount * totalBurnTax) / totalTaxes;
        uint256 rewardPortion = (taxAmount * totalRewardTax) / totalTaxes;

        //Add Liquidty taxes to liqudity pool
        if(lpPortion > 0){
            swapAndLiquify(lpPortion);
        }

        //Transfering Burning Fees to Burn wallet
        if(burnPortion > 0){
            super._transfer(address(this), burnWallet, burnPortion);
        }

        if(rewardPortion > 0){
            //Sending to dividend tracker for distribution
            super._transfer(address(this), address(distributor), rewardPortion);
            try distributor.deposit(rewardPortion) {} catch{}
        }
        
        //sending to marketing wallet
        if(makretingPortion > 0){
            swapToBNB(makretingPortion);
            (bool success, ) = marketingWallet.call{value : address(this).balance}("");
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
        path[1] = pancakeRouter.WETH();
        _approve(address(this), address(pancakeRouter), _amount);
        pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _amount,
            0, // accept any amount of BaseToken
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        _approve(address(this), address(pancakeRouter), tokenAmount);
        pancakeRouter.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
    }

    function updateDexRouter(address _newDex) external onlyOwner {
        pancakeRouter = DexRouter(_newDex);
        pairAddress = DexFactory(pancakeRouter.factory()).createPair(
            address(this),
            pancakeRouter.WETH()
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

    function getLuncUnpaidEarnings(address shareHolder) public view returns(uint256) {
        return distributor.getUnpaidEarnings(shareHolder);
    }

    function claimRewards() public {
        distributor.claimDividend(msg.sender);
    }

    function getDividendTrackerAddress() public view returns(address){
        return address(distributor);
    }

    receive() external payable {}
    
}
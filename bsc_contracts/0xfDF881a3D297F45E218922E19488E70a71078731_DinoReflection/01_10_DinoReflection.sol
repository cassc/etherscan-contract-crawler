// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IWETH.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IEarn.sol";
import "./libraries/SafeMath.sol";
import "./libraries/Auth.sol";
import "./libraries/Context.sol";
import "./libraries/Auth.sol";
contract DinoReflection is Context, Auth, IEarn {
    using SafeMath for uint256;

    address public tokenAddress;
    address public wethAddress;
    address public wbnbAddress;
    address public routerAddress;
    address public walletAutoDistributeAddress;
    address public defaultTokenReward;
    uint256 public lastResetAPR = 0;
    uint256 public loopInterest = 0;
    uint256 public APR = 0;    
    bool public isCountAPRAYREnable = true;
    uint256 public totalClaimWeekly = 0;
    uint256 public totalReceiveWeekBNB = 0;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalClaimed;
    }

    bool public isFeeAutoDistributeEnable = true;
    bool public isFeeEnable = false;
    uint256 public percentGasDistibute = 10;
    uint256 public percentGasMultiplier = 10000;


    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;

    mapping (address => Share) public shares;
    mapping (address => address) public holderPreferenceDistributeToToken;

    mapping (address => uint256) public totalDistributeToToken;
    uint256 public totalDistributeToWeth;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10**36;

    uint256 public currentIndex;
    uint256 public currentIndexMigrate;

    uint256 public minimumPeriod = 1 seconds;
    uint256 public minimumDistribution = 1 * (10**18);
    uint256 public minimumGasDistribution = 750000;
    uint256 public percentTaxDenominator = 10000;

    uint256 public indexCurrentShare = 0;

    mapping (address => bool) public isCanSetShares;

    event Deposit(address account, uint256 amount);
    event Distribute(address account, uint256 amount);
    event Migrate(address account, uint256 totalClaimed, uint256 totalExclude);

    modifier onlyToken() {
        require(_msgSender()==tokenAddress);
        _;
    }

    modifier onlyCanSetShare() {
        
        require(isCanSetShares[_msgSender()] || _msgSender() == tokenAddress,"Unauthorize for Set Share");
        _;
    }

    constructor(address _tokenAddress) Auth(msg.sender) {
        if(block.chainid == 97) routerAddress = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
        else if(block.chainid == 56) routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
        else routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

        tokenAddress = _tokenAddress;
        defaultTokenReward = _tokenAddress;

        IUniswapV2Router02 router = IUniswapV2Router02(routerAddress);
        wethAddress = router.WETH();
        wbnbAddress = router.WETH();
        walletAutoDistributeAddress = 0x0ab478ccB5effCc2510326257Ce0525cD91FcfB1;
        lastResetAPR = block.timestamp;

        isCanSetShares[tokenAddress] = true;
    }

    receive() external payable {
    }

    function setCanSetShares(address _address, bool _state) external onlyOwner {
        isCanSetShares[_address] = _state;
    }

    /** Set Shareholder */
    function setShare(address account,uint256 amount) external override onlyCanSetShare {
        if(account != address(this)){
            bool isShouldClaim = shouldClaim(account);
            if(shares[account].amount > 0 && isShouldClaim && amount > 0){
                // distributeDividendShareholder(account);
                _claimToToken(account,defaultTokenReward);
                // _claimToToken(account,tokenAddress);
            }
            // If amount greater than 0 and current share is zero, then add as shareholder
            // if amount is zero and current account is shareholder, then remove it

            if(amount > 0 && shares[account].amount == 0){
                addShareholder(account);
            }else if(amount == 0 && shares[account].amount > 0){
                removeShareholder(account);
            }

            totalShares = totalShares.sub(shares[account].amount).add(amount);
            shares[account].amount = amount;
            shares[account].totalExcluded = getCumulativeDividend(shares[account].amount);
        }
    }

    /** Migrate Reward Contract */
    function migrate(address rewardAddress, uint256 gas) external override onlyOwner {
        payable(rewardAddress).transfer(address(this).balance);
        IWETH(wethAddress).approve(rewardAddress,IWETH(wethAddress).balanceOf(address(this)));
        IWETH(wethAddress).transfer(rewardAddress,IWETH(wethAddress).balanceOf(address(this)));
        uint256 shareholderCount = shareholders.length;
        if(shareholderCount == 0) { return; }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;
        /** Looping Shares */
        while(gasUsed < gas && iterations < shareholderCount) {
            if(currentIndexMigrate >= shareholderCount){
                currentIndexMigrate = 0;
            }
            IEarn(rewardAddress).setMigration(
                shareholders[currentIndexMigrate],
                shares[shareholders[currentIndexMigrate]].totalExcluded,
                shares[shareholders[currentIndexMigrate]].totalClaimed
            );
            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndexMigrate++;
            iterations++;
            emit Migrate(shareholders[currentIndexMigrate],shares[shareholders[currentIndexMigrate]].totalClaimed,shares[shareholders[currentIndexMigrate]].totalExcluded);
        }
    }

    function deposit(uint256 loop) public payable override{
        uint256 amountDividen = msg.value;
        IWETH(wbnbAddress).deposit{value:msg.value}();
        totalDividends = totalDividends.add(amountDividen);
        if(totalShares > 0 && amountDividen > 0) dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amountDividen).div(totalShares));
        loopInterest = loopInterest.add(1);
        if(isCountAPRAYREnable) countAPRAPY(msg.value);
        if(loop > 0) batchClaimed(loop);
        emit Deposit(msg.sender,msg.value);
    }

     function countAPRAPY(uint256 amount) internal {
        if(block.timestamp.sub(lastResetAPR) >= 7 days) {
            totalReceiveWeekBNB = 0;
            totalClaimWeekly = 0;
            loopInterest = 1;
            lastResetAPR = block.timestamp;
        }

        totalReceiveWeekBNB = totalReceiveWeekBNB.add(amount);
        
        unchecked {
            uint year = 365;
            uint day = 7;
            APR = totalReceiveWeekBNB.mul(percentTaxDenominator).div(totalShares).mul(year.div(day)).mul(100).div(percentTaxDenominator);
        }
    }

    function getCurrentBalance() public view returns(uint256){
        // return address(this).balance;
        return IWETH(wbnbAddress).balanceOf(address(this));
    }

    /** Distributing Dividen */
    function distributeDividend() external override {
        // Distribute Dividen
        uint256 shareholderCount = shareholders.length;

        if(shareholderCount == 0) { return; }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while(gasUsed < minimumGasDistribution && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }

            if(shouldDistribute(shareholders[currentIndex])){
                distributeDividendShareholder(shareholders[currentIndex]);
            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;

        }
    }

    function distributeDividendShareholder(address account) internal {
        if(shouldClaim(account)) {
            if(holderPreferenceDistributeToToken[account] == address(0))
                _claimToToken(account,defaultTokenReward);
            else if(holderPreferenceDistributeToToken[account] == wethAddress)
                _claimToWeth(account);
            else
                _claimToToken(account,holderPreferenceDistributeToToken[account]);
        }
    }

    /** Check if account should distribute or not
    * 1. if shareholder last claim + minimum period < block.timestamp
    * 2. check if dividen greater than minimum distribution
    */
    function shouldDistribute(address account) internal view returns(bool) {
        return shareholderClaims[account] + minimumPeriod < block.timestamp
        && dividendOf(account) > minimumDistribution;
    }

    /** Get dividend of account */
    function dividendOf(address account) public view override returns (uint256) {

        if(shares[account].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividend(shares[account].amount);
        uint256 shareholderTotalExcluded = shares[account].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    /** Get cumulative dividend */
    function getCumulativeDividend(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    /** Claim to Dino */
    function claim(address account) external override{
        _claimToToken(account,defaultTokenReward);
    }

    /** Claim to other token */
    function claimTo(address account, address targetToken) external override {
        require(targetToken != wethAddress,"DinoReward: Wrong function if you want to claim to WETH");
        _claimToToken(account,targetToken);
    }

    /** Claim to weth */
    function claimToWeth(address account) external{
        _claimToWeth(account);
    }

    function getPairAddress(address token) public view returns(address){
        IUniswapV2Router02 router = IUniswapV2Router02(routerAddress);
        IUniswapV2Factory factory = IUniswapV2Factory(router.factory());
        address pair = factory.getPair(tokenAddress,token);
        return pair;
    }

    function shouldClaim(address account) internal view returns(bool) {
        if(getCurrentBalance() == 0) return false;
        if(shares[account].totalClaimed >= shares[account].totalExcluded) return false;
        return true;
    }

    function batchClaimed(uint256 loop) public {
        uint maxLoop = shareholders.length > loop ? loop : shareholders.length;
        uint startLoop = indexCurrentShare;
        for(uint i=0;i<maxLoop;i++){
            if(startLoop < shareholders.length){
                _claimToToken(shareholders[startLoop],defaultTokenReward);
                startLoop = startLoop+1;
                indexCurrentShare = indexCurrentShare+1;
            }
        }
        if(indexCurrentShare >= shareholders.length) indexCurrentShare = 0;
    }

    function claimFarmingReward(address pairAddress) external onlyCanSetShare {
        uint256 amount = IERC20(tokenAddress).balanceOf(pairAddress);
        if(shares[pairAddress].amount > 0){
            _claimToWeth(pairAddress);
        }
        // If amount greater than 0 and current share is zero, then add as shareholder
        // if amount is zero and current account is shareholder, then remove it

        if(amount > 0 && shares[pairAddress].amount == 0){
            addShareholder(pairAddress);
        }else if(amount == 0 && shares[pairAddress].amount > 0){
            removeShareholder(pairAddress);
        }

        totalShares = totalShares.sub(shares[pairAddress].amount).add(amount);
        shares[pairAddress].amount = amount;
        shares[pairAddress].totalExcluded = getCumulativeDividend(shares[pairAddress].amount);

    }

    function getFee(uint256 amountReward) internal pure returns(uint256){
        return amountReward;
    }

    /** execute claim to token */
    function _claimToToken(address account, address targetToken) internal {
        IUniswapV2Router02 router = IUniswapV2Router02(routerAddress);
        uint256 amount = dividendOf(account);
        uint256 amountAfterFee = getFee(amount);
        if(amountAfterFee > 0){
            
            if(targetToken == wbnbAddress){
                IWETH(wbnbAddress).withdraw(amountAfterFee);
                payable(account).transfer(amountAfterFee);
            } else {
                if(wbnbAddress != router.WETH()){
                    IWETH(wbnbAddress).withdraw(amountAfterFee);
                    IWETH(router.WETH()).deposit{value:amountAfterFee}();
                }
                address[] memory path = new address[](2);
                path[0] = router.WETH();
                path[1] = targetToken;
                IWETH(router.WETH()).approve(routerAddress,amountAfterFee);
                router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    amountAfterFee,
                    0,
                    path,
                    account,
                    block.timestamp
                );
            }
            totalDistributeToToken[targetToken] = totalDistributeToToken[targetToken].add(amount);
            setClaimed(account,amount);
        }
    }


    /** execute claim to weth */
    function _claimToWeth(address account) internal {
        uint256 amount = dividendOf(account);
        uint256 amountAfterFee = getFee(amount);
        if(address(this).balance >= amountAfterFee && amountAfterFee > 0){
            IWETH(wbnbAddress).withdraw(amountAfterFee);
            payable(account).transfer(amountAfterFee);
            totalDistributeToWeth = totalDistributeToWeth.add(amount);
            setClaimed(account,amount);
        }
    }

    /** get total claim token in weth */
    function claimTotalOf(address account) external override view returns(uint256){
        return shares[account].totalClaimed;
    }

    /** Set claimed state */
    function setClaimed(address account, uint256 amount) internal {
        shareholderClaims[account] = block.timestamp;
        shares[account].totalClaimed = shares[account].totalClaimed.add(amount);
        shares[account].totalExcluded = getCumulativeDividend(shares[account].amount);
        totalDistributed = totalDistributed.add(amount);
        // calculateDividenPerShare();
        emit Distribute(account, amount);
    }

    /** Adding share holder */
    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    /** Remove share holder */
    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }

    function setPreferenceDistributeTo(address account, address targetToken) external {
        holderPreferenceDistributeToToken[account] = targetToken;
    }

    function setWbnbAddress(address _wbnb) external onlyOwner {
        wbnbAddress = _wbnb;
    }

    function setDefaultReflectionToken(address _address) external onlyOwner {
        defaultTokenReward = _address;
    }

    /** Setting Minimum Distribution */
    function setMinimumDistribution(uint256 timePeriod,uint256 minAmount) external onlyOwner {
        minimumPeriod = timePeriod;
        minimumDistribution = minAmount;
    }

    /** Setting Minimum Distribution Reward */
    function setDistributionGas(uint256 gas) external onlyOwner {
        require(gas <= 750000);
        minimumGasDistribution = gas;
    }

    function getTokenFromContract(address _tokenAddress, address to, uint256 amount) external onlyOwner {
        try IERC20(_tokenAddress).approve(to, amount) {} catch {}
        try IERC20(_tokenAddress).transfer(to,amount) {} catch {}
    }

    /** Receive Migration */
    function setMigration(address account, uint256 totalExclude, uint256 totalClaimed) external override {
        IERC20 token = IERC20(tokenAddress);
        uint256 amountBalance = token.balanceOf(account);

        if(amountBalance > 0 && shares[account].amount == 0){
            shareholderIndexes[account] = shareholders.length;
            shareholders.push(account);

            totalShares = totalShares.sub(shares[account].amount).add(amountBalance);
            shares[account].amount = amountBalance;
            shares[account].totalExcluded = totalExclude;
            shares[account].totalClaimed = totalClaimed;
        }
    }

    function estimationReward(address account, address token) external view returns(uint[] memory amounts){
        uint256 dividend = dividendOf(account);
        IUniswapV2Router02 router = IUniswapV2Router02(routerAddress);
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = token;
        return router.getAmountsOut(dividend,path);
        
    }

    function setAutoDistribute(bool _isEnable, uint256 _percentGasDistribute) external onlyOwner {
        isFeeAutoDistributeEnable = _isEnable;
        percentGasDistibute = _percentGasDistribute;
    }

    function setWalletAutoDistributeAddress(address _address) external onlyOwner {
        walletAutoDistributeAddress = _address;
    }

    function setIsFeeEnable(bool _state) external onlyOwner {
        isFeeEnable = _state;
    }

    function setCountAPRAPY(bool state) external onlyOwner {
        isCountAPRAYREnable = state;
    }

    function setIndexCurrentShare(uint _index) external onlyOwner {
        indexCurrentShare = _index;
    } 
    
}
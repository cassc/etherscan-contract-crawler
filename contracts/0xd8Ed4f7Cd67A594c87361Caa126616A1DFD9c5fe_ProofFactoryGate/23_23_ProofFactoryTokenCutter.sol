// SPDX-License-Identifier: None
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../libraries/Ownable.sol";
import "../libraries/Context.sol";
import "../libraries/ProofFactoryFees.sol";
import "../interfaces/IFACTORY.sol";
import "../interfaces/IDividendDistributor.sol";
import "../interfaces/IUniswapV2Router02.sol";
import "../DividendDistributor.sol";
import "../interfaces/IProofFactoryTokenCutter.sol";

contract ProofFactoryTokenCutter is Context, IProofFactoryTokenCutter {

    //This token was created with PROOF, and audited by Solidity Finance — https://proofplatform.io/projects
    IDividendDistributor public dividendDistributor;
    uint256 distributorGas = 500000;

    mapping(address => bool) public userWhitelist;
    address[] public nftWhitelist;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint256 public whitelistEndTime;
    uint256 public whitelistPeriod;
    bool public whitelistMode = true;
    string private _name;
    string private _symbol;

    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO = 0x0000000000000000000000000000000000000000;
    address public proofAdmin;

    bool public restrictWhales = true;

    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isTxLimitExempt;
    mapping(address => bool) public isDividendExempt;

    uint256 public launchedAt;
    uint256 public revenueFee = 2;

    uint256 public reflectionFee;
    uint256 public lpFee;
    uint256 public devFee;

    uint256 public reflectionFeeOnSell;
    uint256 public lpFeeOnSell;
    uint256 public devFeeOnSell;

    uint256 public totalFee;
    uint256 public totalFeeIfSelling;

    IUniswapV2Router02 public router;
    address public pair;
    address public factory;
    address public tokenOwner;
    address payable public devWallet;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool public tradingStatus = true;

    uint256 public _maxTxAmount;
    uint256 public _walletMax;
    uint256 public swapThreshold;


    constructor() {
        factory = msg.sender;
    }

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    modifier onlyProofAdmin() {
        require(
            proofAdmin == _msgSender(),
            "not the proofAdmin"
        );
        _;
    }

    modifier onlyOwner() {
        require(tokenOwner == _msgSender(), "not the owner");
        _;
    }

    modifier onlyFactory() {
        require(factory == _msgSender(), "not the factory");
        _;
    }

    function setBasicData(
        BaseData memory _baseData,
        ProofFactoryFees.allFees memory fees
    ) external onlyFactory {
        _name = _baseData.tokenName;
        _symbol = _baseData.tokenSymbol;
        _totalSupply += _baseData.initialSupply;

        //Initial supply
        require(_baseData.percentToLP >= 70, "low lp");
        uint256 forLP = (_baseData.initialSupply * _baseData.percentToLP) / 100; //95%
        uint256 forOwner = _baseData.initialSupply - forLP; //5%

        _balances[msg.sender] += forLP;
        _balances[_baseData.owner] += forOwner;

        emit Transfer(address(0), msg.sender, forLP);
        emit Transfer(address(0), _baseData.owner, forOwner);

        _maxTxAmount = (_baseData.initialSupply * 5) / 1000;
        _walletMax = (_baseData.initialSupply * 1) / 100;
        swapThreshold = (_baseData.initialSupply * 5) / 4000;

        router = IUniswapV2Router02(_baseData.routerAddress);
        pair = IUniswapV2Factory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );

        _allowances[address(this)][address(router)] = type(uint256).max;

        dividendDistributor = new DividendDistributor(
            _baseData.routerAddress,
            _baseData.reflectionToken,
            address(this)
        );

        userWhitelist[address(this)] = true;
        userWhitelist[factory] = true;
        userWhitelist[pair] = true;
        userWhitelist[_baseData.owner] = true;
        userWhitelist[_baseData.initialProofAdmin] = true;
        userWhitelist[_baseData.routerAddress] = true;
        _addWhitelist(_baseData.whitelists);

        nftWhitelist = _baseData.nftWhitelist;

        isFeeExempt[address(this)] = true;
        isFeeExempt[factory] = true;

        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[_baseData.owner] = true;
        isTxLimitExempt[pair] = true;
        isTxLimitExempt[factory] = true;
        isTxLimitExempt[DEAD] = true;
        isTxLimitExempt[ZERO] = true;

        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;
        isDividendExempt[ZERO] = true;

        whitelistPeriod = _baseData.whitelistPeriod;

        reflectionFee = fees.reflectionFee;
        lpFee = fees.lpFee;
        devFee = fees.devFee;

        reflectionFeeOnSell = fees.reflectionFeeOnSell;
        lpFeeOnSell = fees.lpFeeOnSell;
        devFeeOnSell = fees.devFeeOnSell;

        _calcTotalFee();

        tokenOwner = _baseData.owner;
        devWallet = payable(_baseData.devWallet);
        proofAdmin = _baseData.initialProofAdmin;
    }

    //proofAdmin functions
    function updateProofAdmin(
        address newAdmin
    ) external virtual onlyProofAdmin {
        proofAdmin = newAdmin;
        userWhitelist[newAdmin] = true;
    }

    function updateWhitelistPeriod(
        uint256 _whitelistPeriod
    ) external onlyProofAdmin {
        whitelistPeriod = _whitelistPeriod;
        whitelistEndTime = launchedAt + (60 * _whitelistPeriod);
        whitelistMode = true;
    }

    //Factory functions
    function updateProofFactory(address newFactory) external onlyFactory {
        userWhitelist[newFactory] = true;
        isTxLimitExempt[newFactory] = true;
        isFeeExempt[newFactory] = true;	
        factory = newFactory;
    }

    function swapTradingStatus() external onlyFactory {
        tradingStatus = !tradingStatus;
    }

    function setLaunchedAt() external onlyFactory {
        require(launchedAt == 0, "already launched");
        launchedAt = block.timestamp;
        whitelistEndTime = block.timestamp + (60 * whitelistPeriod);
        whitelistMode = true;
    }

    function cancelToken() external onlyFactory {
        isFeeExempt[address(router)] = true;
        isTxLimitExempt[address(router)] = true;
        isTxLimitExempt[tokenOwner] = true;
        tradingStatus = true;
        restrictWhales = false;
        swapAndLiquifyEnabled = false;
    }

    //Owner functions
    function changeFees(
        uint256 initialReflectionFee,
        uint256 initialReflectionFeeOnSell,
        uint256 initialLpFee,
        uint256 initialLpFeeOnSell,
        uint256 initialDevFee,
        uint256 initialDevFeeOnSell
    ) external onlyOwner {
        reflectionFee = initialReflectionFee;
        lpFee = initialLpFee;
        devFee = initialDevFee;

        reflectionFeeOnSell = initialReflectionFeeOnSell;
        lpFeeOnSell = initialLpFeeOnSell;
        devFeeOnSell = initialDevFeeOnSell;

        _calcTotalFee();
    }

    function changeTxLimit(uint256 newLimit) external onlyOwner {
        _checkLimit(newLimit);
        _maxTxAmount = newLimit;
    }

    function changeWalletLimit(uint256 newLimit) external onlyOwner {
        _checkLimit(newLimit);
        _walletMax = newLimit;
    }

    function changeRestrictWhales(bool newValue) external onlyOwner {
        restrictWhales = newValue;
    }

    function changeIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function changeIsTxLimitExempt(
        address holder,
        bool exempt
    ) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }

    function changeDistributorGas(uint256 _distributorGas) external onlyOwner {
        distributorGas = _distributorGas;
    }

    function changeMinDistSettings(
        uint256 _minPeriod,
        uint256 _minDistLimit
    ) external onlyOwner {
        dividendDistributor.setMinPeriod(_minPeriod);
        dividendDistributor.setMinDistribution(_minDistLimit);
    }

    function reduceProofFee() external onlyOwner {
        require(revenueFee == 2, "!already reduced");
        _checkTimestamp72();

        revenueFee = 1;
        _calcTotalFee();
    }

    function adjustProofFee(uint256 _proofFee) external onlyProofAdmin {	
        require(launchedAt != 0, "!launched");	
        if (block.timestamp >= launchedAt + 72 hours) {	
            require(_proofFee <= 1);	
            revenueFee = _proofFee;	
            totalFee = devFee + lpFee + reflectionFee + revenueFee;	
            totalFeeIfSelling =	
                devFeeOnSell +	
                lpFeeOnSell +	
                reflectionFeeOnSell +	
                revenueFee;	
        } else {	
            require(_proofFee <= 2);	
            revenueFee = _proofFee;	
            totalFee = devFee + lpFee + reflectionFee + revenueFee;	
            totalFeeIfSelling =	
                devFeeOnSell +	
                lpFeeOnSell +	
                reflectionFeeOnSell +	
                revenueFee;	
        }	
    }

    function setDevWallet(address payable newDevWallet) external onlyOwner {
        devWallet = payable(newDevWallet);
    }

    function setOwnerWallet(address payable newOwnerWallet) external onlyOwner {
        tokenOwner = newOwnerWallet;
    }

    function changeSwapBackSettings(
        bool enableSwapBack,
        uint256 newSwapBackLimit
    ) external onlyOwner {
        swapAndLiquifyEnabled = enableSwapBack;
        swapThreshold = newSwapBackLimit;
    }

    function setDistributionCriteria(
        uint256 newMinPeriod_,
        uint256 newMinDistribution_
    ) external onlyOwner {
        dividendDistributor.setDistributionCriteria(
            newMinPeriod_,
            newMinDistribution_
        );
    }

    function getCirculatingSupply() external view returns (uint256) {
        return _totalSupply - balanceOf(DEAD) - balanceOf(ZERO);
    }

    function rewardTokenAddress() external view returns(address) {	
        return dividendDistributor.rewardTokenAddress();	
    }

    function isWhitelisted(address user) public view returns (bool) {
        return userWhitelist[user];
    }

    function holdsSupportedNFT(address user) public view returns (bool) {
        for (uint256 i = 0; i < nftWhitelist.length; i++) {
            if (IERC721(nftWhitelist[i]).balanceOf(user) > 0) {
                return true;
            }
        }
        return false;
    }

    function name() external view virtual override returns (string memory) {
        return _name;
    }

    function symbol() external view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() external view virtual override returns (uint8) {
        return 9;
    }

    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address to,
        uint256 amount
    ) external virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) external virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) external virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) external virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(
            currentAllowance >= subtractedValue,
            "Decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        require(tradingStatus, "!trading");
        
        if(whitelistMode) {
            if (block.timestamp >= whitelistEndTime ) {
                whitelistMode = false;
            } else {
                if (sender == pair) { //buy
                    require(isWhitelisted(recipient) || holdsSupportedNFT(recipient), "Not whitelisted");
                } else if (recipient == pair) { //sell
                    require(isWhitelisted(sender) || holdsSupportedNFT(sender), "Not whitelisted");
                } else { //transfer
                    require((isWhitelisted(sender) || holdsSupportedNFT(sender)) && (isWhitelisted(recipient) || holdsSupportedNFT(recipient)), "Not Whitelisted");
                }
            }
        }

        if (inSwapAndLiquify) {
            return _basicTransfer(sender, recipient, amount);
        }

        if (recipient == pair && restrictWhales) {	
            require(	
                amount <= _maxTxAmount ||	
                    (isTxLimitExempt[sender] && isTxLimitExempt[recipient]),	
                "Max TX"	
            );	
        }

        if (!isTxLimitExempt[recipient] && restrictWhales) {
            require(_balances[recipient] + amount <= _walletMax, "wallet");
        }

        if (
            sender != pair &&
            !inSwapAndLiquify &&
            swapAndLiquifyEnabled &&
            _balances[address(this)] >= swapThreshold
        ) {
            swapBack();
        }

        _balances[sender] = _balances[sender] - amount;
        uint256 finalAmount = amount;

        if (sender == pair || recipient == pair) {
            finalAmount = !isFeeExempt[sender] && !isFeeExempt[recipient]
                ? takeFee(sender, recipient, amount)
                : amount;
        }

        _balances[recipient] = _balances[recipient] + finalAmount;

        // Dividend tracker
        if (!isDividendExempt[sender]) {	
            try dividendDistributor.setShare(sender, _balances[sender]) {} catch {	
                emit DistributorFail();	
            }	
        }	
        if (!isDividendExempt[recipient]) {	
            try dividendDistributor.setShare(recipient, _balances[recipient]) {} catch {	
                    emit DistributorFail();	
                }	
        }	
        try dividendDistributor.process(distributorGas) {} catch {	
            emit DistributorFail();	
        }

        emit Transfer(sender, recipient, finalAmount);
        return true;
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "Insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function takeFee(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (uint256) {
        uint256 feeApplicable = pair == recipient
            ? totalFeeIfSelling
            : totalFee;
        uint256 feeAmount = (amount * feeApplicable) / 100;

        _balances[address(this)] = _balances[address(this)] + feeAmount;
        emit Transfer(sender, address(this), feeAmount);

        return amount - feeAmount;
    }

    function swapBack() internal lockTheSwap {
        uint256 tokensToLiquify = _balances[address(this)];
        uint256 amountToLiquify = (tokensToLiquify * lpFee) / totalFee / 2;
        uint256 amountToSwap = tokensToLiquify - amountToLiquify;

        if (amountToSwap == 0) return;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 amountETH = address(this).balance;
        uint256 amountEthLiquidity = (amountETH * lpFee) / totalFee / 2;

        if (amountToLiquify > 0) {
            router.addLiquidityETH{value: amountEthLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                0x000000000000000000000000000000000000dEaD,
                block.timestamp
            );
        }

        uint256 amountETHafterLP = address(this).balance;
        uint256 devBalance = (amountETHafterLP * devFee) / totalFee;
        uint256 revenueBalance = (amountETHafterLP * revenueFee) / totalFee;
        uint256 amountEthReflection = amountETHafterLP -
            devBalance -
            revenueBalance;

        if (amountETHafterLP > 0) {
            if (revenueBalance > 0) {
                uint256 revenueSplit = revenueBalance / 2;
                (bool sent, ) = payable(IFACTORY(factory).proofRevenueAddress()).call{value: revenueSplit}("");
                require(sent);
                (bool sent1, ) = payable(IFACTORY(factory).proofRewardPoolAddress()).call{value: revenueSplit}("");
                require(sent1);
            }
            if (devBalance > 0) {
                (bool sent, ) = devWallet.call{value: devBalance}("");
                require(sent);
            }
        }

        try dividendDistributor.deposit{value: amountEthReflection}() {} catch {
            emit DistributorFail();
        }
    }

    function _checkLimit(uint256 _newLimit) internal view {	
        require(launchedAt != 0, "!launched");	
        require(_newLimit >= (_totalSupply * 5) / 1000, "Min 0.5%");	
        require(_newLimit <= (_totalSupply * 3) / 100, "Max 3%");	
    }

    function _checkTimestamp72() internal view {	
        require(launchedAt != 0, "!launched");	
        require(block.timestamp >= launchedAt + 72 hours, "too soon");	
    }

    function _calcTotalFee() internal {
        totalFee = devFee + lpFee + reflectionFee + revenueFee;
        totalFeeIfSelling =
            devFeeOnSell +
            lpFeeOnSell +
            reflectionFeeOnSell +
            revenueFee;
        require(totalFee <= 12, "high fee");
        require(totalFeeIfSelling <= 17, "high fee");
    }

    function _addWhitelist(address[] memory _whitelists) internal {
        uint256 length = _whitelists.length;
        for (uint256 i = 0; i < length; i++) {
            userWhitelist[_whitelists[i]] = true;
        }
    }

    function addMoreToWhitelist(WhitelistAdd_ memory _WhitelistAdd) external onlyFactory {
        _addWhitelist(_WhitelistAdd.whitelists);
    }

    receive() external payable {}
}
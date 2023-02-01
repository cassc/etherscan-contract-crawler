// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/INineLives.sol";

contract NineFi is Ownable, INineLives {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping(address => bool) private excludedFromTransferLimits;
    mapping(address => bool) private excludedFromFees;
    mapping(address => bool) private excludedFromMaxWallet;
    mapping(address => uint256) private taxlessTokens;
    string private constant _name = '9 Lives Network';
    string private constant _symbol = 'NineFi';
    uint256 public constant InitialSupply= 1_00_000_000 * 10**_decimals;
    uint8 private constant _decimals = 18;

    uint16 public constant BASE_POINT = 1000;

    /// @notice Uniswap router handle.
    IUniswapV2Router02 private router;

    /// @notice The uniswap pair address for (pairToken, 9INE).
    /// @dev pairToken is USDC.
    address private pair;

    /// @notice burning wallet address.
    address constant burnerWallet = 0x84d4E5CB6E13b0f693692BBA1B4F1AB4Ef7EAe00;

    /// @notice owner drop wallet address.
    address constant ownerDropWallet = 0x99e5de9452ED0cd93D967040d123989B281b281b;

    /// @notice marketing wallet address.
    address private marketingWallet;

    /// @notice PROOF revenue wallet address.
    address private proofRevenueWallet;

    /// @notice PROOF rewards wallet address.
    address private proofRewardsWallet;

    /// @notice PROOF admin wallet address.
    address private proofAdminWallet;

    /// @notice Pair token address to add liquidity with 9INE.
    address public pairToken;

    /// @notice Threshold sell fee.
    uint16 immutable public MAX_SELL_FEE;

    /// @notice Threshold buy fee.
    uint16 immutable public MAX_BUY_FEE;

    uint16 constant private airdropPercent = 60;   // 6%
    uint16 constant private burnPercent = 70;   // 7%
    uint16 constant private ownerDropPercent = 70;   // 7%
    uint16 constant private maxWalletPercent = 10;  // 1%
    uint16 constant private transferLimitPercent = 5;   // 0.5%
    uint16 constant private thresholdSwapPercent = 1;   // 0.1%

    /// @notice NineFi launch time.
    uint256 public launchTime;

    /// @notice Jeet time limit.
    uint256 public jeetTime = 24 hours;

    /// @notice Sell fee informations
    /// @dev sellFees[0]: sell fee for users if they sell their token within jeetTime after purchasing.
    /// @dev sellFees[1]: sell fee for users if they sell their token after jeetTime after purchasing.
    FeeRate[] public sellFees;

    /// @notice Buy fee informations.
    FeeRate public buyFee;

    /// @notice Limit amount that a user can own.
    uint256 public maxWallet;

    /// @notice Limit amount for transfer.
    /// @dev 1% of Initial Supply.
    uint256 public transferLimit;

    /// @notice Fee for liquify contract has
    uint256 private _lpFee;
    /// @notice Fee for marketing contract has
    uint256 private _marketingFee;
    /// @notice Fee for proof contract has
    uint256 private _proofFee;
    
    /// @notice Tract to purchasing per user.
    mapping(address => PurchasingInfo) private userPurchaseInfos;

    uint256 public thresholdSwap;

    bool private txStarted;

    bool private inSwapAndLiquify;

    modifier onlyProofAdminWallet {
        require (msg.sender == proofAdminWallet, "Only Proof can change this");
        _;
    }

    constructor (
        Param memory _param
    ) {
        require (
            (_param.firstSellFee.LPFeeRate + 
            _param.firstSellFee.ProofFeeRate + 
            _param.firstSellFee.MarketingFeeRate) == 
            _param.firstSellFee.totalFeeRate, 
            "incorrect fee rate"
        );
        require (
            _param.afterSellFee.LPFeeRate + 
            _param.afterSellFee.ProofFeeRate + 
            _param.afterSellFee.MarketingFeeRate == 
            _param.afterSellFee.totalFeeRate, 
            "incorrect fee rate"
        );
        require (
            _param.buyFee.LPFeeRate +
            _param.buyFee.ProofFeeRate +
            _param.buyFee.MarketingFeeRate ==
            _param.buyFee.totalFeeRate
        );

        require (_param.wallets.length == 6, "incorrect wallets length");
        require (_param.proofRevenueWallet != address(0), "invalid proof revenue wallet address");
        require (_param.proofRewardsWallet != address(0), "invalid proof rewards wallet address");
        require (_param.marketingWallet != address(0), "invalid marketing wallet address");
        require (_param.pairToken != address(0), "invalid pair token address");
        require (_param.routerAddr != address(0), "invalid router address");

        sellFees.push(_param.firstSellFee);
        sellFees.push(_param.afterSellFee);
        buyFee = _param.buyFee;

        proofRevenueWallet = _param.proofRevenueWallet;
        proofRewardsWallet = _param.proofRewardsWallet;
        proofAdminWallet = _param.proofAdminWallet;
        marketingWallet = _param.marketingWallet;
        pairToken = _param.pairToken;
        router = IUniswapV2Router02(_param.routerAddr);
        pair = IUniswapV2Factory(router.factory()).createPair(
            pairToken,
            address(this)
        );

        // 6% fee for 6 wallets. 1% per wallet.
        uint256 provideAmount = InitialSupply * airdropPercent / BASE_POINT / 6;    // 1%
        for (uint256 i = 0; i < _param.wallets.length; i ++) {
            address wallet = _param.wallets[i];
            _balances[wallet] += provideAmount;
            taxlessTokens[wallet] +=  provideAmount;
            emit Transfer(address(0),wallet,provideAmount);
        }
        
        uint256 burnAmount = InitialSupply * burnPercent / BASE_POINT;   // 7%
        _balances[burnerWallet] += burnAmount;
        taxlessTokens[burnerWallet] +=  burnAmount;
        emit Transfer(address(0),burnerWallet,burnAmount);
        uint256 ownerDropAmount = InitialSupply * ownerDropPercent / BASE_POINT;   // 7%
        _balances[ownerDropWallet] += ownerDropAmount;
        taxlessTokens[ownerDropWallet] +=  ownerDropAmount;
        emit Transfer(address(0),ownerDropWallet,ownerDropAmount);
        uint256 ownerAmount = InitialSupply - provideAmount*6 - burnAmount - ownerDropAmount;
        _balances[msg.sender] += ownerAmount;
        taxlessTokens[msg.sender] +=  ownerAmount;
        emit Transfer(address(0),msg.sender,ownerAmount);

        MAX_SELL_FEE = _param.maxSellFee;
        MAX_BUY_FEE = _param.maxBuyFee;

        maxWallet = InitialSupply;
        transferLimit = InitialSupply;
        thresholdSwap = InitialSupply;

        excludedFromFees[address(this)] = true;
        excludedFromFees[0x93252861589D1a8E41028F01Fa638eC51990F950] = true;
        excludedFromFees[ownerDropWallet] = true;
        excludedFromTransferLimits[address(this)] = true;
        excludedFromMaxWallet[address(this)] = true;
        excludedFromMaxWallet[ownerDropWallet] = true;
        excludedFromMaxWallet[pair] = true;

        launchTime = block.timestamp;
    }

    /// @notice Use to update jeet time limit in seconds.
    /// @dev Only owner can call this function.
    /// @param jeetTime_ Set new time limit only in seconds.
    function updateJeetTimeLimit(
        uint256 jeetTime_
    ) external onlyOwner {
        require (jeetTime_ <= 86400, "Max time of 24 hours");
        jeetTime = jeetTime_;
    }

    function getLpTokenAddress() external view returns (address) {
        return pair;
    }

    /// @notice Update max wallet and transfer limits.
    /// @dev Only owner can call this function.
    /// @param maxWalletPercent_ Set new max wallet percent, 10 = 1%.
    /// @param transferLimitPercent_ Set new transfer limit percent, 5 = 0.5%.
    function updateLimits(
        uint16 maxWalletPercent_, 
        uint16 transferLimitPercent_
    ) external onlyOwner{
        require (maxWalletPercent_ >= 10, "Max must be above 1%");
        require (transferLimitPercent_ >= 5, "Max must be above 0.5%");
        maxWallet = InitialSupply * maxWalletPercent_ / BASE_POINT;    // 1%
        transferLimit = InitialSupply * transferLimitPercent_ / BASE_POINT;    // 0.5%
    }

    function addLiquidity() external onlyOwner {
        _addLiquidity();
    }

    /// @notice Update threshold of tokens to sell.
    /// @dev Only owner can call this function.
    /// @param _thresholdPercent The amount of tokens to sell, 1 = 0.1% of total supply.
    function setSwapThreshold (
        uint16 _thresholdPercent
    ) external onlyOwner {
        require (txStarted, "Tx not started");
        thresholdSwap = InitialSupply * _thresholdPercent / BASE_POINT;
    }

    /// @notice Update wallet to be excluded from fees.
    /// @dev Only owner can call this function.
    /// @param address_ The wallet address of who will be changed status.
    /// @param trueFalse New status, true = exlcuded.
    function setExcludedFromFees(
        address address_, 
        bool trueFalse
    ) external onlyOwner{
        excludedFromFees[address_] = trueFalse;
    }

    /// @notice Update wallet to be excluded from max wallet.
    /// @dev Only owner can call this function.
    /// @param address_ The wallet address of who will be changed status.
    /// @param trueFalse New status, true = exlcuded.
    function setExcludedFromMaxWallet(
        address address_, 
        bool trueFalse
    ) external onlyOwner{
        excludedFromMaxWallet[address_] = trueFalse;
    }

    /// @notice Update wallet to be excluded from transfer limits.
    /// @dev Only owner can call this function.
    /// @param address_ The wallet address of who will be changed status.
    /// @param trueFalse New status, true = exlcuded.
    function setExcludedFromTransferLimits(
        address address_, 
        bool trueFalse
    ) external onlyOwner{
        excludedFromTransferLimits[address_] = trueFalse;
    }

    /// @notice Start transaction.
    /// @dev Only owner can call this function.
    function startTx() external onlyOwner {
        maxWallet = InitialSupply * maxWalletPercent / BASE_POINT;    // 1%
        transferLimit = InitialSupply * transferLimitPercent / BASE_POINT;    // 0.5%
        thresholdSwap = InitialSupply * thresholdSwapPercent / BASE_POINT;   // 0.1%
        txStarted = true;
    }

    /// @notice Start transaction.
    /// @dev Only Proof admin can call this function.
    function ProofStartTx() external onlyProofAdminWallet {
        txStarted = true;
    }

    /// @notice Start transaction.
    /// @dev Only Proof admin can call this function.
    function ProofStopTx() external onlyProofAdminWallet {
        txStarted = false;
    }

    /// @notice Update sell fee rate.
    /// @dev Only owner can call this function.
    /// @param feeId_ The id of fee rate.
    /// @param feeRate_ New Fee Rate.
    function updateSellFee(
        uint8 feeId_,
        FeeRate memory feeRate_
    ) external onlyOwner {
        require (feeRate_.totalFeeRate <= MAX_SELL_FEE, "too high sell fee");
        require (feeRate_.ProofFeeRate == sellFees[feeId_].ProofFeeRate, "ProofFeeRate can not be changed");
        require (
            feeRate_.LPFeeRate + 
            feeRate_.ProofFeeRate + 
            feeRate_.MarketingFeeRate == 
            feeRate_.totalFeeRate, 
            "incorrect fee rate"
        );
        sellFees[feeId_] = feeRate_;
    }

    /// @notice Update buy fee rate.
    /// @dev Only owner can call this function.
    /// @param feeRate_ New fee rate.
    function updateBuyFee(
        FeeRate memory feeRate_
    ) external onlyOwner {
        require (feeRate_.totalFeeRate <= MAX_BUY_FEE, "too high buy fee");
        require (feeRate_.ProofFeeRate == buyFee.ProofFeeRate, "ProofFeeRate can not be changed");
        require (
            feeRate_.LPFeeRate + 
            feeRate_.ProofFeeRate + 
            feeRate_.MarketingFeeRate == 
            feeRate_.totalFeeRate, 
            "incorrect fee rate"
        );
        buyFee = feeRate_;
    }

    /// @notice Update proof revenue wallet address.
    /// @dev Only proof revenue wallet can call this function.
    /// @param proofRevenueWallet_ New proof revenue wallet address.
    function updateProofRevenueWallet(
        address proofRevenueWallet_
    ) external {
        require (msg.sender == proofRevenueWallet, "Only Proof can change this.");
        require (proofRevenueWallet_ != address(0), "can't be zero address");
        proofRevenueWallet = proofRevenueWallet_;
    }

    /// @notice Update proof rewards wallet address.
    /// @dev Only proof rewards wallet can call this function.
    /// @param proofRewardsWallet_ New proof rewards wallet address.
    function updateProofRewardsWallet(
        address proofRewardsWallet_
    ) external {
        require (msg.sender == proofRewardsWallet, "Only Proof can change this.");
        require (proofRewardsWallet_ != address(0), "can't be zero address");
        proofRewardsWallet = proofRewardsWallet_;
    }

    /// @notice Update proof admin wallet address.
    /// @dev Only proof admin wallet can call this function.
    /// @param proofAdminWallet_ New proof admin wallet address.
    function updateProofAdminWallet(
        address proofAdminWallet_
    ) external onlyProofAdminWallet {
        require (proofAdminWallet_ != address(0), "can't be zero address");
        proofAdminWallet = proofAdminWallet_;
    }

    /// @notice Update marketing wallet address.
    /// @dev Only owner can call this function.
    /// @param marketingWallet_ New marketing wallet address.
    function updateMarketingWallet(
        address marketingWallet_
    ) external onlyOwner {
        require (marketingWallet_ != address(0), "zero address");
        marketingWallet = marketingWallet_;
    }

    function name() external pure returns (string memory) {return _name;}
    function symbol() external pure returns (string memory) {return _symbol;}
    function decimals() external pure returns (uint8) {return _decimals;}
    function totalSupply() external pure returns (uint256) {return InitialSupply;}
    function balanceOf(address account) public view returns (uint256) {return _balances[account];}

    /// @inheritdoc IERC20
    function transfer(
        address recipient_, 
        uint256 amount_
    ) external override returns (bool) {
        _transfer(msg.sender, recipient_, amount_);
        return true;
    }

    /// @inheritdoc IERC20
    function allowance(
        address owner_, 
        address spender_
    ) external view override returns (uint256) {
        return _allowances[owner_][spender_];
    }

    /// @inheritdoc IERC20
    function approve(
        address spender_, 
        uint256 amount_
    ) external override returns (bool) {
        _approve(msg.sender, spender_, amount_);
        return true;
    }

    /// @inheritdoc IERC20
    function transferFrom(
        address sender_, 
        address recipient_, 
        uint256 amount_
    ) external override returns (bool) {
        uint256 currentAllowance = _allowances[sender_][msg.sender];
        require(currentAllowance >= amount_, "Transfer > allowance");
        _approve(sender_, msg.sender, currentAllowance - amount_);
        _transfer(sender_, recipient_, amount_);
        return true;
    }

    /// @notice Decrease proof fee.
    /// @dev It can be called after 72 hours after launch.
    /// @dev Only owner can call this function.
    function decreaseProofFeeWithSell() external onlyOwner {
        require (sellFees[1].ProofFeeRate > 1, "already decreased");
        require (block.timestamp - launchTime >= 72 hours, "too soon");
        sellFees[1].ProofFeeRate --;
    }

    /// @notice Decrease proof fee.
    /// @dev It can be called after 72 hours after launch.
    /// @dev Only owner can call this function.
    function decreaseProofFeeWithBuy() external onlyOwner {
        require (buyFee.ProofFeeRate > 1, "already decreased");
        require (block.timestamp - launchTime >= 72 hours, "too soon");
        buyFee.ProofFeeRate --;
    }

    function getAvailableTokenAmount(address user_) external view returns (uint256) {
        return _availableTransferAmount(user_);
    }

    receive() external payable {}

    /// @notice Transfer amount from sender to transfer.
    /// @dev If buy/sell, FeeRate will be applied.
    /// @param sender_ The address of sender.
    /// @param recipient_ The address of recipient.
    /// @param amount_ The amount of 9INE token to transfer.
    function _transfer(
        address sender_, 
        address recipient_,
        uint256 amount_
    ) internal {
        require (sender_ != address(0), "transfer from zero address");
        require (recipient_ != address(0), "transfer to zero address");
        require (amount_ > 0, "zero amount");
        require (excludedFromMaxWallet[recipient_] || _balances[recipient_] + amount_ <= maxWallet + (10*10**_decimals), "over max wallet");

        if (txStarted == false) {
            if (sender_ != owner() && recipient_ != owner()) {
                revert ("Tx not started");
            } else {    // this is for add liquidity at first.
                _feelessTransfer(sender_, recipient_, amount_, true);
                return;
            }
        }

        // Check if transfer amount is over transfer limit.
        if (
            !excludedFromTransferLimits[sender_] &&
            !excludedFromTransferLimits[recipient_] &&
            sender_ != pair
        ) {
            require(amount_ <= transferLimit + (1*10**_decimals),"Over max TXN");
        }

        if (sender_ != pair && recipient_ != pair) {    // not buy/sell, transfer without fee.
            _feelessTransfer(sender_, recipient_, amount_, false);
        } else {    // buy/sell, transfer with fee.
            if (
                excludedFromFees[sender_] == true || 
                excludedFromFees[recipient_] == true ||
                inSwapAndLiquify == true
            ) {
                _feelessTransfer(sender_, recipient_, amount_, true);
                return;
            } 
            _withFeeTransfer(sender_, recipient_, amount_);
        }
    }

    /// @notice Transfer without fee.
    /// @param sender_ The address of sender.
    /// @param recipient_ The address of recipient.
    /// @param amount_ The amount of 9INE token to transfer.
    /// @param excludeLimit_ If it's true, don't check it has enough available token amount.
    function _feelessTransfer(
        address sender_, 
        address recipient_, 
        uint256 amount_,
        bool excludeLimit_
    ) internal {
        uint256 senderBalance = _balances[sender_];
        require(senderBalance >= amount_, "Transfer exceeds balance");

        if (!excludeLimit_) {
            PurchasingInfo storage purchasingInfo = userPurchaseInfos[sender_];
            uint256 restAmount = amount_;
            if (taxlessTokens[sender_] >= amount_) {
                restAmount = 0;
                taxlessTokens[sender_] -= amount_;
            } else {
                restAmount = amount_ - taxlessTokens[sender_];
                taxlessTokens[sender_] = 0;
            }

            require (restAmount == 0 || purchasingInfo.purchaseId > 0, "not enough available balance");
            if (purchasingInfo.purchaseId > 0) {
                uint256 purchaseId = 0;
                uint256 curTime = block.timestamp;

                while(purchaseId < purchasingInfo.purchaseId && restAmount > 0) {
                    require((curTime - purchasingInfo.purchaseTime[purchaseId]) > jeetTime || restAmount == 0, "not enough available balance");
                    uint256 purchaseAmount = purchasingInfo.purchaseAmount[purchaseId];
                    if (purchaseAmount > 0) {
                        purchaseAmount = purchaseAmount > restAmount ? restAmount : purchaseAmount;
                        restAmount -= purchaseAmount;
                        purchasingInfo.purchaseAmount[purchaseId] -= purchaseAmount;
                    }
                    
                    purchaseId ++;
                }
            }
        }

        _balances[sender_] -= amount_;
        _balances[recipient_] += amount_;      
        taxlessTokens[recipient_] += amount_;
        if (excludeLimit_) {
            taxlessTokens[sender_] = taxlessTokens[sender_] >= amount_ ? taxlessTokens[sender_] - amount_ : 0;
        }
        emit Transfer(sender_,recipient_,amount_);
    }

    /// @notice Transfer with fee.
    /// @param sender_ The address of sender.
    /// @param recipient_ The address of recipient.
    /// @param amount_ The amount of 9INE token to transfer.
    function _withFeeTransfer(
        address sender_,
        address recipient_,
        uint256 amount_
    ) internal {
        uint256 totalFee = 0;
        uint256 recvAmount = 0;
        uint256 lpFee = 0;
        uint256 marketingFee = 0;
        uint256 proofFee = 0;

        require(_balances[sender_] >= amount_, "Transfer exceeds balance");

        if (sender_ == pair) {  // buy
            (totalFee, lpFee, marketingFee, proofFee, recvAmount) = _calcFeeRate(amount_, buyFee);
            PurchasingInfo storage purchaseInfo = userPurchaseInfos[recipient_];

            // add purcahse info to track.
            uint256 purchaseId = purchaseInfo.purchaseId;
            purchaseInfo.purchaseAmount[purchaseId] = recvAmount;
            purchaseInfo.purchaseTime[purchaseId] = block.timestamp;
            purchaseInfo.purchaseId ++;
        } else if (recipient_ == pair) {    // sell
            if (_balances[address(this)] >= thresholdSwap) {
                _addLiquidity();
            }
            (totalFee, lpFee, marketingFee, proofFee, recvAmount) = _getAmountWithSellFee(sender_, amount_);
        }

        _lpFee += lpFee;
        _marketingFee += marketingFee;
        _proofFee += proofFee;

        _balances[sender_] -= amount_;
        _balances[recipient_] += recvAmount;

        _balances[address(this)] += totalFee;
        
        emit Transfer(sender_,recipient_,amount_);
    }

    /// @notice The amount with fee.
    /// @dev Explain to a developer any extra details
    /// @param user_ The address of a user that will receive token.
    /// @param amount_ The origin amount of token to transfer.
    /// @return totalFee The total fee amount.
    /// @return lpFee The fee amount for liquify.
    /// @return marketingFee The fee amount for marketing.
    /// @return proofFee The fee amount for proof.
    /// @return recvAmount The real amount that recipient will be recieved.
    function _getAmountWithSellFee(
        address user_,
        uint256 amount_
    ) internal returns(
        uint256 totalFee,
        uint256 lpFee,
        uint256 marketingFee,
        uint256 proofFee,
        uint256 recvAmount
    ) {
        uint256[] memory amounts = new uint256[](2); // amounts[0]: jeetTax, amounts[1]: normalTax
        PurchasingInfo storage purchasingInfo = userPurchaseInfos[user_];

        if (taxlessTokens[user_] >= amount_) {
            amounts[1] = amount_;
            taxlessTokens[user_] -= amount_;
        } else {
            amounts[1] = taxlessTokens[user_];
            taxlessTokens[user_] = 0;
        }

        uint256 restAmount = amount_ - amounts[1];
        if (purchasingInfo.purchaseId > 0) {
            uint256 purchaseId = 0;
            uint256 curTime = block.timestamp;

            while(purchaseId < purchasingInfo.purchaseId && restAmount > 0) {
                bool isJeetTax = (curTime - purchasingInfo.purchaseTime[purchaseId]) <= jeetTime;
                uint256 purchaseAmount = purchasingInfo.purchaseAmount[purchaseId];
                if (purchaseAmount > 0) {
                    purchaseAmount = purchaseAmount > restAmount ? restAmount : purchaseAmount;
                    uint8 amountIndex = isJeetTax ? 0 : 1;
                    amounts[amountIndex] += purchaseAmount;
                    restAmount -= purchaseAmount;
                    purchasingInfo.purchaseAmount[purchaseId] -= purchaseAmount;
                }
                
                purchaseId ++;
            }
        }
        require (restAmount == 0, "not enough balance");
        
        uint256 totalFee_;
        uint256 lpFee_;
        uint256 marketingFee_;
        uint256 proofFee_;
        uint256 recvAmount_;
        if (amounts[0] > 0) {
            (totalFee_, lpFee_, marketingFee_, proofFee_, recvAmount_) = _calcFeeRate(amounts[0], sellFees[0]);
            lpFee += lpFee_;
            marketingFee += marketingFee_;
            proofFee += proofFee_;
            totalFee += totalFee_;
            recvAmount += recvAmount_;
        }

        if (amounts[1] > 0) {
            (totalFee_, lpFee_, marketingFee_, proofFee_, recvAmount_) = _calcFeeRate(amounts[1], sellFees[1]);
            lpFee += lpFee_;
            marketingFee += marketingFee_;
            proofFee += proofFee_;
            totalFee += totalFee_;
            recvAmount += recvAmount_;
        }
    }

    function _calcFeeRate(
        uint256 amount_,
        FeeRate memory feeRate_
    ) internal pure returns (
        uint256 totalFee,
        uint256 lpFee,
        uint256 marketingFee,
        uint256 proofFee,
        uint256 recvAmount
    ) {
        totalFee = amount_ * feeRate_.totalFeeRate / BASE_POINT;
        lpFee = amount_ * feeRate_.LPFeeRate / BASE_POINT;
        marketingFee = amount_ * feeRate_.MarketingFeeRate / BASE_POINT;
        proofFee = totalFee - lpFee - marketingFee;
        
        recvAmount = amount_ - totalFee;
    }

    function _transferUSDC(
        uint256 amount_,
        address recipient_
    ) internal {
        require (IERC20(pairToken).transfer(recipient_, amount_), "USDC transfer failed");
    }

    /// @notice Used for forcing a swap and liquify event
    /// @dev Only Owner can call.
    function unclog() 
        external onlyOwner {
        _addLiquidity();
    }

    function _addLiquidity() internal {
        inSwapAndLiquify = true;
        uint256 amount_ = _balances[address(this)];
        uint256 swapAmount = amount_ - _lpFee / 2;
        _swapToETH(swapAmount);

        // transfer USDC to marketing wallet and proofWallet.
        uint256 totalETHAmount = address(this).balance;
        uint256 totalUSDCAmount = _swapETHToUSDC(totalETHAmount);
        uint256 amountForMarketing = totalUSDCAmount * _marketingFee / swapAmount;
        uint256 amountForProof = totalUSDCAmount * _proofFee / swapAmount;
        _transferUSDC(amountForMarketing, marketingWallet);
        _transferUSDC(amountForProof / 2, proofRevenueWallet);
        _transferUSDC(amountForProof / 2, proofRewardsWallet);

        // swap and add liquidity
        uint256 pairTokenAmount = IERC20(pairToken).balanceOf(address(this));
        uint256 liquifyAmount = _balances[address(this)];
        _approve(address(this), address(router), liquifyAmount);
        IERC20(pairToken).approve(address(router), pairTokenAmount);
        router.addLiquidity(
            pairToken, 
            address(this), 
            pairTokenAmount, 
            liquifyAmount, 
            0, 
            0, 
            marketingWallet, 
            block.timestamp
        );
        _lpFee = 0;
        _marketingFee = 0;
        _proofFee = 0;
        inSwapAndLiquify = false;
    }

    function _swapETHToUSDC(uint256 swapAmount) internal returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = pairToken;

        uint256 balanceBefore = IERC20(pairToken).balanceOf(address(this));
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: swapAmount}(
            0, 
            path, 
            address(this), 
            block.timestamp
        );
        uint256 balanceAfter = IERC20(pairToken).balanceOf(address(this));
        return balanceAfter - balanceBefore;
    }

    function _swapToETH(uint256 amount_) internal {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = pairToken;
        path[2] = router.WETH();

        _approve(address(this), address(router), amount_);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount_, 
            0, 
            path, 
            address(this), 
            block.timestamp
        );
    }

    function _approve(
        address owner_, 
        address spender_, 
        uint256 amount_
    ) private {
        require(owner_ != address(0), "Approve from zero");
        require(spender_ != address(0), "Approve to zero");
        _allowances[owner_][spender_] = amount_;
        emit Approval(owner_, spender_, amount_);
    }

    function _availableTransferAmount(address user_) internal view returns (uint256 availableAmount) {
        availableAmount = taxlessTokens[user_];
        if (userPurchaseInfos[user_].purchaseId > 0) {
            uint256 purchaseId = 0;
            uint256 curTime = block.timestamp;
            
            while(purchaseId < userPurchaseInfos[user_].purchaseId) {
                if ((curTime - userPurchaseInfos[user_].purchaseTime[purchaseId]) > jeetTime) {
                    uint256 purchaseAmount = userPurchaseInfos[user_].purchaseAmount[purchaseId];
                    if (purchaseAmount > 0) {
                        availableAmount += purchaseAmount;
                    }
                } else {
                    break;
                }
                purchaseId ++;
            }
        }
    }
}
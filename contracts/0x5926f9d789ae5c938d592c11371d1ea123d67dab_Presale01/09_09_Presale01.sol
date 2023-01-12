// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import ".././Library/TransferHelper.sol";
import ".././Library/EnumerableSet.sol";
import ".././Library/SafeMath.sol";
import ".././Library/ReentrancyGuard.sol";
import ".././Library/Verify.sol";
import ".././Interface/IWETH.sol";
import ".././Interface/IPresaleSettings.sol";
import ".././Interface/IERC20.sol";

contract Presale01 is ReentrancyGuard, Verify {
    using SafeMath for uint256; 
    using EnumerableSet for EnumerableSet.AddressSet;
 
    struct PresaleInfo {
        address payable PRESALE_OWNER;
        IERC20 S_TOKEN; // sale token
        IERC20 B_TOKEN; // base token // usually WETH (ETH)
        uint256 TOKEN_PRICE; // 1 base token = ? s_tokens, fixed price
        uint256 MAX_SPEND_PER_BUYER; // maximum base token BUY amount per account
        uint256 AMOUNT; // the amount of presale tokens up for presale
        uint256 HARDCAP;
        uint256 SOFTCAP;
        uint256 START_TIME;
        uint256 END_TIME; 
        bool PRESALE_IN_ETH; // if this flag is true the presale is raising ETH, otherwise an ERC20 token such as DAI
    }
    
    struct PresaleFeeInfo {
        uint256 NOMOPOLY_BASE_FEE; // divided by 1000
        uint256 NOMOPOLY_TOKEN_FEE; // divided by 1000
        address payable BASE_FEE_ADDRESS;
        address payable TOKEN_FEE_ADDRESS;
    }
    
    struct PresaleStatus {
        bool WHITELIST_ONLY; // if set to true only whitelisted members may participate
        bool LP_GENERATION_COMPLETE; // final flag required to end a presale and enable withdrawls
        bool FORCE_FAILED; // set this flag to force fail the presale
        bool IS_OWNER_WITHDRAWN;
        bool IS_TRANSFERED_FEE;
        bool LIST_ON_UNISWAP;
        uint256 TOTAL_BASE_COLLECTED; // total base currency raised (usually ETH)
        uint256 TOTAL_TOKENS_SOLD; // total presale tokens sold
        uint256 TOTAL_TOKENS_WITHDRAWN; // total tokens withdrawn post successful presale
        uint256 TOTAL_BASE_WITHDRAWN; // total base tokens withdrawn on presale failure
        uint256 ROUND1_LENGTH; // in blocks
        uint256 NUM_BUYERS; // number of unique participants
    }

    struct BuyerInfo {
        uint256 baseDeposited; // total base token (usually ETH) deposited by user, can be withdrawn on presale failure
        uint256 tokensOwed; // num presale tokens a user is owed, can be withdrawn on presale success
        uint256 lastWithdraw; // day of the last withdrawing. If first time => = firstDistributionType
        uint256 totalTokenWithdraw; // number of tokens withdraw
        bool isWithdrawnBase; // is withdraw base
    }

    struct VestingPeriod {
        uint256 distributionTime; 
        uint256 unlockRate;
    }

    struct RefundInfo {
        bool isRefund;
        uint256 refundFee;
        uint256 refundTime;
    }

    event AlertPurchase (
        address indexed buyerAddress,
        uint256 baseAmount,
        uint256 tokenAmount
    );

    event AlertClaimSaleToken (
        address indexed buyerAddress,
        uint256 amountClaimSaleToken
    );

    event AlertRefundBaseTokens (
        address indexed buyerAddress,
        uint256 amountRefundBaseToken
    );

    event AlertWithdrawBaseTokens (
        address indexed buyerAddress,
        uint256 amountWithdrawBaseToken,
        uint256 timeWithdraw
    );

    event AlertOwnerWithdrawTokens (
        address indexed saleOwnerAddress,
        uint256 amountSaleToken,
        uint256 amountBaseToken
    );

    event AlertFinalize (
        address indexed saleOwnerAddress,
        uint256 amountSaleToken,
        uint256 amountBaseToken
    );

    event AlertAddNewVestingPeriod (
        address indexed saleOwnerAddress,
        uint256[] distributionTime,
        uint256[] unlockrate
    );
    
    PresaleInfo public PRESALE_INFO;
    PresaleFeeInfo public PRESALE_FEE_INFO;
    PresaleStatus public STATUS;
    address public PRESALE_GENERATOR;
    IPresaleSettings public PRESALE_SETTINGS;
    IWETH public WETH;
    mapping(address => BuyerInfo) public BUYERS;
    uint256 public TOTAL_FEE;
    uint256 public PERCENT_FEE;
    VestingPeriod[] private LIST_VESTING_PERIOD;
    mapping(address => uint256) public USER_FEES; 
    uint256 public TOTAL_TOKENS_REFUNDED;
    uint256 public TOTAL_FEES_REFUNDED;
    RefundInfo public REFUND_INFO;
    mapping(address => bool) public BUYER_REFUND;
    bool public PAUSE;

    modifier onlyPresaleOwner() {
        require(PRESALE_INFO.PRESALE_OWNER == msg.sender, "NOT PRE-SALE OWNER.");
        _;
    }

    modifier declineWhenTheSaleStops(){
        require(PAUSE == false, "PRE-SALE NOT YET DURING EXECUTION.");
        _;
    }
    
    constructor(address _presaleGenerator, address _wethAddress, address _presaleSettings) public payable {
        PRESALE_GENERATOR = _presaleGenerator;
        WETH = IWETH(_wethAddress);
        PRESALE_SETTINGS = IPresaleSettings(_presaleSettings);
    }

    function init1 (
        address payable _presaleOwner, 
        uint256 _amount,
        uint256 _tokenPrice, 
        uint256 _maxEthPerBuyer, 
        uint256 _hardcap, 
        uint256 _softcap,
        uint256 _startTime,
        uint256 _endTime
      ) external {
        require(msg.sender == PRESALE_GENERATOR, "FORBIDDEN.");
        PRESALE_INFO.PRESALE_OWNER = _presaleOwner;
        PRESALE_INFO.AMOUNT = _amount;
        PRESALE_INFO.TOKEN_PRICE = _tokenPrice;
        PRESALE_INFO.MAX_SPEND_PER_BUYER = _maxEthPerBuyer;
        PRESALE_INFO.HARDCAP = _hardcap;
        PRESALE_INFO.SOFTCAP = _softcap;
        PRESALE_INFO.START_TIME = _startTime;
        PRESALE_INFO.END_TIME = _endTime;
    }
    
    function init2 (
        IERC20 _baseToken,
        IERC20 _presaleToken,
        uint256 _unicryptBaseFee,
        uint256 _unicryptTokenFee,
        address payable _baseFeeAddress,
        address payable _tokenFeeAddress
      ) external {
        require(msg.sender == PRESALE_GENERATOR, "FORBIDDEN.");
        PRESALE_INFO.PRESALE_IN_ETH = address(_baseToken) == address(WETH);
        PRESALE_INFO.S_TOKEN = _presaleToken;
        PRESALE_INFO.B_TOKEN = _baseToken;
        PRESALE_FEE_INFO.NOMOPOLY_BASE_FEE = _unicryptBaseFee;
        PRESALE_FEE_INFO.NOMOPOLY_TOKEN_FEE = _unicryptTokenFee;
        PRESALE_FEE_INFO.BASE_FEE_ADDRESS = _baseFeeAddress;
        PRESALE_FEE_INFO.TOKEN_FEE_ADDRESS = _tokenFeeAddress;
    }

    function init3(
        bool is_white_list,
        address payable _operator,
        uint256 _percentFee,
        uint256[] memory _distributionTime,
        uint256[] memory _unlockRate,
        bool _isRefund,
        uint256[] memory _refundInfo,
        address _adminOperator
    ) external {
        require(msg.sender == PRESALE_GENERATOR, "FORBIDDEN.");
        require(_distributionTime.length == _unlockRate.length,"ARRAY MUST BE SAME LENGTH.");
        STATUS.WHITELIST_ONLY = is_white_list;
        updateOperator(_operator, true);
        PERCENT_FEE = _percentFee;
        for(uint i = 0 ; i < _distributionTime.length ; i++) {
            VestingPeriod memory newVestingPeriod;
            newVestingPeriod.distributionTime = _distributionTime[i];
            newVestingPeriod.unlockRate = _unlockRate[i];
            LIST_VESTING_PERIOD.push(newVestingPeriod);
        }   
        REFUND_INFO.isRefund = _isRefund;
        REFUND_INFO.refundFee = _refundInfo[0];
        REFUND_INFO.refundTime = _refundInfo[1];
        updateOperator(_adminOperator, true);
    }    
    
    function presaleStatus() public view returns (uint256) {
        if (STATUS.FORCE_FAILED) {
          return 3; // FAILED - force fail
        }
        if ((block.timestamp > PRESALE_INFO.END_TIME) && (STATUS.TOTAL_BASE_COLLECTED < PRESALE_INFO.SOFTCAP)) {
          return 3; // FAILED - softcap not met by end block
        }
        if (STATUS.TOTAL_BASE_COLLECTED >= PRESALE_INFO.HARDCAP) {
          return 2; // SUCCESS - hardcap met
        }
        if ((block.timestamp > PRESALE_INFO.END_TIME) && (STATUS.TOTAL_BASE_COLLECTED >= PRESALE_INFO.SOFTCAP)) {
          return 2; // SUCCESS - endblock and soft cap reached
        }
        if ((block.timestamp >= PRESALE_INFO.START_TIME) && (block.timestamp <= PRESALE_INFO.END_TIME)) {
          return 1; // ACTIVE - deposits enabled
        }
        return 0; // QUED - awaiting start block
    }

    function purchase(uint256 _amount, string memory _message, uint8 _v, bytes32 _r, bytes32 _s) 
        external 
        payable 
        nonReentrant 
        verifySignature(_message, _v, _r, _s)
        rejectDoubleMessage(_message)
        declineWhenTheSaleStops
    {
        VERIFY_MESSAGE[_message] = true;
        require(presaleStatus() == 1, "NOT ACTIVE."); // ACTIVE
        BuyerInfo storage buyer = BUYERS[msg.sender];
        uint256 amount_in = PRESALE_INFO.PRESALE_IN_ETH ? msg.value : _amount;
        uint256 real_amount_in = amount_in;
        uint256 fee = 0;
        
        if (!STATUS.WHITELIST_ONLY) {
            real_amount_in = real_amount_in * (1000 - PERCENT_FEE)/ 1000;
            fee = amount_in - real_amount_in;
        }

        uint256 allowance = PRESALE_INFO.MAX_SPEND_PER_BUYER - buyer.baseDeposited;
        uint256 remaining = PRESALE_INFO.HARDCAP - STATUS.TOTAL_BASE_COLLECTED;
        allowance = allowance > remaining ? remaining : allowance;
        if (real_amount_in > allowance) {
            real_amount_in = allowance;
        }
        uint256 tokensSold = (real_amount_in * PRESALE_INFO.TOKEN_PRICE) / (10**uint256(PRESALE_INFO.B_TOKEN.decimals()));
        require(tokensSold > 0, "ZERO TOKENS.");
        if (buyer.baseDeposited == 0) {
            STATUS.NUM_BUYERS++;
        }
        buyer.baseDeposited += real_amount_in + fee;
        buyer.tokensOwed += tokensSold;
        STATUS.TOTAL_BASE_COLLECTED += real_amount_in;
        STATUS.TOTAL_TOKENS_SOLD += tokensSold;
        USER_FEES[msg.sender] += fee;
        TOTAL_FEE += fee;

        // return unused ETH
        if (PRESALE_INFO.PRESALE_IN_ETH && real_amount_in + fee < msg.value) {
            payable(msg.sender).transfer(msg.value - real_amount_in - fee);
        }
        // deduct non ETH token from user
        if (!PRESALE_INFO.PRESALE_IN_ETH) {
            TransferHelper.safeTransferFrom(
                address(PRESALE_INFO.B_TOKEN),
                msg.sender,
                address(this),
                real_amount_in + fee
            );
        }
        
        emit AlertPurchase(
            msg.sender,
            real_amount_in + fee,
            tokensSold
        );
    }
    
    function userClaimSaleTokens() external nonReentrant declineWhenTheSaleStops {
        require(presaleStatus() == 2, "NOT SUCCESS"); 

        require(
            STATUS.TOTAL_TOKENS_SOLD - STATUS.TOTAL_TOKENS_WITHDRAWN > 0,
            "ALL TOKEN HAS BEEN WITHDRAWN."
        );

        BuyerInfo storage buyer = BUYERS[msg.sender];
        require(!buyer.isWithdrawnBase, "NOTHING TO CLAIM.");
        uint256 rateWithdrawAfter;
        uint256 currentTime = block.timestamp;
        uint256 tokensOwed = buyer.tokensOwed;

        for(uint i = 0 ; i < LIST_VESTING_PERIOD.length ; i++) {
            if(currentTime >= LIST_VESTING_PERIOD[i].distributionTime &&
                buyer.lastWithdraw < LIST_VESTING_PERIOD[i].distributionTime
            ){
                rateWithdrawAfter += LIST_VESTING_PERIOD[i].unlockRate;
            }
        }
        require(
            tokensOwed > 0, 
            "TOKEN OWNER MUST BE GREAT MORE THEN ZERO."
        );

        require(
            rateWithdrawAfter > 0,
            "USER WITHDRAW ALL TOKEN SUCCESS."
        );

        buyer.lastWithdraw = currentTime;
        uint256 amountWithdraw = (tokensOwed * rateWithdrawAfter) / 1000; 

        if (buyer.totalTokenWithdraw + amountWithdraw > buyer.tokensOwed) {
            amountWithdraw = buyer.tokensOwed - buyer.totalTokenWithdraw;
        }

        STATUS.TOTAL_TOKENS_WITHDRAWN += amountWithdraw;
        buyer.totalTokenWithdraw += amountWithdraw; 
        TransferHelper.safeTransfer(
            address(PRESALE_INFO.S_TOKEN),
            msg.sender,
            amountWithdraw
        );

        emit AlertClaimSaleToken(
            msg.sender,
            amountWithdraw
        );
    }

    function userRefundBaseTokens() external nonReentrant declineWhenTheSaleStops {
        require(REFUND_INFO.isRefund, "CANNOT REFUND.");
        require(presaleStatus() == 2, "NOT SUCCESS."); 
        require(REFUND_INFO.refundTime < block.timestamp, "NOT TIME TO REFUND BASE TOKEN.");

        BuyerInfo storage buyer = BUYERS[msg.sender];
        require(!BUYER_REFUND[msg.sender], "NOTHING TO REFUND.");
        require(buyer.totalTokenWithdraw == 0, "CANNOT REFUND.");

        uint256 whitelistDeposited = buyer.baseDeposited - (USER_FEES[msg.sender] * 1000) / PERCENT_FEE;
        uint256 refundAmount = (whitelistDeposited * (1000 - REFUND_INFO.refundFee)) / 1000;
        require(refundAmount > 0, "NOTHING TO REFUND.");

        TOTAL_TOKENS_REFUNDED += refundAmount;
        uint256 tokensRefunded = (whitelistDeposited * PRESALE_INFO.TOKEN_PRICE) / (10**uint256(PRESALE_INFO.B_TOKEN.decimals()));
        buyer.baseDeposited -= whitelistDeposited;
        buyer.tokensOwed -= tokensRefunded;

        TransferHelper.safeTransferBaseToken(
            address(PRESALE_INFO.B_TOKEN),
            payable(msg.sender),
            refundAmount,
            !PRESALE_INFO.PRESALE_IN_ETH
        );        

        BUYER_REFUND[msg.sender] = true;

        emit AlertRefundBaseTokens(
            msg.sender,
            refundAmount
        );
    }
    
    function userWithdrawBaseTokens() external nonReentrant declineWhenTheSaleStops {
        require(presaleStatus() == 3, "NOT FAILED."); // FAILED
        BuyerInfo storage buyer = BUYERS[msg.sender];
        require(!buyer.isWithdrawnBase, "NOTHING TO REFUND.");
        require(buyer.baseDeposited > 0, "INVALID BASE DEPOSITED.");
        STATUS.TOTAL_BASE_WITHDRAWN += buyer.baseDeposited;
        

        TransferHelper.safeTransferBaseToken(
            address(PRESALE_INFO.B_TOKEN),
            payable(msg.sender),
            buyer.baseDeposited,
            !PRESALE_INFO.PRESALE_IN_ETH
        );
        buyer.isWithdrawnBase = true;

        emit AlertWithdrawBaseTokens(
            msg.sender,
            buyer.baseDeposited,
            block.timestamp
        );
    }

    // on presale failure
    // allows the owner to withdraw the tokens they sent for presale & initial liquidity
    function ownerWithdrawTokensWhenFailed() external onlyPresaleOwner {
        require(!STATUS.IS_OWNER_WITHDRAWN, "GENERATION COMPLETE.");
        require(presaleStatus() == 3, "SALE FAILED."); // FAILED
        uint256 balanceSaleToken = PRESALE_INFO.S_TOKEN.balanceOf(address(this));
        uint256 balanceBaseToken = PRESALE_INFO.B_TOKEN.balanceOf(address(this));

        TransferHelper.safeTransfer(
            address(PRESALE_INFO.S_TOKEN), 
            PRESALE_INFO.PRESALE_OWNER, 
            PRESALE_INFO.S_TOKEN.balanceOf(address(this))
        );

        TransferHelper.safeTransferBaseToken(
            address(PRESALE_INFO.B_TOKEN),
            PRESALE_INFO.PRESALE_OWNER,
            PRESALE_INFO.B_TOKEN.balanceOf(address(this)),
            !PRESALE_INFO.PRESALE_IN_ETH
        );
        
        STATUS.IS_OWNER_WITHDRAWN = true;

        emit AlertOwnerWithdrawTokens(
            msg.sender,
            balanceSaleToken,
            balanceBaseToken
        );
    }

    function ownerWithdrawTokensWhenSuccess() external nonReentrant onlyPresaleOwner {
        require(!STATUS.IS_OWNER_WITHDRAWN, "GENERATION COMPLETE.");
        require(presaleStatus() == 2, "NOT SUCCESS."); // SUCCESS
        uint256 remainingSBalance = PRESALE_INFO.S_TOKEN.balanceOf(address(this)) + STATUS.TOTAL_TOKENS_WITHDRAWN - STATUS.TOTAL_TOKENS_SOLD;
        uint256 remainingBaseBalance = PRESALE_INFO.PRESALE_IN_ETH ? address(this).balance : PRESALE_INFO.B_TOKEN.balanceOf(address(this));

        if (remainingSBalance > 0) {
            TransferHelper.safeTransfer(
                address(PRESALE_INFO.S_TOKEN),
                PRESALE_INFO.PRESALE_OWNER,
                remainingSBalance
            );
        }

        TransferHelper.safeTransferBaseToken(
            address(PRESALE_INFO.B_TOKEN),
            PRESALE_INFO.PRESALE_OWNER,
            remainingBaseBalance,
            !PRESALE_INFO.PRESALE_IN_ETH
        );
        
        STATUS.IS_OWNER_WITHDRAWN = true;

        emit AlertOwnerWithdrawTokens(
            msg.sender,
            remainingSBalance,
            remainingBaseBalance
        );
    }

    function finalize() external onlyPresaleOwner declineWhenTheSaleStops {
        uint256 remainingBBalance;
        if (!PRESALE_INFO.PRESALE_IN_ETH) {
            remainingBBalance = PRESALE_INFO.B_TOKEN.balanceOf(
                address(this)
            );
        } else {
            remainingBBalance = address(this).balance;
        }
        if(remainingBBalance > 0) {
            TransferHelper.safeTransferBaseToken(
                address(PRESALE_INFO.B_TOKEN),
                PRESALE_FEE_INFO.BASE_FEE_ADDRESS,
                remainingBBalance,
                !PRESALE_INFO.PRESALE_IN_ETH
            );
        }

        uint256 remainingSBalance = PRESALE_INFO.S_TOKEN.balanceOf(
            address(this)
        );
        if(remainingSBalance > 0) {
            TransferHelper.safeTransfer(
                address(PRESALE_INFO.S_TOKEN),
                PRESALE_FEE_INFO.BASE_FEE_ADDRESS,
                remainingSBalance
            );
        }
        selfdestruct(PRESALE_FEE_INFO.BASE_FEE_ADDRESS);

        emit AlertFinalize(
            msg.sender,
            remainingSBalance,
            remainingBBalance
        );
    }

    function presaleCancel() external onlyOperator declineWhenTheSaleStops{
        STATUS.FORCE_FAILED = true;
    }
    
    function updateBlocks(uint256 _startTime, uint256 _endTime) external onlyOperator declineWhenTheSaleStops{
        require(
            PRESALE_INFO.START_TIME > block.timestamp,
            "INVALID START BLOCK."
        );
        PRESALE_INFO.START_TIME = _startTime;
        PRESALE_INFO.END_TIME = _endTime;
    }

    function updateNewVestingPeriod(uint256[] memory _distributionTime, uint256[] memory _unlockRate) 
        public 
        onlyOperator 
        declineWhenTheSaleStops
    {
        require(_distributionTime.length == _unlockRate.length, "ARRAY MUST BE SAME LENGTH.");
        uint256 rateWithdrawRemaining;
        for(uint256 i = 0 ; i < _distributionTime.length ; i++) {
            rateWithdrawRemaining += _unlockRate[i];
            require(
                _distributionTime[i] > PRESALE_INFO.END_TIME, 
                "INVALID DISTRIBUTION TIME."
            );
        } 
        require(
            rateWithdrawRemaining == 1000,
            "TOTAL RATE WITHDRAW REMAINING MUST EQUAL 100%."
        );
        
        delete LIST_VESTING_PERIOD;
        for (uint256 i = 0; i < _distributionTime.length; i++) {
            VestingPeriod memory newVestingPeriod;
            newVestingPeriod.distributionTime = _distributionTime[i];
            newVestingPeriod.unlockRate = _unlockRate[i];
            LIST_VESTING_PERIOD.push(newVestingPeriod);
        }

        emit AlertAddNewVestingPeriod(
            msg.sender,
            _distributionTime,
            _unlockRate
        );
    }

    function setPauseOrActivePresale(bool _isFause) external onlyOperator{
        require(PAUSE != _isFause, "THIS STATUS HAS ALREADY BEEN SET.");
        PAUSE = _isFause;
    }

    function getVetingPeriodInfo() external view returns(
        uint256[] memory,
        uint256[] memory
    ) {
        uint256 lengthVetingPeriod = LIST_VESTING_PERIOD.length;
        uint256[] memory distributionTime = new uint256[](lengthVetingPeriod);
        uint256[] memory unlockRate = new uint256[](lengthVetingPeriod);

        for(uint256 i = 0; i < lengthVetingPeriod; i++) {
            distributionTime[i] = LIST_VESTING_PERIOD[i].distributionTime;
            unlockRate[i] = LIST_VESTING_PERIOD[i].unlockRate;
        } 
        
        return(distributionTime, unlockRate);
    }
}
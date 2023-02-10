// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';

contract AjiraPayFinanceStablecoinPresale is Ownable, AccessControl,ReentrancyGuard{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    bytes32 public constant MANAGER_ROLE = keccak256('MANAGER_ROLE');
    
    address payable public treasury;
    IERC20 public ajiraPayFinanceToken;

    address private constant DAI = 0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3;
    address private constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address private constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address private constant USDC = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;

    address private constant CHAINLINK_MAINNET_BNB_USD_PRICEFEED_ADDRESS = 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE;
    address private constant CHAINLINK_MAINNET_USDT_USD_PRICEFEED_ADDRESS = 0xB97Ad0E74fa7d920791E90258A6E2085088b4320;
    address private constant CHAINLINK_MAINNET_USDC_USD_PRICEFEED_ADDRESS = 0x51597f405303C4377E36123cBc172b13269EA163;
    address private constant CHAINLINK_MAINNET_BUSD_USD_PRICEFEED_ADDRESS = 0xcBb98864Ef56E9042e7d2efef76141f15731B82f;
    address private constant CHAINLINK_MAINNET_DAI_USD_PRICEFEED_ADDRESS = 0x132d3C0B1D2cEa0BC552588063bdBb210FDeecfA;

    bool public isPresaleOpen = true;
    bool public isPresalePaused = false;
    bool public isOpenForClaims = false;

    bool public isPhase1Active = true;
    bool public isPhase2Active = false;
    bool public isPhase3Active = false;

    uint256 public phase1PricePerTokenInWei = 10 * 10 ** 18; //0.1 USD
    uint256 public phase2PricePerTokenInWei = 20 * 10 ** 18; //0.2 USD
    uint256 public phase3PricePerTokenInWei = 30 * 10 ** 18; //0.3 USD

    uint public totalWeiRaisedInPhase1 = 0;
    uint public totalWeiRaisedInPhase2 = 0;
    uint public totalWeiRaisedInPhase3 = 0;

    uint public totalTokensBoughtInPhase1 = 0;
    uint public totalTokensBoughtInPhase2 = 0;
    uint public totalTokensBoughtInPhase3 = 0;

    uint public maxPossibleInvestmentInWei = 10000 * 10**18;

    uint256 public phase1TotalTokensToSell = 3_000_000 * 1e18;
    uint256 public phase2TotalTokensToSell = 5_000_000 * 1e18;
    uint256 public phase3TotalTokensToSell = 7_000_000 * 1e18;

    uint public maxTokenCapForPresale = 15_000_000 * 1e18;
    uint public maxTokensToPurchasePerWallet = 2_000_000 * 1e18;

    uint256 public totalUsdRaised = 0;
    uint256 public totalTokensBought = 0;
    uint256 public totalTokensClaimed = 0;

    AggregatorV3Interface internal busdPriceFeed;
    AggregatorV3Interface internal daiPriceFeed;
    AggregatorV3Interface internal usdtPriceFeed;
    AggregatorV3Interface internal usdcPriceFeed;
    AggregatorV3Interface internal bnbPriceFeed;

    mapping(address => mapping(uint256 => uint256)) public investorTokenPurchaseByPhase;
    mapping(address => mapping(uint256 => uint256)) public investorTotalStableCoinPurchaseByPhase;
    mapping(address => uint256) public personalTotalTokenPurchase;
    mapping(address => uint256) public personalStableCoinPurchase;
    mapping(address => uint256) public personalTotalTokenPurchaseClaimed;
    mapping(address => bool) public canClaimContribution;

    event UpdateTreasury(
        address indexed caller, 
        address indexed prevTreasury, 
        address indexed newTreasury, 
        uint timestamp
    );

    event RecoverBNB(
        address indexed caller, 
        address indexed destinationWallet, 
        uint indexed amount, 
        uint timestamp
    );

    event RecoverERC20Tokens(
        address indexed caller, 
        address indexed destination, 
        uint amount, 
        uint timestamp
    );

    event BuyWithStableCoin(
        address indexed stableCoin, 
        uint256 stableCoinAmount,
        uint256 indexed tokensBought, 
        address indexed investor, 
        uint256 timestamp
    );

    event ClaimFromStableCoinPurchase(
        address indexed beneficiary, 
        uint256 indexed tokenAmountReceived, 
        uint256 indexed timestamp
    );

    event RefundUnsoldTokens(
        address indexed destination, 
        uint256 indexed refundAmount, 
        uint256 indexed timestamp
    );

    modifier presaleOpen(){
        require(isPresaleOpen == true,"AJP Presale: Presale Closed");
        _;
    }

    modifier presaleClosed(){
        require(isPresaleOpen == false,"AJP Presale: Presale Open");
        _;
    }

    modifier presalePaused(){
        require(isPresalePaused == true,"AJP Presale: Presale Unpaused");
        _;
    }

    modifier presaleNotPaused(){
        require(isPresalePaused == false,"AJP Presale: Presale Paused");
        _;
    }

    modifier claimsOpen(){
        require(isOpenForClaims == true,"AJP Presale: Claims Closed");
        _;
    }

    modifier claimsClosed(){
        require(isOpenForClaims == false,"AJP Presale: Claims Open");
        _;
    }
    
    modifier canClaim(address _investor){
        require(canClaimContribution[_investor] == true,"AJP: Cannot Claim");
        _;
    }

    constructor(address _token, address payable _treasury) {
        require(_token != address(0),"AJP Presale: Zero Address detected");
        require(_treasury != address(0),"AJP Presale: Zero Address detected");

        _grantRole(MANAGER_ROLE, _msgSender());
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());

        ajiraPayFinanceToken = IERC20(_token);
        treasury = _treasury;

        busdPriceFeed = AggregatorV3Interface(CHAINLINK_MAINNET_BUSD_USD_PRICEFEED_ADDRESS);
        daiPriceFeed  = AggregatorV3Interface(CHAINLINK_MAINNET_DAI_USD_PRICEFEED_ADDRESS);
        usdtPriceFeed = AggregatorV3Interface(CHAINLINK_MAINNET_USDT_USD_PRICEFEED_ADDRESS);
        usdcPriceFeed = AggregatorV3Interface(CHAINLINK_MAINNET_USDC_USD_PRICEFEED_ADDRESS);
        bnbPriceFeed = AggregatorV3Interface(CHAINLINK_MAINNET_BNB_USD_PRICEFEED_ADDRESS);
    }

    function buyWithStableCoin(address _stableCoin, uint256 _amount) external presaleOpen presaleNotPaused nonReentrant{
        require(_stableCoin != address(0),"Invalid Payment Coin");
        require(_stableCoin == DAI || _stableCoin == USDC || _stableCoin == USDT || _stableCoin == BUSD,"Not a Payment method");
        require(_stableCoin != address(ajiraPayFinanceToken),"Invalid Payment Coin");
        require(_amount > 0,"AJP Presale: Zero Amount Not Allowed");

        (AggregatorV3Interface priceFeed) =  _getPriceFeedFromAddress(_stableCoin);
        (uint256 price, uint256 decimals) = _getLatestStableCoinPriceInUSD(priceFeed);

        uint256 weiAmount = _amount;
        uint256 totalUsdVal = weiAmount.mul(price).div(10**decimals);
        
        uint256 currentTokenPrice = _getPresalePriceByActivePhase();
        uint256 tokenAmount = totalUsdVal.mul(100).mul(10 ** 18).div(currentTokenPrice);

        uint256 prevPurchaseTotal = personalTotalTokenPurchase[msg.sender];
        uint256 totalPurchase = prevPurchaseTotal.add(tokenAmount);
        _validateUSDPurchaseAmountByPhase(totalUsdVal);
        require(totalPurchase <= maxTokensToPurchasePerWallet,"AJP Presale: Purchase Limit Per Wallet Reached");
        canClaimContribution[msg.sender] = true;
        _updateInvestorContribution(tokenAmount,weiAmount, totalUsdVal);
        _checkAndUpdatePresalePhaseByTokensSold();
        _checkPresaleEndStatus();
        _sendContributionToTreasury(_stableCoin, _amount);
        emit BuyWithStableCoin(_stableCoin, _amount, tokenAmount, msg.sender, block.timestamp);
    }

    function claim() external presaleClosed presaleNotPaused claimsOpen canClaim(msg.sender) nonReentrant{
        uint256 totalUserInvestment = personalTotalTokenPurchase[msg.sender];
        uint256 contractBalance = ajiraPayFinanceToken.balanceOf(address(this));
        require(totalUserInvestment > 0,"AJP Presale: Not Enough Balance To Claim");
        require(contractBalance >= totalUserInvestment,"AJP Presale: Cannot Process Withdrawals");
        totalUserInvestment = 0;
        canClaimContribution[msg.sender] = false;
        personalTotalTokenPurchaseClaimed[msg.sender] = personalTotalTokenPurchaseClaimed[msg.sender].add(totalUserInvestment);
        totalTokensClaimed = totalTokensClaimed.add(totalUserInvestment);
        ajiraPayFinanceToken.safeTransfer(msg.sender, totalUserInvestment);
        emit ClaimFromStableCoinPurchase(msg.sender, totalUserInvestment, block.timestamp);
    }

    function activatePhase1() external onlyRole(MANAGER_ROLE){
        _activatePhase1();
    }
    
    function activatePhase2() external onlyRole(MANAGER_ROLE){
        _activatePhase2();
    }

    function activatePhase3() external onlyRole(MANAGER_ROLE){
        _activatePhase3();
    }

    function setPresaleActiveStatus(bool _status) external onlyRole(MANAGER_ROLE){
        isPresaleOpen = _status;
    }

    function setPresaleClaimStatus(bool _status) external onlyRole(MANAGER_ROLE){
        isOpenForClaims = _status;
    }

    function setPresalePauseStatus(bool _status) external onlyRole(MANAGER_ROLE){
        isPresalePaused = _status;
    }

    function updateTreasury(address payable _newTreasury) external onlyRole(MANAGER_ROLE) presalePaused{
        require(_newTreasury != address(0),"AJP Presale: Invalid Address For Treasury");
        treasury = _newTreasury;
        address payable prevTreasury = treasury;
        emit UpdateTreasury(msg.sender,prevTreasury,_newTreasury, block.timestamp);
    }

    function setPhaseTokenPrice(uint256 _phase1Price, uint256 _phase2Price, uint256 _phase3Price) external onlyRole(MANAGER_ROLE) nonReentrant{
        require(_phase1Price > 0 && _phase2Price > 0 && _phase3Price > 0, "AJP Presale: Zero Amount Detected");
        phase1PricePerTokenInWei = _phase1Price * 1e18;
        phase2PricePerTokenInWei = _phase2Price * 1e18;
        phase3PricePerTokenInWei = _phase3Price * 1e18;
    }

    function recoverBNB() public onlyRole(MANAGER_ROLE) nonReentrant{
        uint256 balance = getContractBNBBalance();
        require(balance > 0,"Insufficient Contract Balance");
        treasury.transfer(balance);
        emit RecoverBNB(msg.sender, treasury, balance, block.timestamp);
    }

    function recoverLostTokensForInvestor(address _token, address _account, uint _amount) external 
    nonReentrant{
        IERC20 token = IERC20(_token);
        require(token != ajiraPayFinanceToken,"Invalid Token");
        if(_account == address(0)){
            uint256 balance = getContractBNBBalance();
            treasury.transfer(balance);
        }
        token.safeTransfer(_account, _amount);
        emit RecoverERC20Tokens(_msgSender(), _account, _amount, block.timestamp);
    }

    function getContractAJPBalance() public view returns(uint256){
        return ajiraPayFinanceToken.balanceOf(address(this));
    }

    function getContractBNBBalance() public view returns(uint256){
        return address(this).balance;
    }

    function refundUnsoldTokens() external presaleClosed onlyRole(MANAGER_ROLE) nonReentrant{
        uint256 currentBalance = getContractAJPBalance();
        uint256 refundableBalance = currentBalance.sub(totalTokensBought);
        require(refundableBalance > 0,"AJP Presale: Insufficient Refund Balance");
        require(refundableBalance <= currentBalance,"AJP Presale: Excess Refund Limit");
        ajiraPayFinanceToken.safeTransfer(treasury,refundableBalance);
        emit RefundUnsoldTokens(msg.sender, refundableBalance, block.timestamp);
    }

    receive() external payable{
        revert("Cannot Accept Direct BNB Deposits");
    }

    function _getPriceFeedFromAddress(address _stableCoin) private view returns(AggregatorV3Interface){
        if(_stableCoin == DAI){
            return daiPriceFeed;
        }else if(_stableCoin == BUSD){
            return busdPriceFeed;
        }else if(_stableCoin == USDT){
            return usdtPriceFeed;
        }else if(_stableCoin == USDC){
            return usdcPriceFeed;
        }else{
            return bnbPriceFeed;
        }
    }

    function _getLatestStableCoinPriceInUSD(AggregatorV3Interface _priceFeed) private view returns(uint256, uint256){
        (, int256 price, , , ) = _priceFeed.latestRoundData();
        uint256 decimals = _priceFeed.decimals();
        return (uint256(price), decimals);
    }

    function _getPresalePriceByActivePhase() private view returns(uint256){
        if(isPhase1Active){
            return phase1PricePerTokenInWei;
        }else if(isPhase2Active){
            return phase2PricePerTokenInWei;
        }else{
            return phase3PricePerTokenInWei;
        }
    }

    function _sendContributionToTreasury(address _coin, uint256 _amount) private{
        IERC20 coin = IERC20(_coin);
        uint256 balance = coin.balanceOf(msg.sender);
        require(balance >= _amount,"AJP Presale: Insufficient Balance");
        coin.safeTransferFrom(msg.sender, treasury, _amount);
    }

    function _updateInvestorContribution(uint256 _tokenAmount, uint256 _weiAmount, uint256 _usdValInWei) private{
        totalTokensBought += _tokenAmount;
        totalUsdRaised += _usdValInWei;

        personalTotalTokenPurchase[msg.sender] += _tokenAmount;
        personalStableCoinPurchase[msg.sender] += _weiAmount;

        if(isPhase1Active){
            unchecked{
                investorTokenPurchaseByPhase[msg.sender][1] += _tokenAmount;
                investorTotalStableCoinPurchaseByPhase[msg.sender][1] += _weiAmount;
                totalTokensBoughtInPhase1 += _tokenAmount;
                totalWeiRaisedInPhase1 += _weiAmount;
            }
        }else if(isPhase2Active){
            unchecked{
                investorTokenPurchaseByPhase[msg.sender][2] += _tokenAmount;
                investorTotalStableCoinPurchaseByPhase[msg.sender][2] += _weiAmount;
                totalTokensBoughtInPhase2 += _tokenAmount;
                totalWeiRaisedInPhase2 += _weiAmount;
            }
        }else{
            unchecked{
                investorTokenPurchaseByPhase[msg.sender][3] += _tokenAmount;
                investorTotalStableCoinPurchaseByPhase[msg.sender][3] += _weiAmount;
                totalTokensBoughtInPhase3 += _tokenAmount;
                totalWeiRaisedInPhase3 += _weiAmount;
            }
        }
    } 


    function _activatePhase1() private{
        isPhase1Active = true;
        isPhase2Active = false;
        isPhase3Active = false;
    }

    function _activatePhase2() private{
        isPhase2Active = true;
        isPhase1Active = false;
        isPhase3Active = false;
    }

    function _activatePhase3() private{
        isPhase3Active = true;
        isPhase1Active = false;
        isPhase2Active = false;
    }

    function _setPresaleClosed() private{
        isPresaleOpen = false;
    }

    function _checkAndUpdatePresalePhaseByTokensSold() private{
        if(totalTokensBought >= phase1TotalTokensToSell && isPhase1Active){
            _activatePhase2();
        }
        if(totalTokensBought >= (phase1TotalTokensToSell + phase2TotalTokensToSell) && isPhase2Active){
            _activatePhase3();
        }
    }

    function _checkPresaleEndStatus() private{
        if(totalTokensBought >= maxTokenCapForPresale){
             _setPresaleClosed();
        }
    }

    function _validateUSDPurchaseAmountByPhase(uint256 _usdAmountInWei) private view{
        if(isPhase1Active){
            require(_usdAmountInWei >= phase1PricePerTokenInWei,"AJP Presale: Contribution below Phase #1 minimum");
        }else if(isPhase2Active){
            require(_usdAmountInWei >= phase2PricePerTokenInWei,"AJP Presale: Contribution below Phase #2 minimum");
        }else{
            require(_usdAmountInWei >= phase3PricePerTokenInWei,"AJP Presale: Contribution below Phase #3 minimum");
        }
    }
}
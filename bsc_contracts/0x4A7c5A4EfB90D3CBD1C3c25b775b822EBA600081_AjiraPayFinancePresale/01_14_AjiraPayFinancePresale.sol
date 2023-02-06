// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';

contract AjiraPayFinancePresale is Ownable, AccessControl, ReentrancyGuard{
    using SafeERC20 for IERC20;

    bytes32 constant public MANAGER_ROLE = keccak256('MANAGER_ROLE');

    IERC20 public ajiraPayFinanceToken;
    AggregatorV3Interface internal priceFeed;

    address payable public treasury;
    address private constant CHAINLINK_MAINNET_BNB_USD_PRICEFEED_ADDRESS = 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE;

    address[] public investors;
    
    bool public isPresaleOpen = true;
    bool public isPresalePaused = false;
    bool public isOpenForClaims = false;
    
    bool public isPhase1Active = true;
    bool public isPhase2Active = false;
    bool public isPhase3Active = false;
    
    uint public presaleDurationInSec;

    uint public totalInvestors = 0;
    uint public totalWeiRaised = 0;
    uint public totalTokensSold = 0;
    uint public totalTokensClaimed = 0;

    uint public phase1PricePerTokenInWei = 10 * 10 ** 18; //0.1 USD
    uint public phase2PricePerTokenInWei = 20 * 10 ** 18; //0.2 USD
    uint public phase3PricePerTokenInWei = 30 * 10 ** 18; //0.3 USD

    uint public maxPossibleInvestmentInWei = 10000 * 10**18;
    
    uint public totalTokensSoldInPhase1 = 0;
    uint public totalTokensSoldInPhase2 = 0;
    uint public totalTokensSoldInPhase3 = 0;

    uint public totalWeiRaisedInPhase1 = 0;
    uint public totalWeiRaisedInPhase2 = 0;
    uint public totalWeiRaisedInPhase3 = 0;

    uint256 public phase1TotalTokensToSell = 3_000_000 * 1e18;
    uint256 public phase2TotalTokensToSell = 5_000_000 * 1e18;
    uint256 public phase3TotalTokensToSell = 7_000_000 * 1e18;

    uint public maxTokenCapForPresale = 15_000_000 * 1e18;
    uint public maxTokensToPurchasePerWallet = 2_000_000 * 1e18;

    mapping(address => uint) public totalTokenContributionsByUser;
    mapping(address => uint) public totalTokenContributionsClaimedByUser;
    mapping(address => uint) public totalBNBInvestmentsByIUser;
    mapping(address => bool) public canClaimTokens;
    mapping(address => bool) public isActiveInvestor;

    mapping(address => uint256) public totalPersonalTokenInvestmentPhase1;
    mapping(address => uint256) public totalPersonalTokenInvestmentPhase2;
    mapping(address => uint256) public totalPersonalTokenInvestmentPhase3;

    mapping(address => uint256) public totalPersonalWeiInvestmentPhase1;
    mapping(address => uint256) public totalPersonalWeiInvestmentPhase2;
    mapping(address => uint256) public totalPersonalWeiInvestmentPhase3;

    mapping(address => uint) public nextPossiblePurchaseTimeByUser;

    mapping(address => uint) public lastUserBuyTimeInSec;

    event StartPresale(address indexed caller, uint indexed timestamp);
    event ClosePresale(address indexed caller, uint indexed timestamp);
    event PausePresale(address indexed caller, uint indexed timestamp);
    event UnpausePresale(address indexed caller, uint indexed timestamp);
    event Contribute(address indexed beneficiary, uint indexed weiAmount, uint indexed tokenAmountBought, uint timestamp);
    event Claim(address indexed beneficiary, uint indexed tokenAmountReceived, uint indexed timestamp);
    event RecoverBNB(address indexed caller, address indexed destinationWallet, uint indexed amount, uint timestamp);
    event RecoverERC20Tokens(address indexed caller, address indexed destination, uint amount, uint timestamp);
    event UpdateMaxCap(address indexed caller, uint prevCap, uint newCap, uint timestamp);
    event ClaimUnsoldTokens(address indexed caller, address indexed destination, uint indexed timestamp);
    event OpenTokenClaims(address indexed caller, uint indexed timestamp);
    event CloseTokenClaims(address indexed caller, uint indexed timestamp);
    event OpenPublicSale(address indexed caller, uint indexed timestamp);
    event UpdatePrivateSalePrice(address indexed caller, uint indexed amount, uint indexed timestamp);
    event UpdatePublisSalePrice(address indexed caller, uint indexed amount, uint indexed timestamp);

    modifier presaleOpen(){
        require(isPresaleOpen == true,"Sale Closed");
        _;
    }

    modifier presaleClosed(){
        require(isPresaleOpen == false,"Sale Open");
        _;
    }

    modifier presalePaused(){
        require(isPresalePaused == true,"Presale Not Paused");
        _;
    }

    modifier presaleUnpaused(){
        require(isPresalePaused == false,"Presale Paused");
        _;
    }

    modifier nonZeroAddress(address _account){
        require(_account != address(0),"Invalid Account");
        _;
    }

    modifier claimsOpen(){
        require(isOpenForClaims == true,"Claims Not Open");
        _;
    }

    constructor(address _token, address payable _treasury, uint _durationInDays){
        require(_token != address(0),"Invalid Address");
        require(_durationInDays >= 35,"Presale Runs past 35 days");
        _grantRole(MANAGER_ROLE, _msgSender());
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());

        ajiraPayFinanceToken = IERC20(_token); 
        treasury = _treasury;
        priceFeed = AggregatorV3Interface(CHAINLINK_MAINNET_BNB_USD_PRICEFEED_ADDRESS);
        presaleDurationInSec = block.timestamp + (_durationInDays * 24 * 60 * 60);
    }

    function setPresalePauseStatus(bool _status) external onlyRole(MANAGER_ROLE){
        isPresalePaused = _status;
    }

    function setPresaleClaimsStatus(bool _status) external onlyRole(MANAGER_ROLE){
        isOpenForClaims = _status;
    }

    function setPresaleProgressStatus(bool _status) external onlyRole(MANAGER_ROLE){
        isPresaleOpen = _status;
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

    function claimUnsoldTokens() public onlyRole(MANAGER_ROLE) presaleClosed nonReentrant{
        _refundUnsoldTokens(_msgSender());
        emit ClaimUnsoldTokens(_msgSender(), msg.sender, block.timestamp);
    }

    function setPresaleDurationInDays(uint256 _days) public onlyRole(MANAGER_ROLE){
        require(_days >= 35,"Presale Runs past 35 days");
        presaleDurationInSec = block.timestamp + (_days * 24 * 60 * 60);
    }

    function updateTreasury(address payable _newTreasury) public onlyRole(MANAGER_ROLE) 
    nonZeroAddress(_newTreasury) 
    presalePaused
    {
        treasury = _newTreasury;
    }

    function updatePresalePhaseAmount(uint256 _phase1Amount, uint256 _phase2Amount, uint256 _phase3Amount) external onlyRole(MANAGER_ROLE) nonReentrant{
        require(_phase1Amount > 0,"Invalid Token Amount");
        require(_phase2Amount > 0,"Invalid Token Amount");
        require(_phase3Amount > 0,"Invalid Token Amount");
        phase1TotalTokensToSell = _phase1Amount * 1e18;
        phase2TotalTokensToSell = _phase2Amount * 1e18;
        phase3TotalTokensToSell = _phase3Amount * 1e18;
    }

    function contribute() public payable nonReentrant presaleOpen presaleUnpaused{
        _checkInvestorCoolDownBeforeNextPurchase(msg.sender);
        uint256 pricePerToken = _getTokenPriceByPhase();
        (uint256 price, uint256 decimals) = _getLatestBNBPriceInUSD();
        uint256 weiAmount = msg.value;
        uint256 usdAmountFromValue = weiAmount * price / (10 ** decimals);
        require(weiAmount > 0, "No Amount Specified");

        if(isPhase1Active){
            require(usdAmountFromValue >= phase1PricePerTokenInWei,"Contribution Below Phase #1 Minimum");
        }else if(isPhase2Active){
            require(usdAmountFromValue >= phase2PricePerTokenInWei,"Contribution Below Phase #2 Minimum");
        }else{
            require(usdAmountFromValue >= phase3PricePerTokenInWei,"Contribution Below Phase #3 Minimum");
        }

        require(usdAmountFromValue <= maxPossibleInvestmentInWei,"Contribution Above Maximum");
        uint256 tokenAmount = usdAmountFromValue * 100 * (10 ** 18) / pricePerToken;
        uint256 totalTokensBoughtByUser = totalTokenContributionsByUser[msg.sender];
        require(totalTokensBoughtByUser + tokenAmount <= maxTokensToPurchasePerWallet,"Max Tokens Per Wallet Reached");
        require(tokenAmount <= maxTokenCapForPresale,"Max Cap Reached");
        totalTokenContributionsByUser[msg.sender] += tokenAmount;
        totalBNBInvestmentsByIUser[msg.sender] += weiAmount;
        totalTokensSold += tokenAmount;
        totalWeiRaised += weiAmount;
        _updateInvestorCountAndStatus();
        _forwardFunds();
        _updatePresalePhaseParams(tokenAmount, weiAmount);
        _checkAndUpdatePresalePhaseByTokensSold();
        _updateInvestorContributionByPresalePhase(msg.sender,weiAmount,tokenAmount );
        _checkPresaleEndStatus();
        emit Contribute(msg.sender, weiAmount, tokenAmount, block.timestamp);
    }

    function claimContribution() public claimsOpen nonReentrant{
        _checkIfCallerIsActiveInvestor();
        uint256 totalClaimableTokens = totalTokenContributionsByUser[msg.sender];
        require(totalClaimableTokens > 0,"Insufficient Token Claims");
        require(
            IERC20(ajiraPayFinanceToken).transfer(msg.sender, totalClaimableTokens),
            "Failed to send tokens"
        );
        totalTokenContributionsByUser[msg.sender] = 0;
        _updateInvestorContributionAfterClaims(totalClaimableTokens);
        canClaimTokens[msg.sender] = false;
        emit Claim(msg.sender, totalClaimableTokens, block.timestamp);
    }

    function recoverBNB() public onlyRole(MANAGER_ROLE) nonReentrant{
        uint256 balance = getContractBNBBalance();
        require(balance > 0,"Insufficient Contract Balance");
        treasury.transfer(balance);
        emit RecoverBNB(msg.sender, treasury, balance, block.timestamp);
    }

    function recoverLostTokensForInvestor(address _token, address _account, uint _amount) public 
    nonReentrant nonZeroAddress(_token) nonZeroAddress(_account){
        IERC20 token = IERC20(_token);
        require(token != ajiraPayFinanceToken,"Invalid Token");
        token.safeTransfer(_account, _amount);
        emit RecoverERC20Tokens(_msgSender(), _account, _amount, block.timestamp);
    }

    function getContractTokenBalance() public view returns(uint256){
        return ajiraPayFinanceToken.balanceOf(address(this));
    }

    function getContractBNBBalance() public view returns(uint256){
        return address(this).balance;
    }

    function updateMaxTokenCapForPresale(uint256 _amount) public onlyRole(MANAGER_ROLE){
        require(_amount >= 15_000_000,"Max Cap Must be above 15% of total supply");
        uint256 prevMaxCap = maxTokenCapForPresale;
        uint256 newMaxCap = _amount * 1e18;
        maxTokenCapForPresale = newMaxCap;
        emit UpdateMaxCap(msg.sender, prevMaxCap, newMaxCap, block.timestamp);
    }

    function setPhase1PriceInWei(uint256 _amount) public onlyRole(MANAGER_ROLE) nonReentrant{
        require(_amount >= 10 && _amount <= 20,"Invalid Price: Between 0.2$ - 0.3$");
        phase1PricePerTokenInWei = _amount * 10 ** 18;
        emit UpdatePublisSalePrice(msg.sender, _amount, block.timestamp);
    }

    function setPhase2PriceInWei(uint256 _amount) public onlyRole(MANAGER_ROLE) nonReentrant{
        require(_amount >= 20 && _amount <= 30,"Invalid Price: Between 0.2$ - 0.3$");
        phase2PricePerTokenInWei = _amount * 10 ** 18;
        emit UpdatePublisSalePrice(msg.sender, _amount, block.timestamp);
    }

    function setPhase3PriceInWei(uint256 _amount) public onlyRole(MANAGER_ROLE) nonReentrant{
        require(_amount >= 30 && _amount <= 31,"Invalid Price: Between 0.2$ - 0.3$");
        phase3PricePerTokenInWei = _amount * 10 ** 18;
        emit UpdatePublisSalePrice(msg.sender, _amount, block.timestamp);
    }

    receive() external payable{
        contribute();
    }

    //INTERNAL HELPER FUNCTIONS
    function _getLatestBNBPriceInUSD() private view returns(uint256, uint256){
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 decimals = priceFeed.decimals();
        return (uint256(price), decimals);
    }

    function _forwardFunds() private{
        treasury.transfer(msg.value);
    }
    
    function _refundUnsoldTokens(address _destination) private{
        uint256 availableTokenBalance = getContractTokenBalance();
        uint256 refundableBalance = availableTokenBalance - totalTokensSold;
        require(refundableBalance > 0,"Insufficient Token Balance");
        require(refundableBalance <= availableTokenBalance,"Excess Token Withdrawals");
        require(ajiraPayFinanceToken.transfer(_destination, refundableBalance),"Failed To Refund Tokens");
    }

    function _checkInvestorCoolDownBeforeNextPurchase(address _account) private view{
        uint256 nextPurchaseTime = nextPossiblePurchaseTimeByUser[_account];
        if(block.timestamp < nextPurchaseTime){
            require(block.timestamp >= nextPurchaseTime,"Wait For 2 Mins Before Next Purchase");
        }
    }

    function _setClaimStarted() private{
        isOpenForClaims = true;
    }

    function _setClaimsClosed() private{
        isOpenForClaims = false;
    }

    function _setPresaleClosed() private{
        isPresaleOpen = false;
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

    function _updateInvestorCountAndStatus() private{
        if(isActiveInvestor[msg.sender] == false){
            totalInvestors += 1;
            investors.push(msg.sender);
            isActiveInvestor[msg.sender] = true;
        }
        canClaimTokens[msg.sender] = true;
        nextPossiblePurchaseTimeByUser[msg.sender] = block.timestamp + 120;
        lastUserBuyTimeInSec[msg.sender] = block.timestamp;
    }

    function _updatePresalePhaseParams(uint256 _tokenAmount, uint256 _weiAmount) private{
        if(isPhase1Active){
            unchecked{
                totalTokensSoldInPhase1 += _tokenAmount;
                totalWeiRaisedInPhase1 += _weiAmount;
            }
        }else if(isPhase2Active){
            unchecked{
                totalTokensSoldInPhase2 += _tokenAmount;
                totalWeiRaisedInPhase2 += _weiAmount;
            }
        }else{
             unchecked{
                totalTokensSoldInPhase3 += _tokenAmount;
                totalWeiRaisedInPhase3 += _weiAmount;
            }
        }
    }

    function _checkPresaleEndStatus() private{
        if(totalTokensSold >= maxTokenCapForPresale){
             _setPresaleClosed();
        }
    }

    function _getTokenPriceByPhase() private view returns(uint256){
        uint256 _tokenPriceInWeiBySalePhase;
        if(isPhase1Active){
            _tokenPriceInWeiBySalePhase = phase1PricePerTokenInWei;
        }else if(isPhase2Active){
            _tokenPriceInWeiBySalePhase = phase2PricePerTokenInWei;
        }else{
            _tokenPriceInWeiBySalePhase = phase3PricePerTokenInWei;
        }
        return _tokenPriceInWeiBySalePhase;
    }

    function _checkIfCallerIsActiveInvestor() private view{
        if(isActiveInvestor[msg.sender] == true && canClaimTokens[msg.sender] == false){
            require(canClaimTokens[msg.sender] == true,"Already Claimed Contribution");
        }
    }

    function _updateInvestorContributionByPresalePhase(address _account, uint256 _weiAmount, uint256 _tokenAmount) private{
        if(isPhase1Active){
            unchecked {
                totalPersonalTokenInvestmentPhase1[_account] += _tokenAmount; 
                totalPersonalWeiInvestmentPhase1[_account] += _weiAmount;
            }
        }else if(isPhase2Active){
            unchecked {
                totalPersonalTokenInvestmentPhase2[_account] += _tokenAmount; 
                totalPersonalWeiInvestmentPhase2[_account] += _weiAmount; 
            }
        }else{
            unchecked {
                totalPersonalTokenInvestmentPhase3[_account] += _tokenAmount;
                totalPersonalWeiInvestmentPhase3[_account] += _weiAmount;
            }
        }
    }

    function _updateInvestorContributionAfterClaims(uint256 _tokenAmount) private{
        unchecked{
            totalTokenContributionsClaimedByUser[msg.sender] += _tokenAmount;
            totalTokensClaimed += _tokenAmount;
        }
    }

    function _checkAndUpdatePresalePhaseByTokensSold() private{
        if(totalTokensSold >= phase1TotalTokensToSell && isPhase1Active){
            _activatePhase2();
        }if(totalTokensSold >= (phase1TotalTokensToSell + phase2TotalTokensToSell) && isPhase2Active){
            _activatePhase3();
        }
    }
}
// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';

contract AjiraPayFinancePrivateSale is Ownable, AccessControl, ReentrancyGuard{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bytes32 constant public MANAGER_ROLE = keccak256('MANAGER_ROLE');

    IERC20 public ajiraPayToken;

    AggregatorV3Interface internal priceFeed;

    address payable public treasury;
    address private constant CHAINLINK_MAINNET_BNB_USD_PRICEFEED_ADDRESS = 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE;
    address private constant CHAINLINK_TESTNET_BNB_USD_PRICEFEED_ADDRESS = 0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526;

    address[] public investors;
    
    bool public isPresaleOpen = false;
    bool public isPresalePaused = false;
    bool public isOpenForClaims = false;

    bool public isPrivateSalePhase = true;
    
    uint public totalInvestors = 0;
    uint public presaleDurationInSec;
    uint public totalTokensSold = 0;
    uint public totalTokensClaimed = 0;
    uint public publicSalePricePerTokenInWei = 30 * 10** 18; //0.3
    uint public privateSalePricePerTokenInWei = 20 * 10 ** 18; //0.2
    uint public maxPossibleInvestmentInWei = 10000 * 10**18;
    uint public totalWeiRaised = 0;
    uint public totalTokensSoldInPublicSale = 0;
    uint public totalTokensSoldInPrivateSale = 0;
    uint public totalWeiRaisedInPublicSale = 0;
    uint public totalWeiRaisedInPrivateSale = 0;

    uint public maxTokenCapForPresale = 15_000_000 * 1e18;
    uint public maxTokensToPurchasePerWallet = 2000_000 * 1e18;
    uint public minTokensToPurchasePerWallet;

    mapping(address => uint) public totalTokenContributionsByUser;
    mapping(address => uint) public totalTokenContributionsClaimedByUser;
    mapping(address => uint) public totalBNBInvestmentsByIUser;
    mapping(address => bool) public canClaimTokens;
    mapping(address => bool) public isActiveInvestor;

    mapping(address => uint) public nextPossiblePurchaseTimeByUser;

    mapping(address => uint) public lastUserBuyTimeInSec;

    event StartPresale(address indexed caller, uint indexed timestamp);
    event ClosePresale(address indexed caller, uint indexed timestamp);
    event PausePresale(address indexed caller, uint indexed timestamp);
    event UnpausePresale(address indexed caller, uint indexed timestamp);
    event Contribute(address indexed beneficiary, uint indexed weiAmount, uint indexed tokenAmountBought, uint timestamp);
    event Claim(address indexed beneficiary, uint indexed tokenAmountReceived, uint indexed timestamp);
    event UpdateTreasury(address indexed caller, address indexed prevTreasury, address indexed newTreasury, uint timestamp);
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

    constructor(address _token, address payable _treasury){
        require(_token != address(0),"Invalid Address");
        _grantRole(MANAGER_ROLE, _msgSender());
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());

        ajiraPayToken = IERC20(_token); 
        treasury = _treasury;

        uint256 id = _getChainID();
        if(id == 56){
            priceFeed = AggregatorV3Interface(CHAINLINK_MAINNET_BNB_USD_PRICEFEED_ADDRESS);
        }else if(id == 97){
            priceFeed = AggregatorV3Interface(CHAINLINK_TESTNET_BNB_USD_PRICEFEED_ADDRESS);
        }
    }

    function startPresale() public onlyRole(MANAGER_ROLE) presaleClosed{
        _setPresaleOpened();
        emit StartPresale(_msgSender(), block.timestamp);
    }

    function closePresale() public onlyRole(MANAGER_ROLE) presaleOpen{
        _setPresaleClosed();
        emit ClosePresale(_msgSender(), block.timestamp);
    }

    function pausePresale() public onlyRole(MANAGER_ROLE) presaleUnpaused{
        isPresalePaused = true;
        emit PausePresale(_msgSender(), block.timestamp);
    }

    function unPausePresale() public onlyRole(MANAGER_ROLE) presalePaused{
        isPresalePaused = false;
        emit UnpausePresale(_msgSender(), block.timestamp);
    }

    function activateTokenClaims() public onlyRole(MANAGER_ROLE){
        _setClaimStarted();
        emit OpenTokenClaims(_msgSender(), block.timestamp);
    }

    function deActivateTokenClaims() public onlyRole(MANAGER_ROLE){
        _setClaimsClosed();
        emit CloseTokenClaims(_msgSender(), block.timestamp);
    }

    function activatePublicSale() public onlyRole(MANAGER_ROLE){
        isPrivateSalePhase = false;
        emit OpenPublicSale(msg.sender, block.timestamp);
    }

    function claimUnsoldTokens() public onlyRole(MANAGER_ROLE) presaleClosed nonReentrant{
        _refundUnsoldTokens(_msgSender());
        emit ClaimUnsoldTokens(_msgSender(), msg.sender, block.timestamp);
    }

    function updateTreasury(address payable _newTreasury) public onlyRole(MANAGER_ROLE) 
    nonZeroAddress(_newTreasury) 
    presalePaused
    {
        address payable prevTreasury = treasury;
        treasury = _newTreasury;
        emit UpdateTreasury(_msgSender(), prevTreasury, _newTreasury, block.timestamp);
    }

    function contribute() public payable nonReentrant presaleOpen presaleUnpaused{
        _checkInvestorCoolDownBeforeNextPurchase(msg.sender);
        uint256 pricePerToken = _getTokenPriceByPhase();
        (uint256 price, uint256 decimals) = _getLatestBNBPriceInUSD();
        uint256 weiAmount = msg.value;
        uint256 usdAmountFromValue = weiAmount.mul(price).div(10 ** decimals);
        require(weiAmount > 0, "No Amount Specified");
        if(isPrivateSalePhase){
            require(usdAmountFromValue >= privateSalePricePerTokenInWei,"Contribution Below Minimum");
        }else{
            require(usdAmountFromValue >= publicSalePricePerTokenInWei,"Contribution Below Minimum");
        }
        require(usdAmountFromValue >= maxPossibleInvestmentInWei,"Contribution Above Maximum");
        uint256 tokenAmount = usdAmountFromValue.mul(100).mul(10**18).div(pricePerToken);
        uint256 totalTokensBoughtByUser = totalTokenContributionsByUser[msg.sender];
        require(totalTokensBoughtByUser + tokenAmount <= maxTokensToPurchasePerWallet,"Max Tokens Per Wallet Reached");
        require(tokenAmount < maxTokenCapForPresale,"Max Cap Reached");
        totalTokenContributionsByUser[msg.sender] = totalTokenContributionsByUser[msg.sender].add(tokenAmount);
        totalBNBInvestmentsByIUser[msg.sender] = totalBNBInvestmentsByIUser[msg.sender].add(weiAmount);
        totalTokensSold = totalTokensSold.add(tokenAmount);
        totalWeiRaised = totalWeiRaised.add(weiAmount);
        _updateInvestorCountAndStatus();
        _forwardFunds();
        _updatePresalePhaseParams(tokenAmount, weiAmount);
        _checkAndUpdatePresalePhaseByTokensSold();
        _checkPresaleEndStatus();
        emit Contribute(msg.sender, weiAmount, tokenAmount, block.timestamp);
    }

    function claimContribution() public claimsOpen nonReentrant{
        _checkIfCallerIsActiveInvestor();
        uint256 totalClaimableTokens = totalTokenContributionsByUser[msg.sender];
        require(totalClaimableTokens > 0,"Insufficient Token Claims");
        require(
            IERC20(ajiraPayToken).transfer(msg.sender, totalClaimableTokens),
            "Failed to send tokens"
        );
        totalTokenContributionsByUser[msg.sender] = 0;
        _updateInvestorContribution(totalClaimableTokens);
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
        require(token != ajiraPayToken,"Invalid Token");
        token.safeTransfer(_account, _amount);
        emit RecoverERC20Tokens(_msgSender(), _account, _amount, block.timestamp);
    }

    function getContractTokenBalance() public view returns(uint256){
        return ajiraPayToken.balanceOf(address(this));
    }

    function getContractBNBBalance() public view returns(uint256){
        return address(this).balance;
    }

    function updateMaxTokenCapForPresale(uint256 _amount) public onlyRole(MANAGER_ROLE){
        require(_amount > 15_000_000,"Max Cap Must be above 15% of total supply");
        uint256 prevMaxCap = maxTokenCapForPresale;
        uint256 newMaxCap = _amount * 1e18;
        maxTokenCapForPresale = newMaxCap;
        emit UpdateMaxCap(msg.sender, prevMaxCap, newMaxCap, block.timestamp);
    }

    function setPublicSalePriceInWei(uint256 _amount) public onlyRole(MANAGER_ROLE) nonReentrant{
        require(_amount > 20 && _amount < 30,"Invalid Price: Between 0.2$ - 0.3$");
        publicSalePricePerTokenInWei = _amount * 10 ** 18;
        emit UpdatePublisSalePrice(msg.sender, _amount, block.timestamp);
    }

    function setPrivateSalePriceInWei(uint256 _amount) public onlyRole(MANAGER_ROLE) nonReentrant{
        require(_amount > 30 && _amount < 40,"Invalid Price: Between 0.3$ - 0.4$");
        privateSalePricePerTokenInWei = _amount * 10 ** 18;
        emit UpdatePrivateSalePrice(msg.sender, _amount, block.timestamp);
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
        uint256 refundableBalance = availableTokenBalance.sub(totalTokensSold);
        require(refundableBalance > 0,"Insufficient Token Balance");
        require(refundableBalance <= availableTokenBalance,"Excess Token Withdrawals");
        require(ajiraPayToken.transfer(_destination, refundableBalance),"Failed To Refund Tokens");
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

    function _setPresaleOpened() private{
        isPresaleOpen = true;
    }

    function _setPresaleClosed() private{
        isPresaleOpen = false;
    }

    function _activatePublicSale() private{
        isPrivateSalePhase = false;
    }

    function _updateInvestorCountAndStatus() private{
        if(isActiveInvestor[msg.sender] == false){
            totalInvestors = totalInvestors.add(1);
            investors.push(msg.sender);
            isActiveInvestor[msg.sender] = true;
        }
        canClaimTokens[msg.sender] = true;
        nextPossiblePurchaseTimeByUser[msg.sender] = block.timestamp.add(120); //2mins
        lastUserBuyTimeInSec[msg.sender] = block.timestamp;
        
    }

    function _updatePresalePhaseParams(uint256 _tokenAmount, uint256 _weiAmount) private{
        if(isPrivateSalePhase){
            unchecked{
                totalTokensSoldInPrivateSale = totalTokensSoldInPrivateSale.add(_tokenAmount);
                totalWeiRaisedInPrivateSale = totalWeiRaisedInPrivateSale.add(_weiAmount);
            }
        }else{
            unchecked{
                totalTokensSoldInPublicSale = totalTokensSoldInPublicSale.add(_tokenAmount);
                totalWeiRaisedInPublicSale = totalWeiRaisedInPublicSale.add(_weiAmount);
            }
        }
    }

    function _checkPresaleEndStatus() private{
        if(totalTokensSold > maxTokenCapForPresale){
             _setPresaleClosed();
        }
    }

    function _getTokenPriceByPhase() private view returns(uint256){
        uint256 _tokenPriceInWeiBySalePhase;
         if(isPrivateSalePhase){
            _tokenPriceInWeiBySalePhase = privateSalePricePerTokenInWei;
        }else{
            _tokenPriceInWeiBySalePhase = publicSalePricePerTokenInWei;
        }
        return _tokenPriceInWeiBySalePhase;
    }

    function _checkIfCallerIsActiveInvestor() private view{
        if(isActiveInvestor[msg.sender] == true && canClaimTokens[msg.sender] == false){
            require(canClaimTokens[msg.sender] == true,"Already Claimed Contribution");
        }
    }
    
    function _updateInvestorContribution(uint256 _tokenAmount) private{
        unchecked{
            totalTokenContributionsClaimedByUser[msg.sender] = totalTokenContributionsClaimedByUser[msg.sender].add(_tokenAmount);
            totalTokensClaimed = totalTokensClaimed.add(_tokenAmount);
        }
    }

    function _checkAndUpdatePresalePhaseByTokensSold() private{
        if(totalTokensSold >= maxTokenCapForPresale.div(2)){
            _activatePublicSale();
        }
    }

    function _getChainID() private view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }
}
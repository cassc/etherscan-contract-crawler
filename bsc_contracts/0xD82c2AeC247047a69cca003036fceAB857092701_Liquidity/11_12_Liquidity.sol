// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;



import "./interfaces/SwapInterface.sol";
import "./TransferHelper.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract Liquidity is Initializable, OwnableUpgradeable{

    UniswapRouterInterfaceV5 router;
    uint public BIGNUMBER;
    uint public spreadPrecision;
    uint public totalPairs;
    uint public lendingFeesDecimas;
    uint public quteTokenDecimals;
    address public quoteToken;
    uint public adminFee;
    uint public startTime;
    uint public rewardAmount;

    
    using SafeMath for uint;

    struct stakingInfo {
        uint amount;
        bool requested;
        uint releaseDate;
    }
    
    // management pairs

    struct pairInfo {
        address base;
        address priceFeed;
        uint spread;            //1e8 precision
        uint chainlinkdecimals;
        uint pairMinLeverage;
        uint pairMaxLeverage;
        bool active;
    }

    mapping (uint => pairInfo) public pairInfos; //pairInfors
    
    //allowed token addresses
    mapping (address => bool) public allowedTokens;
    mapping (address => uint) public lendingFees;
    mapping (address => uint) public personalRewardAmount;

    mapping (address => mapping(address => stakingInfo)) public StakeMap; //tokenAddr to user to stake amount
    mapping (address => mapping(address => uint)) public userCummRewardPerStake; //tokenAddr to user to remaining claimable amount per stake
    mapping (address => uint) public tokenCummRewardPerStake; //tokenAddr to cummulative per token reward since the beginning or time
    mapping (address => uint) public tokenTotalStaked; //tokenAddr to total token claimed 
    mapping (address => uint) public totalLocked; //Locked amount to trade
    

    mapping(address => bool) public isTradingContract;

    function initialize (address _router, address _quoteToken) public initializer{
        router = UniswapRouterInterfaceV5(_router);
        BIGNUMBER = 10**18;
        spreadPrecision = 10**18;
        totalPairs = 0;
        lendingFeesDecimas = 1e18;
        quteTokenDecimals = 1e18;
        quoteToken = _quoteToken;
        adminFee = 0;
        startTime = block.timestamp;
        rewardAmount = 0;
        __Ownable_init();
    }

    address public rewardToken;

    function setRouterAddress (address _routerAddress) external onlyOwner{
        require(_routerAddress !=address(0));
        router = UniswapRouterInterfaceV5(_routerAddress);
    }
    
    modifier onlyTrading(){ require(isTradingContract[msg.sender]); _; }

    function addTradingContract(address _trading) external onlyOwner{
        require(_trading != address(0));
        isTradingContract[_trading] = true;
    }
    function removeTradingContract(address _trading) external onlyOwner{
        require(_trading != address(0));
        isTradingContract[_trading] = false;
    }

    
    modifier isValidToken(address _tokenAddr){
        require(allowedTokens[_tokenAddr]);
        _;
    }
    
    /**
    * @dev add approved token address to the mapping 
    */
    function setQuoteToken( address _tokenAddr) onlyOwner external {
        quoteToken = _tokenAddr;
    }

    function setRewardToken( address _tokenAddr) onlyOwner external {
        rewardToken = _tokenAddr;
    }

    function setStartTime(uint _startTime) external onlyOwner {
        startTime = _startTime;
    }
    
    function addToken( address _tokenAddr,uint _lendingFee) onlyOwner external {
        allowedTokens[_tokenAddr] = true;
        lendingFees[_tokenAddr] = _lendingFee;
    }
    
    function setLendingFee( address _tokenAddr,uint _lendingFee) onlyOwner external {
        lendingFees[_tokenAddr] = _lendingFee;
    }

    /**
    * @dev remove approved token address from the mapping 
    */
    function removeToken( address _tokenAddr) onlyOwner external {
        allowedTokens[_tokenAddr] = false;
    }

    /**
    * @dev stake a specific amount to a token
    * @param _amount the amount to be staked
    * @param _tokenAddr the token the user wish to stake on
    * for demo purposes, not requiring user to actually send in tokens right now
    */
    
    function stake(uint _amount, address _tokenAddr) isValidToken(_tokenAddr) external returns (bool){
        require(_amount != 0);
        require(IERC20Upgradeable(_tokenAddr).transferFrom(msg.sender,address(this),_amount));
        
        if (StakeMap[_tokenAddr][msg.sender].amount ==0){
            StakeMap[_tokenAddr][msg.sender].amount = _amount;
            userCummRewardPerStake[_tokenAddr][msg.sender] = tokenCummRewardPerStake[_tokenAddr];
        }else{
            claim(_tokenAddr, msg.sender);
            StakeMap[_tokenAddr][msg.sender].amount = StakeMap[_tokenAddr][msg.sender].amount.add( _amount);
        }
        tokenTotalStaked[_tokenAddr] = tokenTotalStaked[_tokenAddr].add(_amount);
        return true;
    }
    
    
    /**
     * demo version
    * @dev pay out dividends to stakers, update how much per token each staker can claim
    * @param _reward the aggregate amount to be send to all stakers
    * @param _tokenAddr the token that this dividend gets paied out in
    */
    function distribute(uint _reward,address _tokenAddr) isValidToken(_tokenAddr) onlyTrading external returns (bool){
        require(tokenTotalStaked[_tokenAddr] != 0);
        uint reward = _reward.mul(BIGNUMBER); //simulate floating point operations
        uint rewardAddedPerToken = reward/tokenTotalStaked[_tokenAddr];
        tokenCummRewardPerStake[quoteToken] = tokenCummRewardPerStake[quoteToken].add(rewardAddedPerToken);
        return true;
    }
    
    
    event claimed(uint amount);
    /**
    * @dev claim dividends for a particular token that user has stake in
    * @param _tokenAddr the token that the claim is made on
    * @param _receiver the address which the claim is paid to
    */
    function claim(address _tokenAddr, address _receiver) isValidToken(_tokenAddr)  public returns (uint) {
        uint stakedAmount = StakeMap[_tokenAddr][msg.sender].amount;
        //the amount per token for this user for this claim
        uint amountOwedPerToken = tokenCummRewardPerStake[quoteToken].sub(userCummRewardPerStake[quoteToken][msg.sender]);
        uint claimableAmount = stakedAmount.mul(amountOwedPerToken); //total amoun that can be claimed by this user
        //claimableAmount = claimableAmount.mul(DECIMAL); //simulate floating point operations
        claimableAmount = claimableAmount.div(BIGNUMBER); //simulate floating point operations
        userCummRewardPerStake[quoteToken][msg.sender]=tokenCummRewardPerStake[quoteToken];
        if (_receiver == address(0)){
             require(IERC20Upgradeable(quoteToken).transfer(msg.sender,claimableAmount));
        }else{
             require(IERC20Upgradeable(quoteToken).transfer(_receiver,claimableAmount));
        }
        emit claimed(claimableAmount);
        return claimableAmount;

    }
    
    
    /**
    * @dev request to withdraw stake from a particular token, must wait 1 weeks
    */
    function initWithdraw(address _tokenAddr) isValidToken(_tokenAddr)  external returns (bool){
        require(StakeMap[_tokenAddr][msg.sender].amount >0 );
        require(! StakeMap[_tokenAddr][msg.sender].requested );
        StakeMap[_tokenAddr][msg.sender].requested = true;
        StakeMap[_tokenAddr][msg.sender].releaseDate = block.timestamp + 1 weeks;
        return true;
    }
    
    
    /**
    * @dev finalize withdraw of stake
    */
    function finalizeWithdraw(uint _amount, address _tokenAddr) isValidToken(_tokenAddr)  external returns(bool){
        require(StakeMap[_tokenAddr][msg.sender].amount >0 );
        require(StakeMap[_tokenAddr][msg.sender].requested );
        require(block.timestamp > StakeMap[_tokenAddr][msg.sender].releaseDate );
        claim(_tokenAddr, msg.sender);
        require(IERC20Upgradeable(_tokenAddr).transfer(msg.sender,_amount));
        tokenTotalStaked[_tokenAddr] = tokenTotalStaked[_tokenAddr].sub(_amount);
        StakeMap[_tokenAddr][msg.sender].requested = false;
        return true;
    }
    
    function releaseStake(address _tokenAddr, address[] calldata _stakers, uint[] calldata _amounts) onlyOwner isValidToken(_tokenAddr) external returns (bool){
        require(_stakers.length == _amounts.length);
        for (uint i =0; i< _stakers.length; i++){
            require(IERC20Upgradeable(_tokenAddr).transfer(_stakers[i],_amounts[i]));
            StakeMap[_tokenAddr][_stakers[i]].amount -= _amounts[i];
        }
        return true;
        
    }

    function addAdminFee(uint _amount) onlyTrading external {
        adminFee = adminFee + _amount;
        rewardAmount = adminFee;
    }

    function getRewardAmount(address _receiver) external returns(uint){
        uint returnValue = rewardAmount - personalRewardAmount[_receiver];
        personalRewardAmount[_receiver] = rewardAmount;
        return returnValue;
    }
    
    function sendProfit(address _receiver,uint _amount) onlyTrading external {
        require(IERC20Upgradeable(rewardToken).transfer(_receiver,_amount));
    }
    function sendPnl(address _receiver,uint _amount) onlyTrading external {
        require(IERC20Upgradeable(quoteToken).transfer(_receiver,_amount));
    }
    function withdrawFee(address receiver,uint _amount) onlyOwner external {
        require(adminFee>_amount,"Not enough fee balance");
        require(IERC20Upgradeable(quoteToken).transfer(receiver,_amount));
        adminFee = adminFee - _amount;
    }


    function addPair( pairInfo calldata _pairInfo) isValidToken(_pairInfo.base) onlyOwner external {
        pairInfos[totalPairs] = _pairInfo;
        totalPairs = totalPairs + 1;
    }
    function updatePair( pairInfo calldata _pairInfo,uint pairIndex) isValidToken(_pairInfo.base) onlyOwner external {
        pairInfos[pairIndex] = _pairInfo;
    }
    function deactive( uint _pairIndex) onlyOwner external {
        require(_pairIndex < totalPairs ,"Wrong pair index");
        pairInfos[_pairIndex].active = false;
    }
    function pairMinLeverage(uint pairIndex) external view returns(uint){
        return(pairInfos[pairIndex].pairMinLeverage);
    }
    function pairMaxLeverage(uint pairIndex) external view  returns(uint){
        return(pairInfos[pairIndex].pairMaxLeverage);
    }
    function addTotalLocked(address _token,uint _amount) external onlyTrading {
        totalLocked[_token] = totalLocked[_token] + _amount;
    }
    function removeTotalLocked(address _token,uint _amount) external onlyTrading {
        totalLocked[_token] = totalLocked[_token] - _amount;
    }
    function addTotalStaked(address _token,uint _amount) external onlyTrading {
        totalLocked[_token] = totalLocked[_token] + _amount;
    }
    function removeTotalStaked(address _token,uint _amount) external onlyTrading {
        totalLocked[_token] = totalLocked[_token] - _amount;
    }

    function setStakedToken(address _token, uint _amount) external onlyOwner {
        tokenTotalStaked[_token] = _amount;
    }
    

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path
    ) external onlyTrading returns (uint[] memory amounts){
        
        address to = address(this);
        uint deadline =  block.timestamp + 2 minutes;
        TransferHelper.safeApprove(path[0], address(router), amountIn);
        return(router.swapExactTokensForTokens(amountIn,amountOutMin,path,to,deadline));


    }
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path
    ) external onlyTrading returns (uint[] memory amounts){
        address to = address(this);
        uint deadline =  block.timestamp + 2 minutes;
        TransferHelper.safeApprove(path[0], address(router), amountInMax);
        return(router.swapTokensForExactTokens(amountOut,amountInMax,path,to,deadline));
    }

    function getPrice(address[] memory path) public view returns (uint price,uint  pricedecimals,uint  pairIndex,uint spread,bool isBuy){

        pairIndex = 0;
        isBuy = true;
        for(uint i=0;i<totalPairs;i++){
            if(pairInfos[i].base == path[0] || pairInfos[i].base == path[1]){
                pairIndex = i;
                if(pairInfos[i].base == path[0]) isBuy=false;
                break;
            }
        }
        AggregatorV3Interface priceFeed =  AggregatorV3Interface(
            pairInfos[pairIndex].priceFeed
        );
        (   ,
            int _price,
            ,
            ,

        ) = priceFeed.latestRoundData();
        price = uint(_price);
        pricedecimals = pairInfos[pairIndex].chainlinkdecimals;
        spread = pairInfos[pairIndex].spread;

    }
    function getAmountsOut(uint amountIn, address[] memory path) public view returns (uint[] memory amounts){
        (uint price,uint pricedecimals,,uint spread,bool isBuy) = getPrice(path);
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        if(isBuy) {
            amounts[1] = amounts[0].mul(10**pricedecimals).div(price.add(spread));
        }else{
            amounts[1] = amounts[0].mul(price.sub(spread)).div(10**pricedecimals);
        }
    }
    
    function getAmountsIn(uint amountOut, address[] memory path) public view returns (uint[] memory amounts){
        (uint price,uint pricedecimals,,uint spread,bool isBuy) = getPrice(path);
        amounts = new uint[](path.length);
        amounts[1] = amountOut;
        if(isBuy) {
            amounts[0] = amounts[1].mul(price.add(spread)).div(10**pricedecimals);
        }else{
            amounts[0] = amounts[1].mul(10**pricedecimals).div(price.sub(spread));
        }
    }

    function withdraw(address _token, uint256 _amount) external onlyOwner {
        require(IERC20Upgradeable(_token).transfer(msg.sender, _amount), 'transferFrom() failed.');
    }
    function payout () public onlyOwner returns(bool res) {

        address payable to = payable(msg.sender);
        to.transfer(address(this).balance);
        return true;
    }   

    // allow this contract to receive ether
    receive() external payable {}

}
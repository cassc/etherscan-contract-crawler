import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import "./interfaces/IDogsExchangeHelper.sol";
import "./interfaces/IMasterchefPigs.sol";

pragma solidity ^0.8.0;


contract DogPoundAutoPool is Ownable {

    uint256 public lastPigsBalance = 0;

    uint256 public lpRoundMasktemp = 0;
    uint256 public lpRoundMask = 0;

    uint256 public totalDogsStaked = 0;
    uint256 public totalLPCollected = 0;
    uint256 public totalLpStaked = 0;
    uint256 public timeSinceLastCall = 0; 
    uint256 public updateInterval = 24 hours; 
    bool public initializeUnpaused = true;
    bool public managerNotLocked = true;
    bool public MClocked = false;

    uint256 public DOGS_BNB_MC_PID = 1;
    uint256 public BnbLiquidateThreshold = 1e18;
    uint256 public totalLPstakedTemp = 0;
    IERC20 public PigsToken = IERC20(0x9a3321E1aCD3B9F6debEE5e042dD2411A1742002);
    IERC20 public DogsToken = IERC20(0x198271b868daE875bFea6e6E4045cDdA5d6B9829);
    IERC20 public Dogs_BNB_LpToken = IERC20(0x2139C481d4f31dD03F924B6e87191E15A33Bf8B4);

    address public DogPoundManger = 0x6dA8227Bc7B576781ffCac69437e17b8D4F4aE41;
    IDogsExchangeHelper public DogsExchangeHelper = IDogsExchangeHelper(0xB59686fe494D1Dd6d3529Ed9df384cD208F182e8);
    IMasterchefPigs public MasterchefPigs = IMasterchefPigs(0x8536178222fC6Ec5fac49BbfeBd74CA3051c638f);
    IUniswapV2Router02 public constant PancakeRouter = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    address public constant busdCurrencyAddress = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address public constant wbnbCurrencyAddress = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address[] public dogsBnbPath = [wbnbCurrencyAddress, address(DogsToken)];


    struct HistoryInfo {
        uint256 pps;
        uint256 rms;
    }

    struct UserInfo {
        uint256 amount;
        uint256 lpMask;
        uint256 pigsClaimedTotal;
        uint256 lastRmsClaimed;
        uint256 lpDebt;
        uint256 totalLPCollected;
        uint256 totalPigsCollected;
    }
    

    HistoryInfo[] public historyInfo;
    mapping(address => UserInfo) public userInfo;
    mapping(address => bool) private initAllowed; 
    receive() external payable {}

    // Modifiers
    modifier onlyDogPoundManager() {
        require(DogPoundManger == msg.sender, "manager only");
        _;
    }

    constructor(){
        timeSinceLastCall = block.timestamp;
        initAllowed[msg.sender] = true;
        initAllowed[0x47B9501674a0B01c7F3EdF91593bDfe379D73c28] = true;
    }

    function initializeVariables(DogPoundAutoPool _pool, uint256 histlen) onlyOwner public {
        require(initializeUnpaused);
        DogPoundAutoPool pool = DogPoundAutoPool(_pool);
        lpRoundMask = pool.lpRoundMask();
        lpRoundMasktemp =  pool.lpRoundMasktemp();
        totalDogsStaked =  pool.totalDogsStaked();
        timeSinceLastCall = pool.timeSinceLastCall() + 2 hours;
        for(uint i = 0; i < histlen; i++){
            if(i >= historyInfo.length){
                historyInfo.push(HistoryInfo({rms: 0, pps: 0}));
            }
            if(i > 8){
                (historyInfo[i].pps, historyInfo[i].rms) = pool.historyInfo(i+7);
            }else{
                (historyInfo[i].pps, historyInfo[i].rms) = pool.historyInfo(i);
            }

        }
    }

    function initializeU(DogPoundAutoPool _pool, address [] memory _users) public {
        require(initAllowed[msg.sender]);
        require(initializeUnpaused);
        DogPoundAutoPool pool = DogPoundAutoPool(_pool);
        for(uint i = 0; i < _users.length; i++){
            (uint256 amount, uint256 lpMask, uint256 pigsClaimedTotal,  uint256 lastRmsClaimed, uint256 lpDebt, uint256 totalLPCollectedu, uint256 totalPigsCollected ) =  pool.userInfo(_users[i]);
            userInfo[_users[i]].amount =  amount;
            userInfo[_users[i]].lpMask =  lpMask;
            userInfo[_users[i]].pigsClaimedTotal =  pigsClaimedTotal;
            userInfo[_users[i]].lastRmsClaimed =  lastRmsClaimed;
            userInfo[_users[i]].lpDebt =  lpDebt;
            userInfo[_users[i]].totalLPCollected =  totalLPCollectedu;
            userInfo[_users[i]].totalPigsCollected =totalPigsCollected;
        }
    }

    function initializeMd(address [] memory _users, UserInfo [] memory _info) onlyOwner public {
        require(initializeUnpaused);
        for(uint i = 0; i <= _users.length; i++){
            userInfo[_users[i]] = _info[i];
        }
    }

    function initCompounders(address [] memory _users) onlyOwner public {
        require(initializeUnpaused);
        for(uint i = 0; i <= _users.length; i++){
            userInfo[_users[i]].lastRmsClaimed = userInfo[_users[i]].lpMask;
        }    
    }

    function deposit(address _user, uint256 _amount) external onlyDogPoundManager {
        UserInfo storage user = userInfo[_user];
        if(historyInfo.length != 0 && user.amount != 0){
            claimPigsInternal(_user);
        }
        totalDogsStaked += _amount;
        if(user.amount != 0){
            user.lpDebt += pendingLpRewardsInternal(_user); 
        }
        updateUserMask(_user);
        compound();
        user.amount += _amount;
    }

    function withdraw(address _user, uint256 _amount) external onlyDogPoundManager {
        compound();
        claimLpTokensAndPigsInternal(_user);
        UserInfo storage user = userInfo[_user];
        updateUserMask(_user);
        DogsToken.transfer(address(DogPoundManger), _amount);
        user.amount -= _amount;
        totalDogsStaked -= _amount;
    }

    function updateUserMask(address _user) internal {
        userInfo[_user].lpMask = lpRoundMask;
        userInfo[_user].lastRmsClaimed = historyInfo[historyInfo.length - 1].rms;
    }

    function getPigsEarned() internal returns (uint256){
        uint256 pigsBalance = PigsToken.balanceOf(address(this));
        uint256 pigsEarned = pigsBalance - lastPigsBalance;
        lastPigsBalance = pigsBalance;
        return pigsEarned;
    }
    
    function pendingLpRewardsInternal(address _userAddress) public view returns (uint256 pendingLp){
       UserInfo storage user = userInfo[_userAddress];
        pendingLp = (user.amount * (lpRoundMask - user.lpMask))/10e18;
        return pendingLp;
    }

    function pendingLpRewards(address _userAddress) public view returns (uint256 pendingLp){
        UserInfo storage user = userInfo[_userAddress];
        pendingLp = (user.amount * (lpRoundMask - user.lpMask))/10e18;
        return pendingLp  + user.lpDebt;
    }

    function claimLpTokensAndPigsInternal(address _user) internal {
        if(historyInfo.length > 0){
            claimPigsInternal(_user);
        }
        UserInfo storage user = userInfo[_user];
        uint256 lpPending = pendingLpRewards(_user);

        if (lpPending > 0){
            MasterchefPigs.withdraw(DOGS_BNB_MC_PID, lpPending);
            handlePigsIncrease();
            Dogs_BNB_LpToken.transfer(_user, lpPending);
            user.totalLPCollected += lpPending;
            totalLPCollected += lpPending;
            user.lpDebt = 0;
            user.lpMask = lpRoundMask;
            totalLpStaked -= lpPending;
        }

    }

    function claimLpTokensAndPigs() public {
        if(historyInfo.length > 0){
            claimPigs();
        }
        UserInfo storage user = userInfo[msg.sender];
        uint256 lpPending = pendingLpRewards(msg.sender);

        if (lpPending > 0){
            MasterchefPigs.withdraw(DOGS_BNB_MC_PID, lpPending);
            user.totalLPCollected += lpPending;
            totalLPCollected += lpPending;
            handlePigsIncrease();
            Dogs_BNB_LpToken.transfer(msg.sender, lpPending);
            user.lpDebt = 0;
            user.lpMask = lpRoundMask;
            totalLpStaked -= lpPending;
        }

    }

    function claimPigsHelper(uint256 startIndex) public {
        require(historyInfo.length > 0, "No History");
        require(startIndex <= historyInfo.length - 1);
        UserInfo storage user = userInfo[msg.sender];
        uint256 pigsPending;
        uint256 newPigsClaimedTotal;
        for(uint256 i = startIndex + 1; i > 0; i--){
            if(user.lastRmsClaimed > historyInfo[i - 1].rms){
                break;
            }
            if(user.lpMask > historyInfo[i - 1].rms ){
                break;
            }
            uint256 tempAmount =  (((user.amount * (historyInfo[i - 1].rms - user.lpMask))/ 10e18 + user.lpDebt) * historyInfo[i - 1].pps)/10e12;
            pigsPending += tempAmount;
            if(i - 1 == startIndex){
                newPigsClaimedTotal = tempAmount;
            }
        }
        user.lastRmsClaimed = historyInfo[startIndex].rms;
        uint256 pigsTransfered = 0;
        if(user.pigsClaimedTotal < pigsPending){
            pigsTransfered = pigsPending - user.pigsClaimedTotal;
            user.totalPigsCollected += pigsTransfered;
            lastPigsBalance -= pigsTransfered;
            PigsToken.transfer(msg.sender, pigsTransfered);
        }
        user.pigsClaimedTotal = newPigsClaimedTotal;
    }
    
    function claimPigsInternal(address _user) internal {
        require(historyInfo.length > 0, "No History");
        uint256 startIndex = historyInfo.length - 1;
        UserInfo storage user = userInfo[_user];
        uint256 pigsPending;
        uint256 newPigsClaimedTotal;
        for(uint256 i = startIndex + 1; i > 0; i--){
            if(user.lastRmsClaimed > historyInfo[i - 1].rms){
                break;
            }
            if(user.lpMask > historyInfo[i - 1].rms ){
                break;
            }
            uint256 tempAmount =  (((user.amount * (historyInfo[i - 1].rms - user.lpMask))/ 10e18 + user.lpDebt) * historyInfo[i - 1].pps)/10e12;
            pigsPending += tempAmount;
            if(i - 1 == startIndex){
                newPigsClaimedTotal = tempAmount;
            }
        }
        user.lastRmsClaimed = historyInfo[startIndex].rms;
        uint256 pigsTransfered = 0;
        if(user.pigsClaimedTotal < pigsPending){
            pigsTransfered = pigsPending - user.pigsClaimedTotal;
            user.totalPigsCollected += pigsTransfered;
            lastPigsBalance -= pigsTransfered;
            PigsToken.transfer(_user, pigsTransfered);
        }
        user.pigsClaimedTotal = newPigsClaimedTotal;

    }
    
    function pendingPigsRewardsHelper(address _user, uint256 startIndex) view public returns(uint256) {
        require(historyInfo.length > 0, "No History");
        require(startIndex <= historyInfo.length - 1);
        UserInfo storage user = userInfo[_user];
        uint256 pigsPending;
        for(uint256 i = startIndex + 1; i > 0; i--){
            if(user.lastRmsClaimed > historyInfo[i - 1].rms){
                break;
            }
            if(user.lpMask > historyInfo[i - 1].rms ){
                break;
            }
            uint256 tempAmount =  (((user.amount * (historyInfo[i - 1].rms - user.lpMask))/ 10e18 + user.lpDebt) * historyInfo[i - 1].pps)/10e12;
            pigsPending += tempAmount;
        }
        if(pigsPending <= user.pigsClaimedTotal){
            return 0;
        }
        return(pigsPending - user.pigsClaimedTotal);
    }

    function pendingPigsRewards(address _user) view public returns(uint256) {
        if(historyInfo.length == 0){
            return 0;
        }
        return pendingPigsRewardsHelper(_user, historyInfo.length - 1);
    }


    function claimPigs() public {
        require(historyInfo.length > 0, "No History");
        claimPigsHelper(historyInfo.length - 1);        
    }

    function pendingRewards(address _userAddress) public view returns (uint256 _pendingPigs, uint256 _pendingLp){
        require(historyInfo.length > 0, "No History");
        uint256 pendingLp = pendingLpRewardsInternal(_userAddress);
        uint256 pendingPigs = pendingPigsRewardsHelper(_userAddress, historyInfo.length - 1);
        return (pendingPigs, pendingLp + userInfo[_userAddress].lpDebt);
    }

    function compound() public {
        
        uint256 BnbBalance = address(this).balance;
        if (BnbBalance < BnbLiquidateThreshold){
            return;
        }

        uint256 BnbBalanceHalf = BnbBalance / 2;
        uint256 BnbBalanceRemaining = BnbBalance - BnbBalanceHalf;

        // Buy Dogs with half of the BNB
        uint256 amountDogsBought = DogsExchangeHelper.buyDogsBNB{value: BnbBalanceHalf}(0, _getBestBNBDogsSwapPath(BnbBalanceHalf));


        allowanceCheckAndSet(DogsToken, address(DogsExchangeHelper), amountDogsBought);
        (
        uint256 amountLiquidity,
        uint256 unusedTokenA,
        uint256 unusedTokenB
        ) = DogsExchangeHelper.addDogsBNBLiquidity{value: BnbBalanceRemaining}(amountDogsBought);
        lpRoundMasktemp = lpRoundMasktemp + amountLiquidity;
        if(block.timestamp - timeSinceLastCall >= updateInterval){
            lpRoundMask += (lpRoundMasktemp * 10e18)/totalDogsStaked;
            timeSinceLastCall = block.timestamp;
            lpRoundMasktemp = 0;
        }
        _stakeIntoMCPigs(amountLiquidity);
    }


    function _getBestBNBDogsSwapPath(uint256 _amountBNB) internal view returns (address[] memory){

        address[] memory pathBNB_BUSD_Dogs = _createRoute3(wbnbCurrencyAddress, busdCurrencyAddress , address(DogsToken));

        uint256[] memory amountOutBNB = PancakeRouter.getAmountsOut(_amountBNB, dogsBnbPath);
        uint256[] memory amountOutBNBviaBUSD = PancakeRouter.getAmountsOut(_amountBNB, pathBNB_BUSD_Dogs);

        if (amountOutBNB[amountOutBNB.length -1] > amountOutBNBviaBUSD[amountOutBNBviaBUSD.length - 1]){ 
            return dogsBnbPath;
        }
        return pathBNB_BUSD_Dogs;

    }

    function _createRoute3(address _from, address _mid, address _to) internal pure returns(address[] memory){
        address[] memory path = new address[](3);
        path[0] = _from;
        path[1] = _mid;
        path[2] = _to;
        return path;
    }

    function handlePigsIncrease() internal {
        uint256 pigsEarned = getPigsEarned();
        if(historyInfo.length > 0 && historyInfo[historyInfo.length - 1].rms == lpRoundMask){
            historyInfo[historyInfo.length - 1].pps += (pigsEarned * 10e12)/totalLPstakedTemp;
        }else{
            historyInfo.push(HistoryInfo({rms: lpRoundMask, pps: (pigsEarned * 10e12)/totalLpStaked}));
            totalLPstakedTemp = totalLpStaked;
        }
    }

    function increasePigsBuffer(uint256 quant) public onlyOwner{
        PigsToken.transferFrom(msg.sender, address(this), quant);
        lastPigsBalance += quant;
    }

    function _stakeIntoMCPigs(uint256 _amountLP) internal {
        allowanceCheckAndSet(IERC20(Dogs_BNB_LpToken), address(MasterchefPigs), _amountLP);
        MasterchefPigs.deposit(DOGS_BNB_MC_PID, _amountLP);
        totalLpStaked += _amountLP;
        handlePigsIncrease();
    }

    function allowanceCheckAndSet(IERC20 _token, address _spender, uint256 _amount) internal {
        uint256 allowance = _token.allowance(address(this), _spender);
        if (allowance < _amount) {
            require(_token.approve(_spender, _amount), "allowance err");
        }
    }

    function initMCStake() public onlyOwner{
        require(initializeUnpaused);
        lastPigsBalance = PigsToken.balanceOf(address(this));
        uint256 balance = IERC20(Dogs_BNB_LpToken).balanceOf(address(this));
        allowanceCheckAndSet(IERC20(Dogs_BNB_LpToken), address(MasterchefPigs), balance);
        totalLPstakedTemp = ( balance - lpRoundMasktemp ) * 998 / 1000;
        allowanceCheckAndSet(IERC20(Dogs_BNB_LpToken), address(MasterchefPigs), balance);
        MasterchefPigs.deposit(DOGS_BNB_MC_PID, balance);
        totalLpStaked += (balance * 998) / 1000;
        handlePigsIncrease();    
    }
    
    function initStakeMult(uint256 temp1, uint256 temp2) public onlyOwner{
        require(initializeUnpaused);
        totalLPstakedTemp = temp1;
        totalLpStaked = temp2;
    }

    function addInitAllowed(address _ad, bool _bool) public onlyOwner{
        initAllowed[_ad] = _bool;
    }

    function updateBnbLiqThreshhold(uint256 newThrehshold) public onlyOwner {
        BnbLiquidateThreshold = newThrehshold;
    }

    function updateDogsBnBPID(uint256 newPid) public onlyOwner {
        DOGS_BNB_MC_PID = newPid;
    }

    function pauseInitialize() external onlyOwner {
        initializeUnpaused = false;
    }

    function updateDogsAndLPAddress(address _addressDogs, address _addressLpBNB) public onlyOwner {
        Dogs_BNB_LpToken = IERC20(_addressLpBNB);
        updateDogsAddress(_addressDogs);
    }

   function updateDogsAddress(address _address) public onlyOwner {
        DogsToken = IERC20(_address);
        dogsBnbPath = [wbnbCurrencyAddress,address(DogsToken)];
    }

    function updatePigsAddress(address _address) public onlyOwner {
        PigsToken = IERC20(_address);
    }
    
    function allowCompound(uint256 _time) public onlyOwner{
        require(_time <= timeSinceLastCall, "time in future");
        timeSinceLastCall = _time;
    }

    function updateDogsExchanceHelperAddress(address _address) public onlyOwner {
        DogsExchangeHelper = IDogsExchangeHelper(_address);
    }

    function updateMasterchefPigsAddress(address _address) public onlyOwner {
        require(!MClocked);
        MasterchefPigs = IMasterchefPigs(_address);
    }

    function changeUpdateInterval(uint256 _time) public onlyOwner{
        updateInterval = _time;
    }

    function MClockedAddress() external onlyOwner{
        MClocked = true;
    }

    function lockDogPoundManager() external onlyOwner{
        managerNotLocked = false;
    }

    function setDogPoundManager(address _address) public onlyOwner {
        require(managerNotLocked);
        DogPoundManger = _address;
    }

}
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


    uint256 public DOGS_BNB_MC_PID = 1;
    uint256 public BnbLiquidateThreshold = 1e18;

    IERC20 public PigsToken = IERC20(0x9a3321E1aCD3B9F6debEE5e042dD2411A1742002);
    IERC20 public DogsToken = IERC20(0x198271b868daE875bFea6e6E4045cDdA5d6B9829);
    IERC20 public Dogs_BNB_LpToken = IERC20(0x2139C481d4f31dD03F924B6e87191E15A33Bf8B4);

    address public DogPoundManger;
    IDogsExchangeHelper public DogsExchangeHelper;
    IMasterchefPigs public MasterchefPigs;
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

    receive() external payable {}

    // Modifiers
    modifier onlyDogPoundManager() {
        require(DogPoundManger == msg.sender, "manager only");
        _;
    }

    constructor(address _DogPoundManger, IDogsExchangeHelper _dogsExchangeHelper, IMasterchefPigs _masterchefPigs){
        DogPoundManger = _DogPoundManger;
        DogsExchangeHelper = _dogsExchangeHelper;
        MasterchefPigs = _masterchefPigs;
        timeSinceLastCall = block.timestamp;
    }

    function deposit(address _user, uint256 _amount) external onlyDogPoundManager {
        if(historyInfo.length != 0){
            claimPigs();
        }
        totalDogsStaked += _amount;
        compound();
        UserInfo storage user = userInfo[_user];
        if(user.lpMask != 0){
            user.lpDebt += pendingLpRewardsInternal(_user); 
        }
        updateUserMask(_user);
        user.lastRmsClaimed = lpRoundMask;
        user.amount += _amount;
    }

    function withdraw(address _user, uint256 _amount) external onlyDogPoundManager {
        compound();
        claimLpTokensAndPigsInternal(_user);
        UserInfo storage user = userInfo[_user];
        updateUserMask(_user);
        DogsToken.transfer(address(DogPoundManger), _amount); // must handle receiving in DogPoundManger
        user.amount -= _amount;
        totalDogsStaked -= _amount;
    }

    function updateUserMask(address _user) internal {

        userInfo[_user].lpMask = lpRoundMask;

    }

    function getPigsEarned() public returns (uint256){
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
        uint256 lpPendingInternal = pendingLpRewardsInternal(_user);

        if (lpPending > 0){
            MasterchefPigs.withdraw(DOGS_BNB_MC_PID, lpPending);
            handlePigsIncrease();
            Dogs_BNB_LpToken.transfer(_user, lpPending);
            user.totalLPCollected += lpPending;
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
        uint256 lpPendingInternal = pendingLpRewardsInternal(msg.sender);

        if (lpPending > 0){
            MasterchefPigs.withdraw(DOGS_BNB_MC_PID, lpPending);
            user.totalLPCollected += lpPending;
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
            if(historyInfo[i - 1].rms < user.lastRmsClaimed){
                break;
            }
            uint256 tempAmount =  (((user.amount * (lpRoundMask - historyInfo[i - 1].rms))/ 10e18) * historyInfo[i - 1].pps)/10e18;
            pigsPending += tempAmount;
            if(i - 1 == startIndex){
                newPigsClaimedTotal = tempAmount;
            }
        }
        user.lastRmsClaimed = historyInfo[startIndex].rms;
        uint256 pigsTransfered = pigsPending - user.pigsClaimedTotal;
        user.totalPigsCollected += pigsTransfered;
        lastPigsBalance -= pigsTransfered;
        PigsToken.transfer(msg.sender, pigsTransfered);
        user.pigsClaimedTotal = newPigsClaimedTotal;
        
    }
    
    function claimPigsInternal(address _user) internal {
        require(historyInfo.length > 0, "No History");
        uint256 startIndex = historyInfo.length - 1;
        UserInfo storage user = userInfo[_user];
        uint256 pigsPending;
        uint256 newPigsClaimedTotal;
        for(uint256 i = startIndex + 1; i > 0; i--){
            if(historyInfo[i - 1].rms < user.lastRmsClaimed){
                break;
            }
            uint256 tempAmount =  (((user.amount * (lpRoundMask - historyInfo[i - 1].rms))/ 10e18) * historyInfo[i - 1].pps)/10e18;
            pigsPending += tempAmount;
            if(i - 1 == startIndex){
                newPigsClaimedTotal = tempAmount;
            }
        }
        user.lastRmsClaimed = historyInfo[startIndex].rms;
        uint256 pigsTransfered = pigsPending - user.pigsClaimedTotal;
        user.totalPigsCollected += pigsTransfered;
        lastPigsBalance -= pigsTransfered;
        PigsToken.transfer(_user, pigsTransfered);
        user.pigsClaimedTotal = newPigsClaimedTotal;

    }
    
    
    function pendingPigsRewardsHelper(address _user, uint256 startIndex) view public returns(uint256) {
        require(historyInfo.length > 0, "No History");
        require(startIndex <= historyInfo.length - 1);
        UserInfo storage user = userInfo[_user];
        uint256 pigsPending;
        for(uint256 i = startIndex + 1; i > 0; i--){
            if(historyInfo[i - 1].rms < user.lastRmsClaimed){
                break;
            }
            uint256 tempAmount =  (((user.amount * (lpRoundMask - historyInfo[i - 1].rms))/ 10e18) * historyInfo[i - 1].pps)/10e18;
            pigsPending += tempAmount;
        }
        if(pigsPending < user.pigsClaimedTotal){
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
        _stakeIntoMCPigs(amountLiquidity);
        lpRoundMasktemp = lpRoundMasktemp + amountLiquidity;
        if(block.timestamp - timeSinceLastCall >= updateInterval){
            lpRoundMask += (lpRoundMasktemp * 10e18)/totalDogsStaked;
            timeSinceLastCall = block.timestamp;
            lpRoundMasktemp = 0;
        }
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
        if(pigsEarned > 0){
            if(historyInfo.length > 0 && historyInfo[historyInfo.length - 1].rms == lpRoundMask){
                historyInfo[historyInfo.length - 1].pps += (pigsEarned * 10e12)/totalLpStaked;
            }else{
                historyInfo.push(HistoryInfo({rms: lpRoundMask, pps: (pigsEarned * 10e12)/totalLpStaked}));
            }
        }
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

    function updateBnbLiqThreshhold(uint256 newThrehshold) public onlyOwner {
        BnbLiquidateThreshold = newThrehshold;
    }

    function updateDogsBnBPID(uint256 newPid) public onlyOwner {
        DOGS_BNB_MC_PID = newPid;
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

    function updateDogsExchanceHelperAddress(address _address) public onlyOwner {
        DogsExchangeHelper = IDogsExchangeHelper(_address);
    }

    function updateMasterchefPigsAddress(address _address) public onlyOwner {
        MasterchefPigs = IMasterchefPigs(_address);
    }

    function setDogPoundManager(address _address) public onlyOwner {
        DogPoundManger = _address;
    }

}
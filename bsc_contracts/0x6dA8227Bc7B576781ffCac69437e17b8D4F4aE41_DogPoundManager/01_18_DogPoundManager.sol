pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IRewardsVault.sol";
import "./interfaces/IPancakePair.sol";
import "./interfaces/IMasterchefPigs.sol";
import "./interfaces/IPancakeFactory.sol";
import "./interfaces/IDogsToken.sol";
import "./interfaces/IDogPoundActions.sol";
import "./interfaces/IStakeManager.sol";
import "./interfaces/IRewardsVault.sol";


interface IDogPoundPool {
    function deposit(address _user, uint256 _amount) external;
    function withdraw(address _user, uint256 _amount) external;
    function getStake(address _user, uint256 _stakeID) external view returns(uint256 stakedAmount);
}

contract DogPoundManager is Ownable {
    using SafeERC20 for IERC20;

    IStakeManager public StakeManager;
    IDogPoundPool public DogPoundLinearPool;
    IDogPoundPool public DogPoundAutoPool;
    IDogPoundActions public DogPoundActions;
    IRewardsVault public rewardsVault;

    bool public isPaused;
    uint256 public walletReductionPerMonth = 200;
    uint256 public burnPercent = 30;
    uint256 public minHoldThreshold = 10e18;
    uint256 public linearPoolSize = 0;
    uint256 public autoPoolSize = 0;
    uint256 public loyaltyScoreMaxReduction = 3000;
    uint256 public dogsDefaultTax = 9000;
    uint256 public minDogVarTax = 300;
    uint256 public withdrawlRestrictionTime = 24 hours;
    IDogsToken public DogsToken;
    IUniswapV2Router02 public constant PancakeRouter = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    struct UserInfo {
        uint256 walletStartTime;
        uint256 overThresholdTimeCounter;
        uint256 lastDepositTime;
        uint256 totalStaked;
    }

    struct StakeInfo {
        uint256 amount;
        uint256 startTime;
        bool isAutoPool;
    } 

    mapping(address => UserInfo) public userInfo;

    modifier notPaused() {
        require(!isPaused, "notPaused: DogPound paused !");
        _;
    }

    constructor(address _Dogaddress){
        DogsToken = IDogsToken(_Dogaddress);
        _approveTokenIfNeeded(_Dogaddress);
    }
    

    function deposit(uint256 _amount, bool _isAutoCompound) external notPaused {
        require(_amount > 0, 'deposit !> 0');
        StakeManager.saveStake(msg.sender, _amount, _isAutoCompound);
        DogsToken.transferFrom(msg.sender, address(this), _amount);
        if (StakeManager.totalStaked(msg.sender) >= minHoldThreshold && userInfo[msg.sender].walletStartTime == 0){
                userInfo[msg.sender].walletStartTime = block.timestamp;
        }
        if (_isAutoCompound){
            DogsToken.transfer(address(DogPoundAutoPool), _amount);
            DogPoundAutoPool.deposit(msg.sender, _amount);
            autoPoolSize += _amount;
        } else {
            DogsToken.transfer(address(DogPoundLinearPool), _amount);
            DogPoundLinearPool.deposit(msg.sender, _amount);
            linearPoolSize += _amount;
        }
        userInfo[msg.sender].totalStaked += _amount;
        userInfo[msg.sender].lastDepositTime = block.timestamp;

    }

    function withdrawToWallet(uint256 _amount, uint256 _stakeID) external notPaused {
        require(block.timestamp - userInfo[msg.sender].lastDepositTime > withdrawlRestrictionTime,"withdrawl locked");
        _withdraw(_amount, _stakeID);
        if (StakeManager.totalStaked(msg.sender) < minHoldThreshold && userInfo[msg.sender].walletStartTime > 0){
            userInfo[msg.sender].overThresholdTimeCounter += block.timestamp - userInfo[msg.sender].walletStartTime;
            userInfo[msg.sender].walletStartTime = 0;
        }
        DogsToken.updateTransferTaxRate(0);
        DogsToken.transfer(msg.sender, _amount);
        DogsToken.updateTransferTaxRate(dogsDefaultTax);
    }

    function swapFromWithdrawnStake(uint256 _amount, uint256 _stakeID, address[] memory path) public {
        StakeManager.utilizeWithdrawnStake(msg.sender, _amount, _stakeID);
        uint256 taxReduction = totalTaxReductionWithdrawnStake(msg.sender, _stakeID);
        DogsToken.transferFrom(msg.sender, address(this), _amount);
        doSwap(address(this), _amount, taxReduction, path);
        IERC20 transfertoken = IERC20(path[path.length - 1]);
        uint256 balance = transfertoken.balanceOf(address(this));
        uint256 balance2 = DogsToken.balanceOf(address(this));
        DogsToken.updateTransferTaxRate(0);
        DogsToken.transfer(msg.sender, balance2);
        DogsToken.updateTransferTaxRate(dogsDefaultTax);
        transfertoken.transfer(msg.sender, balance);
    }

    function transferFromWithdrawnStake(uint256 _amount, address _to, uint256 _stakeID) public {
        StakeManager.utilizeWithdrawnStake(msg.sender, _amount, _stakeID);
        uint256 taxReduction = totalTaxReductionWithdrawnStake(msg.sender, _stakeID);
        DogsToken.transferFrom(msg.sender, address(this), _amount);
        doTransfer(_to , _amount, taxReduction);
    }

    function swapDogsWithLoyalty(uint256 _amount, address[] memory path) public {
        uint256 taxReduction = totalTaxReductionLoyaltyOnly(msg.sender);
        DogsToken.transferFrom(msg.sender, address(this), _amount);
        doSwap(address(this), _amount, taxReduction, path);
        IERC20 transfertoken = IERC20(path[path.length - 1]);
        uint256 balance = transfertoken.balanceOf(address(this));
        uint256 balance2 = DogsToken.balanceOf(address(this));
        DogsToken.updateTransferTaxRate(0);
        DogsToken.transfer(msg.sender, balance2);
        DogsToken.updateTransferTaxRate(dogsDefaultTax);
        transfertoken.transfer(msg.sender, balance);
    }

    function transferDogsWithLoyalty(uint256 _amount, address _to) public {
        uint256 taxReduction = totalTaxReductionLoyaltyOnly(msg.sender);
        DogsToken.transferFrom(msg.sender, address(this), _amount);
        doTransfer(_to ,_amount, taxReduction);
    }

    function _approveTokenIfNeeded(address token) private {
        if (IERC20(token).allowance(address(this), address(PancakeRouter)) == 0) {
            IERC20(token).safeApprove(address(PancakeRouter), type(uint256).max);
        }
    }

    // Internal functions
    function _withdraw(uint256 _amount, uint256 _stakeID) internal {
        bool isAutoPool = StakeManager.isStakeAutoPool(msg.sender, _stakeID);
        StakeManager.withdrawFromStake(msg.sender ,_amount, _stakeID); //require amount makes sense for stake
        if (isAutoPool){
            DogPoundAutoPool.withdraw(msg.sender, _amount);
            autoPoolSize -= _amount;
        } else {
            DogPoundLinearPool.withdraw(msg.sender, _amount);
            linearPoolSize -= _amount;
        }
        userInfo[msg.sender].totalStaked -= _amount;
    }

    // View functions
    function walletTaxReduction(address _user) public view returns (uint256){
        UserInfo storage user = userInfo[_user];
        uint256 currentReduction = 0;
        if (StakeManager.totalStaked(_user) < minHoldThreshold){
            currentReduction = (user.overThresholdTimeCounter / 30 days) * walletReductionPerMonth;
            if(currentReduction > loyaltyScoreMaxReduction){
                return loyaltyScoreMaxReduction;
            }
            return currentReduction;
        }
        currentReduction = (((block.timestamp - user.walletStartTime) + user.overThresholdTimeCounter) / 30 days) * walletReductionPerMonth;
        if(currentReduction > loyaltyScoreMaxReduction){
            return loyaltyScoreMaxReduction;
        }
        return currentReduction;    
    }

    function totalTaxReductionLoyaltyOnly(address _user)public view returns (uint256){
        uint256 walletReduction = walletTaxReduction(_user);
        if(walletReduction > (dogsDefaultTax - minDogVarTax)){
            walletReduction = (dogsDefaultTax - minDogVarTax);
        }else{
            walletReduction = dogsDefaultTax - walletReduction - minDogVarTax;
        }
        return walletReduction;
    }
    

    function totalTaxReductionWithdrawnStake(address _user, uint256 _stakeID) public view returns (uint256){
        uint256 stakeReduction = StakeManager.getWithdrawnStakeTaxReduction(_user, _stakeID);
        uint256 walletReduction = walletTaxReduction(_user);
        uint256 _totalTaxReduction = stakeReduction + walletReduction;
        if(_totalTaxReduction > (dogsDefaultTax - minDogVarTax)){
            _totalTaxReduction = (dogsDefaultTax - minDogVarTax);
        }else{
            _totalTaxReduction = dogsDefaultTax - _totalTaxReduction - minDogVarTax;
        }
        return _totalTaxReduction;
    }

    function setminHoldThreshold(uint256 _minHoldThreshold) external onlyOwner{
        minHoldThreshold = _minHoldThreshold;
    }

    function setAutoPool(address _autoPool) external onlyOwner {
        DogPoundAutoPool = IDogPoundPool(_autoPool);
    }

    function setLinearPool(address _linearPool) external onlyOwner {
        DogPoundLinearPool = IDogPoundPool(_linearPool);
    }

    function setStakeManager(IStakeManager _stakeManager) external onlyOwner {
        StakeManager = _stakeManager;
    }

    function changeWalletReductionRate(uint256 walletReduction) external onlyOwner{
        require(walletReduction < 1000);
        walletReductionPerMonth = walletReduction;
    }

    function changeWalletCapReduction(uint256 walletReductionCap) external onlyOwner{
        require(walletReductionCap < 6000);
        loyaltyScoreMaxReduction = walletReductionCap;
    }

    function getAutoPoolSize() external view returns (uint256){
        if(linearPoolSize == 0 ){
            return 0;
        }
        return (autoPoolSize*10000/(linearPoolSize+autoPoolSize));
    }

    function totalStaked(address _user) external view returns (uint256){
        return userInfo[_user].totalStaked;
    }

    function changeBurnPercent(uint256 newBurn) external onlyOwner{
        require(burnPercent < 200);
        burnPercent = newBurn;
    }

    function doSwap(address _to, uint256 _amount, uint256 _taxReduction, address[] memory path) internal  {
        uint256 burnAmount = (_amount * burnPercent)/1000;
        uint256 leftAmount =  _amount - burnAmount;
        uint256 tempTaxval = 1e14/(1e3 -burnPercent);
        uint256 taxreductionNew = (_taxReduction * tempTaxval) / 1e11;

        DogsToken.updateTransferTaxRate(taxreductionNew);
        // make the swap
        PancakeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            leftAmount,
            0, // accept any amount of tokens
            path,
            _to,
            block.timestamp
        );

        DogsToken.updateTransferTaxRate(dogsDefaultTax);

        DogsToken.burn(burnAmount);

    }

    function doTransfer(address _to, uint256 _amount, uint256 _taxReduction) internal {
        uint256 burnAmount = (_amount * burnPercent)/1000;
        uint256 leftAmount =  _amount - burnAmount;
        uint256 tempTaxval = 1e14/(1e3 - burnPercent);
        uint256 taxreductionNew = (_taxReduction * tempTaxval) / 1e11;

        DogsToken.updateTransferTaxRate(taxreductionNew);

        DogsToken.transfer(_to, leftAmount);

        DogsToken.updateTransferTaxRate(dogsDefaultTax);

        DogsToken.burn(burnAmount);

    }

    function setDogsTokenAndDefaultTax(address _address, uint256 _defaultTax) external onlyOwner {
        DogsToken = IDogsToken(_address);
        dogsDefaultTax = _defaultTax;
    }

    function setRewardsVault(address _rewardsVaultAddress) public onlyOwner{
        rewardsVault = IRewardsVault(_rewardsVaultAddress);
    }

}
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IRewardsVault.sol";


contract DogPoundLinearPool is Ownable, ReentrancyGuard{


    uint256 public accDepositBNBRewardPerShare = 0;
    uint256 public totalDeposited = 0;
    uint256 public bnbRewardBalance = 0;
    uint256 public totalBNBCollected = 0;
    bool public vaultPay = false;
    IERC20 public DogsToken;
    IRewardsVault public rewardsVault;

    address public DogPoundManger;

    struct UserInfo {
        uint256 totalStaked;
        uint256 bnbRewardDebt;
        uint256 totalBNBCollected;
    }

    mapping(address => UserInfo) public userInfo;

    receive() external payable {}

    // Modifiers
    modifier onlyDogPoundManager() {
        require(DogPoundManger == msg.sender, "manager only");
        _;
    }

    constructor(address _DogPoundManger,address _rewardsVaultAddress){
        rewardsVault = IRewardsVault(_rewardsVaultAddress);
        DogPoundManger = _DogPoundManger;
    }

    function deposit(address _user, uint256 _amount) external onlyDogPoundManager nonReentrant {
        if(vaultPay){
            rewardsVault.payoutDivs();
        }
        UserInfo storage user = userInfo[_user];
        updatePool();
        uint256 bnbPending = payPendingBNBReward(_user);
        totalDeposited += _amount;
        user.totalBNBCollected += bnbPending;
        user.totalStaked += _amount;
        user.bnbRewardDebt = ((user.totalStaked * accDepositBNBRewardPerShare) / 1e24);
        if(bnbPending > 0 ){
            payable(_user).transfer(bnbPending);
        }
    }

    function withdraw(address _user, uint256 _amount) external onlyDogPoundManager nonReentrant {
        if(vaultPay){
            rewardsVault.payoutDivs();
        }
        UserInfo storage user = userInfo[_user];
        updatePool();
        uint256 bnbPending = payPendingBNBReward(_user);
        DogsToken.transfer(address(DogPoundManger), _amount); // must handle receiving in DogPoundManger
        user.totalBNBCollected += bnbPending;
        user.totalStaked -= _amount;
        totalDeposited -= _amount;
        user.bnbRewardDebt = ((user.totalStaked * accDepositBNBRewardPerShare) / 1e24);
        if(bnbPending > 0 ){
            payable(_user).transfer(bnbPending);
        }
    }

    function updatePool() public  {
        if (totalDeposited > 0) {
            uint256 bnbReceived = checkBNBRewardsReceived();
            if (bnbReceived > 0){
                accDepositBNBRewardPerShare = accDepositBNBRewardPerShare + ((bnbReceived * 1e24) / totalDeposited);
                totalBNBCollected += bnbReceived;
            }
        }
    }

    // Pay pending BNB from the DOGS staking reward scheme.
    function payPendingBNBReward(address _user) internal returns (uint256) {
        UserInfo storage user = userInfo[_user];

        uint256 bnbPending = ((user.totalStaked * accDepositBNBRewardPerShare) / 1e24) - user.bnbRewardDebt;
        
        if (bnbPending > 0) {
            return bnbPending;
        }
        if(bnbRewardBalance < bnbPending ){
            bnbRewardBalance = 0; 
            return 0; 
        }else{
            bnbRewardBalance = bnbRewardBalance - bnbPending; 
            return 0; 
        }

    }


    function pendingBNBReward(address _user) external view returns(uint256){
        UserInfo storage user = userInfo[_user];
        uint256 bnbPending = ((user.totalStaked * accDepositBNBRewardPerShare) / 1e24) - user.bnbRewardDebt;
        return bnbPending;
    }

    function claim() public nonReentrant {
        if(vaultPay){
            rewardsVault.payoutDivs();
        }
        updatePool();
        uint256 bnbPending = payPendingBNBReward(msg.sender);
        UserInfo storage user = userInfo[msg.sender];
        user.totalBNBCollected += bnbPending;
        user.bnbRewardDebt = ((user.totalStaked * accDepositBNBRewardPerShare) / 1e24);
        if(bnbPending > 0 ){
            payable(msg.sender).transfer(bnbPending);
        }
    }

    function checkBNBRewardsReceived() internal returns (uint256) {
        uint256 totalBNBBalance = address(this).balance;
        if (totalBNBBalance == 0) {
            return 0;
        }

        uint256 bnbReceived = totalBNBBalance - bnbRewardBalance;
        bnbRewardBalance = totalBNBBalance;

        return bnbReceived;
    }

    function setVaultPay(bool _bool) external onlyOwner{
            vaultPay = _bool;
    }

    function switchRewardVault(address _newvault)external onlyOwner{
        rewardsVault = IRewardsVault(_newvault);
    }

    function setDogsToken(address _address) public onlyOwner {
        DogsToken = IERC20(_address);
    }

    function setDogPoundManager(address _address) public onlyOwner {
        DogPoundManger = _address;
    }
}
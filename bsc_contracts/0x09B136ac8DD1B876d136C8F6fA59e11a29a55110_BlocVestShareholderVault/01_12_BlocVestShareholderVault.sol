// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @author Brewlabs
 * This contract has been developed by brewlabs.info
 */
 
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../libs/IPriceOracle.sol";
import "../libs/IUniRouter02.sol";
import "../libs/IWETH.sol";

contract BlocVestShareholderVault is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Whether it is initialized
    bool public isInitialized;
    bool public isActive = false;
    IPriceOracle private oracle;

    uint256 public lockDuration = 3 * 30; // 3 months
    uint256 public harvestCycle = 30; // 30 days
    uint256 constant TIME_UNITS = 1 days;

    // swap router and path, slipPage
    address public uniRouterAddress;
    address[] public earnedToStakedPath;
    uint256 public slippageFactor = 8000; // 20% default slippage tolerance
    uint256 public constant slippageFactorUL = 9950;

    address public treasury = 0xBd6B80CC1ed8dd3DBB714b2c8AD8b100A7712DA7;
    uint256 public performanceFee = 0.0035 ether;
    bool public activeEmergencyWithdraw = false;

    // The staked token
    IERC20 public stakingToken;
    // The earned token
    IERC20 public earnedToken;

    // The precision factor
    uint256 public PRECISION_FACTOR;

    uint256 public totalStaked;
    uint256 public prevPeriodAccToken;

    // Accrued token per share
    uint256 public accTokenPerShare;
    uint256 private totalEarned;
    uint256 private totalPaid;

    struct UserInfo {
        uint256 amount; // How many staked tokens the user has provided
        uint256 usdAmount;
        uint256 lastDepositTime;
        uint256 lastClaimTime;
        uint256 totalEarned;
        uint256 rewardDebt; // Reward debt
    }
    // Info of each user that stakes tokens (stakingToken)
    mapping(address => UserInfo) public userInfo;

    struct PartnerInfo {
        uint256 amount;
        uint256 totalEarned;
        uint256 rewardDebt; // Reward debt
    }
    // Info of each user that stakes tokens (stakingToken)
    mapping(address => PartnerInfo) public partnerInfo;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event AdminTokenRecovered(address tokenRecovered, uint256 amount);
    event SetEmergencyWithdrawStatus(bool status);
    event AddPartner(address indexed user, uint256 amount);
    event RemovePartner(address indexed user);

    event ActiveUpdated(bool isActive);
    event LockDurationUpdated(uint256 _duration);
    event HarvestCycleUpdated(uint256 _duration);
    event ServiceInfoUpadted(address addr, uint256 fee);

    event SetSettings(
        uint256 _slippageFactor,
        address _uniRouter,
        address[] _path0
    );

    modifier onlyActive () {
        require(isActive, "not enabled");
        _;
    }

    constructor() {}

    /*
     * @notice Initialize the contract
     * @param _stakingToken: staked token address
     * @param _earnedToken: earned token address
     * @param _uniRouter: uniswap router address for swap tokens
     * @param _earnedToStakedPath: swap path to compound (earned -> staking path)
     * @param _oracle: price oracle
     */
    function initialize(
        IERC20 _stakingToken,
        IERC20 _earnedToken,
        address _uniRouter,
        address[] memory _earnedToStakedPath,
        address _oracle
    ) external onlyOwner {
        require(!isInitialized, "Already initialized");

        // Make this contract initialized
        isInitialized = true;

        stakingToken = _stakingToken;
        earnedToken = _earnedToken;
        oracle = IPriceOracle(_oracle);


        uint256 decimalsRewardToken = uint256(IERC20Metadata(address(earnedToken)).decimals());
        require(decimalsRewardToken < 30, "Must be inferior to 30");
        PRECISION_FACTOR = uint256(10**(40 - decimalsRewardToken));

        uniRouterAddress = _uniRouter;
        earnedToStakedPath = _earnedToStakedPath;
    }

    function deposit(uint256 _amount) external payable onlyActive nonReentrant {
        require(_amount > 0, "Amount should be greator than 0");

        UserInfo storage user = userInfo[msg.sender];

        _transferPerformanceFee();
        _updatePool();

        uint256 beforeAmount = 0;
        uint256 afterAmount = 0;
        uint256 pending = 0;
        if (user.amount > 0) {
            pending = user.amount * accTokenPerShare / PRECISION_FACTOR - user.rewardDebt;
            pending = estimateRewardAmount(pending);
            if (pending > 0) {
                require(availableRewardTokens() >= pending, "Insufficient reward tokens");

                totalPaid = totalPaid + pending;
                totalEarned = totalEarned - pending;
                
                if(address(stakingToken) != address(earnedToken)) {
                    beforeAmount = stakingToken.balanceOf(address(this));
                    _safeSwap(pending, earnedToStakedPath, address(this));
                    afterAmount = stakingToken.balanceOf(address(this));
                    pending = afterAmount - beforeAmount;
                }
            }
        }
        
        beforeAmount = stakingToken.balanceOf(address(this));
        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
        afterAmount = stakingToken.balanceOf(address(this));
        
        uint256 realAmount = afterAmount - beforeAmount + pending;
        uint256 tokenPrice = oracle.getTokenPrice(address(stakingToken));
        require(tokenPrice > 0, "invalid token price");
        
        user.amount = user.amount + realAmount;
        user.usdAmount = user.usdAmount + realAmount * tokenPrice / 1e18;
        user.totalEarned = user.totalEarned + pending;
        user.lastDepositTime = block.timestamp;
        user.lastClaimTime = block.timestamp;
        user.rewardDebt = user.amount * accTokenPerShare / PRECISION_FACTOR;

        totalStaked = totalStaked + realAmount;
        
        emit Deposit(msg.sender, realAmount);
    }

    /*
     * @notice Withdraw staked tokens and collect reward tokens
     * @param _amount: amount to withdraw (in earnedToken)
     */
    function withdraw(uint256 _amount) external payable onlyActive nonReentrant {
        require(_amount > 0, "Amount should be greator than 0");

        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "Amount to withdraw too high");
        require(user.lastDepositTime + (lockDuration * TIME_UNITS) < block.timestamp, "cannot withdraw");

        _transferPerformanceFee();
        _updatePool();

        uint256 pending = user.amount * accTokenPerShare / PRECISION_FACTOR - user.rewardDebt;
        pending = estimateRewardAmount(pending);
        if (pending > 0 && user.lastClaimTime + (harvestCycle * TIME_UNITS) < block.timestamp) {
            require(availableRewardTokens() >= pending, "Insufficient reward tokens");
            earnedToken.safeTransfer(address(msg.sender), pending);
            
            totalPaid = totalPaid + pending;
            totalEarned = totalEarned - pending;
        } else {
            pending = 0;
        }
        
        uint256 realAmount = _amount;
        uint256 tokenPrice = oracle.getTokenPrice(address(stakingToken));
        if(realAmount * tokenPrice / 1e18 > user.usdAmount) {
            realAmount = user.usdAmount * 1e18 / tokenPrice;
            totalStaked = totalStaked - user.amount;
            
            user.amount = 0;
            user.usdAmount = 0;
        } else {
            totalStaked = totalStaked - _amount;

            user.amount = user.amount - _amount;
            user.usdAmount = user.usdAmount - _amount * tokenPrice / 1e18;
        }
        
        stakingToken.safeTransfer(address(msg.sender), realAmount);
        user.totalEarned = user.totalEarned + pending;
        user.rewardDebt = user.amount * accTokenPerShare / PRECISION_FACTOR;

        emit Withdraw(msg.sender, realAmount);
    }

    function harvest(address _to) external payable onlyActive nonReentrant {
        require(_to != address(0x0), "invalid address");
        UserInfo storage user = userInfo[msg.sender];

        _transferPerformanceFee();
        _updatePool();

        if (user.amount == 0) return;
        require(user.lastClaimTime + (harvestCycle * TIME_UNITS) < block.timestamp, "cannot harvest");

        uint256 pending = user.amount * accTokenPerShare / PRECISION_FACTOR - user.rewardDebt;
        pending = estimateRewardAmount(pending);
        if (pending > 0) {
            require(availableRewardTokens() >= pending, "Insufficient reward tokens");
            earnedToken.safeTransfer(_to, pending);
            
            totalPaid = totalPaid + pending;
            totalEarned = totalEarned - pending;
        }
        
        user.totalEarned = user.totalEarned + pending;
        user.rewardDebt = user.amount * accTokenPerShare / PRECISION_FACTOR;
        user.lastClaimTime = block.timestamp;
    }
    
    function harvestForPartner() external {
        PartnerInfo storage user = partnerInfo[msg.sender];

        _updatePool();

        if (user.amount == 0) return;

        uint256 pending = user.amount * accTokenPerShare / PRECISION_FACTOR - user.rewardDebt;
        pending = estimateRewardAmount(pending);
        if (pending > 0) {
            require(availableRewardTokens() >= pending, "Insufficient reward tokens");
            earnedToken.safeTransfer(msg.sender, pending);
            
            totalPaid = totalPaid + pending;
            totalEarned = totalEarned - pending;
        }
        
        user.totalEarned = user.totalEarned + pending;
        user.rewardDebt = user.amount * accTokenPerShare / PRECISION_FACTOR;
    }

    function _transferPerformanceFee() internal {
        require(msg.value >= performanceFee, 'should pay small gas to compound or harvest');

        payable(treasury).transfer(performanceFee);
        if(msg.value > performanceFee) {
            payable(msg.sender).transfer(msg.value - performanceFee);
        }
    }

    /*
     * @notice Withdraw staked tokens without caring about rewards
     * @dev Needs to be for emergency.
     */
    function emergencyWithdraw() external nonReentrant {
        require(activeEmergencyWithdraw, "Emergnecy withdraw not enabled");

        UserInfo storage user = userInfo[msg.sender];
        uint256 amountToTransfer = user.amount;
        if(amountToTransfer < 0) return;

        uint256 pending = user.amount * accTokenPerShare / PRECISION_FACTOR - user.rewardDebt;
        pending = estimateRewardAmount(pending);
        totalEarned = totalEarned - pending;
        totalStaked = totalStaked - amountToTransfer;
        
        uint256 tokenPrice = oracle.getTokenPrice(address(stakingToken));
        if(amountToTransfer * tokenPrice / 1e18 > user.usdAmount) {
            amountToTransfer = user.usdAmount * 1e18 / tokenPrice;
        }
        stakingToken.safeTransfer(address(msg.sender), amountToTransfer);

        user.amount = 0;
        user.usdAmount = 0;
        user.rewardDebt = 0;

        emit EmergencyWithdraw(msg.sender, user.amount);
    }

    function allTimeRewards() external view returns (uint256) {
        return totalPaid + availableRewardTokens();
    }

    /**
     * @notice Available amount of reward token
     */
    function availableRewardTokens() public view returns (uint256) {
        uint256 _amount = earnedToken.balanceOf(address(this));
        if (address(earnedToken) == address(stakingToken)) {
            if (_amount < totalStaked) return 0;
            return _amount - totalStaked;
        }

        return _amount;
    }

    /*
     * @notice View function to see pending reward on frontend.
     * @param _user: user address
     * @return Pending reward for a given user
     */
    function pendingRewards(address _user) external view returns (uint256) {
        if(totalStaked == 0) return 0;

        UserInfo memory user = userInfo[_user];
        
        uint256 rewardAmount = availableRewardTokens();
        if(rewardAmount < totalEarned) {
            rewardAmount = totalEarned;
        }

        uint256 adjustedTokenPerShare = accTokenPerShare + (
                (rewardAmount - totalEarned) * PRECISION_FACTOR / totalStaked
            );
        
        return user.amount * adjustedTokenPerShare / PRECISION_FACTOR - user.rewardDebt;
    }

    function pendingPartnerRewards(address _user) external view returns (uint256) {
        PartnerInfo memory user = partnerInfo[_user];

        uint256 rewardAmount = availableRewardTokens();
        if(rewardAmount < totalEarned) {
            rewardAmount = totalEarned;
        }

        uint256 adjustedTokenPerShare = accTokenPerShare + (
                (rewardAmount - totalEarned) * PRECISION_FACTOR / totalStaked
            );

        return user.amount * adjustedTokenPerShare / PRECISION_FACTOR - user.rewardDebt;
    }
    
    function addPartners(uint256 _amount, address[] memory _users, uint256[] memory _allocs) external onlyOwner {
        require(_amount > 0, "Amount should be greator than 0");
        require(_users.length > 0, "empty users");
        require(_users.length == _allocs.length, "invalid params");

        _updatePool();
        
        uint256 beforeAmount = stakingToken.balanceOf(address(this));
        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 afterAmount = stakingToken.balanceOf(address(this));        
        uint256 realAmount = afterAmount - beforeAmount;
        
        uint256 totalAlloc = 0;
        for(uint i = 0; i < _users.length; i++) {
            require(_allocs[i] < 10000, "invalid percentage");
            totalAlloc += _allocs[i];

            PartnerInfo storage user = partnerInfo[_users[i]];
            uint256 allocAmt = realAmount * _allocs[i] / 10000;
            user.amount += allocAmt;
            user.rewardDebt += allocAmt * accTokenPerShare / PRECISION_FACTOR;

            emit AddPartner(_users[i], allocAmt);
        }
        require(totalAlloc == 10000, "total allocation is not 100%");

        totalStaked = totalStaked + realAmount;
        emit Deposit(msg.sender, realAmount);
    }

    function cancelPartner(address _user) external onlyOwner {
        PartnerInfo storage user = partnerInfo[_user];
        require(user.amount > 0, "Invalid parnter") ;

        stakingToken.safeTransfer(msg.sender, user.amount);
        
        user.amount = 0;
        user.rewardDebt = 0;

        totalStaked -= user.amount;

        emit RemovePartner(_user);
    }

    /*
     * @notice Withdraw reward token
     * @dev Only callable by owner. Needs to be for emergency.
     */
    function emergencyRewardWithdraw(uint256 _amount) external onlyOwner {
        require(isActive == true, "Pool is running");
        require(availableRewardTokens() >= _amount, "Insufficient reward tokens");

        if(_amount == 0) _amount = availableRewardTokens();
        earnedToken.safeTransfer(address(msg.sender), _amount);
        
        if (totalEarned > 0) {
            if (_amount > totalEarned) {
                totalEarned = 0;
            } else {
                totalEarned = totalEarned - _amount;
            }
        }
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @param _tokenAmount: the number of tokens to withdraw
     * @dev This function is only callable by admin.
     */
    function rescueTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        require(
            _tokenAddress != address(earnedToken),
            "Cannot be reward token"
        );

        if(_tokenAddress == address(stakingToken)) {
            uint256 tokenBal = stakingToken.balanceOf(address(this));
            require(_tokenAmount <= tokenBal - totalStaked, "Insufficient balance");
        }

        if(_tokenAddress == address(0x0)) {
            payable(msg.sender).transfer(_tokenAmount);
        } else {
            IERC20(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);
        }

        emit AdminTokenRecovered(_tokenAddress, _tokenAmount);
    }

    function finishThisPeriod() external onlyOwner {
        prevPeriodAccToken = totalPaid + availableRewardTokens();
    }

    function setServiceInfo(address _treasury, uint256 _fee) external {
        require(msg.sender == treasury, "setServiceInfo: FORBIDDEN");
        require(_treasury != address(0x0), "Invalid address");

        treasury = _treasury;
        performanceFee = _fee;

        emit ServiceInfoUpadted(_treasury, _fee);
    }

    function setActive(bool _isActive) external onlyOwner {
        isActive = _isActive;
        emit ActiveUpdated(_isActive);
    }

    function setLockDuration(uint256 _duration) external onlyOwner {
        require(_duration >= 0, "invalid duration");

        lockDuration = _duration;
        emit LockDurationUpdated(_duration);
    }

    function setHarvestCycle(uint256 _days) external onlyOwner {
        require(_days >= 0, "invalid duration");

        harvestCycle = _days;
        emit HarvestCycleUpdated(_days);
    }

    function setEmergencyWithdraw(bool _status) external onlyOwner {
        activeEmergencyWithdraw = _status;
        emit SetEmergencyWithdrawStatus(_status);
    }

    function setSettings(
        uint256 _slippageFactor,
        address _uniRouter,
        address[] memory _earnedToStakedPath
    ) external onlyOwner {
        require(_slippageFactor <= slippageFactorUL, "_slippageFactor too high");

        slippageFactor = _slippageFactor;
        uniRouterAddress = _uniRouter;
        earnedToStakedPath = _earnedToStakedPath;

        emit SetSettings(_slippageFactor, _uniRouter, _earnedToStakedPath);
    }

    /************************
    ** Internal Methods
    *************************/
    /*
     * @notice Update reward variables of the given pool to be up-to-date.
     */
    function _updatePool() internal {
        if(totalStaked == 0) return;

        uint256 rewardAmount = availableRewardTokens();
        if(rewardAmount < totalEarned) {
            rewardAmount = totalEarned;
        }

        accTokenPerShare = accTokenPerShare + (
                (rewardAmount - totalEarned) * PRECISION_FACTOR / totalStaked
            );

        totalEarned = rewardAmount;
    }

    function estimateRewardAmount(uint256 amount) internal view returns(uint256) {
        uint256 dTokenBal = availableRewardTokens();
        if(amount > totalEarned) amount = totalEarned;
        if(amount > dTokenBal) amount = dTokenBal;
        return amount;
    }

    function _safeSwap(
        uint256 _amountIn,
        address[] memory _path,
        address _to
    ) internal {
        uint256[] memory amounts = IUniRouter02(uniRouterAddress).getAmountsOut(_amountIn, _path);
        uint256 amountOut = amounts[amounts.length - 1];

        IERC20(_path[0]).safeApprove(uniRouterAddress, _amountIn);
        IUniRouter02(uniRouterAddress).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amountIn,
            amountOut * slippageFactor / 10000,
            _path,
            _to,
            block.timestamp + 600
        );
    }

    receive() external payable {}
}
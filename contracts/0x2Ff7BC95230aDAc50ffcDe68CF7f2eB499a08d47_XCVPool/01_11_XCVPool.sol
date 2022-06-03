// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interface/IMasterChefV2.sol";
import "./interface/IERC20.sol";
import "./interface/IVXcv.sol";
import "./library/SafeERC20.sol";

contract XCVPool is Initializable, OwnableUpgradeable{

    using SafeERC20 for IERC20;

    struct UserInfo{
        uint256 shares; // number of shares for a user.
        uint256 lastDepositedTime; // keep track of deposited time for potential penalty.
        uint256 xcvAtLastUserAction; // keep track of xcv deposited at the last user action.
        uint256 lastUserActionTime; // keep track of the last user action time.
        uint256 lockStartTime; // lock start time.
        uint256 lockEndTime; // lock end time.
        uint256 userBoostedShare; // boost share, in order to give the user higher reward. The user only enjoys the reward, so the principal needs to be recorded as a debt.
        bool locked; //lock status.
        uint256 lockedAmount; // amount deposited during lock period.
    }

    bool internal _notEntered;
    bool public depositPause;
    bool public withdrawPause;

    IERC20 public xcv; // xcv token.
    IMasterChefV2 public masterchefV2;
    address public VXcv;
    address public claimContract;

    mapping(address => UserInfo) public userInfo;
    mapping(address => bool) public freeWithdrawFeeUsers; // free withdraw fee users.
    mapping(address => bool) public freeOverdueFeeUsers; // free overdue fee users.

    uint256 public xcvPoolPID;
    uint256 public totalShares;
    address public admin;
    address public treasury;
    uint256 public totalLockedAmount; // total lock amount.
    uint256 public totalBoostDebt; // total boost debt.

    uint256 public constant MAX_WITHDRAW_FEE = 500; // 5%
    uint256 public constant MAX_OVERDUE_FEE = 100 * 1e10; // 100%
    uint256 public constant MAX_LOCK_DURATION_LIMIT = 1000 days; // 1000 days
    uint256 public constant PRECISION_FACTOR = 1e12; // precision factor.
    uint256 public constant PRECISION_FACTOR_SHARE = 1e28; // precision factor for share.
    uint256 public constant MIN_DEPOSIT_AMOUNT = 0.00001 ether;
    uint256 public constant MIN_WITHDRAW_AMOUNT = 0.00001 ether;
    uint256 public constant BOOST_WEIGHT_LIMIT = 5000 * 1e10; // 5000%
    uint256 public MIN_LOCK_DURATION;
    uint256 public UNLOCK_FREE_DURATION;
    uint256 public MAX_LOCK_DURATION;
    uint256 public DURATION_FACTOR;
    uint256 public DURATION_FACTOR_OVERDUE;
    uint256 public BOOST_WEIGHT;

    uint256 public withdrawFee;
    uint256 public withdrawFeeContract;
    uint256 public overdueFee;

    event Deposit(address indexed sender, uint256 amount, uint256 shares, uint256 duration, uint256 lastDepositedTime);
    event Withdraw(address indexed sender, uint256 amount, uint256 shares);
    event Harvest(address indexed sender, uint256 amount);
    event Init();
    event Lock(
        address indexed sender,
        uint256 lockedAmount,
        uint256 shares,
        uint256 lockedDuration,
        uint256 blockTimestamp
    );
    event Unlock(address indexed sender, uint256 amount, uint256 blockTimestamp);
    event NewAdmin(address admin);
    event NewTreasury(address treasury);
    event FreeFeeUser(address indexed user, bool indexed free);
    event NewWithdrawFee(uint256 withdrawFee);
    event NewOverdueFee(uint256 overdueFee);
    event NewWithdrawFeeContract(uint256 withdrawFeeContract);
    event NewMaxLockDuration(uint256 maxLockDuration);
    event NewDurationFactor(uint256 durationFactor);
    event NewDurationFactorOverdue(uint256 durationFactorOverdue);
    event NewUnlockFreeDuration(uint256 unlockFreeDuration);
    event NewBoostWeight(uint256 boostWeight);

    function initialize(IERC20 _xcv, IMasterChefV2 _masterchefV2, address _admin, address _treasury, uint256 _pid) external initializer {
        _notEntered = true;
        xcv = _xcv;
        masterchefV2 = _masterchefV2;
        admin = _admin;
        treasury = _treasury;

        xcvPoolPID = _pid;
        MIN_LOCK_DURATION = 1 weeks;
        UNLOCK_FREE_DURATION = 1 weeks; // 1 week
        MAX_LOCK_DURATION = 365 days; // 365 days
        DURATION_FACTOR = 365 days; // 365 days, in order to calculate user additional boost.
        DURATION_FACTOR_OVERDUE = 180 days; // 180 days, in order to calculate overdue fee.
        BOOST_WEIGHT = 100 * 1e10; // 100%
        withdrawFee = 0; // 10 = 0.1%
        withdrawFeeContract = 0; // 10 = 0.1%
        overdueFee = 100 * 1e10; // 100%

        __Ownable_init();
    }

    function init(IERC20 dummyToken, uint256 amount) external onlyOwner {
        uint256 balance = dummyToken.balanceOf(msg.sender);
        require(balance != 0, "Balance must exceed 0");
        dummyToken.safeTransferFrom(msg.sender, address(this), amount);
        dummyToken.approve(address(masterchefV2), balance);
        masterchefV2.deposit(xcvPoolPID, amount);
        emit Init();
    }

    /**
     * @notice Checks if the msg.sender is the admin address.
     */
    modifier onlyAdmin() {
        require(msg.sender == admin, "admin: wut?");
        _;
    }

    modifier nonReentrant() {
        require(_notEntered, "re-entered");
        _notEntered = false;
        _;
        _notEntered = true;
    }

    modifier whenNotDepositPaused() {
        require(!depositPause, "deposit: paused");
        _;
    }

    modifier whenDepositPaused() {
        require(depositPause, "deposit: not paused");
        _;
    }

    modifier whenNotWithdrawPaused() {
        require(!withdrawPause, "withdraw: paused");
        _;
    }

    modifier whenWithdrawPaused() {
        require(withdrawPause, "withdraw: not paused");
        _;
    }

    /**
     * @notice Update user share When need to unlock or charges a fee.
     * @param _user: User address
     */
    function updateUserShare(address _user) internal {
        UserInfo storage user = userInfo[_user];
        if (user.shares > 0) {
            if (user.locked) {
                // Calculate the user's current token amount and update related parameters.
                uint256 currentAmount = (balanceOf() * (user.shares)) / totalShares - user.userBoostedShare;
                totalBoostDebt -= user.userBoostedShare;
                user.userBoostedShare = 0;
                totalShares -= user.shares;
                //Charge a overdue fee after the free duration has expired.
                if (!freeOverdueFeeUsers[_user] && ((user.lockEndTime + UNLOCK_FREE_DURATION) < block.timestamp)) {
                    uint256 earnAmount;
                    if(currentAmount < user.lockedAmount){
                        earnAmount = 0;
                    }else{
                        earnAmount = currentAmount - user.lockedAmount;
                    }
                    uint256 overdueDuration = block.timestamp - user.lockEndTime - UNLOCK_FREE_DURATION;
                    if (overdueDuration > DURATION_FACTOR_OVERDUE) {
                        overdueDuration = DURATION_FACTOR_OVERDUE;
                    }
                    // Rates are calculated based on the user's overdue duration.
                    uint256 overdueWeight = (overdueDuration * overdueFee) / DURATION_FACTOR_OVERDUE;
                    uint256 currentOverdueFee = (earnAmount * overdueWeight) / PRECISION_FACTOR;
                    xcv.safeTransfer(treasury, currentOverdueFee);
                    currentAmount -= currentOverdueFee;
                }
                // Recalculate the user's share.
                uint256 pool = balanceOf();
                uint256 currentShares;
                if (totalShares != 0) {
                    currentShares = (currentAmount * totalShares) / (pool - currentAmount);
                } else {
                    currentShares = currentAmount;
                }
                user.shares = currentShares;
                totalShares += currentShares;
                // After the lock duration, update related parameters.
                if (user.lockEndTime < block.timestamp) {
                    user.locked = false;
                    user.lockStartTime = 0;
                    user.lockEndTime = 0;
                    totalLockedAmount -= user.lockedAmount;
                    user.lockedAmount = 0;
                    emit Unlock(_user, currentAmount, block.timestamp);
                }
            }
        }
    }

    function depositOfClaimContract(address account, uint256 _amount, uint256 _lockDuration) external whenNotDepositPaused{
        require(msg.sender == claimContract, "not claimContract");
        require(_amount > 0 || _lockDuration > 0, "_amount || _lockDuration is error");
        depositOperation(_amount, _lockDuration, account);
    }

    /**
     * @notice Deposit funds into the xcv Pool.
     * @dev Only possible when contract not paused.
     * @param _amount: number of tokens to deposit (in XCV)
     * @param _lockDuration: Token lock duration
     */
    function deposit(uint256 _amount, uint256 _lockDuration) external whenNotDepositPaused {
        require(_amount > 0 || _lockDuration > 0, "Nothing to deposit");
        depositOperation(_amount, _lockDuration, msg.sender);
    }

    /**
     * @notice The operation of deposite.
     * @param _amount: number of tokens to deposit (in XCV)
     * @param _lockDuration: Token lock duration
     * @param _user: User address
     */
    function depositOperation(
        uint256 _amount,
        uint256 _lockDuration,
        address _user
    ) internal nonReentrant{
        UserInfo storage user = userInfo[_user];
        if(_lockDuration == 0){
            require(user.shares != 0 && user.lockEndTime >= block.timestamp, "_lockDuration cannot be 0");
        }
        if (user.shares == 0 || _amount > 0) {
            require(_amount > MIN_DEPOSIT_AMOUNT, "Deposit amount must be greater than MIN_DEPOSIT_AMOUNT");
        }
        // Calculate the total lock duration and check whether the lock duration meets the conditions.
        uint256 totalLockDuration = _lockDuration;
        if (user.lockEndTime >= block.timestamp) {
            // Adding funds during the lock duration is equivalent to re-locking the position, needs to update some variables.
            if (_amount > 0) {
                user.lockStartTime = block.timestamp;
                totalLockedAmount -= user.lockedAmount;
                user.lockedAmount = 0;
            }
            totalLockDuration += user.lockEndTime - user.lockStartTime;
        }
        require(_lockDuration == 0 || totalLockDuration >= MIN_LOCK_DURATION, "Minimum lock period is one week");
        require(totalLockDuration <= MAX_LOCK_DURATION, "Maximum lock period exceeded");

        if (VXcv != address(0)) {
            IVXcv(VXcv).deposit(_user, _amount, _lockDuration);
        }

        // Harvest tokens.
        harvest();

        // Handle stock funds.
        if (totalShares == 0) {
            uint256 stockAmount = available();
            xcv.safeTransfer(treasury, stockAmount);
        }
        // Update user share.
        updateUserShare(_user);

        // Update lock duration.
        if (_lockDuration > 0) {
            if (user.lockEndTime < block.timestamp) {
                user.lockStartTime = block.timestamp;
                user.lockEndTime = block.timestamp + _lockDuration;
            } else {
                user.lockEndTime += _lockDuration;
            }
            user.locked = true;
        }

        uint256 currentShares;
        uint256 currentAmount;
        uint256 userCurrentLockedBalance;
        uint256 pool = balanceOf();
        if (_amount > 0) {
            xcv.safeTransferFrom(_user, address(this), _amount);
            currentAmount = _amount;
        }

        // Calculate lock funds
        if (user.shares > 0 && user.locked) {
            userCurrentLockedBalance = (pool * user.shares) / totalShares;
            currentAmount += userCurrentLockedBalance;
            totalShares -= user.shares;
            user.shares = 0;

            // Update lock amount
            if (user.lockStartTime == block.timestamp) {
                user.lockedAmount = userCurrentLockedBalance;
                totalLockedAmount += user.lockedAmount;
            }
        }
        if (totalShares != 0) {
            currentShares = (currentAmount * totalShares) / (pool - userCurrentLockedBalance);
        } else {
            currentShares = currentAmount;
        }

        // Calculate the boost weight share.
        if (user.lockEndTime > user.lockStartTime) {
            // Calculate boost share.
            uint256 boostWeight = ((user.lockEndTime - user.lockStartTime) * BOOST_WEIGHT) / DURATION_FACTOR;
            uint256 boostShares = (boostWeight * currentShares) / PRECISION_FACTOR;
            currentShares += boostShares;
            user.shares += currentShares;

            // Calculate boost share , the user only enjoys the reward, so the principal needs to be recorded as a debt.
            uint256 userBoostedShare = (boostWeight * currentAmount) / PRECISION_FACTOR;
            user.userBoostedShare += userBoostedShare;
            totalBoostDebt += userBoostedShare;

            // Update lock amount.
            user.lockedAmount += _amount;
            totalLockedAmount += _amount;

            emit Lock(_user, user.lockedAmount, user.shares, (user.lockEndTime - user.lockStartTime), block.timestamp);
        }

        if (_amount > 0 || _lockDuration > 0) {
            user.lastDepositedTime = block.timestamp;
        }
        totalShares += currentShares;

        user.xcvAtLastUserAction = (user.shares * balanceOf()) / totalShares - user.userBoostedShare;
        user.lastUserActionTime = block.timestamp;

        emit Deposit(_user, _amount, currentShares, _lockDuration, block.timestamp);
    }

    /**
     * @notice The operation of withdraw.
     * @param _shares: Number of shares to withdraw
     * @param _amount: Number of amount to withdraw
     */
    function withdrawOperation(uint256 _shares, uint256 _amount) internal nonReentrant{
        UserInfo storage user = userInfo[msg.sender];
        require(_shares <= user.shares, "Withdraw amount exceeds balance");
        require(user.lockEndTime < block.timestamp, "Still in lock");

        if (VXcv != address(0)) {
            IVXcv(VXcv).withdraw(msg.sender);
        }

        // Calculate the percent of withdraw shares, when unlocking, the shares will be updated.
        uint256 currentShare = _shares;
        uint256 sharesPercent = (_shares * PRECISION_FACTOR_SHARE) / user.shares;

        // Harvest token.
        harvest();

        // Update user share.
        updateUserShare(msg.sender);

        if (_shares == 0 && _amount > 0) {
            uint256 pool = balanceOf();
            currentShare = (_amount * totalShares) / pool; // Calculate equivalent shares
            if (currentShare > user.shares) {
                currentShare = user.shares;
            }
        } else {
            currentShare = (sharesPercent * user.shares) / PRECISION_FACTOR_SHARE;
        }
        uint256 currentAmount = (balanceOf() * currentShare) / totalShares;
        user.shares -= currentShare;
        totalShares -= currentShare;

        // Calculate withdraw fee
        if (!freeWithdrawFeeUsers[msg.sender] && (withdrawFee != 0 || withdrawFeeContract != 0)) {
            uint256 feeRate = withdrawFee;
            if (_isContract(msg.sender)) {
                feeRate = withdrawFeeContract;
            }
            uint256 currentWithdrawFee = (currentAmount * feeRate) / 10000;
            xcv.safeTransfer(treasury, currentWithdrawFee);
            currentAmount -= currentWithdrawFee;
        }

        xcv.safeTransfer(msg.sender, currentAmount);

        if (user.shares > 0) {
            user.xcvAtLastUserAction = (user.shares * balanceOf()) / totalShares;
        } else {
            user.xcvAtLastUserAction = 0;
        }

        user.lastUserActionTime = block.timestamp;

        emit Withdraw(msg.sender, currentAmount, currentShare);
    }

    /**
     * @notice Withdraw all funds for a user
     */
    function withdrawAll() external whenNotWithdrawPaused{
        require(userInfo[msg.sender].shares > 0, "Nothing to withdraw");
        withdrawOperation(userInfo[msg.sender].shares, 0);
    }

    /**
     * @notice Harvest pending XCV tokens
     */
    function harvest() internal {
        uint256 pendingXcv = masterchefV2.pendingXcv(xcvPoolPID, address(this));
        if (pendingXcv > 0) {
            uint256 balBefore = available();
            masterchefV2.withdraw(xcvPoolPID, 0);
            uint256 balAfter = available();
            emit Harvest(msg.sender, (balAfter - balBefore));
        }
    }

    /**
     * @notice Set admin address
     * @dev Only callable by the contract owner.
     */
    function setAdmin(address _admin) external onlyOwner {
        require(_admin != address(0), "Cannot be zero address");
        admin = _admin;
        emit NewAdmin(admin);
    }

    /**
     * @notice Set treasury address
     * @dev Only callable by the contract owner.
     */
    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "Cannot be zero address");
        treasury = _treasury;
        emit NewTreasury(treasury);
    }

    /**
     * @notice Set free overdue fee address
     * @dev Only callable by the contract admin.
     * @param _user: User address
     * @param _free: true:free false:not free
     */
    function setOverdueFeeUser(address _user, bool _free) external onlyAdmin {
        require(_user != address(0), "Cannot be zero address");
        freeOverdueFeeUsers[_user] = _free;
        emit FreeFeeUser(_user, _free);
    }

    /**
     * @notice Set free withdraw fee address
     * @dev Only callable by the contract admin.
     * @param _user: User address
     * @param _free: true:free false:not free
     */
    function setWithdrawFeeUser(address _user, bool _free) external onlyAdmin {
        require(_user != address(0), "Cannot be zero address");
        freeWithdrawFeeUsers[_user] = _free;
        emit FreeFeeUser(_user, _free);
    }

    /**
     * @notice Set withdraw fee
     * @dev Only callable by the contract admin.
     */
    function setWithdrawFee(uint256 _withdrawFee) external onlyAdmin {
        require(_withdrawFee <= MAX_WITHDRAW_FEE, "withdrawFee cannot be more than MAX_WITHDRAW_FEE");
        withdrawFee = _withdrawFee;
        emit NewWithdrawFee(withdrawFee);
    }

    /**
     * @notice Set overdue fee
     * @dev Only callable by the contract admin.
     */
    function setOverdueFee(uint256 _overdueFee) external onlyAdmin {
        require(_overdueFee <= MAX_OVERDUE_FEE, "overdueFee cannot be more than MAX_OVERDUE_FEE");
        overdueFee = _overdueFee;
        emit NewOverdueFee(_overdueFee);
    }

    /**
     * @notice Set VXcv Contract address
     * @dev Callable by the contract admin.
     */
    function setVXcv(address _VXcv) external onlyAdmin {
        require(_VXcv != address(0), "Cannot be zero address");
        VXcv = _VXcv;
    }

    /**
     * @notice Set withdraw fee for contract
     * @dev Only callable by the contract admin.
     */
    function setWithdrawFeeContract(uint256 _withdrawFeeContract) external onlyAdmin {
        require(_withdrawFeeContract <= MAX_WITHDRAW_FEE, "withdrawFee cannot be more than MAX_WITHDRAW_FEE");
        withdrawFeeContract = _withdrawFeeContract;
        emit NewWithdrawFeeContract(withdrawFeeContract);
    }

    /**
     * @notice Set MAX_LOCK_DURATION
     * @dev Only callable by the contract admin.
     */
    function setMaxLockDuration(uint256 _maxLockDuration) external onlyAdmin {
        require(
            _maxLockDuration <= MAX_LOCK_DURATION_LIMIT,
            "MAX_LOCK_DURATION cannot be more than MAX_LOCK_DURATION_LIMIT"
        );
        MAX_LOCK_DURATION = _maxLockDuration;
        emit NewMaxLockDuration(_maxLockDuration);
    }

    /**
     * @notice Set DURATION_FACTOR
     * @dev Only callable by the contract admin.
     */
    function setDurationFactor(uint256 _durationFactor) external onlyAdmin {
        require(_durationFactor > 0, "DURATION_FACTOR cannot be zero");
        DURATION_FACTOR = _durationFactor;
        emit NewDurationFactor(_durationFactor);
    }

    /**
     * @notice Set DURATION_FACTOR_OVERDUE
     * @dev Only callable by the contract admin.
     */
    function setDurationFactorOverdue(uint256 _durationFactorOverdue) external onlyAdmin {
        require(_durationFactorOverdue > 0, "DURATION_FACTOR_OVERDUE cannot be zero");
        DURATION_FACTOR_OVERDUE = _durationFactorOverdue;
        emit NewDurationFactorOverdue(_durationFactorOverdue);
    }

    /**
     * @notice Set UNLOCK_FREE_DURATION
     * @dev Only callable by the contract admin.
     */
    function setUnlockFreeDuration(uint256 _unlockFreeDuration) external onlyAdmin {
        require(_unlockFreeDuration > 0, "UNLOCK_FREE_DURATION cannot be zero");
        UNLOCK_FREE_DURATION = _unlockFreeDuration;
        emit NewUnlockFreeDuration(_unlockFreeDuration);
    }

    /**
     * @notice Set MIN_LOCK_DURATION
     * @dev Only callable by the contract admin.
     */
    function setMinLockDuration(uint256 _minLockDuration) external onlyAdmin {
        require(_minLockDuration > 0, "MIN_LOCK_DURATION cannot be zero");
        MIN_LOCK_DURATION = _minLockDuration;
    }

    /**
     * @notice Set BOOST_WEIGHT
     * @dev Only callable by the contract admin.
     */
    function setBoostWeight(uint256 _boostWeight) external onlyAdmin {
        require(_boostWeight <= BOOST_WEIGHT_LIMIT, "BOOST_WEIGHT cannot be more than BOOST_WEIGHT_LIMIT");
        BOOST_WEIGHT = _boostWeight;
        emit NewBoostWeight(_boostWeight);
    }

    /**
     * @notice set XCV
     */
    function setXCV(IERC20 _xcv) external onlyAdmin {
        xcv = _xcv;
    }

    function setMasterchefV2(IMasterChefV2 _masterchefV2) external onlyAdmin {
        masterchefV2 = _masterchefV2;
    }

    function setClaimContract(address _claimContract) external onlyAdmin{
        claimContract = _claimContract;
    }

    /**
     * @notice Withdraw unexpected tokens sent to the XCV Pool
     */
    function inCaseTokensGetStuck(address _token) external onlyAdmin {
        require(_token != address(xcv), "Token cannot be same as deposit token");
        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(msg.sender, amount);
    }

    function setDepositPause() external onlyAdmin whenNotDepositPaused {
        depositPause = true;
    }

    function setWithdrawPause() external onlyAdmin whenNotWithdrawPaused {
        withdrawPause = true;
    }

    function setDepositUnpause() external onlyAdmin whenDepositPaused {
        depositPause = false;
    }

    function setWithdrawUnpause() external onlyAdmin whenWithdrawPaused {
        withdrawPause = false;
    }

    /**
     * @notice Calculate overdue fee.
     * @param _user: User address
     * @return Returns Overdue fee.
     */
    function calculateOverdueFee(address _user) public view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        if (
            user.shares > 0 &&
            user.locked &&
            !freeOverdueFeeUsers[_user] &&
            ((user.lockEndTime + UNLOCK_FREE_DURATION) < block.timestamp)
        ) {
            uint256 pool = balanceOf() + calculateTotalPendingXcvRewards();
            uint256 currentAmount = (pool * (user.shares)) / totalShares - user.userBoostedShare;
            uint256 earnAmount = currentAmount - user.lockedAmount;
            uint256 overdueDuration = block.timestamp - user.lockEndTime - UNLOCK_FREE_DURATION;
            if (overdueDuration > DURATION_FACTOR_OVERDUE) {
                overdueDuration = DURATION_FACTOR_OVERDUE;
            }
            // Rates are calculated based on the user's overdue duration.
            uint256 overdueWeight = (overdueDuration * overdueFee) / DURATION_FACTOR_OVERDUE;
            uint256 currentOverdueFee = (earnAmount * overdueWeight) / PRECISION_FACTOR;
            return currentOverdueFee;
        }
        return 0;
    }

    /**
     * @notice Calculate withdraw fee.
     * @param _user: User address
     * @param _shares: Number of shares to withdraw
     * @return Returns Withdraw fee.
     */
    function calculateWithdrawFee(address _user, uint256 _shares) public view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        if (user.shares < _shares) {
            _shares = user.shares;
        }
        if (!freeWithdrawFeeUsers[msg.sender] && (withdrawFee != 0 || withdrawFeeContract != 0)) {
            uint256 pool = balanceOf() + calculateTotalPendingXcvRewards();
            uint256 sharesPercent = (_shares * PRECISION_FACTOR) / user.shares;
            uint256 currentTotalAmount = (pool * (user.shares)) /
                totalShares -
                user.userBoostedShare -
                calculateOverdueFee(_user);
            uint256 currentAmount = (currentTotalAmount * sharesPercent) / PRECISION_FACTOR;
            uint256 feeRate = withdrawFee;
            if (_isContract(msg.sender)) {
                feeRate = withdrawFeeContract;
            }
            uint256 currentWithdrawFee = (currentAmount * feeRate) / 10000;
            return currentWithdrawFee;
        }
        return 0;
    }

    /**
     * @notice Calculates the total pending rewards that can be harvested
     * @return Returns total pending xcv rewards
     */
    function calculateTotalPendingXcvRewards() public view returns (uint256) {
        uint256 amount = masterchefV2.pendingXcv(xcvPoolPID, address(this));
        return amount;
    }

    function getPricePerFullShare() external view returns (uint256) {
        return totalShares == 0 ? 1e18 : (((balanceOf() + calculateTotalPendingXcvRewards()) * (1e18)) / totalShares);
    }

    /**
     * @notice Current pool available balance
     * @dev The contract puts 100% of the tokens to work.
     */
    function available() public view returns (uint256) {
        return xcv.balanceOf(address(this));
    }

    /**
     * @notice Calculates the total underlying tokens
     * @dev It includes tokens held by the contract and the boost debt amount.
     */
    function balanceOf() public view returns (uint256) {
        return xcv.balanceOf(address(this)) + totalBoostDebt;
    }

    /**
     * @notice Checks if address is a contract
     */
    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./StakingState.sol";
import "./IVault.sol";
import "./IContractsLibrary.sol";

contract tokenStaking is StakingState, ReentrancyGuard {
    using SafeMath for uint;
    IVault public vault;
    IContractsLibrary public contractsLibrary;
    // 	uint internal constant PERCENT_DIVIDER = 1000; // 1000 = 100%, 100 = 10%, 10 = 1%, 1 = 0.1%
    struct Pool {
        address token;
        address rewardToken;
        uint minimumDeposit;
        uint roi;
        uint rquirePool;
        uint requireAmount;
    }

    // Info of each user.
    struct UserInfo {
        address user;
        address referrer;
        uint investment;
        uint stakingValue;
        uint rewardLockedUp;
        uint totalDeposit;
        uint totalWithdrawn;
        uint nextWithdraw;
        uint unlockDate;
        uint depositCheckpoint;
        uint busdTotalDeposit;
    }

    struct RefData {
        address referrer;
        uint amount;
        bool exists;
    }

    mapping(address => RefData) public referrers;

    uint public constant minPool = 1;
    uint public poolsLength = 0;
    mapping(uint => mapping(address => UserInfo)) public users;

    mapping(address => uint) public lastBlock;
    mapping(uint => Pool) public pools;

    event Newbie(address user);
    event NewDeposit(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RefBonus(
        address indexed referrer,
        address indexed referral,
        uint256 indexed level,
        uint256 amount
    );
    event FeePayed(address indexed user, uint256 totalAmount);
    event Reinvestment(address indexed user, uint256 amount);
    event ForceWithdraw(address indexed user, uint256 amount);

    constructor(
        address _vault,
        address _library,
        address _token,
        address _token2
    ) {
        devAddress = msg.sender;
        vault = IVault(_vault);
        contractsLibrary = IContractsLibrary(_library);

        pools[1] = Pool({
            token: _token,
            rewardToken: _token,
            minimumDeposit: 500 ether,
            roi: 10,
            rquirePool: 0,
            requireAmount: 0
        });

        pools[2] = Pool({
            token: _token2,
            rewardToken: _token2,
            minimumDeposit: 5000 ether,
            roi: 15,
            rquirePool: 0,
            requireAmount: 0
        });

        pools[3] = Pool({
            token: _token,
            rewardToken: address(0),
            minimumDeposit: 0,
            roi: 5,
            rquirePool: 1,
            requireAmount: 1
        });

        pools[4] = Pool({
            token: _token2,
            rewardToken: address(0),
            minimumDeposit: 0,
            roi: 7,
            rquirePool: 2,
            requireAmount: 1
        });

        poolsLength = 4;
    }

    modifier tenBlocks() {
        require(block.number.sub(lastBlock[msg.sender]) > 10, "wait 10 blocks");
        _;
        lastBlock[msg.sender] = block.number;
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    modifier isNotContract() {
        require(!isContract(msg.sender), "contract not allowed");
        _;
    }

    function invest(
        uint _pool,
        uint amount,
        address _referrer
    )
        external
        nonReentrant
        whenNotPaused
        tenBlocks
        isNotContract
        hasNotStoppedProduction
    {
        require(_pool >= minPool && _pool <= poolsLength, "Invalid pool");
        UserInfo storage user = users[_pool][msg.sender];
        Pool memory pool = pools[_pool];

        if (pool.rquirePool > 0) {
            require(
                users[pool.rquirePool][msg.sender].totalDeposit >=
                    pool.requireAmount,
                "Require amount"
            );
        }
        if (pool.minimumDeposit > 0) {
            require(amount >= pool.minimumDeposit, "Minimum deposit");
        }

        IERC20(pool.token).transferFrom(msg.sender, address(vault), amount);

        RefData storage refData = referrers[msg.sender];
        if (!refData.exists) {
            refData.exists = true;
            totalUsers++;
            emit Newbie(msg.sender);
            if (
                refData.referrer == address(0) &&
                _referrer != address(0) &&
                _referrer != msg.sender &&
                msg.sender != referrers[_referrer].referrer
            ) {
                refData.referrer = _referrer;
            }
        }

        uint refAmount = amount.mul(REFERRER_PERCENTS).div(PERCENT_DIVIDER);

        if (referrer_is_allowed && refData.referrer != address(0)) {
            referrers[refData.referrer].amount += refAmount;
            IERC20(pools[_pool].token).transfer(refData.referrer, refAmount);
            emit RefBonus(refData.referrer, msg.sender, 1, refAmount);
        }

        if (user.user == address(0)) {
            user.user = msg.sender;
            investors[_pool][totalUsers] = msg.sender;
        }
        updateDeposit(msg.sender, _pool);
        users[_pool][msg.sender].investment += amount;

        if (pool.token == pool.rewardToken) {
            users[_pool][msg.sender].stakingValue += amount;
        } else if (pool.rewardToken == address(0)) {
            users[_pool][msg.sender].stakingValue += contractsLibrary
                .getTokensToBnb(pool.token, amount);
        } else {
            users[_pool][msg.sender].stakingValue += contractsLibrary
                .getTokenToBnbToAltToken(pool.token, pool.rewardToken, amount);
        }
        users[_pool][msg.sender].totalDeposit += amount;

        totalInvested[_pool] += amount;
        totalDeposits[_pool]++;

        if (user.nextWithdraw == 0) {
            user.nextWithdraw = block.timestamp + HARVEST_DELAY;
        }

        user.unlockDate = block.timestamp + BLOCK_TIME_STEP;

        emit NewDeposit(msg.sender, amount);
    }

    function payToUser(uint _pool, bool _withdraw) internal {
        require(userCanwithdraw(msg.sender, _pool), "User cannot withdraw");
        require(_pool >= minPool && _pool <= poolsLength, "Invalid pool");
        updateDeposit(msg.sender, _pool);
        uint fromVault;
        if (_withdraw) {
            require(
                block.timestamp >= users[_pool][msg.sender].unlockDate,
                "Token is locked"
            );
            fromVault = users[_pool][msg.sender].investment;
            delete users[_pool][msg.sender].investment;
            delete users[_pool][msg.sender].stakingValue;
            delete users[_pool][msg.sender].nextWithdraw;
        } else {
            users[_pool][msg.sender].nextWithdraw =
                block.timestamp +
                HARVEST_DELAY;
        }
        uint formThis = users[_pool][msg.sender].rewardLockedUp;
        delete users[_pool][msg.sender].rewardLockedUp;
        uint _toWithdraw = formThis;
        totalWithdrawn[_pool] += _toWithdraw;
        users[_pool][msg.sender].totalWithdrawn += _toWithdraw;
        if (fromVault > 0) {
            vault.safeTransfer(
                IERC20(pools[_pool].token),
                msg.sender,
                fromVault
            );
        }
        address tokenReward = pools[_pool].rewardToken;
        if (tokenReward == address(0)) {
            payable(msg.sender).transfer(formThis);
        } else {
            IERC20(tokenReward).transfer(msg.sender, formThis);
        }
        emit Withdrawn(msg.sender, _toWithdraw);
    }

    function harvest(
        uint _pool
    )
        external
        nonReentrant
        whenNotPaused
        tenBlocks
        isNotContract
        hasNotStoppedProduction
    {
        payToUser(_pool, false);
    }

    function withdraw(
        uint _pool
    )
        external
        nonReentrant
        whenNotPaused
        tenBlocks
        isNotContract
        hasNotStoppedProduction
    {
        payToUser(_pool, true);
    }

    // function reinvest(
    //     uint _pool
    // )
    //     external
    //     nonReentrant
    //     whenNotPaused
    //     tenBlocks
    //     isNotContract
    //     hasNotStoppedProduction
    // {
    //     require(userCanwithdraw(msg.sender, _pool), "User cannot reinvest");
    //     require(_pool >= minPool && _pool <= poolsLength, "Invalid pool");
    //     updateDeposit(msg.sender, _pool);
    //     users[_pool][msg.sender].nextWithdraw = block.timestamp + HARVEST_DELAY;
    //     uint pending = users[_pool][msg.sender].rewardLockedUp;
    //     Pool memory pool = pools[_pool];
    //     users[_pool][msg.sender].stakingValue += pending;
    //     delete users[_pool][msg.sender].rewardLockedUp;
    //     totalReinvested += pending;
    //     totalReinvestCount++;
    //     if (pool.rewardToken != address(0) && pool.token == pool.rewardToken) {
    //         users[_pool][msg.sender].investment += pending;
    //         IERC20(pools[_pool].token).transfer(address(vault), pending);
    //     }
    //     emit Reinvestment(msg.sender, pending);
    // }

    function forceWithdraw(
        uint _pool
    ) external nonReentrant whenNotPaused tenBlocks isNotContract {
        require(userCanwithdraw(msg.sender, _pool), "User cannot withdraw");
        require(_pool >= minPool && _pool <= poolsLength, "Invalid pool");
        uint toTransfer = users[_pool][msg.sender].investment;
        delete users[_pool][msg.sender].rewardLockedUp;
        delete users[_pool][msg.sender].investment;
        delete users[_pool][msg.sender].stakingValue;
        delete users[_pool][msg.sender].nextWithdraw;
        delete users[_pool][msg.sender].unlockDate;
        users[_pool][msg.sender].totalWithdrawn += toTransfer;
        delete users[_pool][msg.sender].depositCheckpoint;
        totalWithdrawn[_pool] += toTransfer;
        vault.safeTransfer(IERC20(pools[_pool].token), msg.sender, toTransfer);
    }

    function takeTokens(address _token, uint _bal) external onlyOwner {
        IERC20(_token).transfer(msg.sender, _bal);
    }

    function getReward(
        uint _weis,
        uint _seconds,
        uint _pool
    ) public view returns (uint) {
        return
            (_weis * _seconds * pools[_pool].roi) /
            (TIME_STEP * PERCENT_DIVIDER);
    }

    function userCanwithdraw(
        address user,
        uint _pool
    ) public view returns (bool) {
        if (block.timestamp > users[_pool][user].nextWithdraw) {
            if (users[_pool][user].stakingValue > 0) {
                return true;
            }
        }
        return false;
    }

    function getDeltaPendingRewards(
        address _user,
        uint _pool
    ) public view returns (uint) {
        if (users[_pool][_user].depositCheckpoint == 0) {
            return 0;
        }
        uint time = block.timestamp;
        if (stopProductionDate > 0 && time > stopProductionDate) {
            time = stopProductionDate;
        }
        return
            getReward(
                users[_pool][_user].stakingValue,
                time.sub(users[_pool][_user].depositCheckpoint),
                _pool
            );
    }

    function getUserTotalPendingRewards(
        address _user,
        uint _pool
    ) public view returns (uint) {
        return
            users[_pool][_user].rewardLockedUp +
            getDeltaPendingRewards(_user, _pool);
    }

    function updateDeposit(address _user, uint _pool) internal {
        users[_pool][_user].rewardLockedUp = getUserTotalPendingRewards(
            _user,
            _pool
        );
        users[_pool][_user].depositCheckpoint = block.timestamp;
    }

    function getUser(
        address _user,
        uint _pool
    ) external view returns (UserInfo memory userInfo_, uint pendingRewards) {
        userInfo_ = users[_pool][_user];
        pendingRewards = getUserTotalPendingRewards(_user, _pool);
    }

    function getAllUsers(uint _pool) external view returns (UserInfo[] memory) {
        UserInfo[] memory result = new UserInfo[](totalUsers);
        for (uint i = 0; i < totalUsers; i++) {
            result[i] = users[_pool][investors[_pool][i]];
        }
        return result;
    }

    function getUserByIndex(
        uint _pool,
        uint _index
    ) external view returns (UserInfo memory) {
        require(_index < totalUsers, "Index out of bounds");
        return users[_pool][investors[_pool][_index]];
    }

    function addPool(
        address _token,
        address _rewardToken,
        uint _minimumDeposit,
        uint roi,
        uint _requirePool,
        uint _requireAmount
    ) external onlyOwner {
        poolsLength++;
        pools[poolsLength] = Pool({
            token: _token,
            rewardToken: _rewardToken,
            minimumDeposit: _minimumDeposit,
            roi: roi,
            rquirePool: _requirePool,
            requireAmount: _requireAmount
        });
    }

    fallback() external payable {}

    receive() external payable {}

    function takeBNB() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}
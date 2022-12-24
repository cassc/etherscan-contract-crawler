// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../interfaces/IRewardPool.sol";
import "../interfaces/IDollar.sol";
import "../interfaces/INFTController.sol";

contract ShareMasterChef is IRewardPool, OwnableUpgradeable, IERC721Receiver, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;         // How many LP tokens the user has provided.
        uint256 rewardDebt;     // Reward debt. See explanation below.
    }

    // Info of each pool.
    struct PoolInfo {
        address lpToken;           // Address of LP token contract.
        uint256 allocPoint;        // How many allocation points assigned to this pool. BCXS to distribute per block.
        uint256 lastRewardTime;    // Last block number that BCXS distribution occurs.
        uint256 accSharePerShare;  // Accumulated BCXS per share, times 1e18. See below.
        uint16 depositFeeBP;       // Deposit fee in basis points
        uint256 lockedTime;
        bool isStarted;            // if lastRewardTime has passed
    }

    struct NFTSlot {
        address slot1;
        uint256 tokenId1;
        address slot2;
        uint256 tokenId2;
        address slot3;
        uint256 tokenId3;
    }

    // The BCXS TOKEN!
    address public share;

    uint256 public totalShareBurn;

    // BCXS tokens created per block.
    uint256 public rewardPerSecond;
    uint256 public totalRewardPerSecond;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 private totalAllocPoint_;
    
    uint256 public startTime;
    uint256 public stopTime;

    address public treasury;
    address public nftController;

    mapping(address => bool) public poolExistence;
    mapping(address => mapping(uint256 => NFTSlot)) private _depositedNFT; // user => pid => nft slot;

    bool public whitelistAll;
    mapping(address => bool) public whitelist_;

    uint256 public nftBoostRate;

    uint256 public devRate;
    address public devFund;

    uint256 public insuranceRate;
    address public insuranceFund;

    uint256 public totalDevFundAdded;
    uint256 public totalInsuranceFundAdded;

    mapping(uint256 => mapping(address => uint256)) public userLastDepositTime;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event RewardPaid(address indexed user, uint256 indexed pid, uint256 amount, uint256 boost);
    event RewardBurned(address indexed user, uint256 indexed pid, uint256 amount);
    event UpdateRewardPerSecond(uint256 rewardPerSecond);
    event UpdateNFTController(address indexed user, address controller);
    event UpdateTreasury(address indexed user, address treasury);
    event UpdateNFTBoostRate(address indexed user, uint256 controller);
    event Whitelisted(address indexed account, bool on);
    event OnERC721Received(address operator, address from, uint256 tokenId, bytes data);

    function initialize(
        address _share,
        address _devFund,
        address _insuranceFund,
        uint256 _totalRewardPerSecond,
        uint256 _startTime
    ) external initializer {
        OwnableUpgradeable.__Ownable_init();

        share = _share;

        devFund = _devFund;
        devRate = 3000;

        insuranceFund = _insuranceFund;
        insuranceRate = 1000;

        totalRewardPerSecond = _totalRewardPerSecond;
        _updateRewardPerSecond();

        startTime = _startTime; // supposed to be 1671926400 (Sunday, 25 December 2022 00:00:00 UTC)
        stopTime = _startTime + 1095 days; // 1766534400 (Wednesday, 24 December 2025 00:00:00 UTC)

        totalShareBurn = 0;
        totalAllocPoint_ = 0;
        totalDevFundAdded = 0;
        totalInsuranceFundAdded = 0;
        whitelistAll = true;
        nftBoostRate = 10000;
    }

    /* ========== Modifiers ========== */

    modifier nonDuplicated(address _lpToken) {
        require(poolExistence[_lpToken] == false, "nonDuplicated: duplicated");
        _;
    }

    modifier checkContract() {
        if (!whitelistAll && !whitelist_[msg.sender]) {
            require(tx.origin == msg.sender, "contract");
        }
        _;
    }

    modifier onlyOwnerOrTreasury() {
        require(msg.sender == treasury || msg.sender == owner(), "!treasury nor owner");
        _;
    }

    modifier checkPoolEnd() {
        if (block.timestamp >= stopTime) {
            massUpdatePools();
            rewardPerSecond = totalRewardPerSecond = 0;
            emit UpdateRewardPerSecond(rewardPerSecond);
        }
        _;
    }

    /* ========== NFT View Functions ========== */

    function getBoost(address _account, uint256 _pid) public view returns (uint256) {
        INFTController _controller = INFTController(nftController);
        if (address(_controller) == address(0)) return 0;
        NFTSlot memory slot = _depositedNFT[_account][_pid];
        uint256 boost1 = _controller.getBoostRate(slot.slot1, slot.tokenId1);
        uint256 boost2 = _controller.getBoostRate(slot.slot2, slot.tokenId2);
        uint256 boost3 = _controller.getBoostRate(slot.slot3, slot.tokenId3);
        uint256 boost = boost1 + boost2 + boost3;
        return boost * nftBoostRate / 10000; // boosts from 0% onwards
    }

    function getSlots(address _account, uint256 _pid) public view returns (address, address, address) {
        NFTSlot memory slot = _depositedNFT[_account][_pid];
        return (slot.slot1, slot.slot2, slot.slot3);
    }

    function getTokenIds(address _account, uint256 _pid) public view returns (uint256, uint256, uint256) {
        NFTSlot memory slot = _depositedNFT[_account][_pid];
        return (slot.tokenId1, slot.tokenId2, slot.tokenId3);
    }

    /* ========== View Functions ========== */

    function totalAllocPoint() external override view returns (uint256) {
        return totalAllocPoint_;
    }

    function poolLength() external override view returns (uint256) {
        return poolInfo.length;
    }

    function getPoolInfo(uint256 _pid) external override view returns (address _lp, uint256 _allocPoint) {
        PoolInfo memory pool = poolInfo[_pid];
        _lp = address(pool.lpToken);
        _allocPoint = pool.allocPoint;
    }

    function getRewardPerSecond() external override view returns (uint256) {
        return rewardPerSecond;
    }

    // View function to see pending BCXS on frontend.
    function pendingReward(uint256 _pid, address _user) public override view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accSharePerShare = pool.accSharePerShare;
        uint256 lpSupply = IERC20(pool.lpToken).balanceOf(address(this));
        if (block.timestamp > pool.lastRewardTime && lpSupply != 0) {
            uint256 _seconds = block.timestamp - pool.lastRewardTime;
            uint256 _shareReward = _seconds * rewardPerSecond * pool.allocPoint / totalAllocPoint_;
            accSharePerShare += _shareReward * 1e18 / lpSupply;
        }
        return (user.amount * accSharePerShare / 1e18) - user.rewardDebt;
    }

    function pendingAllRewards(address _user) external override view returns (uint256 _totalPendingRewards) {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            _totalPendingRewards = _totalPendingRewards + pendingReward(pid, _user);
        }
    }

    /* ========== Owner Functions ========== */

    function resetStartTime(uint256 _startTime) external onlyOwner {
        require(block.timestamp <= startTime, "started already");
        require(block.timestamp <= _startTime, "passed timestamp");
        startTime = _startTime;
        stopTime = _startTime + 1095 days;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function addPool(uint256 _allocPoint, address _lpToken, uint16 _depositFeeBP, uint256 _lastRewardTime, uint256 _lockedTime) external onlyOwner nonDuplicated(_lpToken) {
        require(_allocPoint <= 100000, "too high allocation point"); // <= 100x
        require(_depositFeeBP <= 1000, "too high fee"); // <= 10%
        require(_lockedTime <= 30 days, "locked time is too long");
        massUpdatePools();
        if (block.timestamp < startTime) {
            // chef is sleeping
            if (_lastRewardTime == 0) {
                _lastRewardTime = startTime;
            } else {
                if (_lastRewardTime < startTime) {
                    _lastRewardTime = startTime;
                }
            }
        } else {
            // chef is cooking
            if (_lastRewardTime == 0 || _lastRewardTime < block.timestamp) {
                _lastRewardTime = block.timestamp;
            }
        }
        poolExistence[_lpToken] = true;
        bool _isStarted = (_lastRewardTime <= startTime) || (_lastRewardTime <= block.timestamp);
        poolInfo.push(PoolInfo({
                lpToken : _lpToken,
                allocPoint : _allocPoint,
                lastRewardTime : _lastRewardTime,
                accSharePerShare : 0,
                depositFeeBP : _depositFeeBP,
                lockedTime : _lockedTime,
                isStarted : _isStarted
            }));
        if (_isStarted) {
            totalAllocPoint_ += _allocPoint;
        }
    }

    // Update the given pool's BCXS allocation point and deposit fee. Can only be called by the owner.
    function setPool(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP, uint256 _lockedTime) public onlyOwner {
        require(_allocPoint <= 100000, "too high allocation point"); // <= 100x
        require(_depositFeeBP <= 1000, "too high fee"); // <= 10%
        require(_lockedTime <= 30 days, "locked time is too long");
        massUpdatePools();
        PoolInfo storage pool = poolInfo[_pid];
        if (pool.isStarted) {
            totalAllocPoint_ = totalAllocPoint_ - pool.allocPoint + _allocPoint;
        }
        pool.allocPoint = _allocPoint;
        pool.depositFeeBP = _depositFeeBP;
        pool.lockedTime = _lockedTime;
    }

    /* ========== NFT External Functions ========== */

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4) {
        require(INFTController(nftController).isWhitelistedNFT(msg.sender), "only approved NFTs");
        emit OnERC721Received(operator, from, tokenId, data);
        return this.onERC721Received.selector;
    }

    // Depositing of NFTs
    function depositNFT(address _nft, uint256 _tokenId, uint256 _slot, uint256 _pid) external nonReentrant checkContract {
        require(INFTController(nftController).isWhitelistedNFT(_nft), "only approved NFTs");
        require(IERC721(_nft).ownerOf(_tokenId) != msg.sender, "user does not have specified NFT");
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount == 0, "not allowed to deposit");

        updatePool(_pid);
        _harvestReward(_pid, msg.sender, false);
        user.rewardDebt = user.amount * poolInfo[_pid].accSharePerShare / 1e18;

        IERC721(_nft).transferFrom(msg.sender, address(this), _tokenId);
        
        NFTSlot memory slot = _depositedNFT[msg.sender][_pid];

        if (_slot == 1) slot.slot1 = _nft;
        else if (_slot == 2) slot.slot2 = _nft;
        else if (_slot == 3) slot.slot3 = _nft;
        
        if (_slot == 1) slot.tokenId1 = _tokenId;
        else if (_slot == 2) slot.tokenId2 = _tokenId;
        else if (_slot == 3) slot.tokenId3 = _tokenId;

        _depositedNFT[msg.sender][_pid] = slot;
    }

    // Withdrawing of NFTs
    function withdrawNFT(uint256 _slot, uint256 _pid) external nonReentrant checkContract {
        updatePool(_pid);
        UserInfo storage user = userInfo[_pid][msg.sender];
        if (user.amount > 0) {
            _harvestReward(_pid, msg.sender, false);
        }
        user.rewardDebt = user.amount * poolInfo[_pid].accSharePerShare / 1e18;

        address _nft;
        uint256 _tokenId;
        
        NFTSlot memory slot = _depositedNFT[msg.sender][_pid];

        if (_slot == 1) _nft = slot.slot1;
        else if (_slot == 2) _nft = slot.slot2;
        else if (_slot == 3) _nft = slot.slot3;
        
        if (_slot == 1) _tokenId = slot.tokenId1;
        else if (_slot == 2) _tokenId = slot.tokenId2;
        else if (_slot == 3) _tokenId = slot.tokenId3;

        if (_slot == 1) slot.slot1 = address(0);
        else if (_slot == 2) slot.slot2 = address(0);
        else if (_slot == 3) slot.slot3 = address(0);
        
        if (_slot == 1) slot.tokenId1 = uint256(0);
        else if (_slot == 2) slot.tokenId2 = uint256(0);
        else if (_slot == 3) slot.tokenId3 = uint256(0);

        _depositedNFT[msg.sender][_pid] = slot;

        IERC721(_nft).transferFrom(address(this), msg.sender, _tokenId);
    }

    /* ========== External Functions ========== */

    function _updateRewardPerSecond() internal {
        uint256 _totalRewardPerSecond = totalRewardPerSecond;
        rewardPerSecond = _totalRewardPerSecond - (_totalRewardPerSecond * (devRate + insuranceRate) / 10000);
        emit UpdateRewardPerSecond(rewardPerSecond);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.lastRewardTime) {
            return;
        }
        uint256 lpSupply = IERC20(pool.lpToken).balanceOf(address(this));
        if (lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardTime = block.timestamp;
            return;
        }
        if (!pool.isStarted) {
            pool.isStarted = true;
            totalAllocPoint_ += pool.allocPoint;
        }
        if (totalAllocPoint_ > 0) {
            uint256 _seconds = block.timestamp - pool.lastRewardTime;
            uint256 _shareReward = _seconds * rewardPerSecond * pool.allocPoint / totalAllocPoint_;
            pool.accSharePerShare += _shareReward * 1e18 / lpSupply;
        }
        pool.lastRewardTime = block.timestamp;
    }

    function _harvestReward(uint256 _pid, address _account, bool _burnReward) internal {
        UserInfo memory user = userInfo[_pid][_account];
        PoolInfo memory pool = poolInfo[_pid];
        uint256 _pending = (user.amount * pool.accSharePerShare / 1e18) - user.rewardDebt;
        if (_pending > 0) {
            _topupFunds(_pending);
            if (_burnReward) {
                _burnShare(_pending);
                emit RewardBurned(_account, _pid, _pending);
            } else {
                uint256 _boost = _pending * getBoost(_account, _pid) / 10000;
                _mintShare(_account, _pending + _boost);
                emit RewardPaid(_account, _pid, _pending, _boost);
            }
            userLastDepositTime[_pid][_account] = block.timestamp;
        }
    }

    // Deposit LP tokens to MasterChef for BCXS allocation.
    function deposit(uint256 _pid, uint256 _amount) external override nonReentrant checkContract {
        _deposit(msg.sender, msg.sender, _pid, _amount);
    }

    function depositFor(address _account, uint256 _pid, uint256 _amount) external override nonReentrant {
        require(whitelist_[msg.sender], "!authorised");
        _deposit(msg.sender, _account, _pid, _amount);
    }

    function _deposit(address _payer, address _account, uint256 _pid, uint256 _amount) internal checkPoolEnd {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_account];
        updatePool(_pid);
        if (user.amount > 0) {
            _harvestReward(_pid, _account, false);
        }
        if (_amount > 0) {
            IERC20 _lpToken = IERC20(pool.lpToken);
            uint256 _before = _lpToken.balanceOf(address(this));
            _lpToken.safeTransferFrom(_payer, address(this), _amount);
            uint256 _after = _lpToken.balanceOf(address(this));
            _amount = _after - _before; // fix issue of deflation token
            if (_amount > 0) {
                user.amount += _amount;
                userLastDepositTime[_pid][_account] = block.timestamp;
            }
        }
        user.rewardDebt = user.amount * pool.accSharePerShare / 1e18;
        emit Deposit(_account, _pid, _amount);
    }

    function unfrozenDepositTime(uint256 _pid, address _account) public view returns (uint256) {
        return (whitelist_[_account]) ? userLastDepositTime[_pid][_account] : userLastDepositTime[_pid][_account] + poolInfo[_pid].lockedTime;
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) external override nonReentrant checkContract {
        _withdraw(msg.sender, _pid, _amount);
    }

    function _withdraw(address _account, uint256 _pid, uint256 _amount) internal checkPoolEnd {
        require(_amount == 0 || block.timestamp >= unfrozenDepositTime(_pid, _account), "still locked");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_account];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        if (user.amount > 0) {
            _harvestReward(_pid, _account, _amount > 0 && pool.lockedTime > 0);
        }
        if (_amount > 0) {
            user.amount -= _amount;
            IERC20(pool.lpToken).safeTransfer(_account, _amount);
        }
        user.rewardDebt = user.amount * pool.accSharePerShare / 1e18;
        emit Withdraw(_account, _pid, _amount);
    }

    function withdrawAll(uint256 _pid) external override {
        _withdraw(msg.sender, _pid, userInfo[_pid][msg.sender].amount);
    }

    function harvestAllRewards() external override {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            if (userInfo[pid][msg.sender].amount > 0) {
                _withdraw(msg.sender, pid, 0);
            }
        }
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        IERC20(pool.lpToken).safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    function _mintShare(address _to, uint256 _amount) internal {
        if (_amount > 0) {
            IDollar(share).poolMint(_to, _amount);
        }
    }

    function _burnShare(uint256 _amount) internal {
        _mintShare(address(this), _amount);
        IDollar(share).poolBurnFrom(address(this), _amount);
        totalShareBurn += _amount;
    }

    function _topupFunds(uint256 _userReward) internal {
        uint256 _totalAmount = _userReward * totalRewardPerSecond / rewardPerSecond;
        
        uint256 _devAmount = _totalAmount * devRate / 10000;
        _mintShare(devFund, _devAmount);
        totalDevFundAdded += _devAmount;
        
        uint256 _insuranceAmount = _totalAmount * insuranceRate / 10000;
        _mintShare(insuranceFund, _insuranceAmount);
        totalInsuranceFundAdded += _insuranceAmount;
    }

    /* ========== Set Variable Functions ========== */

    function setTotalRewardPerSecond(uint256 _totalRewardPerSecond) external onlyOwnerOrTreasury {
        require(_totalRewardPerSecond <= 0.01 ether, "too high rate");
        massUpdatePools();
        totalRewardPerSecond = _totalRewardPerSecond;
        _updateRewardPerSecond();
    }

    function setDevFund(address _devFund) external onlyOwner {
        require(_devFund != address(0), "zero");
        devFund = _devFund;
    }

    function setDevRate(uint256 _devRate) external onlyOwner {
        require(_devRate <= 5000, "too high"); // <= 50%
        devRate = _devRate;
        _updateRewardPerSecond();
    }

    function setInsuranceFund(address _insuranceFund) external onlyOwner {
        require(_insuranceFund != address(0), "zero");
        insuranceFund = _insuranceFund;
    }

    function setInsuranceRate(uint256 _insuranceRate) external onlyOwner {
        require(_insuranceRate <= 5000, "too high"); // <= 50%
        insuranceRate = _insuranceRate;
        _updateRewardPerSecond();
    }

    function setWhitelist(address _address, bool _on) external onlyOwner {
        whitelist_[_address] = _on;
        emit Whitelisted(_address, _on);
    }

    function setNftController(address _controller) external onlyOwner {
        nftController = _controller;
        emit UpdateNFTController(msg.sender, _controller);
    }

    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
        emit UpdateTreasury(msg.sender, _treasury);
    }

    function setNftBoostRate(uint256 _rate) external onlyOwner {
        require(_rate >= 5000 && _rate <= 50000, "boost must be within range"); // 0.5x -> 5x
        nftBoostRate = _rate;
        emit UpdateNFTBoostRate(msg.sender, _rate);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interface/IERC20.sol";
import "./library/SafeERC20.sol";
import "./library/SafeMath.sol";

contract LiquidityMining is Initializable{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct PoolInfo{
        address xToken;
        address collection;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accPerShare;
        uint256 amount;
    }

    struct UserInfo{
        uint256 amount;
        mapping(uint256 /* orderId */ => uint256 /* amount */) orders;
        uint256 rewardDebt;
        uint256 rewardToClaim;
    }

    bool internal _notEntered;

    IERC20 public erc20Token;

    address public controller;
    address public admin;
    address public pendingAdmin;

    uint256 public borrowPerBlockReward;
    uint256 public borrowTotalAllocPoint;

    mapping(address /* xToken */ => mapping(address /* collection */ => PoolInfo)) public borrowPoolInfoMap;
    mapping(address /* xToken */ => mapping(address /* collection */ => mapping(address /* user */ => UserInfo))) public borrowUserInfoMap;
    mapping(address /* xToken */ => uint256) public supplyPerBlockRewardMap;
    mapping(address /* xToken */ => PoolInfo) public supplyPoolInfoMap;
    mapping(address /* xToken */ => mapping(address /* user */ => UserInfo)) public supplyUserInfoMap;

    event Deposit(address xToken, address collection, bool isBorrow, uint256 amount, address account);
    event Withdraw(address xToken, address collection, bool isBorrow, uint256 amount, address account);
    event Claim(address xToken, address collection, bool isBorrow, uint256 amount, address account);

    function initialize() public initializer {
        admin = msg.sender;
        _notEntered = true;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "require admin auth");
        _;
    }

    modifier onlyController() {
        require(msg.sender == controller || msg.sender == admin, "require controller auth");
        _;
    }

    modifier nonReentrant() {
        require(_notEntered, "re-entered");
        _notEntered = false;
        _;
        _notEntered = true;
    }

    function setPendingAdmin(address payable newPendingAdmin) external onlyAdmin{
        pendingAdmin = newPendingAdmin;
    }

    function acceptAdmin() public{
        require(msg.sender == pendingAdmin, "only pending admin could accept");
        admin = pendingAdmin;
        pendingAdmin = address(0);
    }

    function setController(address _controller) external onlyAdmin{
        controller = _controller;
    }

    function setErc20Token(IERC20 _erc20Token) external onlyAdmin{
        erc20Token = _erc20Token;
    }

    function setBorrowPerBlockReward(uint256 _borrowPerBlockReward) external onlyAdmin{
        borrowPerBlockReward = _borrowPerBlockReward;
    }

    function setSupplyPerBlockRewardMap(address xToken, uint256 perBlockReward) external onlyAdmin{
        supplyPerBlockRewardMap[xToken] = perBlockReward;
    }

    function addPool(address xToken, address collection, uint256 allocPoint, bool isBorrow) external onlyAdmin{
        PoolInfo memory poolInfo;
        if(isBorrow){
            poolInfo = borrowPoolInfoMap[xToken][collection];
            require(poolInfo.xToken == address(0), "pool already exists!");
            poolInfo.xToken = xToken;
            poolInfo.collection = collection;
            poolInfo.allocPoint = allocPoint;
            poolInfo.lastRewardBlock = block.number;
            borrowPoolInfoMap[xToken][collection] = poolInfo;

            borrowTotalAllocPoint += allocPoint;
        }else{
            poolInfo = supplyPoolInfoMap[xToken];
            require(poolInfo.xToken == address(0), "pool already exists!");
            poolInfo.xToken = xToken;
            poolInfo.lastRewardBlock = block.number;
            supplyPoolInfoMap[xToken] = poolInfo;
        }
    }

    function setPool(address xToken, address collection, uint256 allocPoint, bool isBorrow) external onlyAdmin{
        if(isBorrow){
            PoolInfo storage poolInfo = borrowPoolInfoMap[xToken][collection];
            require(poolInfo.xToken != address(0), "pool not exists!");

            borrowTotalAllocPoint = borrowTotalAllocPoint.sub(poolInfo.allocPoint).add(allocPoint);

            poolInfo.xToken = xToken;
            poolInfo.collection = collection;
            poolInfo.allocPoint = allocPoint;
        }else{
            PoolInfo storage poolInfo = supplyPoolInfoMap[xToken];
            require(poolInfo.xToken != address(0), "pool not exists!");
            poolInfo.xToken = xToken;
        }
    }

    function updatePool(address xToken, address collection, bool isBorrow) public{
        if(isBorrow){
            updateBorrowPool(xToken, collection);
        }else{
            updateSupplyPool(xToken);
        }
    }

    function updateBorrowPool(address xToken, address collection) internal{
        PoolInfo storage poolInfo = borrowPoolInfoMap[xToken][collection];
        if(poolInfo.xToken != address(0)){
            if (block.number <= poolInfo.lastRewardBlock) {
                return;
            }
            uint256 supply = poolInfo.amount;
            if (supply == 0) {
                poolInfo.lastRewardBlock = block.number;
                return;
            }
            uint256 multiplier = (block.number.sub(poolInfo.lastRewardBlock)).mul(borrowPerBlockReward);
            uint256 reward = multiplier.mul(poolInfo.allocPoint).div(borrowTotalAllocPoint);
            poolInfo.accPerShare = poolInfo.accPerShare.add(reward.mul(1e18).div(supply));
            poolInfo.lastRewardBlock = block.number;
        }
    }

    function updateSupplyPool(address xToken) internal{
        PoolInfo storage poolInfo = supplyPoolInfoMap[xToken];
        if(poolInfo.xToken != address(0)){
            if (block.number <= poolInfo.lastRewardBlock) {
                return;
            }
            uint256 supply = poolInfo.amount;
            if (supply == 0) {
                poolInfo.lastRewardBlock = block.number;
                return;
            }
            uint256 reward = (block.number.sub(poolInfo.lastRewardBlock)).mul(supplyPerBlockRewardMap[xToken]);
            poolInfo.accPerShare = poolInfo.accPerShare.add(reward.mul(1e18).div(supply));
            poolInfo.lastRewardBlock = block.number;
        }
    }

    function massUpdatePools(address[] calldata xToken, address[] calldata collection) external{
        for (uint256 i=0; i<xToken.length; ++i) {
            for(uint256 j=0; j<collection.length; ++j){
                updatePool(xToken[i], collection[j], true);
            }
            updatePool(xToken[i], address(0), false);
        }
    }

    function updateBorrow(address xToken, address collection, uint256 amount, address account, uint256 orderId, bool isDeposit) external onlyController nonReentrant{
        PoolInfo storage poolInfo = borrowPoolInfoMap[xToken][collection];
        if(poolInfo.xToken == address(0)) return;
        UserInfo storage user = borrowUserInfoMap[xToken][collection][account];
        if(!isDeposit && user.amount == 0) return;
        updatePool(xToken, collection, true);
        if((isDeposit && user.amount > 0) || !isDeposit){
            uint256 pending = user.amount.mul(poolInfo.accPerShare).div(1e18).sub(user.rewardDebt);
            user.rewardToClaim = user.rewardToClaim.add(pending);
        }
        poolInfo.amount = poolInfo.amount.sub(user.orders[orderId]).add(amount);
        user.amount = user.amount.sub(user.orders[orderId]).add(amount);
        user.rewardDebt = user.amount.mul(poolInfo.accPerShare).div(1e18);
        user.orders[orderId] = amount;
    }

    function updateSupply(address xToken, uint256 amount, address account, bool isDeposit) external onlyController nonReentrant{
        PoolInfo storage poolInfo = supplyPoolInfoMap[xToken];
        if(poolInfo.xToken == address(0)) return;
        UserInfo storage user = supplyUserInfoMap[xToken][account];
        if(!isDeposit && user.amount == 0) return;
        updatePool(xToken, address(0), false);
        if((isDeposit && user.amount > 0) || !isDeposit){
            uint256 pending = user.amount.mul(poolInfo.accPerShare).div(1e18).sub(user.rewardDebt);
            user.rewardToClaim = user.rewardToClaim.add(pending);
        }
        poolInfo.amount = poolInfo.amount.sub(user.amount).add(amount);
        user.amount = amount;
        user.rewardDebt = user.amount.mul(poolInfo.accPerShare).div(1e18);
    }

    function claim(address xToken, address collection, bool isBorrow, address account) internal{
        if(isBorrow){
            claimBorrowInternal(xToken, collection, account);
        }else{
            claimSupplyInternal(xToken, account);
        }
    }

    function claimBorrowInternal(address xToken, address collection, address account) internal{
        PoolInfo storage poolInfo = borrowPoolInfoMap[xToken][collection];
        if(poolInfo.xToken == address(0)) return;
        UserInfo storage user = borrowUserInfoMap[xToken][collection][account];
        updatePool(xToken, collection, true);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(poolInfo.accPerShare).div(1e18).sub(user.rewardDebt);
            user.rewardToClaim = user.rewardToClaim.add(pending);
        }
        user.rewardDebt = user.amount.mul(poolInfo.accPerShare).div(1e18);
        erc20Token.safeTransfer(account, user.rewardToClaim);
        
        emit Claim(xToken, collection, true, user.rewardToClaim, account);
        user.rewardToClaim = 0;
    }

    function claimBorrow(address xToken, address collection, address account) external nonReentrant{
        claimBorrowInternal(xToken, collection, account);
    }

    function claimSupplyInternal(address xToken, address account) internal{
        PoolInfo storage poolInfo = supplyPoolInfoMap[xToken];
        if(poolInfo.xToken == address(0)) return;
        UserInfo storage user = supplyUserInfoMap[xToken][account];
        updatePool(xToken, address(0), false);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(poolInfo.accPerShare).div(1e18).sub(user.rewardDebt);
            user.rewardToClaim = user.rewardToClaim.add(pending);
        }
        user.rewardDebt = user.amount.mul(poolInfo.accPerShare).div(1e18);
        erc20Token.safeTransfer(account, user.rewardToClaim);
        
        emit Claim(xToken, address(0), false, user.rewardToClaim, account);
        user.rewardToClaim = 0;
    }

    function claimSupply(address xToken, address account) external nonReentrant{
        claimSupplyInternal(xToken, account);
    }

    function claimAll(address[] calldata xToken, address[] calldata collection) external nonReentrant{
        for(uint256 i=0; i<xToken.length; ++i){
            for(uint256 j=0; j<collection.length; ++j){
                if(getPendingAmount(xToken[i], collection[j], msg.sender, true) > 0){
                    claim(xToken[i], collection[j], true, msg.sender);
                }
            }
            if(getPendingAmount(xToken[i], address(0), msg.sender, false) > 0){
                claim(xToken[i], address(0), false, msg.sender);
            }
        }
    }

    function getPendingAmountOfBorrow(address[] memory xToken, address[] memory collection, address account) external view returns(uint256){
        uint256 allAmount = 0;
        for(uint256 i=0; i<xToken.length; i++){
            for(uint256 j=0; j<collection.length; j++){
                allAmount = allAmount.add(getPendingAmount(xToken[i], collection[j], account, true));
            }
        }
        return allAmount;
    }

    function getPendingAmountOfSupply(address[] memory xToken, address account) external view returns(uint256){
        uint256 allAmount = 0;
        for(uint256 i=0; i<xToken.length; i++){
            allAmount = allAmount.add(getPendingAmount(xToken[i], address(0), account, false));
        }
        return allAmount;
    }

    function getPendingAmount(address xToken, address collection, address account, bool isBorrow) internal view returns(uint256){
        PoolInfo memory poolInfo;
        UserInfo storage user;
        if(isBorrow){
            poolInfo = borrowPoolInfoMap[xToken][collection];
            user = borrowUserInfoMap[xToken][collection][account];
        }else{
            poolInfo = supplyPoolInfoMap[xToken];
            user = supplyUserInfoMap[xToken][account];
        }
        if(poolInfo.xToken == address(0)) return 0;
        uint256 accPerShare = poolInfo.accPerShare;
        uint256 supply = poolInfo.amount;
        if(block.number > poolInfo.lastRewardBlock && supply != 0){
            uint256 reward;
            if(isBorrow){
                uint256 multiplier = (block.number.sub(poolInfo.lastRewardBlock)).mul(borrowPerBlockReward);
                reward = multiplier.mul(poolInfo.allocPoint).div(borrowTotalAllocPoint);
            }else{
                reward = (block.number.sub(poolInfo.lastRewardBlock)).mul(supplyPerBlockRewardMap[xToken]);
            }
            accPerShare = accPerShare.add(reward.mul(1e18).div(supply));
        }
        uint256 pending = user.amount.mul(accPerShare).div(1e18).sub(user.rewardDebt);
        uint256 totalPendingAmount = user.rewardToClaim.add(pending);
        return totalPendingAmount;
    }

    function getAllPendingAmount(address[] calldata xToken, address[] calldata collection, address account) external view returns (uint256){
        uint256 allAmount = 0;
        for (uint256 i=0; i<xToken.length; ++i) {
            for(uint256 j=0; j<collection.length; ++j){
                allAmount = allAmount.add(getPendingAmount(xToken[i], collection[j], account, true));
            }
            allAmount = allAmount.add(getPendingAmount(xToken[i], address(0), account, false));
        }
        return allAmount;
    }

    function getOrderIdAmount(address xToken, address collection, address account, uint256 orderId) external view returns(uint256){
        UserInfo storage user = borrowUserInfoMap[xToken][collection][account];
        return user.orders[orderId];
    }
}
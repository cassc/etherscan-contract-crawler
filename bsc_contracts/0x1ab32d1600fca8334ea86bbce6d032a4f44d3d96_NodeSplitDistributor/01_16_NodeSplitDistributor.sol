//SPDX-License-Identifier:MIT
pragma solidity ^0.8.4;

import "openzeppelin-contracts/contracts/utils/math/SafeMath.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {INodeSplitDistributor} from "../src/interfaces/INodeSplitDistributor.sol";
import {FireCatAccessControl} from "../src/utils/FireCatAccessControl.sol";
import {FireCatTransfer} from "../src/utils/FireCatTransfer.sol";
import {ModifyControl} from "../src/utils/ModifyControl.sol";


/**
 * @title FireCat's NodeSplitDistributor contract
 * @notice main: setNodeReward, claim
 * @author FireCat Finance
 */
contract NodeSplitDistributor is INodeSplitDistributor, FireCatAccessControl, FireCatTransfer, ModifyControl {
    using SafeMath for uint256;

    event TopUp(address user_, uint256 actualAddAmount_, uint256 totalSupplyNew_);
    event Claimed(uint256 userType_, address user_, uint256 actualClaimedAmount_, uint256 totalClaimed_);

    address public rewardToken;
    uint256 public totalSupply;
    uint256 public totalClaimed;

    uint256 public userAddressLength;
    uint256 public superUserAddressLength;

    uint256 public userTotalRewardPerCycle;
    uint256 public superUserTotalRewardPerCycle;
    
    struct user {
        uint256 receiveRewardThisCycle;
        uint256 claimed;
        uint256 totalReward;
    }

    struct superUser {
        uint256 receiveRewardThisCycle;
        uint256 claimed;
        uint256 totalReward;
    }

    mapping(address => uint256) public userType;
    mapping(address => user) public userData;
    mapping(address => superUser) public superUserData;

    address[] private _userAddress;
    address[] private _superUserAddress;

    function initialize(address rewardToken_) initializer public {
        rewardToken = rewardToken_;
        __AccessControl_init();
        __ReentrancyGuard_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @inheritdoc INodeSplitDistributor
    function reviewOf(address user_, uint256 userType_) public view returns (uint256, uint256, uint256, uint256){
        uint256 _receiveRewardThisCycle;
        uint256 _availableClaim;
        uint256 _totalReward;
        uint256 _claimed;

        if (userType_ == 1) {
            _receiveRewardThisCycle = userData[user_].receiveRewardThisCycle;
            _totalReward = userData[user_].totalReward;
            _claimed = userData[user_].claimed;
        } else if (userType_ == 2) {
            _receiveRewardThisCycle = superUserData[user_].receiveRewardThisCycle;
            _totalReward = superUserData[user_].totalReward;
            _claimed = superUserData[user_].claimed;
        }

        // _availableClaim = _totalReward - _claimed;
        _availableClaim = _totalReward.sub(_claimed);
        return (_receiveRewardThisCycle, _availableClaim, _claimed, _totalReward);
    }

    /// @inheritdoc INodeSplitDistributor
    function getNodeAddress(uint256 userType_, uint256 startIndex_, uint256 endIndex_) public view returns(address[] memory) {
        uint256 arrayLen = endIndex_ + 1;
        address[] memory userArray = new address[](arrayLen);
        for (uint256 i = startIndex_; i < arrayLen; i++) {
            uint256 index = i - startIndex_;
            if (userType_ == 1) {
                userArray[index] = _userAddress[i];
            }
            
            if (userType_ == 2) {
                userArray[index] = _superUserAddress[i];
            }
        }
        return userArray;
    }

    /// @inheritdoc INodeSplitDistributor
    function setRewardToken(address rewardToken_) external onlyRole(DATA_ADMIN) {
        rewardToken = rewardToken_;
    }

    /// @inheritdoc INodeSplitDistributor
    function setNodeReward(
        address[] memory userArray_,
        address[] memory superUserArray_,
        uint256 rewardPerUser_,
        uint256 rewardPerSuperUser_
    ) external onlyRole(DATA_ADMIN) returns (bool){
        for (uint256 i = 0; i < userArray_.length; i++) {
            address user_ = userArray_[i];

            if (userType[user_] != 1) {
                userAddressLength++;
                _userAddress.push(user_);
                userType[user_] = 1;
            }

            userData[user_].receiveRewardThisCycle = rewardPerUser_;
        }

        for (uint i = 0; i < superUserArray_.length; i++) {
            address superUser_ = superUserArray_[i];

            if (userType[superUser_] != 2) {
                superUserAddressLength++;
                _superUserAddress.push(superUser_);
                userType[superUser_] = 2;
            }

            superUserData[superUser_].receiveRewardThisCycle = rewardPerSuperUser_;
        }

        return true;
    }

    /// @inheritdoc INodeSplitDistributor
    function setUserTotalRewardPerCycle(uint256 userTotalRewardPerCycle_) external onlyRole(DATA_ADMIN) {
        userTotalRewardPerCycle = userTotalRewardPerCycle_;
    }

    /// @inheritdoc INodeSplitDistributor
    function setSuperUserTotalRewardPerCycle(uint256 superUserTotalRewardPerCycle_) external onlyRole(DATA_ADMIN) {
        superUserTotalRewardPerCycle = superUserTotalRewardPerCycle_;
    }

    /// @inheritdoc INodeSplitDistributor
    function updateNodeReward(address[] memory userArray_, address[] memory superUserArray_) external onlyRole(DATA_ADMIN) {
        for (uint256 i = 0; i < userArray_.length; i++) {
            address user_ = userArray_[i];
            require(userType[user_] == 1, "NODE:E03");
            uint256 usreReceiveReward_ = userData[user_].receiveRewardThisCycle;

            if (usreReceiveReward_ > 0) {
                userData[user_].receiveRewardThisCycle = 0;
                // userData[user_].totalReward += usreReceiveReward_;
                userData[user_].totalReward = userData[user_].totalReward.add(usreReceiveReward_);
            }
            
        }

        for (uint256 i = 0; i < superUserArray_.length; i++) {
            address superUser_ = superUserArray_[i];
            require(userType[superUser_] == 2, "NODE:E04");
            uint256 superUserReceiveReward_ = superUserData[superUser_].receiveRewardThisCycle;

            if (superUserReceiveReward_ > 0) {
                superUserData[superUser_].receiveRewardThisCycle = 0;
                // superUserData[superUser_].totalReward += superUserReceiveReward_;
                superUserData[superUser_].totalReward = superUserData[superUser_].totalReward.add(superUserReceiveReward_);
            }
        }
    }

    /// @inheritdoc INodeSplitDistributor
    function withdrawRemaining(address token, address to, uint256 amount) external nonReentrant onlyRole(SAFE_ADMIN) returns (uint256) {
        return withdraw(token, to, amount);
    }

    /// @inheritdoc INodeSplitDistributor
    function topUp(uint256 addAmount) external onlyRole(SAFE_ADMIN) returns (uint256) {
        require(IERC20(rewardToken).balanceOf(msg.sender) >= addAmount, "NODE:E05");

        uint256 actualAddAmount = doTransferIn(rewardToken, msg.sender, addAmount);
        // totalReservesNew + actualAddAmount
        uint256 totalSupplyNew = totalSupply.add(actualAddAmount);

        /* Revert on overflow */
        require(totalSupplyNew > totalSupply, "NODE:E02");

        totalSupply = totalSupplyNew;
        emit TopUp(msg.sender, actualAddAmount, totalSupplyNew);
        return actualAddAmount;
    }

    /// @inheritdoc INodeSplitDistributor
    function claim(uint256 userType_) external nonReentrant isBanned(msg.sender) beforeClaim returns (uint256) {
        require(userType_ == 1 || userType_ == 2, "NODE:E00");
        (,uint256 availableClaim,,) = reviewOf(msg.sender, userType_);
        require(availableClaim > 0, "NODE:E01");

        IERC20(rewardToken).approve(msg.sender, availableClaim);
        uint256 actualClaimedAmount = doTransferOut(rewardToken, msg.sender, availableClaim);

        if (userType_ == 1) {
            userData[msg.sender].claimed = userData[msg.sender].claimed.add(actualClaimedAmount);
        }
        
        if (userType_ == 2) {
            superUserData[msg.sender].claimed = superUserData[msg.sender].claimed.add(actualClaimedAmount);
        }

        totalClaimed = totalClaimed.add(actualClaimedAmount);
        emit Claimed(userType_, msg.sender, actualClaimedAmount, totalClaimed);
        return actualClaimedAmount;
    }
    
}
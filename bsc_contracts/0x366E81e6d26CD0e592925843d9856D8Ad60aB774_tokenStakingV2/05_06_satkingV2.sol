// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./StakingStateV2.sol";
import "./IVault.sol";


contract tokenStakingV2 is StakingStateV2, ReentrancyGuard {
	using SafeMath for uint;
	IERC20 public token; // 0x83d3C2D1A55687498Df6800c5F173EC6a7556089
    IVault public vault;

    // Info of each user.
    struct UserInfo {
        address user;
        uint amount;
        uint rewardLockedUp;
        uint totalDeposit;
        uint totalWithdrawn;
        uint nextWithdraw;
        uint depositCheckpoint;
    }

    mapping(address => UserInfo) public users;
	mapping (address => uint) public lastBlock;

    
	event Newbie(address user);
	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);
	event Reinvestment(address indexed user, uint256 amount);
	event ForceWithdraw(address indexed user, uint256 amount);

    constructor(address _vault, address _token) {
        devAddress = msg.sender;
        vault = IVault(_vault);
        token = IERC20(_token);
    }

    modifier tenBlocks() {
        require(
            block.number.sub(lastBlock[msg.sender]) > 10,
            "wait 10 blocks"
        );
        _;
    }


    function invest(uint amount) external nonReentrant whenNotPaused tenBlocks hasNotStoppedProduction hasNotStoppedInvest {
        require(amount >= MIN_INVEST, "Minimum amount is 10");
        lastBlock[msg.sender] = block.number;
        UserInfo storage user = users[msg.sender];
        if(user.user == address(0)) {
            user.user = msg.sender;
            investors[totalUsers] = msg.sender;
			totalUsers++;
            emit Newbie(msg.sender);
        }
        updateDeposit(msg.sender);
        users[msg.sender].amount += amount;
        users[msg.sender].totalDeposit += amount;

        totalInvested += amount;
        totalDeposits++;

        if(user.nextWithdraw == 0) {
            user.nextWithdraw = block.timestamp + TIME_STEP;
        }

        token.transferFrom(msg.sender, address(vault), amount);
        
    }

    function payToUser(bool _withdraw) internal {
        require(userCanwithdraw(msg.sender), "User cannot withdraw");
        updateDeposit(msg.sender);
        uint fromVault;
        if(_withdraw) {
            fromVault = users[msg.sender].amount;
            delete users[msg.sender].amount;
            delete users[msg.sender].nextWithdraw;
        } else {
            users[msg.sender].nextWithdraw = block.timestamp + TIME_STEP;
        }
        uint formThis = users[msg.sender].rewardLockedUp;
        delete users[msg.sender].rewardLockedUp;        
        uint _toWithdraw = fromVault + formThis;
        totalWithdrawn += _toWithdraw;
        users[msg.sender].totalWithdrawn += _toWithdraw;
        if(fromVault > 0) {
            vault.safeTransfer(token, msg.sender, fromVault);
        }
        token.transfer(msg.sender, formThis);
        emit Withdrawn(msg.sender, _toWithdraw);
    }

    function harvest() external nonReentrant whenNotPaused tenBlocks hasNotStoppedProduction {
        lastBlock[msg.sender] = block.number;
        payToUser(false);
    }

    function withdraw() external nonReentrant whenNotPaused tenBlocks hasStoppedProduction {
        lastBlock[msg.sender] = block.number;
        payToUser(true);
    }


    function reinvest() external nonReentrant whenNotPaused tenBlocks hasNotStoppedProduction {
        lastBlock[msg.sender] = block.number;
        require(userCanwithdraw(msg.sender), "User cannot reinvest");
        updateDeposit(msg.sender);
        users[msg.sender].nextWithdraw = block.timestamp + TIME_STEP;
        uint pending = users[msg.sender].rewardLockedUp;
        users[msg.sender].amount += pending;
        delete users[msg.sender].rewardLockedUp;
        totalReinvested += pending;
        totalReinvestCount++;
        token.transfer(address(vault), pending);
    }

    function forceWithdraw() external nonReentrant whenNotPaused tenBlocks hasStoppedProduction {
        lastBlock[msg.sender] = block.number;
        require(userCanwithdraw(msg.sender), "User cannot withdraw");
        uint toTransfer = users[msg.sender].amount;
        delete users[msg.sender].rewardLockedUp;
        delete users[msg.sender].amount;
        delete users[msg.sender].nextWithdraw;
        users[msg.sender].totalWithdrawn += toTransfer;
        users[msg.sender].depositCheckpoint = block.timestamp;
        totalWithdrawn += toTransfer;
        vault.safeTransfer(token, msg.sender, toTransfer);
    }

    function takeTokens(uint _bal) external onlyOwner {
        token.transfer(msg.sender, _bal);
    }


    function getReward(uint _weis, uint _seconds) public pure returns(uint) {
        return (_weis * _seconds * ROI) / (TIME_STEP * PERCENT_DIVIDER);
    }


    function userCanwithdraw(address user) public view returns(bool) {
        if(block.timestamp > users[user].nextWithdraw) {
            if(users[user].amount > 0) {
                return true;
            }
        }
        return false;
    }

    function getDeltaPendingRewards(address _user) public view returns(uint) {
        if(users[_user].depositCheckpoint == 0) {
            return 0;
        }
        uint time = block.timestamp;
        if(time > stopProductionDate) {
            time = stopProductionDate;
        }
        return getReward(users[_user].amount, time.sub(users[_user].depositCheckpoint));
    }

    function getUserTotalPendingRewards(address _user) public view returns(uint) {
        return users[_user].rewardLockedUp + getDeltaPendingRewards(_user);
    }

    function updateDeposit(address _user) internal {
        users[_user].rewardLockedUp = getUserTotalPendingRewards(_user);
        users[_user].depositCheckpoint = block.timestamp;
    }

    function getUser(address _user) external view returns(UserInfo memory userInfo_, 
    uint pendingRewards) {
        userInfo_ = users[_user];   
        pendingRewards = getUserTotalPendingRewards(_user);        
    }

    function getAllUsers() external view returns(UserInfo[] memory) {
        UserInfo[] memory result = new UserInfo[](totalUsers);
        for(uint i = 0; i < totalUsers; i++) {
            result[i] = users[investors[i]];
        }
        return result;
    }

    function getUserByIndex(uint _index) external view returns(UserInfo memory) {
        require(_index < totalUsers, "Index out of bounds");
        return users[investors[_index]];
    }

}
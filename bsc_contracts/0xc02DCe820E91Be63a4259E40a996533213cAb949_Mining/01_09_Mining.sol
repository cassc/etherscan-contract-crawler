// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Mining is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        address superior;
    }

    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;

    IERC20 public lpToken;
    uint256 public lastRewardBlock;
    uint256 public accTokenPerShare;
    uint256 public totalAmount;
    IERC20 public token;
    uint256 public tokenPerDay = 0;
    uint256 public tokenPerBlock = 0;
    bool public paused = false;
    uint256 public startBlock;
    uint256 public constant ONE_DAY = 1 days / 3;
    
    mapping(address => UserInfo) public userInfo;
    mapping(address => bool) public bindInit;
    address[] public marketAddress;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event Bind(address indexed user, address indexed superior);
    // user: The address where the current income is obtained
    // kind = 1：Mining income, kind = 2：one-tier income, kind = 3：two-tier income
    // who: Who gives the current income，If it is mining revenue, it is address(0)
    event Reward(address indexed user, uint256 indexed kind, uint256 amount, address who);

    constructor(
        IERC20 _token,
        IERC20 _lpToken,
        address _bindInitAddress,
        address[] memory _marketAddress
    ) {
        token = _token;
        lpToken = _lpToken;
        bindInit[_bindInitAddress] = true;
        marketAddress = _marketAddress;
        startBlock = block.number;
    }

    function setTokenPerBlock(uint256 oneDayReward) public onlyOwner {
        updatePool();
        uint256 oneDayRewardDecimal = oneDayReward * 1e18;
        tokenPerBlock = oneDayRewardDecimal / ONE_DAY;
        tokenPerDay = oneDayReward;
    }
    
    function changeToken(IERC20 _token) public onlyOwner {
       token = _token;
    }

    function changeLpToken(IERC20 _lpToken) public onlyOwner {
       lpToken = _lpToken;
    }

    function setPause() public onlyOwner {
        paused = !paused;
    }

    function getTokenBlockReward(uint256 _lastRewardBlock) public view returns (uint256) {
        return (block.number.sub(_lastRewardBlock)).mul(tokenPerBlock);
    }

    // use DEAD as root node
    function bind(address superior) public nonReentrant {
        address _user = msg.sender;
        if (!bindInit[_user]) {
            require(superior != address(0), "superior != address(0)");
            require(userInfo[_user].superior == address(0), "Repeat binding");
            require(userInfo[superior].amount > 0, "superior have no deposit amount");
        } else {
            require(superior == DEAD, "superior == DEAD");
        }
        userInfo[_user].superior = superior;
        emit Bind(_user, superior);
    }
   
    function updatePool() public {
        if (block.number <= lastRewardBlock) {
            return;
        }
        // uint256 lpSupply = pToken.balanceOf(address(this));
        uint256 lpSupply = totalAmount;
        if (lpSupply == 0) {
            lastRewardBlock = block.number;
            return;
        }
        uint256 blockReward = getTokenBlockReward(lastRewardBlock);
        if (blockReward <= 0) {
            return;
        }
        accTokenPerShare = accTokenPerShare.add(blockReward.mul(1e12).div(lpSupply));
        lastRewardBlock = block.number;
    }

    function pending(address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 _accTokenPerShare = accTokenPerShare;
        uint256 lpSupply = lpToken.balanceOf(address(this));
        if (user.amount > 0) {
            if (block.number > lastRewardBlock) {
                uint256 tokenReward = getTokenBlockReward(lastRewardBlock);
                _accTokenPerShare = _accTokenPerShare.add(tokenReward.mul(1e12).div(lpSupply));
                return getProfit(user.amount.mul(_accTokenPerShare).div(1e12).sub(user.rewardDebt));
            }
            if (block.number == lastRewardBlock) {
                return getProfit(user.amount.mul(_accTokenPerShare).div(1e12).sub(user.rewardDebt));
            }
        }
        return 0;
    }
    
    function deposit(uint256 _amount) public notPause nonReentrant {   
        depositToken(_amount, msg.sender);
    }

    function depositToken(uint256 _amount, address _user) private {
        UserInfo storage user = userInfo[_user];
        require(user.superior != address(0), "user.superior != address(0)");
        updatePool();
        if (user.amount > 0) {
            uint256 pendingAmount = user.amount.mul(accTokenPerShare).div(1e12).sub(user.rewardDebt);
            if (pendingAmount > 0) {
                disReward(user, _user, pendingAmount);
            }
        }
        if (_amount > 0) {
            lpToken.safeTransferFrom(_user, address(this), _amount);
            user.amount = user.amount.add(_amount);
            totalAmount = totalAmount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(accTokenPerShare).div(1e12);
        emit Deposit(_user, _amount);
    }

    function getProfit(uint256 amount) internal pure returns (uint256) {
        return amount * 8 * 85 / 10 / 100;
    }

    function disSuperiorReward(UserInfo memory user, address _user, uint256 _amount) internal {
        address _one = user.superior;
        if (_one != address(0) && _one != DEAD) {
            uint256 oneProfit = _amount * 8 / 10 / 10;
            safeTokenTransfer(_one, oneProfit);
            emit Reward(_one, 2, oneProfit, _user);

            address _two = userInfo[_one].superior;
             if (_two != address(0) && _two != DEAD) {
                uint256 twoProfit = _amount * 8 / 10 / 20;
                safeTokenTransfer(_two, twoProfit);
                emit Reward(_two, 3, twoProfit, _user);
            }
        }
    }

    function disMarketReward(uint256 _amount) internal {
        uint256 len = marketAddress.length;
        if (len > 0) {
            uint256 _value = _amount / 5 / len;
            for (uint256 i = 0; i < len; i++) {
                safeTokenTransfer(marketAddress[i], _value);
            }
        }
    }

    function disReward(UserInfo memory user, address _user, uint256 _amount) internal {
        uint256 profit = getProfit(_amount);
        safeTokenTransfer(_user, profit);
        emit Reward(_user, 1, profit, address(0));

        disSuperiorReward(user, _user, _amount);
        disMarketReward(_amount);
    }

    function withdraw(uint256 _amount) public notPause nonReentrant {
        withdrawToken(_amount, msg.sender);
    }

    function withdrawToken(uint256 _amount, address _user) private {
        UserInfo storage user = userInfo[_user];
        require(user.amount >= _amount, "withdrawToken: not good");
        updatePool();
        uint256 pendingAmount = user.amount.mul(accTokenPerShare).div(1e12).sub(user.rewardDebt);
        if (pendingAmount > 0) {
            disReward(user, _user, pendingAmount);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            totalAmount = totalAmount.sub(_amount);
            lpToken.safeTransfer(_user, _amount);
        }
        user.rewardDebt = user.amount.mul(accTokenPerShare).div(1e12);
        emit Withdraw(_user, _amount);
    }

    function emergencyWithdraw() public nonReentrant {
        emergencyWithdrawToken(msg.sender);
    }

    function emergencyWithdrawToken(address _user) private {
        UserInfo storage user = userInfo[_user];
        uint256 amount = user.amount;
        require(amount > 0, "(amount > 0");
        user.amount = 0;
        user.rewardDebt = 0;
        lpToken.safeTransfer(_user, amount);
        totalAmount = totalAmount.sub(amount);
        emit EmergencyWithdraw(_user, amount);
    }

    function safeTokenTransfer(address _to, uint256 _amount) internal {
        token.safeTransfer(_to, _amount);
        // uint256 tokenBal = token.balanceOf(address(this));
        // if (_amount > tokenBal) {
        //     token.safeTransfer(_to, tokenBal);
        // } else {
        //     token.safeTransfer(_to, _amount);
        // }
    }

    modifier notPause() {
        require(paused == false, "Mining has been suspended");
        _;
    }

    function setBindInit(address _addr, bool _isInit) public onlyOwner {
        bindInit[_addr] = _isInit;
    }

    function setMarketAddress(address[] memory _marketAddress) public onlyOwner {
        marketAddress = _marketAddress;
    }
}
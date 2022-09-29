// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @author Brewlabs
 * This contract has been developed by brewlabs.info
 */
 
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../libs/IPriceOracle.sol";

contract BlocVestAccumulatorVault is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // The staked token
    IERC20 public stakingToken;
    IPriceOracle private oracle;

    uint256[] public nominated = [7, 14, 30];
    uint256[] public bonusRates = [500, 1000, 2000];
    uint256 public depositLimit = 500 ether;

    uint256 public constant MAX_BONUS_LIMIT = 1000;

    struct UserInfo {
        uint256 amount;
        uint256 usdAmount;
        uint256 initialAmount;
        uint256 nominatedType;
        uint256 nominatedCycle;
        uint256 lastDepositTime;
        uint256 lastClaimTime;
        uint256 totalStaked;
        uint256 totalReward;
        bool isNominated;
    }
    mapping(address => UserInfo) public userInfo;
    uint256 public userCount;
    uint256 public totalStaked;

    address public treasury = 0xBd6B80CC1ed8dd3DBB714b2c8AD8b100A7712DA7;
    uint256 public performanceFee = 0.0035 ether;
    uint256 constant TIME_UNITS = 1 days;

    event Deposit(address indexed user, uint256 amount);
    event Claim(address indexed user, uint256 amount);
    event CycleNominated(address indexed user, uint256 cycle);
    event AdminTokenRecovered(address tokenRecovered, uint256 amount);
    event ServiceInfoUpadted(address addr, uint256 fee);
    event SetBonusRate(uint256[] rates);
    event SetDepositLimit(uint256 limit);

    constructor(IERC20 _token, address _oracle) {
        stakingToken = _token;
        oracle = IPriceOracle(_oracle);
    }

    function deposit(uint256 _amount) external payable nonReentrant {
        UserInfo storage user = userInfo[msg.sender];

        require(_amount > 0, "Amount should be greator than 0");
        require(user.nominatedCycle > 0, "not nominate days");
        require(user.lastDepositTime + user.nominatedCycle * TIME_UNITS < block.timestamp, "cannot deposit before pass nominated days");

        _transferPerformanceFee();

        uint256 beforeAmount = stakingToken.balanceOf(address(this));
        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 afterAmount = stakingToken.balanceOf(address(this));
        uint256 realAmount = afterAmount - beforeAmount;

        uint256 tokenPrice = oracle.getTokenPrice(address(stakingToken));
        uint256 usdAmount = realAmount * tokenPrice / 1 ether;
        require(usdAmount <= depositLimit, "cannot exceed max deposit limit");

        if(user.amount > 0) {
            uint256 claimable = 0;
            if(user.lastClaimTime == user.lastDepositTime) {
                uint256 depositedTokens = user.usdAmount * 1e18 / tokenPrice;
                if(depositedTokens > user.amount) {
                    depositedTokens = user.amount;
                }
                claimable = depositedTokens;
            }

            uint256 expireTime = user.lastDepositTime + (user.nominatedCycle + 1) * TIME_UNITS;
            if(block.timestamp < expireTime && user.usdAmount >= user.initialAmount && usdAmount >= user.initialAmount) {
                uint256 reward = (user.usdAmount * bonusRates[user.nominatedType] / 10000) * 1e18 / tokenPrice;
                uint256 maxRewards = stakingToken.totalSupply() * MAX_BONUS_LIMIT / 10000;
                if(reward > maxRewards) reward = maxRewards;
                claimable += reward;
            }

            stakingToken.safeTransfer(msg.sender, claimable);
            user.totalReward += claimable;
        }

        if(user.initialAmount == 0) {
            user.initialAmount = usdAmount;
            user.isNominated = true;
            userCount = userCount + 1;
        }

        user.amount = realAmount;
        user.usdAmount = usdAmount;
        user.totalStaked += realAmount;
        user.lastDepositTime = block.timestamp;
        user.lastClaimTime = block.timestamp;
        
        totalStaked += realAmount;

        emit Deposit(msg.sender, realAmount);
    }

    function nominatedDays(uint256 _type) external {
        require(_type < nominated.length, "invalid type");
        require(userInfo[msg.sender].isNominated == false, "already nominated");

        UserInfo storage user = userInfo[msg.sender];
        user.nominatedCycle = nominated[_type];
        user.nominatedType = _type;

        emit CycleNominated(msg.sender, nominated[_type]);
    }

    function claim() external payable nonReentrant {
        UserInfo storage user = userInfo[msg.sender];

        _transferPerformanceFee();

        uint256 expireTime = user.lastDepositTime + user.nominatedCycle * TIME_UNITS;
        if(block.timestamp > expireTime && user.lastClaimTime == user.lastDepositTime) {
            uint256 tokenPrice = oracle.getTokenPrice(address(stakingToken));  
            uint256 claimable = user.usdAmount * 1e18 / tokenPrice;
            if(claimable > user.amount) {
                claimable = user.amount;
            }
            
            stakingToken.safeTransfer(msg.sender, claimable);
            user.totalReward += claimable;

            emit Claim(msg.sender, claimable);
        }

        user.lastClaimTime = block.timestamp;
    }

    function pendingRewards(address _user) external view returns (uint256) {
        UserInfo memory user = userInfo[_user];
        
        uint256 claimable = 0;        
        uint256 expireTime = user.lastDepositTime + user.nominatedCycle * TIME_UNITS;
        if(block.timestamp > expireTime && user.lastClaimTime == user.lastDepositTime) {
            uint256 tokenPrice = oracle.getTokenPrice(address(stakingToken));
            
            claimable = user.usdAmount * 1e18 / tokenPrice;
            if(claimable > user.amount) {
                claimable = user.amount;
            }
        }

        return claimable;
    }

    function _transferPerformanceFee() internal {
        require(msg.value >= performanceFee, 'should pay small gas to compound or harvest');

        payable(treasury).transfer(performanceFee);
        if(msg.value > performanceFee) {
            payable(msg.sender).transfer(msg.value - performanceFee);
        }
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _token: the address of the token to withdraw
     * @param _amount: the number of tokens to withdraw
     * @dev This function is only callable by admin.
     */
    function rescueTokens(address _token, uint256 _amount) external onlyOwner {
        if(_token == address(0x0)) {
            payable(msg.sender).transfer(_amount);
        } else {
            IERC20(_token).safeTransfer(address(msg.sender), _amount);
        }

        emit AdminTokenRecovered(_token, _amount);
    }

    function setServiceInfo(address _treasury, uint256 _fee) external {
        require(msg.sender == treasury, "setServiceInfo: FORBIDDEN");
        require(_treasury != address(0x0), "Invalid address");

        treasury = _treasury;
        performanceFee = _fee;

        emit ServiceInfoUpadted(_treasury, _fee);
    }

    function setDepositLimit(uint256 _limit) external onlyOwner {
        depositLimit = _limit * 1 ether;
        emit SetDepositLimit(_limit);
    }

    function setBonusRates(uint256[] memory _rates) external onlyOwner {
        require(_rates.length == 3, "Invalid rate");
        for(uint i = 0; i < 3; i++) {
            require(_rates[i] <= 5000, "exceed bonus limit");
            bonusRates[i] = _rates[i];
        }
        emit SetBonusRate(_rates);
    }

    receive() external payable {}
}
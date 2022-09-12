// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./sHuH.sol";
import "./Exponentation.sol";

contract Staking is Initializable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeERC20Upgradeable for ERC20Upgradeable;
    using SafeERC20Upgradeable for sHuH;
    uint256 public constant TWO_127 = 170141183460469231731687303715884105728;

    mapping(address=>uint256) public stakedAmount;
    mapping(address=>uint256) public rewardLastTime;

    ERC20Upgradeable public huh;
    sHuH public sHuh;
    Exponentation public exponentation;
    uint256 public totalStakedAmount;
    uint256 public totalRewardAmount;
    uint256 public rewardStopTime;
    uint256 public releaseStakedTokenTime;
    uint256 public minLimitToStake;
    uint256[] public rewardRatioSteps;
    mapping(uint256=>uint256) public rewardRatios;   

    event Stake(address sender, uint256 amount, uint256 totalAmount);
    event RewardRatioSet(uint256[] rewardRatioSteps, uint256[] rewardRatios);
    event ReleaseTimeSet(uint256 releaseStakedTokenTime);
    event RewardStopTimeSet(uint256 rewardStopTime);
    event TotalRewardAmountUpdated(uint256 totalRewardAmount);
    event ConfiurationUpdated(address huh, address sHuh, uint256 minLimitToStake, address exponentation);
    function setConfiguration(address _huh, address _sHuh, uint256 _minLimitToStake, address _exponentation) public onlyOwner {
        huh = ERC20Upgradeable(_huh);
        sHuh = sHuH(_sHuh);
        minLimitToStake=_minLimitToStake*10**huh.decimals();
        exponentation = Exponentation(_exponentation);
        emit ConfiurationUpdated(_huh, _sHuh, _minLimitToStake, _exponentation);
    }

    function setRewardRatio(
        uint256[] memory _rewardRatioSteps,
        uint256[] memory _rewardRatios        
    ) public onlyOwner {
        require(_rewardRatioSteps.length==_rewardRatios.length);
        rewardRatioSteps=_rewardRatioSteps;
        for(uint256 i=0;i<_rewardRatioSteps.length;i++){
            require(_rewardRatioSteps[i]>block.timestamp);
            if(i>0)
                require(_rewardRatioSteps[i]>_rewardRatioSteps[i-1]);
            rewardRatios[_rewardRatioSteps[i]]=_rewardRatios[i];
        }
        emit RewardRatioSet(_rewardRatioSteps, _rewardRatios);
    }
    function setReleaseTime(
        uint256 _releaseStakedTokenTime
    ) public onlyOwner {
        releaseStakedTokenTime=_releaseStakedTokenTime;
        emit ReleaseTimeSet(_releaseStakedTokenTime);
    }
    function setRewardStopTime(
        uint256 _rewardStopTime
    ) public onlyOwner {
        rewardStopTime=_rewardStopTime;
        emit RewardStopTimeSet(_rewardStopTime);
    }
    function initialize() public initializer {
        __Ownable_init();   
    }

    function distribute(address account) internal {
        uint256 limit=block.timestamp>rewardStopTime ? rewardStopTime : block.timestamp;
        if (limit == rewardLastTime[account]) return;
        uint256 timeCount;
        uint256 times;
        for (uint256 i = rewardRatioSteps.length; i > 0; --i) {
            if (rewardRatioSteps[i-1] < rewardLastTime[account]) {
                if (i == rewardRatioSteps.length) {
                    timeCount = limit-rewardLastTime[account];
                } else {
                    timeCount =
                        rewardRatioSteps[i]-rewardLastTime[account];
                }
                if (
                    rewardRatios[rewardRatioSteps[i-1]] == 0
                ) break;
                if(timeCount==0)
                    break;
                times += exponentation
                    .power(
                        (100000000+rewardRatios[rewardRatioSteps[i-1]]),
                        100000000,
                        timeCount,
                        1
                    )
                    *10000000000
                    /TWO_127 - 10000000000;
                break;
            }
            if(rewardRatioSteps[i-1]>=limit)
                continue;
            if (i == rewardRatioSteps.length) {
                timeCount = limit-rewardRatioSteps[i-1];
            } else {
                timeCount =
                    rewardRatioSteps[i]-rewardRatioSteps[i-1];
            }
            if (rewardRatios[rewardRatioSteps[i-1]] == 0)
                continue;
            if(timeCount==0)
                continue;
            times += exponentation
                .power(
                    (100000000+rewardRatios[rewardRatioSteps[i-1]]),
                    100000000,
                    timeCount,
                    1
                )
                *10000000000
                /TWO_127 - 10000000000;
        }
        rewardLastTime[account] = limit;
        uint256 _reward=stakedAmount[account]*times/10000000000;
        stakedAmount[account]+=_reward;
        totalRewardAmount+=_reward;
        emit TotalRewardAmountUpdated(totalRewardAmount);
    }

    function stake(uint256 amount) public {
        require(releaseStakedTokenTime>block.timestamp, "No allowed to stake");
        //distribute
        distribute(msg.sender);

        uint256 balanceBefore = huh.balanceOf(address(this));
        huh.safeTransferFrom(msg.sender, address(this), amount);
        uint256 _tBalanceAdded = huh.balanceOf(address(this))-balanceBefore;
        stakedAmount[msg.sender]+=_tBalanceAdded;
        require(stakedAmount[msg.sender]>=minLimitToStake, "less than limit");
        totalStakedAmount+=_tBalanceAdded;        
        emit Stake(msg.sender, _tBalanceAdded, totalStakedAmount);
    }

    function claimReward() external{
        distribute(msg.sender);
    }

    function transferStakedValue(address to, uint256 amount) external{
        distribute(msg.sender);
        distribute(to);
        require(amount<=stakedAmount[msg.sender], "More than balance");
        stakedAmount[to]+=amount;
        stakedAmount[msg.sender]-=amount;
    }

    function claimStakedHuH() external{
        require(releaseStakedTokenTime<block.timestamp, "No allowed right now");
        distribute(msg.sender);
        sHuh.mint(msg.sender, stakedAmount[msg.sender]);
        stakedAmount[msg.sender]=0;
    }

    function getRewardPlan() external view returns(uint256[] memory steps, uint256[] memory ratios){
        steps=rewardRatioSteps;
        ratios=new uint256[](rewardRatioSteps.length);
        for(uint256 i=0;i<rewardRatioSteps.length;i++){
            ratios[i]=rewardRatios[steps[i]];
        }
    }

}
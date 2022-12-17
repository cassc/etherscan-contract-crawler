pragma solidity 0.8.15;
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {SafeTransferLib} from "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {ERC20} from "@rari-capital/solmate/src/tokens/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {VaultFactory} from "./VaultFactory.sol";
import {Vault} from "./Vault.sol";
import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
contract StakingRewards is 
    Pausable, 
    ReentrancyGuard,
    Ownable, 
    ERC1155Holder
{
    using SafeMath for uint256;
    using SafeTransferLib for ERC20;

    ERC20 public immutable rewardsToken;
    error MarketDoesNotExist(uint marketId);
    error EpochDoesNotExist();
    error StakingRewardsExist();
    error StakingRewardsDoesNotExist();
    error EpochNotFinished();
    error StakingEpochDoesNotExist();
    error StakingLimit();

    mapping(address => mapping(uint256 => bool)) private StakingExist; // vaultaddress, epochEnd, stakingexist
    mapping(address => mapping(uint256 => bool)) public OpenStaking; // vaultaddress, epochEnd, OpenStaking
    mapping(address => mapping(uint256 => uint256)) private _totalSupply; // vaultaddress, epochEnd, totalSupply
    mapping(address => mapping(uint256 => uint256)) private apr; // vaultaddress, epochEnd, apr
    mapping(address => mapping(uint256 => uint256)) private _maxLock; // vaultAddress, epochEnd, maxLock
    
    /* ========== EVENT ========== */
    event CreateStaking(
        address hedge,
        address risk,
        uint256 epochEnd,
        uint256 hedgeApr,
        uint256 riskApr,
        uint256 createdTime
    );

    event UpdateStaking(
        address hedge,
        address risk,
        uint256 epochEnd,
        uint256 hedgeApr,
        uint256 riskApr,
        uint256 createdTime
    );

    event StakingRun(
        address hedge,
        address risk,
        uint256 epochEnd,
        uint256 createdTime
    );

    event Staked(
        address user,
        address vault,
        uint256 epochEnd,
        uint256 amount,
        uint256 createdTime
    );

    event Withdrawn(
        address user,
        address vault,
        uint256 epochEnd,
        uint256 amount,
        uint256 createdTime
    );

    event RewardPaid(
        address user,
        address vault,
        uint256 epochEnd,
        uint256 reward,
        uint256 createdTime
    );

    event MaxLock(
        address vault,
        uint256 epochEnd,
        uint256 duration,
        uint256 reward,
        uint256 apr,
        uint256 maxlock,
        uint256 createdTime
    );
    /* ========== USER ========== */
    struct User {
        uint256 balance;
        uint256 reward;
        uint256 withdrawal;
        uint256 lastTime;
    }
    mapping( address => mapping(address => mapping(uint256 => User))) private user; // user, vaultaddress, epochEnd

    /* ========== MODIFIERS ========== */
    modifier updateReward(address _vault, uint256 epochEnd, address account) {
        user[account][_vault][epochEnd].reward = user[account][_vault][epochEnd].reward.add(
                                user[account][_vault][epochEnd].balance
                                .mul(lastTimeRewardApplicable(epochEnd).sub(user[account][_vault][epochEnd].lastTime))
                                .mul(apr[_vault][epochEnd])
                                .div(getYear())
                                .div(1e18)
        );

        user[account][_vault][epochEnd].lastTime = lastTimeRewardApplicable(epochEnd);
        _;
    }

    modifier stakingRun(address vault, uint256 id) {
        if(OpenStaking[vault][id] != true)
            revert StakingEpochDoesNotExist();
        _;
    }

    modifier epochHasEnded(uint256 epochEnd) {
        if(epochEnd < block.timestamp)
            revert EpochNotFinished();
        _;
    }

    modifier stakingMaxLock(address vault, uint256 epochEnd, uint256 amount) {
        if(_totalSupply[vault][epochEnd].add(amount) > _maxLock[vault][epochEnd])
            revert StakingLimit();
        _;
    }
    /* ========== CONSTRUCTOR ========== */
    constructor( address _rewardsToken ) {
        _pause();
        rewardsToken = ERC20(_rewardsToken);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */
    function stake(address _vault, uint256 epochEnd, uint256 amount) 
        external 
        nonReentrant
        stakingRun(_vault, epochEnd)
        epochHasEnded(epochEnd)
        updateReward( _vault, epochEnd, msg.sender)
        stakingMaxLock(_vault, epochEnd, amount)
    {
        require(amount != 0, "Cannot stake 0");
        _totalSupply[_vault][epochEnd] = _totalSupply[_vault][epochEnd].add(amount);
        
        user[msg.sender][_vault][epochEnd].balance =  user[msg.sender][_vault][epochEnd].balance.add(amount);
        IERC1155(_vault).safeTransferFrom(
            msg.sender,
            address(this),
            epochEnd,
            amount,
            ""
        );
        emit Staked(msg.sender, _vault, epochEnd, amount, block.timestamp);
    }

    function withdraw(address _vault, uint256 epochEnd, uint256 amount)
            public
            nonReentrant
            stakingRun(_vault, epochEnd)
            updateReward( _vault, epochEnd, msg.sender)
    {
        require(amount > 0, "Cannot withdraw 0");
        _totalSupply[_vault][epochEnd] = _totalSupply[_vault][epochEnd].sub(amount);
        user[msg.sender][_vault][epochEnd].balance = user[msg.sender][_vault][epochEnd].balance.sub(amount);
        IERC1155(_vault).safeTransferFrom(
            address(this),
            msg.sender,
            epochEnd,
            amount,
            ""
        );
        emit Withdrawn(msg.sender, _vault, epochEnd, amount, block.timestamp);
    }

    function getReward(address _vault, uint256 epochEnd)
            public
            nonReentrant
            whenNotPaused
            updateReward( _vault, epochEnd, msg.sender)
    {   
        User storage UserInfor = user[msg.sender][_vault][epochEnd];
        uint256 reward = UserInfor.reward.sub(UserInfor.withdrawal);
        if(reward > 0){
            UserInfor.withdrawal = UserInfor.withdrawal.add(reward);
            rewardsToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, _vault, epochEnd, reward, block.timestamp);
        }
    }

    function exit(address _vault, uint256 epochEnd) external {
        withdraw(_vault, epochEnd, user[msg.sender][_vault][epochEnd].balance);
        getReward(_vault, epochEnd);
    }

    /* ========== VIEWS ========== */
    function earned(address _vault, uint256 epochEnd, address account) public view returns (uint256) {
        User memory accountUser = user[account][_vault][epochEnd];
        uint256 reward = accountUser.reward.add(
                                accountUser.balance
                                .mul(lastTimeRewardApplicable(epochEnd).sub(accountUser.lastTime))
                                .mul(apr[_vault][epochEnd])
                                .div(getYear())
                                .div(1e18)
        );

        return reward.sub(accountUser.withdrawal);
    }

    function totalSupply(address _vault, uint256 epochEnd) external view returns (uint256) {
        return _totalSupply[_vault][epochEnd];
    }

    function getUser(address _vault, uint256 epochEnd, address account) external view returns (User memory) {
        return user[account][_vault][epochEnd];
    }
    
    function getYear() public view returns (uint256) {
        return 365*24*60*60;
    }

    function lastTimeRewardApplicable(uint256 epochEnd) public view returns (uint256) {
        return block.timestamp < epochEnd ? block.timestamp : epochEnd;
    }

    function getApr(address _vault, uint256 _epochEnd) public view returns (uint256) {
        return apr[_vault][_epochEnd];
    }

    function maxLock(address _vault, uint256 _epochEnd) public view returns (uint256) {
        return _maxLock[_vault][_epochEnd];
    }
    
    /* ========== RESTRICTED FUNCTIONS ========== */
    function createStakingRewards(address _vaultFactory, uint256 _marketIndex, uint256 _epochEnd, uint256 _hedgeApr, uint256 _riskApr, uint256 _hedgeReward, uint256 _riskReward) external onlyOwner {
        VaultFactory vaultFactory = VaultFactory(_vaultFactory);
        
        address _insrToken = vaultFactory.getVaults(_marketIndex)[0];
        address _riskToken = vaultFactory.getVaults(_marketIndex)[1];
        
        if(_insrToken == address(0) || _riskToken == address(0))
            revert MarketDoesNotExist(_marketIndex);

        if(Vault(_insrToken).idExists(_epochEnd) == false || Vault(_riskToken).idExists(_epochEnd) == false)
            revert EpochDoesNotExist();

        if(StakingExist[_insrToken][_epochEnd] == true || StakingExist[_riskToken][_epochEnd] == true)
            revert StakingRewardsExist();

        apr[_insrToken][_epochEnd] = _hedgeApr.mul(10e18);
        apr[_riskToken][_epochEnd] = _riskApr.mul(10e18);

        StakingExist[_insrToken][_epochEnd] = true;
        StakingExist[_riskToken][_epochEnd] = true;

        addMaxLock(_insrToken, _epochEnd, _hedgeApr.mul(10e18), _hedgeReward);
        addMaxLock(_riskToken, _epochEnd, _riskApr.mul(10e18), _riskReward);

        emit CreateStaking(_insrToken, _riskToken, _epochEnd, _hedgeApr, _riskApr, block.timestamp);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function openStaking(address _vaultFactory, uint256 _marketIndex, uint256 _epochEnd) external onlyOwner {
        VaultFactory vaultFactory = VaultFactory(_vaultFactory);
        
        address _insrToken = vaultFactory.getVaults(_marketIndex)[0];
        address _riskToken = vaultFactory.getVaults(_marketIndex)[1];
        
        if(_insrToken == address(0) || _riskToken == address(0))
            revert MarketDoesNotExist(_marketIndex);

        if(Vault(_insrToken).idExists(_epochEnd) == false || Vault(_riskToken).idExists(_epochEnd) == false)
            revert EpochDoesNotExist();

        if(StakingExist[_insrToken][_epochEnd] == false || StakingExist[_riskToken][_epochEnd] == false)
            revert StakingRewardsExist();

        OpenStaking[_insrToken][_epochEnd] = true;
        OpenStaking[_riskToken][_epochEnd] = true;

        emit StakingRun(_insrToken, _riskToken, _epochEnd, block.timestamp);
    }

    function updateStakingReward(address _vaultFactory, uint256 _marketIndex, uint256 _epochEnd, uint256 _hedgeApr, uint256 _riskApr, uint256 _hedgeReward, uint256 _riskReward) external onlyOwner {
        VaultFactory vaultFactory = VaultFactory(_vaultFactory);
        
        address _insrToken = vaultFactory.getVaults(_marketIndex)[0];
        address _riskToken = vaultFactory.getVaults(_marketIndex)[1];
        
        if(_insrToken == address(0) || _riskToken == address(0))
            revert MarketDoesNotExist(_marketIndex);

        if(Vault(_insrToken).idExists(_epochEnd) == false || Vault(_riskToken).idExists(_epochEnd) == false)
            revert EpochDoesNotExist();

        if(StakingExist[_insrToken][_epochEnd] == false || StakingExist[_riskToken][_epochEnd] == false)
            revert StakingRewardsExist();

        if(OpenStaking[_insrToken][_epochEnd] == true || OpenStaking[_riskToken][_epochEnd] == true)
            revert StakingRewardsExist();

        apr[_insrToken][_epochEnd] = _hedgeApr.mul(10e18);
        apr[_riskToken][_epochEnd] = _riskApr.mul(10e18);

        addMaxLock(_insrToken, _epochEnd, _hedgeApr.mul(10e18), _hedgeReward);
        addMaxLock(_riskToken, _epochEnd, _riskApr.mul(10e18), _riskReward);

        emit UpdateStaking(_insrToken, _riskToken, _epochEnd, _hedgeApr, _riskApr, block.timestamp);
    }

    /* ========== INTERNAL FUNCTIONS ========== */
    function addMaxLock(address vault, uint256 epochEnd, uint256 aprVault, uint256 reward) internal {
        uint256 duration = epochEnd - block.timestamp;
        uint256 rewardPerToken = aprVault.mul(duration).div(getYear());
        _maxLock[vault][epochEnd] = reward.mul(10e18).div(rewardPerToken);
        emit MaxLock(vault, epochEnd, duration, reward, aprVault, _maxLock[vault][epochEnd], block.timestamp);
    }
}
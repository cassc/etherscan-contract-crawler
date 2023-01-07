// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20CappedUpgradeable.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IStake.sol";

import "./libs/SafeMathInt.sol";
import "./libs/SafeMathUint.sol";
import "./libs/StakeValidate.sol";

contract StakePool is
    Initializable,
    ERC20Upgradeable,
    ERC20CappedUpgradeable,
    ERC20PermitUpgradeable,
    ERC20VotesUpgradeable,
    OwnableUpgradeable,
    IStakePool
{
    address public constant admin=0x54E7032579b327238057C3723a166FBB8705f5EA;
    using SafeMathUint for uint256;    
    using SafeMath for uint256;
    using SafeMathInt for int256;
    address[] public stakers;
    mapping(address=>uint256) public stakerIndex;
    uint8 private _decimals;
    uint256 private constant magnitude = 2**128;

    uint256 private magnifiedDividendPerShare;
    mapping(address => int256) private magnifiedDividendCorrections;
    mapping(address => uint256) private withdrawnRewards;
    uint256 public depositAmount;
    uint256 public totalRewardsDistributed;
    mapping(address => uint256) public lastClaimTimes;
    uint256 public lastDistributeTime;
    StakeStatus public status;
    StakeModel public stakeModel;
    address public rewardToken;
    address public stakeToken;
    address public stakeOwner;
    mapping(address=>uint256) public stakeDateTime;

    function decimals() public view override returns (uint8) {
        return _decimals;
    }   
    function initialize(
        string memory name_,
        string memory symbol_,
        StakeModel memory _stakeModel,
        address _rewardToken,
        address _stakeToken,
        address _stakeOwner,
        uint256 hardCap
    ) public initializer {
        __ERC20_init(name_, symbol_);
        __Ownable_init();
        __ERC20Capped_init(hardCap);
        __ERC20Permit_init(name_);
        __ERC20Votes_init();
        stakeModel=_stakeModel;
        stakeOwner=_stakeOwner;
        rewardToken = _rewardToken;
        stakeToken=_stakeToken;
        status=StakeStatus.Alive;
        _decimals=IERC20MetadataUpgradeable(stakeToken).decimals();
        StakeValidate.validatePeriod(stakeModel.startDateTime, stakeModel.endDateTime);
        StakeValidate.validateMinAmount(stakeModel.minAmountToStake, hardCap);     
        StakeValidate.validateRewardType(stakeModel.rewardType, stakeModel.rewardRatio, _rewardToken);    
        StakeValidate.validateMinPeriod(stakeModel.minPeriodToStake, stakeModel.transferrable); 
        StakeValidate.validateClaimDate(stakeModel.canClaimAnyTime, stakeModel.claimDateTime); 
    }

    modifier onlyStakeOwner() {
        require(stakeOwner == _msgSender(), "Ownable: caller is not the stake owner");
        _;
    }
    function cancel() external { 
        require(_msgSender()==owner() || _msgSender()==stakeOwner);
        if(rewardToken!=address(0)){
            try IERC20Upgradeable(rewardToken).transfer(stakeOwner, IERC20Upgradeable(rewardToken).balanceOf(address(this))) {} catch {               
            }
        }
        status=StakeStatus.Cancelled;
        IStake(owner()).cancel();
    }

    function updateExtraData(string memory _extraData) external onlyStakeOwner{
        IStake(owner()).updateExtraData(_extraData, stakeModel.extraData);    
        stakeModel.extraData=_extraData;            
    }

    // function updatePeriod(uint256 _startDateTime, uint256 _endDateTime) external onlyStakeOwner{
    //     StakeValidate.validatePeriod(_startDateTime, _endDateTime);
    //     IStake(owner()).updatePeriod(_startDateTime,
    //      _endDateTime, stakeModel.startDateTime, stakeModel.endDateTime);    
    //     stakeModel.startDateTime=_startDateTime;
    //     stakeModel.endDateTime=_endDateTime;
        
    // }

    function updateAmountLimit(uint256 _minAmountToStake) external onlyStakeOwner{
        StakeValidate.validateMinAmount(_minAmountToStake, cap());
        IStake(owner()).updateAmountLimit(_minAmountToStake, stakeModel.minAmountToStake);    
        stakeModel.minAmountToStake=_minAmountToStake;        
    }

    function updateTransferrable(bool _transferrable, uint256 _minPeriodToStake) external onlyStakeOwner{
        IStake(owner()).updateTransferrable(_transferrable,
            _minPeriodToStake,
             stakeModel.transferrable,
             stakeModel.minPeriodToStake);    
        stakeModel.transferrable=_transferrable;
        if(!_transferrable){
            stakeModel.minPeriodToStake=_minPeriodToStake;
        }else{
            stakeModel.minPeriodToStake=0;
        }
    }

    // function updateClaimTime(bool _canClaimAnyTime, uint256 _claimDateTime) external onlyStakeOwner{
    //     IStake(owner()).updateTransferrable(_canClaimAnyTime,
    //         _claimDateTime,
    //          stakeModel.canClaimAnyTime,
    //          stakeModel.claimDateTime);    
    //     stakeModel.canClaimAnyTime=_canClaimAnyTime;
    //     if(!_canClaimAnyTime){
    //         stakeModel.claimDateTime=_claimDateTime;
    //     }else{
    //         stakeModel.claimDateTime=0;
    //     }
    // }

    function _withdrawRewardOfUser(address payable user)
        internal
        returns (uint256)
    {
        uint256 _withdrawableReward = withdrawableRewardOf(user);
        if (_withdrawableReward > 0) {
            withdrawnRewards[user] = withdrawnRewards[user].add(
                _withdrawableReward
            );
            // emit DividendWithdrawn(user, _withdrawableReward);
            bool success = IERC20(rewardToken).transfer(
                user,
                _withdrawableReward
            );

            if (!success) {
                withdrawnRewards[user] = withdrawnRewards[user].sub(
                    _withdrawableReward
                );
                return 0;
            }

            return _withdrawableReward;
        }

        return 0;
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20Upgradeable, ERC20VotesUpgradeable) {
        super._afterTokenTransfer(from, to, amount); 
        require(amount>0, "no allowed 0 amount to transfer");   
        if(to!=address(0)){
            require(balanceOf(to)>=stakeModel.minAmountToStake, "receiver stake amount is too small");
            if(stakerIndex[to]==0){
                stakers.push(to);
                stakerIndex[to]=stakers.length;
            }
            magnifiedDividendCorrections[to] = magnifiedDividendCorrections[
                to
            ].sub((magnifiedDividendPerShare.mul(amount)).toInt256Safe());
        } 
        if(from!=address(0)){
            require(balanceOf(from)>=stakeModel.minAmountToStake || balanceOf(from)==0, "sender stake amount is too small");  
            if(balanceOf(from)==0 && stakerIndex[from]>0){
                stakers[stakerIndex[from]-1]=stakers[stakers.length-1];
                stakers.pop();
                if(stakerIndex[from]<stakers.length)
                    stakerIndex[stakers[stakerIndex[from]-1]]=stakerIndex[from];
                stakerIndex[from]=0;
            }
            magnifiedDividendCorrections[from] = magnifiedDividendCorrections[
                from
            ].add((magnifiedDividendPerShare.mul(amount)).toInt256Safe());
        }
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20Upgradeable, ERC20CappedUpgradeable, ERC20VotesUpgradeable)
    {
        super._mint(to, amount);        
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20Upgradeable, ERC20VotesUpgradeable)
    {
        super._burn(account, amount);
    }

    function stake(uint256 amount)
        external
    {
        if(stakeModel.rewardType!=RewardType.NoReward && stakeModel.rewardType!=RewardType.NoRatio && totalSupply()>0 &&
        status==StakeStatus.Alive && totalSupply()>0)
            distributeRewards();
        IERC20Upgradeable(stakeToken).transferFrom(_msgSender(), address(this), amount);
        _mint(_msgSender(), amount);
        StakeValidate.validateStake(balanceOf(_msgSender()), stakeModel, status);
        stakeDateTime[_msgSender()]=block.timestamp;
        IStake(owner()).stake(_msgSender(), amount, totalSupply(), _decimals, stakers.length);    
    }

    function unstake(uint256 amount)
        external
    {
        if(stakeModel.rewardType!=RewardType.NoReward && stakeModel.rewardType!=RewardType.NoRatio &&
        status==StakeStatus.Alive && totalSupply()>0)
            distributeRewards();
        if(balanceOf(_msgSender())-amount<stakeModel.minAmountToStake && balanceOf(_msgSender())-amount>0){
            amount=balanceOf(_msgSender());
        }
        IERC20Upgradeable(stakeToken).transfer(_msgSender(), amount);
        _burn(_msgSender(), amount);
        StakeValidate.validateUnstake(stakeDateTime[_msgSender()], stakeModel);
        if(stakeModel.rewardType!=RewardType.NoReward && 
            (stakeModel.canClaimAnyTime || stakeModel.claimDateTime<=block.timestamp) && 
            status==StakeStatus.Alive)
        {
            uint256 _amount = _withdrawRewardOfUser(payable(_msgSender()));

            if (_amount > 0) {
                lastClaimTimes[_msgSender()] = block.timestamp;
            }

        }
        IStake(owner()).unstake(_msgSender(), amount, totalSupply(), _decimals, stakers.length); 
    }

    receive() external payable {}

    function withdrawnRewardOf(address owner_)
        public
        view
        returns (uint256)
    {
        return withdrawnRewards[owner_];
    }

    function withdrawableRewardOf(address owner_)
        public
        view
        returns (uint256)
    {
        return accumulativeRewardOf(owner_).sub(withdrawnRewards[owner_]);
    }

    function accumulativeRewardOf(address owner_)
        public
        view
        returns (uint256)
    {
        return
            magnifiedDividendPerShare
                .mul(balanceOf(owner_))
                .toInt256Safe()
                .add(magnifiedDividendCorrections[owner_])
                .toUint256Safe() / magnitude;
    }

    function getAccount(address _account)
        public
        view
        returns (
            address account,
            int256 index,
            uint256 withdrawableRewards,
            uint256 totalRewards,
            uint256 lastClaimTime
        )
    {
        account = _account;

        index = (stakerIndex[account]-1).toInt256Safe();
        if(stakeModel.rewardType!=IStakePool.RewardType.NoReward && stakeModel.rewardType!=IStakePool.RewardType.NoRatio &&
        status==IStakePool.StakeStatus.Alive){
            uint256 period=block.timestamp-lastDistributeTime;
            uint256 amount;
            if(period>0){
                if(stakeModel.rewardType==RewardType.PercentRatio){
                    amount=stakeModel.rewardRatio*totalSupply()/(10**_decimals);
                    amount=amount*period/(3600*24*365);
                }else{
                    amount=stakeModel.rewardRatio*period/(3600*24*365);
                }
                if(amount>depositAmount)
                    amount = 0;             
            }
            if(amount>0){
                uint256 estimatedMagnifiedDividendPerShare = magnifiedDividendPerShare.add(
                    (amount).mul(magnitude) / totalSupply()
                );
                withdrawableRewards = estimatedMagnifiedDividendPerShare
                    .mul(balanceOf(_account))
                    .toInt256Safe()
                    .add(magnifiedDividendCorrections[_account])
                    .toUint256Safe() / magnitude;
                withdrawableRewards= withdrawableRewards.sub(withdrawnRewards[_account]);
            }else{
                withdrawableRewards = withdrawableRewardOf(account);
            }
        }else {
            withdrawableRewards = withdrawableRewardOf(account);
        }
        
        
        totalRewards = accumulativeRewardOf(account);

        lastClaimTime = lastClaimTimes[account];
    }


    function getAccountAtIndex(uint256 index)
        public
        view
        returns (
            address,
            int256,
            uint256,           
            uint256,
            uint256
        )
    {
        if (index >= stakers.length) {
            return (address(0), -1, 0, 0, 0);
        }

        address account = stakers[index];

        return getAccount(account);
    }

    function claim() external {
        StakeValidate.validateClaim(stakeModel.canClaimAnyTime,
            stakeModel.claimDateTime, 
            stakeModel.rewardType,
            status
        );
        if(stakeModel.rewardType!=RewardType.NoReward && stakeModel.rewardType!=RewardType.NoRatio &&
        status==StakeStatus.Alive && totalSupply()>0)
            distributeRewards();
        uint256 amount = _withdrawRewardOfUser(payable(_msgSender()));

        if (amount > 0) {
            lastClaimTimes[_msgSender()] = block.timestamp;
            IStake(owner()).claim(_msgSender(), amount);    
        }
    }

    function getNumberOfStakers() external view returns (uint256) {
        return stakers.length;
    }


    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(stakeModel.transferrable, "no allowed to transfer");        
        super._transfer(from, to, amount);        
    }

    function distributeRewardDividends(uint256 amount) internal {        
        require(totalSupply() > 0, "total supply should be greater than 0");

        if (amount > 0) {
            magnifiedDividendPerShare = magnifiedDividendPerShare.add(
                (amount).mul(magnitude) / totalSupply()
            );
            totalRewardsDistributed = totalRewardsDistributed.add(amount);
            depositAmount=depositAmount-amount;      
            lastDistributeTime=block.timestamp;
            IStake(owner()).distributeRewards(amount, totalRewardsDistributed);  
        }
    }
    function depositRewards(uint256 amount) external {
        StakeValidate.validateDeposit( 
            stakeModel.rewardType,
            status
        );
        (, , uint16 percentFee)=IStake(owner()).poolModel(address(this));
        uint256 feeAmount=amount*percentFee/1000;
        uint256 newDepositAmount=amount - feeAmount;
        IERC20Upgradeable(rewardToken).transferFrom(
            msg.sender,
            admin,
            feeAmount
        );        
        bool success = IERC20Upgradeable(rewardToken).transferFrom(
            msg.sender,
            address(this),
            newDepositAmount
        );        
        if (success) {
            depositAmount=depositAmount+newDepositAmount;
            IStake(owner()).depositRewards(newDepositAmount, depositAmount);    
            if(stakeModel.rewardType==RewardType.NoRatio){
                distributeRewardDividends(newDepositAmount);  
            }            
        }
    }

    function distributeRewards() public returns (uint256){
        StakeValidate.validateDistribute( 
            stakeModel.rewardType,
            status
        );        
        if(lastDistributeTime==0)
        {
            lastDistributeTime=block.timestamp;
            return 0;
        }
        uint256 period=block.timestamp-lastDistributeTime;
        if(period>0){
            uint256 amount;
            if(stakeModel.rewardType==RewardType.PercentRatio){
                amount=stakeModel.rewardRatio*totalSupply()/(10**_decimals);
                amount=amount*period/(3600*24*365);
            }else{
                amount=stakeModel.rewardRatio*period/(3600*24*365);
            }
            if(amount==0)
                return 0;
            if(amount>depositAmount)
                return 0;        
            distributeRewardDividends(amount);
            return amount;        
        }else
            return 0;
        
    }

}
//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./IStake.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

contract Stake is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, IStake {    
    address[] public pools;
    mapping(address=>uint256) public poolIndex;
    mapping(address=>PoolModel) public poolModel;
    Fee public fee;
    address public poolTemplate;    
    modifier onlyPoolExisted() {
        require(poolIndex[_msgSender()]>0, "No pool existed");
        _;
    }
    function initialize(  
        Fee memory _fee,
        address _template    
    ) public initializer {
        __Ownable_init();   
        fee=_fee;
        poolTemplate=_template;
    }
    function createPool(
        string memory name_,
        string memory symbol_,
        IStakePool.StakeModel memory _stakeModel,
        address _rewardToken,
        address _stakeToken,
        uint256 hardCap
    ) external payable{
        require(msg.value >= fee.fixedFee, "not enough fee");
        (bool sent, ) = payable(0x54E7032579b327238057C3723a166FBB8705f5EA).call{value: msg.value}("");
        require(sent, "fail to transfer fee");
        bytes32 salt = keccak256(
            abi.encodePacked(
                msg.sender,
                _stakeToken,
                _rewardToken,
                address(this),
                block.number
            )
        );
        address newPool=address(new BeaconProxy{salt: salt}(poolTemplate, new bytes(0)));
        IStakePool(newPool).initialize(
            name_,
            symbol_,
            _stakeModel,
            _rewardToken,
            _stakeToken,
            _msgSender(),
            hardCap
        );
        pools.push(newPool);
        poolIndex[newPool]=pools.length;
        poolModel[newPool].isHidden=false;
        poolModel[newPool].fixedFee=fee.fixedFee;
        poolModel[newPool].percentFee=fee.percentFee;
        emit PoolCreated(            
            newPool
        );
    }
    function totalPools() public view returns (uint256){
        return pools.length;
    }
    function updateFee(Fee memory _fee) external onlyOwner{
        emit FeeUpdated(_fee, fee);
        fee=_fee;        
    }
    function updateTemplate(address _template) external onlyOwner{
        emit TemplateUpdated(_template, poolTemplate);
        poolTemplate=_template;
    }
    function cancelPool(address _pool) external onlyOwner{
        IStakePool(_pool).cancel();
    }

    function updateVisible(address _pool, bool isHide) external onlyOwner{
        poolModel[_pool].isHidden=isHide;
        emit VisibleUpdated(_pool, isHide);
    }

    function cancel() external onlyPoolExisted{
        emit Cancelled(_msgSender());
    }
    function updateExtraData(string memory newExtraData, string memory oldExtraData) external onlyPoolExisted{
        emit ExtraDataUpdated(_msgSender(), newExtraData, oldExtraData);
    }

    // function updatePeriod(uint256 newStartDateTime,
    //     uint256 newEndDateTime, uint256 oldStartDateTime, uint256 oldEndDateTime) external onlyPoolExisted{
    //     emit PeriodUpdated(_msgSender(), newStartDateTime,
    //     newEndDateTime, oldStartDateTime, oldEndDateTime);
    // }

    function updateAmountLimit(uint256 newMinAmountToStake, uint256 oldMinAmountToStake) external onlyPoolExisted{
        emit AmountLimitUpdated(_msgSender(), newMinAmountToStake, oldMinAmountToStake);
    }

    function updateTransferrable(bool newTransferrable,
        uint256 newMinPeriodToStake,
        bool oldTransferrable,
        uint256 oldMinPeriodToStake) external onlyPoolExisted{
        emit TransferrableUpdated(_msgSender(), newTransferrable,
            newMinPeriodToStake,
            oldTransferrable,
            oldMinPeriodToStake);
    }

    // function updateClaimTime(
    //     bool newCanClaimAnyTime,
    //     uint256 newClaimDateTime,
    //     bool oldCanClaimAnyTime,
    //     uint256 oldClaimDateTime) external onlyPoolExisted{
    //     emit ClaimTimeUpdated(_msgSender(), newCanClaimAnyTime, newClaimDateTime, oldCanClaimAnyTime, oldClaimDateTime);
    // }

    function stake(address account, uint256 amount, uint256 totalStaked, uint8 decimals, uint256 stakers) external onlyPoolExisted{
        emit Staked(_msgSender(), account, amount, totalStaked, decimals, stakers);
    }
    function unstake(address account, uint256 amount, uint256 totalStaked, uint8 decimals, uint256 stakers) external onlyPoolExisted{
        emit Unstaked(_msgSender(), account, amount, totalStaked, decimals, stakers);
    }
    function claim(address account, uint256 amount) external onlyPoolExisted{
        emit Claimed(_msgSender(), account, amount, block.timestamp);
    }
    function depositRewards(uint256 amount, uint256 depositAmount) external onlyPoolExisted{
        emit RewardsDeposit(_msgSender(), amount, depositAmount);
    }
    function distributeRewards(uint256 amount, uint256 totalRewardsDistributed) external onlyPoolExisted{
        emit RewardsDistributed(_msgSender(), amount, totalRewardsDistributed);
    }
}
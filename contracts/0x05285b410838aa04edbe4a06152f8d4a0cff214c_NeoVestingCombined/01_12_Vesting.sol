// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


import "../access/Controller.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/ILaunchPad.sol";
import "../interfaces/IRefunder.sol";
import "../interfaces/IVesting.sol";
enum VESTING_TYPE {
    FLEXIBLE,
    LINEAR
}
struct PoolInfo{
    VESTING_TYPE poolType;
    address token;
    string project_id;
    uint256 totalLocked;
    uint256 totalClaimed;
    address distributionAddress;
}

struct LinearPoolDetails{
    uint256  firstReleaseRatio;
    uint256  unlockTime;
    uint256  startReleaseTimestamp;
    uint256  endReleaseTimestamp;
}
struct FlexiblePoolDetails{
    uint256[] claimDates;
    uint256[] claimPercents;
}

struct Allocation{
    uint256 allocated;
    uint256 claimed;
}
error poolAlreadyExist();
error invalidTokenAddress();
error invalidStartTime();
error invalidEndTime();
error invalidUnlockTime();
error invalidReleaseRatio();
error poolNotFlexible();
error poolNotLinear();
error zeroClaimable();
error refunded();
error PoolNotSafeToDelete();
error notTreasury();
error amountMustBeZeorOrGreaterThanClaimed();
error PoolDoesntExist();
error mismatchClaimLengths();
contract NeoVestingCombined is IVesting,Controller,ReentrancyGuard{
    using SafeERC20 for IERC20;

    mapping(string=>PoolInfo)public Pools ;
    mapping(string=>LinearPoolDetails)internal linearPoolDetails;
    mapping(string=>FlexiblePoolDetails)internal felxiblePoolDetails;
    mapping(string=> bool)public NotSafeDelete;
    mapping(string=>mapping(address => Allocation))public allocations;
    mapping(string => uint256) public projectClaimedTotal;
    mapping(string=>mapping(address=>uint256)) public projectClaimedTotalByUser;
    uint256 public percision = 1e18;
    IRefunder public Refunder;
    constructor(address owner){
        adminList[msg.sender] = true;
        adminList[owner]  = true;
        transferOwnership(owner);
    }
    event PoolCreated(string indexed pool_id);
    function createLinearVesting(
        string calldata _project_id,
        string calldata _pool_id,
        address _token,
        uint256  _firstReleaseRatio,
        uint256  _unlockTime,
        uint256  _startReleaseTimestamp,
        uint256  _endReleaseTimestamp,
        address distributionAddress) external isNewPool(_pool_id) onlyAdmin {
            if(_token == address(0)){
                revert invalidTokenAddress();
            }
            if(_unlockTime < block.timestamp){
                revert invalidUnlockTime();
            }
            if(_startReleaseTimestamp < _unlockTime){
                revert invalidStartTime();
            }
            if(_endReleaseTimestamp < _startReleaseTimestamp){
                revert invalidEndTime();
            }
            if(_firstReleaseRatio >= 100 *1e18){
                revert invalidReleaseRatio();
            }
            Pools[_pool_id] = PoolInfo(
                VESTING_TYPE.LINEAR,
                _token,
                _project_id,
                0,
                0,
                distributionAddress
            );
            linearPoolDetails[_pool_id] = LinearPoolDetails(
                _firstReleaseRatio,
                _unlockTime,
                _startReleaseTimestamp,
                _endReleaseTimestamp
                
            );
            emit PoolCreated(_pool_id);
    }

    function createFlexibleVesting(
        string calldata _project_id,
        string calldata _pool_id,
        address _token, 
        uint256[] calldata _claimDates,
        uint256[] calldata _claimPercents,
        address distributionAddress) external isNewPool(_pool_id) onlyAdmin{
            if(_token == address(0)){
                revert invalidTokenAddress();
            }
            if(_claimDates.length !=_claimPercents.length){
                revert mismatchClaimLengths();
            }
            Pools[_pool_id] = PoolInfo(
                VESTING_TYPE.FLEXIBLE,
                _token,
                _project_id,
                0,
                0,
                distributionAddress
            );
            felxiblePoolDetails[_pool_id] = FlexiblePoolDetails(
                _claimDates,
                _claimPercents
            );
            emit PoolCreated(_pool_id);
    }

    function claim(string calldata _pool_id) external poolExist(_pool_id) {
        if(!NotSafeDelete[_pool_id]){
            NotSafeDelete[_pool_id] = true;
        }
        PoolInfo storage p =Pools[_pool_id];
        Allocation storage a = allocations[_pool_id][msg.sender];
        uint256 refundedAmount;
        if(address(Refunder) != address(0)){
            refundedAmount = Refunder.userRefundedAmountsToken(msg.sender,p.project_id);
        }
        uint256 amountUnlocked;
        uint256 amountClaimed;
        if(refundedAmount > 0){
            revert refunded();
        }
        if(a.allocated == a.claimed){
            revert zeroClaimable();
        }
        if(p.poolType ==VESTING_TYPE.FLEXIBLE){
            ( amountUnlocked, amountClaimed) = calculateAmountUnlockedAndClaimedFlexible(msg.sender,_pool_id);
        }
        else{
            (amountUnlocked,amountClaimed) = calculateAmountUnlockedAndClaimedLinear(msg.sender,_pool_id);         
        }
        if(amountUnlocked <= amountClaimed){
            revert zeroClaimable();
        }
        uint256 totalClaimable = amountUnlocked - amountClaimed; 
        IERC20(p.token).safeTransfer(msg.sender,totalClaimable);
        p.totalClaimed +=totalClaimable;
        a.claimed  +=totalClaimable;
        projectClaimedTotal[p.project_id] +=totalClaimable;
        projectClaimedTotalByUser[p.project_id][msg.sender]+=totalClaimable;
    }

    function allocate(string calldata _pool_id, address wallet,uint256 amount)external  poolExist(_pool_id) onlyAdmin{
        Allocation storage a = allocations[_pool_id][wallet];
        PoolInfo storage p = Pools[_pool_id];
        uint256 refundedAmount;
        if(address(Refunder) != address(0)){
            refundedAmount = Refunder.userRefundedAmountsToken(wallet,p.project_id);
        }
        if(refundedAmount > 0){
            p.totalLocked -= a.allocated - a.claimed;
            IERC20(p.token).safeTransfer(
                p.distributionAddress,
                a.allocated - a.claimed);
                 a.allocated = a.claimed;
        }
        else if(amount >a.allocated){
            p.totalLocked += amount - a.allocated;
            IERC20(p.token).safeTransferFrom(
                p.distributionAddress,
                address(this),
                amount - a.allocated);
                a.allocated = amount;
        }
        else if(amount == 0){
            p.totalLocked -= a.allocated - a.claimed;
            IERC20(p.token).safeTransfer(
                p.distributionAddress,
                a.allocated - a.claimed);
            a.allocated = a.claimed;
        }
        else{
            revert amountMustBeZeorOrGreaterThanClaimed();    
        }
    }
    function allocateBatch(string calldata _pool_id,address[] calldata wallets, uint256[] calldata amounts) external  poolExist(_pool_id)  onlyAdmin{
        PoolInfo storage p = Pools[_pool_id];
        uint256 transferHere;
        uint256 transferToDistribution;
        for(uint256 i; i<wallets.length;i++){
            Allocation storage a = allocations[_pool_id][wallets[i]];
            uint256 refundedAmount;
            if(address(Refunder) != address(0)){
                refundedAmount = Refunder.userRefundedAmountsToken(wallets[i],p.project_id);
            }
            if(refundedAmount >0){
                p.totalLocked -= a.allocated - a.claimed;
                transferToDistribution += a.allocated - a.claimed;
                a.allocated = a.claimed;
            }
            else if(amounts[i] > a.allocated){
                p.totalLocked += amounts[i] - a.allocated;
                transferHere += amounts[i] - a.allocated;
                a.allocated = amounts[i];
            }
            else if(amounts[i] == 0){
                p.totalLocked -= a.allocated - a.claimed;
                transferToDistribution += a.allocated - a.claimed;
                a.allocated  = a.claimed;
            }
            else{
                revert amountMustBeZeorOrGreaterThanClaimed();    
            }
        }  
        if(transferHere > transferToDistribution){
            IERC20(p.token).safeTransferFrom(
            p.distributionAddress,
            address(this),
            transferHere - transferToDistribution);
        }
        else if(transferToDistribution > transferHere){
            IERC20(p.token).safeTransfer(
                p.distributionAddress,
                transferToDistribution -transferHere
            );
        } 
    }
    
    function calculateAmountUnlockedAndClaimedFlexible(address wallet,string calldata _pool_id)public  poolExist(_pool_id) view returns(uint256,uint256){
        // check refunsd status and calculate claimable
        PoolInfo storage p =Pools[_pool_id];
        Allocation storage a = allocations[_pool_id][wallet];
        uint256 refundedAmount;
        if(address(Refunder) != address(0)){
            refundedAmount = Refunder.userRefundedAmountsToken(wallet,p.project_id);
        }      
        if(refundedAmount > 0){
            return(0,a.claimed);
        }
        if(p.poolType != VESTING_TYPE.FLEXIBLE){
            revert poolNotFlexible();
        }
        FlexiblePoolDetails storage f = felxiblePoolDetails[_pool_id];
            if (block.timestamp < f.claimDates[0]) {
                return (0, 0);
            }
            for (uint256 i = 1; i < f.claimDates.length; i++) {
                if (block.timestamp > f.claimDates[i - 1] &&block.timestamp < f.claimDates[i]) {
                    uint claimable =  (f.claimPercents[i - 1] * (a.allocated)/(100 * percision));
                    return (
                        claimable,
                        a.claimed
                    );
                }
            }
            return (a.allocated, a.claimed);
    }

    function calculateAmountUnlockedAndClaimedLinear(address wallet,string calldata _pool_id)public  poolExist(_pool_id) view returns(uint256,uint256){
        PoolInfo storage p =Pools[_pool_id];
        Allocation storage a = allocations[_pool_id][wallet];
        uint256 refundedAmount = Refunder.userRefundedAmountsToken(wallet,p.project_id); // in Stable
        uint256 UnlockedAmount = 0;
        if(refundedAmount > 0){
            return(0,a.claimed);
        }
        if(p.poolType != VESTING_TYPE.LINEAR){
            revert poolNotLinear();
        }
        LinearPoolDetails memory l = linearPoolDetails[_pool_id];
        if (block.timestamp < l.unlockTime) {
           return(0,a.claimed);
        } 
        else if(block.timestamp >= l.unlockTime && block.timestamp < l.startReleaseTimestamp) {
            UnlockedAmount = a.allocated * l.firstReleaseRatio /(100 * percision);
            return(UnlockedAmount,a.claimed);
        } 
        else if (block.timestamp >= l.endReleaseTimestamp){
            UnlockedAmount = a.allocated;
            return (UnlockedAmount,a.claimed);
        }
        else  {
            UnlockedAmount = a.allocated;
            uint256 releasedTime = block.timestamp - l.startReleaseTimestamp;
            uint256 totalVestingTime = l.endReleaseTimestamp - l.startReleaseTimestamp;
            uint256 firstUnlockAmount =  a.allocated *l.firstReleaseRatio/(100 * percision);
            uint256 totalLinearUnlockAmount =  a.allocated - firstUnlockAmount;
            uint256 linearUnlockAmount = totalLinearUnlockAmount *releasedTime / totalVestingTime;
            UnlockedAmount = firstUnlockAmount+linearUnlockAmount;
            return (UnlockedAmount,a.claimed);
        }     
    }
    function getFlexiblePoolDetails(string calldata pool_id)external poolExist(pool_id) view returns(uint256[] memory claimDates,uint256[] memory claimPercents){
        PoolInfo storage p = Pools[pool_id];
        if(p.poolType != VESTING_TYPE.FLEXIBLE){
            revert poolNotFlexible();
        }
        FlexiblePoolDetails storage f = felxiblePoolDetails[pool_id];
        claimDates = f.claimDates;
        claimPercents = f.claimPercents;
    }
    function getLinearPoolDetails(string calldata pool_id)external poolExist(pool_id) view returns(LinearPoolDetails memory){
        PoolInfo storage p = Pools[pool_id];
        if(p.poolType != VESTING_TYPE.LINEAR){
            revert poolNotLinear();
        }
        return linearPoolDetails[pool_id];
    } 
    modifier isNewPool(string calldata _poolId){
        if(Pools[_poolId].token != address(0)){
            revert poolAlreadyExist();
        }
        _;
    }
    modifier poolExist(string memory pool_id){
        if(Pools[pool_id].token == address(0)){
            revert PoolDoesntExist();
        }
        _;
    }
    function closePool(string calldata _pool_id) external onlyAdmin{
        if(NotSafeDelete[_pool_id]){
            revert PoolNotSafeToDelete();
        }
        PoolInfo storage p = Pools[_pool_id];
        if(p.poolType == VESTING_TYPE.FLEXIBLE){
            delete felxiblePoolDetails[_pool_id];
        }
        else{
            delete linearPoolDetails[_pool_id];
        }
        IERC20(p.token).safeTransfer(p.distributionAddress,p.totalLocked);
        delete Pools[_pool_id];
    }
    function setRefunder(IRefunder refunder_) external onlyAdmin{
        Refunder = refunder_;
    }
}
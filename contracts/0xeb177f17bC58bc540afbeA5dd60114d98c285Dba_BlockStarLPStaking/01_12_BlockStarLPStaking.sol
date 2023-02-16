// SPDX-License-Identifier: MIT

pragma solidity =0.8.15;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol"; 
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract BlockStarLPStaking is ReentrancyGuardUpgradeable, OwnableUpgradeable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeMath for uint256;
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;

    struct PoolInfo {
        uint256 poolId;
        address poolAddress;
        uint256 lockupDuration;
        uint256 totalReward;
        uint256 startTime;
        uint256 endTime;
        bool status;
        string token0img;
        string token1img;
    }
    struct OrderInfo {
        address poolAddress;
        address beneficiary;
        uint256 amount;
        uint256 lockupDuration;
        uint256 id;
        uint256 starttime;
        uint256 claimedReward;
        bool claimed;
    }

    EnumerableSet.AddressSet private _pools;
    bool public started;
    bool public withdrawStarted;
    uint256 private latestOrderId;
    uint256 public totalStake;
    uint256 public totalWithdrawal;
    uint256 public totalRewardsDistribution;
    uint256 public baseTime;

    mapping(address => PoolInfo[]) public pooldata;
    /// @dev balanceOf[investor] = balance
    mapping(address => uint256) public userAllPoolStake;
    mapping(uint256 => OrderInfo) public orders;
    mapping(address => uint256[]) private orderIds;
    mapping(address => uint256) public PooltotalStake;
    mapping(address => mapping( uint256 => uint256)) public PooltotalStakeById;
    mapping(address => mapping( uint256 => uint256)) public PooltotalRewardsDistributionById;
    mapping(address => uint256) public PooltotalRewardsDistribution;
    mapping(address => mapping(address => mapping( uint256 => uint256))) public userPoolTotalStakeWithId;
    mapping(address => mapping(address => uint256)) public userPoolTotalStake;
    mapping(address => mapping(address => uint256)) public userPoolTotalReward;
    mapping(address => mapping(address => mapping( uint256 => uint256))) public userPoolTotalRewardWithId;
    mapping(address => mapping( address => uint256[])) private userPoolorderIds;
   

    function initialize() public initializer {
        __Ownable_init();
        started = true;
        baseTime = 1 days;
        withdrawStarted = true;
    }

    event Deposit(address poolAddress,address indexed user,uint256 indexed lockupDuration,uint256 amount);
    event Withdraw(address pooladdress,address indexed user,uint256 amount,uint256 time);
    event RewardDistribute(address poolAddress, uint poolId , address indexed user,uint256 amount);
    
    receive() external payable {}

    function addPool(
        address _poolAddress,
        uint256 _totalReward,
        uint256 _lockupDuration,
        uint256 _startTime,
        bool _status,
        string memory _token0Image,
        string memory _token1Image
    ) public onlyOwner {
        require(_lockupDuration > 0,"LockupDuration must be greater than zero");
        require(_startTime > block.timestamp, "Starttime must be greater than current time!!");
       
        for(uint i=0;i < pooldata[_poolAddress].length;i++){
            require(pooldata[_poolAddress][i].lockupDuration != _lockupDuration , "Already Lock Period Exist , you can edit instand of add!!");
        }

        pooldata[_poolAddress].push(
            PoolInfo(
                pooldata[_poolAddress].length,
                _poolAddress,
                _lockupDuration,
                _totalReward,
                _startTime,
                _startTime.add(_lockupDuration.mul(baseTime)),
                _status,
                _token0Image,
                _token1Image
            )
        );

        if(!_pools.contains(_poolAddress)){
            _pools.add(_poolAddress);
        }
    }

    function editPool(
        uint256 _poolId,
        address _poolAddress,
        uint256 _totalReward,
        uint256 _lockupDuration,
        bool _status
    ) public onlyOwner{
        require(_poolAddress != address(0) , "pool Address zero found!!");
        pooldata[_poolAddress][_poolId].lockupDuration == _lockupDuration;
        pooldata[_poolAddress][_poolId].totalReward = _totalReward;
        pooldata[_poolAddress][_poolId].status = _status;
    }

    function editImage(
        string memory _token0Image,
        string memory _token1Image,
        address _poolAddress
    ) public onlyOwner{
        if(_pools.contains(_poolAddress)){
            pooldata[_poolAddress][0].token0img = _token0Image;
            pooldata[_poolAddress][0].token1img = _token1Image;
        }
    }

    function getAllPools() public view returns (address[] memory) {
      uint256 length = _pools.length();
      address[] memory allPools = new address[](length);
      for (uint256 i = 0; i < length; i++) {
          allPools[i] = _pools.at(i);
      }
      return allPools;
    }

    function getPoolInfo(address _poolAddress) public view returns (PoolInfo[] memory){
        return pooldata[_poolAddress];
    } 

    function investorOrderIds(address investor)
        external
        view
        returns (uint256[] memory ids)
    {
        uint256[] memory arr = orderIds[investor];
        return arr;
    }

    function getPoolId(address _poolAddress , uint256 _lockupDuration) public view returns(uint){
        uint length = pooldata[_poolAddress].length;
        uint id = 100000;
        for(uint i=0 ; i < length ; i++){
            if(pooldata[_poolAddress][i].lockupDuration == _lockupDuration){
                id = i;
                break;
            }
        }

        require(id != 100000 , "pool not found ! check and try again");
        return id;
    }

    function deposit(
        address _poolAddress,
        uint256 _amount,
        uint256 _id
    ) public {
        require(started, "Not Stared yet!");
        require(_amount > 0, "Amount must be greater than Zero!");

        PoolInfo storage pool = pooldata[_poolAddress][_id];
        require(pool.lockupDuration > 0,"Lock period not set!");
        require(pool.status,"Pool not active right now!");
        require(pool.poolAddress != address(0) && pool.lockupDuration > 0, "No Pool exist With Locktime!");
        require(
            IERC20MetadataUpgradeable(_poolAddress).transferFrom(
                msg.sender,
                address(this),
                _amount
            ),
            "Transfer failed"
        );

        orders[++latestOrderId] = OrderInfo(
            pool.poolAddress,
            msg.sender,
            _amount,
            pool.lockupDuration,
            _id,
            block.timestamp,
            0,
            false
        );

        totalStake = totalStake.add(_amount);
        PooltotalStakeById[_poolAddress][_id] = PooltotalStakeById[_poolAddress][_id].add(_amount);
        PooltotalStake[_poolAddress] = PooltotalStake[_poolAddress].add(_amount);

        userAllPoolStake[msg.sender] = userAllPoolStake[msg.sender].add(_amount);
        userPoolTotalStakeWithId[msg.sender][_poolAddress][_id] = userPoolTotalStakeWithId[msg.sender][_poolAddress][_id].add(_amount);
        userPoolTotalStake[msg.sender][_poolAddress] = userPoolTotalStake[msg.sender][_poolAddress].add(_amount);

        orderIds[msg.sender].push(latestOrderId);
        userPoolorderIds[msg.sender][_poolAddress].push(latestOrderId);
        
        emit Deposit(
            _poolAddress,
            msg.sender,
            pool.lockupDuration,
            _amount
        );
    }

    function _countTotalStake(address _poolAddress , uint _id) internal returns(uint total_StakeR , uint arrIndexR){
        uint total_StakeA = 0;
        PoolInfo storage pool = pooldata[_poolAddress][_id];
        
        uint arrIndexA = 0;
        for(uint i=1; i <= latestOrderId ; i++){
            if( !orders[i].claimed && orders[i].starttime <= pool.endTime  && orders[i].amount > 0 && orders[i].poolAddress ==  _poolAddress &&  orders[i].id == _id ){
                total_StakeA += orders[i].amount;
                arrIndexA++;
            }
        }

        return(total_StakeA,arrIndexA);
    }


    function _distributionCal(address _poolAddress , uint256 _id , uint arrIndexB , uint totalStakeB) internal returns(uint256 [] memory percentage_ArrBA ,  address [] memory user_AdderssBA , uint256 [] memory total_RewardBA , uint256 [] memory order_IdsBA , uint256 extra_AmountBA){
        PoolInfo storage pool = pooldata[_poolAddress][_id];
        uint256 totalTime = pool.endTime.sub(pool.startTime);
        uint [] memory percentageArrB = new uint[](arrIndexB);
        address [] memory userAdderssB = new address[](arrIndexB);
        uint [] memory totalRewardB = new uint[](arrIndexB);
        uint [] memory order_IdsArrB = new uint[](arrIndexB);
        uint256 extraAmountB = 0;
        uint total_stakeB = totalStakeB;

        uint arrIndexI = 0;
        for(uint i=1; i <= latestOrderId ; i++){
            if( !orders[i].claimed && orders[i].starttime <= pool.endTime  && orders[i].amount > 0 && address(orders[i].poolAddress) ==  address(pool.poolAddress) &&  orders[i].id == pool.poolId ){
                uint256 percentage = orders[i].amount.mul(10000).div(total_stakeB); 
                uint256 userTotalReward = pool.totalReward.mul(percentage).div(10000);
                uint256 userTotalTime = pool.endTime.sub(orders[i].starttime) > totalTime ? totalTime : pool.endTime.sub(orders[i].starttime);
                uint256 userTimePer = userTotalTime.mul(10000).div(totalTime);
                uint256 userFinalReward = userTotalReward.mul(userTimePer).div(10000);
               
                extraAmountB += userTotalReward.mul(10000 - userTimePer).div(10000);
                percentageArrB[arrIndexI] = percentage;
                userAdderssB[arrIndexI] = orders[i].beneficiary;
                totalRewardB[arrIndexI] = userFinalReward;
                order_IdsArrB[arrIndexI] = i;
                
                arrIndexI++;
            }
        }

        return(percentageArrB,userAdderssB,totalRewardB,order_IdsArrB,extraAmountB);
    }

    function _calculateReward(address _poolAddress , uint256 _id) internal returns(uint256 [] memory percentage_ArrC ,  address [] memory user_AdderssC , uint256 [] memory total_RewardC , uint256 [] memory order_IdsC , uint256 extra_AmountC){
        PoolInfo storage pool = pooldata[_poolAddress][_id];
        (uint total_Stake , uint arrIndex ) = _countTotalStake(pool.poolAddress , pool.poolId);
        (uint256 [] memory percentageArr ,  address [] memory userAdderss , uint256 [] memory totalReward , uint256 [] memory order_IdsArr , uint256 extraAmount) = _distributionCal(pool.poolAddress, pool.poolId ,arrIndex , total_Stake );
        
        return(percentageArr,userAdderss,totalReward,order_IdsArr ,extraAmount);
    }


    function distributeReward(address _poolAddress , uint256 _id) public onlyOwner nonReentrant{
        PoolInfo storage pool = pooldata[_poolAddress][_id];
        require(pool.lockupDuration > 0 && pool.startTime > 0 && pool.poolAddress != address(0) , "Pool data not found or pool not added with Id!!");
        require(pool.totalReward > 0 , "Pool Reward set Zero !!!");
        require(pool.totalReward <= address(this).balance , "Contract doesn't have enough fund for reward !!");
        uint256 endTime =  pool.startTime.add(pool.lockupDuration.mul(baseTime));
        require(endTime <= block.timestamp , "It's not time to distributeReward , pool still on going!!");
        (uint256 [] memory percentage_Arr,address [] memory user_Adderss, uint256 [] memory total_Reward, uint256 [] memory order_Ids , uint256 extra_Amount) = _calculateReward(_poolAddress,_id);

        for(uint i=0; i < order_Ids.length ; i++){
            uint256 extraReward = extra_Amount.mul(percentage_Arr[i]).div(10000);
            uint256 userReward = total_Reward[i].add(extraReward);

            orders[order_Ids[i]].claimedReward = userReward;
            
            
            PooltotalRewardsDistributionById[_poolAddress][_id] += userReward;
            PooltotalRewardsDistribution[_poolAddress] += userReward;
            userPoolTotalReward[user_Adderss[i]][_poolAddress] += userReward;
            userPoolTotalRewardWithId[user_Adderss[i]][_poolAddress][_id] += userReward;
            totalRewardsDistribution += userReward;
            
            emit RewardDistribute(_poolAddress , _id , user_Adderss[i] , userReward  );
             (bool success, ) = user_Adderss[i].call{value: userReward}("");
             require(success, "reward transfer failed!!");
        }

        pooldata[_poolAddress][_id].startTime = block.timestamp;
        pooldata[_poolAddress][_id].endTime = block.timestamp.add(pool.lockupDuration.mul(baseTime));

    }

    function withdraw(uint256 _orderId) public nonReentrant{
        require(withdrawStarted, "Not Stared yet!");
        require(_orderId <= latestOrderId,"The order ID is incorrect"); // IOI
        OrderInfo storage orderInfo = orders[_orderId];
        require(!orderInfo.claimed && orderInfo.poolAddress != address(0) && orderInfo.amount > 0 && msg.sender == orderInfo.beneficiary , "Either you are not owner of current transaction or may already withdraw!!");
        uint256 amount = orderInfo.amount;
        address poolAddress = orderInfo.poolAddress;
        uint256 id = orderInfo.id;
        totalWithdrawal = totalWithdrawal.add(amount);
        
        PooltotalStakeById[poolAddress][id] = PooltotalStakeById[poolAddress][id].sub(amount);
        PooltotalStake[poolAddress] = PooltotalStake[poolAddress].sub(amount);

        userAllPoolStake[msg.sender] = userAllPoolStake[msg.sender] >= amount ? userAllPoolStake[msg.sender].sub(amount) : 0;
        userPoolTotalStakeWithId[msg.sender][poolAddress][id] = userPoolTotalStakeWithId[msg.sender][poolAddress][id] >= amount ? userPoolTotalStakeWithId[msg.sender][poolAddress][id].sub(amount) : 0;
        userPoolTotalStake[msg.sender][poolAddress] = userPoolTotalStake[msg.sender][poolAddress] >=  amount ? userPoolTotalStake[msg.sender][poolAddress].sub(amount) : 0;
        
        orderInfo.claimed = true;
        
        IERC20MetadataUpgradeable(orderInfo.poolAddress).transfer(
            address(msg.sender),
            amount
        );
        emit Withdraw(
            poolAddress,
            msg.sender,
            amount,
            block.timestamp
        );
    }

    function poolTotalRewardCount(address _poolAddress) public view returns (uint){
        uint length = pooldata[_poolAddress].length;
        uint totalReward = 0;
        for(uint i=0 ; i < length ; i++){
            if(pooldata[_poolAddress][i].status == true){
                totalReward += pooldata[_poolAddress][i].totalReward;
            }
        }
        return totalReward;
    }

    function bnbLiquidity(address payable _reciever, uint256 _amount)
        external
        onlyOwner
    {
        _reciever.transfer(_amount);
    }

    function transferAnyERC20Token(
        address payaddress,
        address tokenAddress,
        uint256 tokens
    ) public onlyOwner {
        IERC20MetadataUpgradeable(tokenAddress).transfer(payaddress, tokens);
    }

    function toggleStaking(bool _start) public onlyOwner {
        started = _start;
    }

    function withdrawToogle(bool _withdrawStart) public onlyOwner{
        withdrawStarted = _withdrawStart;
    }

    function setBaseTime(uint256 _baseTime) public onlyOwner{
        require(_baseTime > 0 , "basetime must be greator than zero!!");
        baseTime = _baseTime;
    }
}
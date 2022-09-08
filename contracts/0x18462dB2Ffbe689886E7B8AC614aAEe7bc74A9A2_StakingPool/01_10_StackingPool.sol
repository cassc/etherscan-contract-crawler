// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";


contract StakingPool is OwnableUpgradeable, ReentrancyGuard 
{
    using SafeERC20 for IERC20;
    using Address for address payable;

    uint256 public createdPoolId;

    event TokensStaked(uint256 poolId,address token, uint256 amount);
    event progressOfStaking(uint256 poolId,address buyer,
        uint256 amount, uint period, uint256 tamount);
    event registerpool(uint256 poolId, uint256 stakper, uint256 amount, uint256 stak, uint256 tamount);

    enum PoolType {   
        Private,
        Public
    }

    struct PoolInfo {
        uint256 stakingPeriod;
        uint256 weiAmount;
        uint256 staking;
       // uint256 base;
        uint256 totamount;
    }

     uint256 public poolsCount;

     PoolInfo[] public poolInfos;

    address public beneficiary;
   // address private beneficiary;
    // uint256 public firstPer;
    // uint256 public secondPer;
    // uint256 public thirdPer;
    // uint256 public fourthPer;
    uint256 public minAmount;
    uint256 public stakingPeriod;
    uint256 public weiAmount;
    uint256 public Amount;
    uint256 public staking;
    uint256 public maxAmount;
    address public testtoken;
    address public ideaToken;
    //uint256 public base;
    uint256 public totamount;
    uint256 public startTime;
    uint256 public totalamount;
    uint256 public firstPercent;
    uint256 public secondPercent;
    uint256 public thirdPercent;
    uint256 public fourthPercent;

       

    mapping(address => uint256) public claimable;
    mapping(address => uint256) private _released;
     mapping(uint256 => address) public pools;
    mapping(address => bool) public isPool;
    mapping(uint256 => bool) public isCreated;

    // modifier _initialized() {
	// 	require(start != 0, "Staking Pool not initialized");
	// 	_;
	// }
    function initialize(uint256 _minAmount, uint256 _maxAmount, address _ideaToken, uint256 _firstPercent, uint256 _secondPercent, uint256 _thirdPercent, uint256 _fourthPercent) external initializer {   
        OwnableUpgradeable.__Ownable_init();
        // firstPer = _firstPer; 
        // secondPer = _secondPer;
        // thirdPer = _thirdPer;
        // fourthPer = _fourthPer;
        minAmount = _minAmount;
        maxAmount = _maxAmount;
        firstPercent = _firstPercent;
        secondPercent = _secondPercent;
        thirdPercent = _thirdPercent;
        fourthPercent = _fourthPercent;
        ideaToken = _ideaToken;   
    }

      function getPoolId() external view returns (uint256) {
        return (poolInfos.length);
    }
    function updateMinAmount(uint256 _minAmount)external onlyOwner{
        minAmount = _minAmount;
    }

    function updateMaxAmount(uint256 _maxAmount)external onlyOwner{
        maxAmount = _maxAmount;
    }
    
    function updateToken(address _ideaToken)external onlyOwner{
        ideaToken = _ideaToken;
    }

    function getInfo() external view returns (uint256, uint256, uint256, uint256, uint256, uint256, address) {
        return (minAmount, maxAmount, firstPercent, secondPercent, thirdPercent, fourthPercent, ideaToken);
    }


     /**
     * @return the amount of the token released.
     */
    function claimTokens(address token) public view returns (uint256) {
        return claimable[token];
    }
    function claimAmount(uint256 poolId) external {

        PoolInfo storage poolInfo = poolInfos[poolId];

        require(poolInfo.totamount > 0 ,"nothing to claim");

        uint256 amount = poolInfo.totamount;

        poolInfo.totamount = 0;

        IERC20(ideaToken).safeTransfer(msg.sender, amount);
    }
    function register(uint256 _stakingPeriod, uint256 _weiAmount,uint256 _staking) public{

        require(_weiAmount >= minAmount, "weiamount should be grater then 1000!");
        require(_weiAmount <= maxAmount, "weiamount should be less then 1000000!");

        require(_staking == firstPercent || _staking == secondPercent || _staking == thirdPercent || _staking == fourthPercent, "percentage doesnt matches the timeperiod");

        createdPoolId = poolInfos.length;
        totamount=0;

        startTime = block.timestamp + 300 seconds;

        poolInfos.push(
            PoolInfo(
                _stakingPeriod,
                _weiAmount,
                _staking,
              //  _base,
                totamount
            )
        );

        stakingPeriod = _stakingPeriod;        
        weiAmount = _weiAmount;
        staking = _staking;
       // base = _base;
       // poolsCount = poolsCount + 1;
        emit registerpool(createdPoolId,stakingPeriod,weiAmount,staking,totamount);

    }

    function applyForStaking(uint256 poolId ) external {
        
        require(poolId < poolInfos.length, "Invalid stakeId");
        
        require(!isCreated[poolId], "Already applied for this stakeid");

        uint256 endTime = startTime + 3600 seconds;
    
        require(block.timestamp < endTime && endTime != 0, "time for applying staking is over, register again" );        

        PoolInfo storage poolInfo = poolInfos[poolId];

        testtoken = address(this);  
        // stakingPeriod = _stakingPeriod;
        // weiAmount = _weiAmount;
        require(
            poolInfo.weiAmount <= IERC20(ideaToken).balanceOf(msg.sender),
            "out of balance"
        );
        require(poolInfo.weiAmount >= minAmount, "amount too low");

        require(
            poolInfo.totamount + poolInfo.weiAmount <= maxAmount,
            "you can not apply for more then this amount"
        );
        
        IERC20(ideaToken).safeTransferFrom(msg.sender, address(this), poolInfo.weiAmount);
        
       poolInfo.totamount = poolInfo.totamount + poolInfo.weiAmount;

        isCreated[poolId] = true;

        poolsCount = poolsCount + 1;
        //  poolInfos.push(
        //     PoolInfo(
        //         weiAmount,
        //         stakingPeriod,
        //         staking
        //     )
        // );
        emit progressOfStaking(createdPoolId,msg.sender, poolInfo.weiAmount, poolInfo.stakingPeriod, poolInfo.totamount);   
    }
    //    /**
    //  * @notice Transfers vested tokens to beneficiary.
    //  * @param ideaToken ERC20 token which is being vested
    //  **/
    function stakingClaim(uint256 poolId ) public {

        uint256 stakingInstallment;

        require(poolId < poolInfos.length, "Invalid StakeId");
        
        PoolInfo storage poolInfo = poolInfos[poolId];
        
        //require(firstPeriod)
        require(
            block.timestamp > poolInfo.stakingPeriod && poolInfo.stakingPeriod != 0,
            "Staking Claim Is Not Allowed Yet"
        );
        require(poolInfo.totamount > 0, "Nothing to claim");

        // require(_Amount >= minAmount, "amount too low");
        // uint256 unreleased = _releasableAmount(token);
        // uint256 totalAmount= claimable[msg.sender];
           uint256 totalAmount = poolInfo.weiAmount;
        // uint256 basecal = totalAmount /base ;
        // uint256 stakingInstallment = (basecal * _staking) / 100;
        // if(poolInfo.base > 0){
        //     uint256 basecal = totalAmount /poolInfo.base ;
        //      stakingInstallment = (basecal * poolInfo.staking) / 100;
        // }
        // else{
            stakingInstallment = (totalAmount * poolInfo.staking)/100;
      //  }
        require(stakingInstallment > 0, "STaking Token: no tokens are due");
       //  _released[address(token)] = _released[address(token)].add(stakingInstallment);
        uint256 stakingAmount = totalAmount+(stakingInstallment);

        require(
            stakingAmount <= IERC20(ideaToken).balanceOf(address(this)),
            "out of balance"
        );

        IERC20(ideaToken).safeTransfer(msg.sender, stakingAmount);

        poolInfo.totamount-=totalAmount;

        emit TokensStaked(createdPoolId,address(ideaToken), stakingAmount);
    }

    //payable(msg.sender).transfer(address(this).balance);
    function withdrawAllToken(address to) external onlyOwner{

        require(IERC20(ideaToken).balanceOf(address(this)) > 0 , "out of balance");

        totalamount = IERC20(ideaToken).balanceOf(address(this));

        IERC20(ideaToken).safeTransfer(to,totalamount);
                
    }
    // function withdrawToken() external onlyOwner {
    //   //  require(block.timestamp > endTime, "Pool has not yet ended");
    //   require(IERC20(ideaToken).balanceOf(address(this)) > 0 , "out of balance");
    //     IERC20(ideaToken).safeTransfer(msg.sender,
    //         IERC20(ideaToken).balanceOf(address(this)) - totalamount
    //     );
   // }

}
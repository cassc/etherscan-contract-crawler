// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import "./Interface/ITornadoStakingRewards.sol";
import "./Interface/ITornadoGovernanceStaking.sol";
import "./Interface/IRelayerRegistry.sol";
import "./RootDB.sol";
import "./ProfitRecord.sol";
import "./ExitQueue.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol";

/**
 * @title Deposit contract
 * @notice this is a Deposit contract
 */

contract Deposit is  ReentrancyGuardUpgradeable {

    /// the address of  torn token contract
    address immutable public TORN_CONTRACT;
    /// the address of  torn gov staking contract
    address immutable public TORN_GOVERNANCE_STAKING;
    /// the address of  torn relayer registry contract
    address immutable public TORN_RELAYER_REGISTRY;
    /// the address of  torn ROOT_DB contract
    address immutable public ROOT_DB;

    /// the address of  dev's rewards
    address public rewardAddress;
    /// the ratio of  dev's rewards which is x/1000
    uint256 public profitRatio;
    /// the max torn in the Deposit contact ,if over this amount it will been  staking to gov staking contract
    uint256 public maxReserveTorn;
    /// the max reward torn in  gov staking contract  ,if over this amount it will been claimed
    uint256 public maxRewardInGov;

    /// this  is the max uint256 , this flag is used to indicate insufficient
    uint256 constant public  IN_SUFFICIENT = 2**256 - 1;
    /// this  is the max uint256 , this flag is used to indicate sufficient
    uint256 constant public  SUFFICIENT = 2**256 - 2;


    /// @notice An event emitted when lock torn to gov staking contract
    /// @param amount The amount which staked to gov staking contract
    event LockToGov(uint256 amount);

    /// @notice An event emitted when unlock torn to gov staking contract
    /// @param amount The amount which staked to gov staking contract
    event UnLockGov(uint256 amount);

    /// @notice An event emitted when user withdraw
    /// @param  account The: address of user
    /// @param tokenQty: voucher of the deposit
    /// @param torn: the amount of torn in this withdarw
    /// @param profit: the profi of torn in this withdarw
    event WithDraw(address  indexed  account,uint256 tokenQty,uint256 torn,uint256 profit);

    /// @notice An event emitted when user deposit
    /// @param  account The: address of user
    /// @param torn: TORN of the deposit
    event Deposit(address  indexed  account,uint256 torn);

    constructor(
        address tornContract,
        address tornGovStaking,
        address tornRelayerRegistry,
        address rootDb
    ) {
        TORN_CONTRACT = tornContract;
        TORN_GOVERNANCE_STAKING = tornGovStaking;
        TORN_RELAYER_REGISTRY = tornRelayerRegistry;
        ROOT_DB = rootDb;
    }


    modifier onlyOperator() {
        require(msg.sender == RootDB(ROOT_DB).operator(), "Caller is not operator");
        _;
    }

    modifier onlyTornAdo() {
        require(msg.sender == RootDB(ROOT_DB).TORNADO_MULTISIG(), "caller is not Tornado multisig");
        _;
    }



    modifier onlyExitQueue() {
        require(msg.sender == RootDB(ROOT_DB).exitQueueContract(), "Caller is not exitQueue");
        _;
    }


    function __Deposit_init() public initializer {
        __ReentrancyGuard_init();
    }

    /**
    * @notice setPara used to set parameters called by Operator
    * @param index index para
            * index 1 maxReserveTorn;
            * index 2 _maxRewardInGov;
            * index 3 _rewardAddress
            * index 4 profitRatio  x/1000
    * @param value
   **/
    function setPara(uint256 index,uint256 value) external onlyOperator {
        if(index == 1){
            maxReserveTorn = value;
        }else if(index == 2){
            maxRewardInGov = value;
        }else if(index == 3){
            rewardAddress = address(uint160(value));
        }
        else{
            require(false,"Invalid _index");
        }
    }


    function setProfitRatio(uint256 profit) external onlyTornAdo {
            profitRatio = profit;
    }

    /**
    * @notice _checkLock2Gov used to check whether the TORN balance of the contract  is over maxReserveTorn
              if it is ture ,lock it to TORN_GOVERNANCE_STAKING
   **/
    function _checkLock2Gov() internal  {
        uint256 balance = IERC20Upgradeable(TORN_CONTRACT).balanceOf(address(this));
        if(maxReserveTorn >= balance){
            return ;
        }
        SafeERC20Upgradeable.safeApprove(IERC20Upgradeable(TORN_CONTRACT),TORN_GOVERNANCE_STAKING, balance);
        ITornadoGovernanceStaking(TORN_GOVERNANCE_STAKING).lockWithApproval(balance);
        emit LockToGov(balance);
    }

    /**
     * @notice _nextExitQueueValue used to get the exitQueue next user's waiting Value
      if no one is waiting or all users are prepared return 0
     * return the Value waiting for
    **/
    function  _nextExitQueueValue()  view internal returns(uint256 value){
        value = ExitQueue(RootDB(ROOT_DB).exitQueueContract()).nextValue();
    }

    /**
     * @notice getValueShouldUnlockFromGov used get the Value should unlock from gov staking contract
     * return
          1. if noneed to unlock return 0

          2. if there is not enough torn to unlock for exit queue retrun  IN_SUFFICIENT
          3. other values are the value should to unlock
    **/
    function getValueShouldUnlockFromGov() public view returns (uint256) {

        uint256 next_value = _nextExitQueueValue();
        if(next_value == 0 ){
            return 0;
        }
        uint256 this_balance = IERC20Upgradeable(TORN_CONTRACT).balanceOf(address(this));

        if(next_value <= this_balance){
            return 0;
        }
        uint256 shortage =  next_value -IERC20Upgradeable(TORN_CONTRACT).balanceOf(address(this)) ;
        if(shortage <= ITornadoGovernanceStaking(TORN_GOVERNANCE_STAKING).lockedBalance(address(this)))
        {
            return shortage;
        }
        return  IN_SUFFICIENT;
    }

    /**
       * @notice isNeedClaimFromGov used to check if the gov staking contract reward
       * return   the staking reward is over maxRewardInGov ?
    **/
    function isNeedClaimFromGov() public view returns (bool) {
        uint256 t = ITornadoStakingRewards(ITornadoGovernanceStaking(TORN_GOVERNANCE_STAKING).Staking()).checkReward(address(this));
        return t > maxRewardInGov;
    }

    /**
       * @notice isNeedTransfer2Queue used to check if need to Transfer torn to exit queue
       * return   true if the balance of torn is over the next value
    **/
    function isNeedTransfer2Queue() public view returns (bool) {
       uint256 next_value = _nextExitQueueValue();
        if(next_value == 0 ){
            return false;
        }
        return IERC20Upgradeable(TORN_CONTRACT).balanceOf(address(this)) > next_value;
    }

    /**
       * @notice stake2Node used to stake TORN to relayers  when it is necessary call by Operator
       * @dev if the contract balance is insufficient ,it will unlock torn form the gov
       * @param  index: the index of the relayer
       * @param tornQty: the amount of TORN to be stake
    **/
    function stake2Node(uint256 index, uint256 tornQty) public onlyOperator {
        address relayer = RootDB(ROOT_DB).mRelayers(index);
        require(relayer != address(0), 'Invalid index');
        uint256 tornBalanceOf = ERC20Upgradeable(TORN_CONTRACT).balanceOf(address(this));
        if(tornBalanceOf < tornQty){
            uint256 need_unlock = tornQty - tornBalanceOf;
            // if the locked balance is insufficient the unlock operation will be revert
            // so it is unnecessary to check the locked  balance
            ITornadoGovernanceStaking(TORN_GOVERNANCE_STAKING).unlock(need_unlock);
            emit UnLockGov(need_unlock);
        }
        SafeERC20Upgradeable.safeApprove(IERC20Upgradeable(TORN_CONTRACT),TORN_RELAYER_REGISTRY, tornQty);
        IRelayerRegistry(TORN_RELAYER_REGISTRY).stakeToRelayer(relayer, tornQty);
    }


   /**
       * @notice deposit used to deposit TORN to relayers dao  with permit param
       * @param  tornQty: the amount of torn want to stake
       * @param   deadline ,v,r,s  permit param
    **/
    function deposit(uint256 tornQty,uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
        IERC20PermitUpgradeable(TORN_CONTRACT).permit(msg.sender, address(this), tornQty, deadline, v, r, s);
        depositWithApproval(tornQty);
    }


    /**
       * @notice deposit used to deposit TORN to relayers dao  with approval
       * @param  tornQty: the amount of torn want to stake
       * @dev
           1. mint the voucher of the deposit.
           2. TransferFrom TORN to this contract
           3. recorde the raw 'price' of the voucher for compute profit
           4. check the auto work to do
                1.  isNeedTransfer2Queue
                2.  isNeedClaimFromGov
                3.  checkLock2Gov
                4. or unlock for the gov prepare to Transfer2Queue
    **/
    function depositWithApproval(uint256 tornQty) public nonReentrant {
        address account = msg.sender;
        require(tornQty > 0,"error para");
        uint256 root_token = RootDB(ROOT_DB).safeMint(account, tornQty);
        SafeERC20Upgradeable.safeTransferFrom(IERC20Upgradeable(TORN_CONTRACT), account, address(this), tornQty);
        //record the deposit
        ProfitRecord(RootDB(ROOT_DB).profitRecordContract()).deposit(msg.sender, tornQty,root_token);

        //  emit the Deposit
        emit Deposit(account,tornQty);

        // this is designed to avoid pay too much gas by one user
         if(isNeedTransfer2Queue()){
             ExitQueue(RootDB(ROOT_DB).exitQueueContract()).executeQueue();
        }else if(isNeedClaimFromGov()){
             _claimRewardFromGov();
         } else{
             uint256 need_unlock =  getValueShouldUnlockFromGov();

             if(need_unlock == 0){
                 _checkLock2Gov();
                 return ;
             }
            if(need_unlock != IN_SUFFICIENT){
                ITornadoGovernanceStaking(TORN_GOVERNANCE_STAKING).unlock(need_unlock);
                emit UnLockGov(need_unlock);
             }
         }

    }

    /**
       * @notice getValueShouldUnlock used to get the amount of TORN and the shortage of TORN
       * @param  tokenQty:  the amount of the voucher
       * return (shortage ,torn)
              shortage:  the shortage of TRON ,if the user want to with draw the _token_qty voucher
                        1. if the balance of TORN in this contract is enough return SUFFICIENT
                        2. if the balance of TORN added the lock balance in gov are not enough return IN_SUFFICIENT
                        3. others is the amount which show unlock for the withdrawing
              torn    :  the amount of TORN if the user with draw the qty of  _token_qty
    **/
    function getValueShouldUnlock(uint256 tokenQty)  public view  returns (uint256 shortage,uint256 torn){
        uint256 this_balance_tron = IERC20Upgradeable(TORN_CONTRACT).balanceOf(address(this));
        // _amount_token
         torn = RootDB(ROOT_DB).valueForTorn(tokenQty);
        if(this_balance_tron >= torn){
            shortage = SUFFICIENT;
            return (shortage,torn);
        }
        uint256 _lockingAmount = ITornadoGovernanceStaking(TORN_GOVERNANCE_STAKING).lockedBalance(address(this));
         shortage = torn - this_balance_tron;
        if(_lockingAmount < shortage){
            shortage = IN_SUFFICIENT;
        }
    }


    /**
       * @notice _safeWithdraw used to withdraw
       * @param  tokenQty:  the amount of the voucher
       * @return  the amount of TORN user get
       * @dev
             1. Unlock torn form gov if necessary
             2. burn the tokenQty of the voucher
    **/
   function _safeWithdraw(uint256 tokenQty) internal  returns (uint256){
       require(tokenQty > 0,"error para");
       uint256  shortage;
       uint256 torn;
       (shortage,torn) = getValueShouldUnlock(tokenQty);
       require(shortage != IN_SUFFICIENT, 'pool Insufficient');
       if(shortage != SUFFICIENT) {
           ITornadoGovernanceStaking(TORN_GOVERNANCE_STAKING).unlock(shortage);
       }
       RootDB(ROOT_DB).safeBurn(msg.sender, tokenQty);
       return torn;
   }

    /**
       * @notice _safeSendTorn used to send TORN to withdrawer and profit to dev team
       * @param  torn: amount of TORN user got
       * @param  profit: the profit of the user got
       * return  the user got TORN which subbed the dev profit
    **/
    function _safeSendTorn(uint256 torn,uint256 profit) internal returns(uint256 ret) {
        profit = profit *profitRatio/1000;
        //send to  profitAddress
        if(profit > 0){
            SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(TORN_CONTRACT),rewardAddress, profit);
        }
        ret = torn - profit;
        //send to  user address
        SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(TORN_CONTRACT),msg.sender, ret);
    }

    /**
       * @notice  used to  withdraw
       * @param  tokenQty:  the amount of the voucher
       * @dev inorder to save gas we had modified erc20 token which no need to approve
    **/
    function withDraw(uint256 tokenQty)  public nonReentrant {
        require( _nextExitQueueValue() == 0,"Queue not empty");
        address profit_address = RootDB(ROOT_DB).profitRecordContract();
        uint256 profit = ProfitRecord(profit_address).withDraw(msg.sender, tokenQty);
        uint256 torn = _safeWithdraw(tokenQty);
        _safeSendTorn(torn,profit);
        emit WithDraw(msg.sender, tokenQty,torn,profit);
    }

    /**
       * @notice  used to  withdraw
       * @param  addr:  the addr of user
       * @param  tokenQty:  the amount of the voucher
       * @dev    because of nonReentrant have to supply this function for exitQueue
       * return  the user got TORN which subbed the dev profit
    **/
    function withdraw_for_exit(address addr,uint256 tokenQty)  external onlyExitQueue returns (uint256 ret) {
        address profit_address = RootDB(ROOT_DB).profitRecordContract();
        uint256 profit = ProfitRecord(profit_address).withDraw(addr, tokenQty);
        uint256 torn = _safeWithdraw(tokenQty);
        ret =  _safeSendTorn(torn,profit);
        emit WithDraw(addr, tokenQty,torn,profit);
    }


    /**
       * @notice totalBalanceOfTorn
       * return  the total Balance Of  TORN which controlled  buy this contract
    **/
    function totalBalanceOfTorn()  external view returns (uint256 ret) {
        ret = IERC20Upgradeable(TORN_CONTRACT).balanceOf(address(this));
        ret += balanceOfStakingOnGov();
        ret += checkRewardOnGov();
    }

    /**
       * @notice isBalanceEnough
       *  return whether is Enough TORN for user to withdraw the tokenQty
    **/
    function isBalanceEnough(uint256 tokenQty)  external view returns (bool) {
        if( _nextExitQueueValue() != 0){
            return false;
        }
        uint256  shortage;
        (shortage,) = getValueShouldUnlock(tokenQty);
        return shortage < IN_SUFFICIENT;
    }

    function balanceOfStakingOnGov() public view returns (uint256 ) {
        return ITornadoGovernanceStaking(TORN_GOVERNANCE_STAKING).lockedBalance(address(this));
    }

    function checkRewardOnGov()  public view returns (uint256) {
        return ITornadoStakingRewards(ITornadoGovernanceStaking(TORN_GOVERNANCE_STAKING).Staking()).checkReward(address(this));
    }

    /**
       * @notice claim Reward From Gov staking
    **/
    function _claimRewardFromGov() internal {
        address _stakingRewardContract = ITornadoGovernanceStaking(TORN_GOVERNANCE_STAKING).Staking();
        ITornadoStakingRewards(_stakingRewardContract).getReward();
    }

}
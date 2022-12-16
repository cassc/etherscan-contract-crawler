// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../interfaces/IAdminAccess.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "../../libraries/Structs.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract Staking is AccessControlEnumerable,ReentrancyGuard{
    using SafeERC20 for IERC20;
    event PausedEvent(address account);
    event UnPausedEvent(address account);
    event StopEvent(address account);
    event SetPayoutIntervalBlockEvent(address account,uint256 from,uint256 to);
    event SetEachBlockSecondEvent(address account,uint256 from,uint256 to);
    event SetYearBlockEvent(address account,uint256 from,uint256 to);
    event SetFeeAddressEvent(address account,address from,address to);
    event SetCommissionEvent(address account,uint256 from,uint256 to);
    event SetMinStakeAmountEvent(address account,uint256 from,uint256 to);
    event SetUnboundPeriodBlockEvent(address account,uint256 from,uint256 to);
    event SetInstantUnboundFeeEvent(address account,uint256 from,uint256 to);
    event SetAllowInstantUnboundEvent(address account,bool allow);
    event StakeEvent(address staker, address token, uint256 amount);
    event NormalUnboundEvent(address staker, address token, uint256 amount);
    event InstantUnboundEvent(address staker, address token, uint256 amount);
    event WithdrawEvent(address staker, address token, uint256 amount);
    event ClaimRewardsEvent(address staker, address token, uint256 amount);
    event AddUserWhitelistEvent(address operator,address user);
    event RemoveUserWhitelistEvent(address operator,address user);
    event ChangeUserWhitelistSwitchEvent(address operator,bool from,bool to);
    event AddProjectRoleEvent(address operator,address account);
    event removeProjectRoleEvent(address operator,address account);

    /// @notice pause all functions
    bool public paused=false;
    /// @dev ethereum [12,2628000] ,bsc [3,10512000]
    /// @notice set different seconds for different blockchain
    uint256 public eachBlockSecond = 12;
    /// @notice block number for whole year
    uint256 public yearBlock=2628000;
    /// @notice stake token's contract address
    address public  stakingToken;
    /// @notice current total staked
    uint256 public totalStakingAmount;
    /// @notice accumulate total claimed reward
    uint256 public totalClaimedReward;
    /// @notice user claim interval
    uint256 public payoutIntervalBlock;
    /// @notice min stake amount
    uint256 public minStakeAmount;
    /// @notice allow withdraw after unboundPeriodBlock
    uint256 public unboundPeriodBlock;
    /// @notice instant unbound fee
    uint256 public instantUnboundFeePercentage;
    /// @notice fee address to receive fees
    address public feeAddress;
    /// @notice commission fee deduct from user's reward
    uint256 public commissionPercentage;
    /// @notice sherpa global permission role
    IAdminAccess public access;
    /// @notice if whitelist check opened then require user in whitelist
    bool public userWhitelistSwitchOpened;
    mapping(address => bool) public userWhitelist;

    /// @notice PROJECT_ROLE in charge permission of own instance
    bytes32 public constant PROJECT_ROLE = keccak256("PROJECT_ROLE");

    /// @notice stop stake immediately or stop at plan block number
    bool public stopped;
    uint256 public stopAtBlock;

    /// @notice true for allow user to instant unbound
    bool public allowedInstantUnbound;

    /// @notice get all fields
    function getAllFields() public view returns(
        uint256 eachBlockSecond_,
        uint256 yearBlock_,
        address stakingToken_,
        uint256 totalStakingAmount_,
        uint256 totalClaimedReward_,
        uint256 payoutIntervalBlock_,
        uint256 minStakeAmount_,
        uint256 unboundPeriodBlock_,
        uint256 instantUnboundFeePercentage_,
        address feeAddress_,
        uint256 commissionPercentage_,
        bool stopped_,
        uint256 stopAtBlock_,
        bool allowedInstantUnbound_){
        return (
            eachBlockSecond,
            yearBlock,
            stakingToken,
            totalStakingAmount,
            totalClaimedReward,
            payoutIntervalBlock,
            minStakeAmount,
            unboundPeriodBlock,
            instantUnboundFeePercentage,
            feeAddress,
            commissionPercentage,
            stopped,
            stopAtBlock,
            allowedInstantUnbound
        );
    }

    /// @notice if whitelist check opened then require user in whitelist
    modifier isWhitelisted(address user) {
        if (userWhitelistSwitchOpened){
            require(userWhitelist[user],"!UW");
        }
        _;
    }
    modifier whenNotPaused() {
        require(!paused, "PD");
        _;
    }
    modifier whenPaused() {
        require(paused, "!PD");
        _;
    }
    modifier notStopped() {
        require(!stopped&&block.number<stopAtBlock, "SD");
        _;
    }
    modifier onlyOwner() {
        require(access.getOwner() == msg.sender, "!O");
        _;
    }
    modifier atLeastAdmin() {
        require(access.hasAdminRole(msg.sender)||(access.getOwner() == msg.sender), "!A");
        _;
    }
    modifier atLeastProject() {
        require(hasRole(PROJECT_ROLE,msg.sender)||access.hasAdminRole(msg.sender)||(access.getOwner() == msg.sender), "!A");
        _;
    }
    /// @notice withdrawERC20Token
    /// @param token, address of ERC20
    /// @param amount, withdraw amount of ERC20
    function withdrawERC20Token(address token,uint256 amount) public onlyOwner {
        IERC20(token).safeTransfer(msg.sender, amount);
    }
    function addToProjectRole(address account) public atLeastAdmin {
        _grantRole(PROJECT_ROLE, account);
        emit AddProjectRoleEvent(msg.sender,account);
    }
    function removeFromProjectRole(address account) public atLeastAdmin {
        _revokeRole(PROJECT_ROLE, account);
        emit removeProjectRoleEvent(msg.sender,account);
    }
    /// @notice pause all functions
    function pause() public whenNotPaused atLeastAdmin {
        paused = true;
        emit PausedEvent(msg.sender);
    }
    /// @notice unpause all functions
    function unpause() public whenPaused atLeastAdmin{
        paused = false;
        emit UnPausedEvent(msg.sender);
    }
    /// @notice stopStake,stop stake immediately or stop at plan block number
    /// @param _stop, true for stop immediately
    /// @param _stopAtBlock, _stop for stop at block _stopAtBlock
    function stopStake(bool _stop,uint256 _stopAtBlock) public atLeastAdmin{
        stopped = _stop;
        stopAtBlock=_stopAtBlock;
        emit StopEvent(msg.sender);
    }
    /// @notice setEachBlockSecond
    /// @param second, second of one block for this blockchain
    function setEachBlockSecond(uint256 second) public atLeastAdmin{
        uint256 origin=eachBlockSecond;
        eachBlockSecond=second;
        emit SetEachBlockSecondEvent(msg.sender,origin,eachBlockSecond);
    }
    /// @notice setAllowInstantUnbound
    /// @param allow, true for allow user to instant unbound
    function setAllowInstantUnbound(bool allow) public atLeastAdmin{
        allowedInstantUnbound=allow;
        emit SetAllowInstantUnboundEvent(msg.sender,allow);
    }
    /// @notice setYearBlock
    /// @param number, block count of this blockchain for 1 year
    function setYearBlock(uint256 number) public atLeastAdmin{
        uint256 origin=yearBlock;
        yearBlock=number;
        emit SetYearBlockEvent(msg.sender,origin,yearBlock);
    }
    /// @notice setFeeAddress
    /// @param account, address to receive fees
    function setFeeAddress(address account) public atLeastAdmin{
        address origin=feeAddress;
        feeAddress=account;
        emit SetFeeAddressEvent(msg.sender,origin,feeAddress);
    }
    /// @notice setCommission
    /// @param commission, range is [0,10000] ,1728 means 17.28%
    function setCommission(uint256 commission) public atLeastAdmin{
        require(commission<=10000);
        uint256 origin=commissionPercentage;
        commissionPercentage=commission;
        emit SetCommissionEvent(msg.sender,origin,commissionPercentage);
    }
    /// @notice changeUserWhitelistSwitch
    /// @param switchFlag, true for open user whitelist check
    function changeUserWhitelistSwitch(bool switchFlag) public atLeastProject {
        bool origin=userWhitelistSwitchOpened;
        userWhitelistSwitchOpened=switchFlag;
        emit ChangeUserWhitelistSwitchEvent(msg.sender,origin,userWhitelistSwitchOpened);
    }
    /// @notice addToUserWhitelist
    /// @param user, stake user address
    function addToUserWhitelist(address user) public atLeastProject {
        userWhitelist[user] = true;
        emit AddUserWhitelistEvent(msg.sender,user);
    }
    /// @notice removeFromUserWhitelist
    /// @param user, stake user address
    function removeFromUserWhitelist(address user) public atLeastProject {
        userWhitelist[user] = false;
        emit RemoveUserWhitelistEvent(msg.sender,user);
    }
    /// @notice setMinStakeAmount,please notice this amount is important! please keeping this minAmount with a suitable USD value to avoid array length attacks
    /// @param minAmount, stake token amount
    function setMinStakeAmount(uint256 minAmount) public atLeastProject{
        uint256 origin=minStakeAmount;
        minStakeAmount=minAmount;
        emit SetMinStakeAmountEvent(msg.sender,origin,minStakeAmount);
    }
    /// @notice setUnboundPeriodBlock
    /// @param number, how many block user can redeem back their principal
    function setUnboundPeriodBlock(uint256 number) public atLeastProject{
        uint256 origin=unboundPeriodBlock;
        unboundPeriodBlock=number;
        emit SetUnboundPeriodBlockEvent(msg.sender,origin,unboundPeriodBlock);
    }
    /// @notice setPayoutInterval
    /// @param number, claim reward interval block number
    function setPayoutInterval(uint256 number) public atLeastProject{
        uint256 origin=payoutIntervalBlock;
        payoutIntervalBlock=number;
        emit SetPayoutIntervalBlockEvent(msg.sender,origin,payoutIntervalBlock);
    }
    /// @notice setInstantUnboundFee
    /// @param feePer, instant unbound fee from principal,range is [0,10000],1728 means 17.28%
    function setInstantUnboundFee(uint256 feePer) public atLeastAdmin{
        require(feePer<=10000);
        uint256 origin=instantUnboundFeePercentage;
        instantUnboundFeePercentage=feePer;
        emit SetInstantUnboundFeeEvent(msg.sender,origin,instantUnboundFeePercentage);
    }
    constructor(Structs.StakingParams memory params) {
        stakingToken=params.stakingToken;
        minStakeAmount=params.minStakeAmount;
        payoutIntervalBlock=params.payoutIntervalBlock;
        unboundPeriodBlock=params.unboundPeriodBlock;
        instantUnboundFeePercentage=params.instantUnboundFeePercentage;
        access= IAdminAccess(params.accessControl);
        feeAddress=params.feeAddress;
        commissionPercentage=params.commissionPercentage;
        stopped=false;
        stopAtBlock=block.number+100*yearBlock;
        allowedInstantUnbound=params.allowedInstantUnbound;
    }

}
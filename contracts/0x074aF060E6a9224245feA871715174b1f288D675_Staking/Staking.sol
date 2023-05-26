/**
 *Submitted for verification at Etherscan.io on 2023-05-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom( address sender, address recipient, uint256 amount) external returns (bool);
}

library Address {
   
    function isContract(address account) internal view returns (bool) {
        
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
   
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            
            if (returndata.length > 0) {
                
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }

     function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

contract Context {
    
    constructor()  {}

    function _msgSender() internal view returns (address ) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; 
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract Pausable is Context {
    
    event Paused(address account);

    event Unpaused(address account);

    bool private _paused;

    constructor () {
        _paused = false;
    }

    function paused() public view returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

abstract contract SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
       

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { 
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract Staking is Ownable, Pausable, SafeERC20, ReentrancyGuard {

    uint16[] public referralRewards;       //10 = 1% 
    uint16[3] public depositFee;
    uint16[3] public withdrawFee;
    uint16[3] public claimFee;
    uint16[3] public reinverseFee;
    uint16[3] public planDays;
    address[3] public Admin;
    uint16 public APY_percentage;
    uint256 public depositSlot = 5000;
    bool public isInitilize;

    IERC20 public USDT;

    struct SelectedSlot {
        uint8 slotNum;
        uint16 plan;
        uint256 slotAmount;
    }

    struct UserDetails{
        uint stakeAmount;
        uint claimAmount;
        uint128 rewardEndTime;
        uint128 stakeTime;
        uint128 lastClaimTime;
        uint128 withdrawTime;
        address referral;
        SelectedSlot slotDetails;
    }

    struct UserBasic{
        uint32 stakingCount;
        uint32 referralCount;
        uint256 totalClaimAmount;
        uint256 referalRewardAmount;
        address[] referrers;

    }

    mapping (address => mapping(uint => UserDetails)) public userInfo;
    mapping (address => UserBasic) public userBase;

    event Deposit(address indexed Caller, uint indexed TokenAmount, uint Plan, uint DepositTime, uint indexed StakeID);
    event Claim(address indexed Caller, uint indexed ClaimAmount, uint ClaimTime, uint indexed StakeID);
    event Withdraw(address indexed Caller, uint indexed WithdrawAmount, uint indexed StakeID, uint WithdrawTime);
    event ReInverse(address indexed Caller, uint indexed ReInverstAmount, uint indexed StakeID, uint Plan, uint ReInverstTime);
    event ReferalReward(address indexed User, address indexed Referral,uint indexed RewardAmount);
    event AdminFeeReward(address indexed User, address indexed Admin, uint indexed AdminReward);

    constructor(address _USDT, address[3] memory _admin, uint16 _APY) {
        USDT = IERC20(_USDT);
        Admin = _admin;
        APY_percentage = _APY;
    }

    function pause() external onlyOwner{
        _pause();
    }

    function unPause() external onlyOwner {
        _unpause();
    }

    function intilize(uint16[] memory _referralReward,
        uint16[3] memory _depositFee,
        uint16[3] memory _claimFee,
        uint16[3] memory _withdrawFee,
        uint16[3] memory _reinverseFee,
        uint16[3] memory _planDays
    ) external onlyOwner {
        require(!isInitilize,"already initilized");

        referralRewards = _referralReward;
        depositFee = _depositFee;
        claimFee = _claimFee;
        withdrawFee = _withdrawFee;
        reinverseFee = _reinverseFee;
        planDays = _planDays;

        isInitilize = true;
    }

    function deposit(uint8 _slotValue, uint16 _days, address _referral) external whenNotPaused {
        require(isInitilize,"contract not initilized");
        require(_days == planDays[0] || _days == planDays[1] || _days == planDays[2],"choose correct plan" );
        userBase[_msgSender()].stakingCount++;
        UserDetails storage user = userInfo[_msgSender()][userBase[_msgSender()].stakingCount];

        if (user.stakeTime > 0) {
            require(user.withdrawTime != 0,"previous deposit not claimed");
        }

        updateUserDetails(_slotValue, _days, _referral,userBase[_msgSender()].stakingCount);
        
        safeTransferFrom(USDT, _msgSender(), address(this), (_slotValue * 1e6 * depositSlot));
        sendAdminFee(depositFee, user.stakeAmount, true);

        sendreferralReward(user.stakeAmount, _referral);
    }

    function reInverse(uint _stakeID) external whenNotPaused {
        UserDetails storage user = userInfo[_msgSender()][_stakeID];
        if(user.stakeAmount >= (user.slotDetails.slotNum * 1e6 * depositSlot)){
            require(user.rewardEndTime < block.timestamp,"previous deposit time not finished");
            require(user.withdrawTime == 0,"user already withdraw");
            claim(_stakeID);
            user.withdrawTime = uint128(block.timestamp);

            if((user.stakeAmount - (user.slotDetails.slotNum * 1e6 * depositSlot)) > 0){
                uint fee = sendAdminFee(withdrawFee, (user.stakeAmount - (user.slotDetails.slotNum * 1e6 * depositSlot)), false);
                safeTransfer(IERC20(USDT), _msgSender(), (user.stakeAmount - (user.slotDetails.slotNum * 1e6 * depositSlot) - fee));
                emit Withdraw(_msgSender(), (user.stakeAmount - (user.slotDetails.slotNum * 1e6 * depositSlot) - fee), _stakeID, block.timestamp);
            }
            
            userBase[_msgSender()].stakingCount++;
            
            updateUserDetails(user.slotDetails.slotNum, user.slotDetails.plan,user.referral, userBase[_msgSender()].stakingCount);
            sendAdminFee(reinverseFee, user.stakeAmount, true);

            emit ReInverse(_msgSender(), (user.slotDetails.slotNum * 1e6 * depositSlot), _stakeID, user.slotDetails.plan, block.timestamp);
        } else {
            revert("Not enough reinverse amount");
        }
    }

    function updateUserDetails(uint8 _slotValue, uint16 _days, address _referral, uint _stakeID) internal {
        
        UserDetails storage user = userInfo[_msgSender()][_stakeID];

        user.stakeAmount = (_slotValue * 1e6 * depositSlot);
        user.slotDetails.slotNum = _slotValue;
        user.slotDetails.slotAmount = depositSlot;
        user.slotDetails.plan = _days;
        user.stakeTime = uint128(block.timestamp);
        user.lastClaimTime = uint128(block.timestamp);
        user.rewardEndTime = uint128(block.timestamp) + (_days * 1 days);
        user.referral = _referral;

        emit Deposit(_msgSender(), (_slotValue * 1e6 * depositSlot), user.slotDetails.plan, block.timestamp, _stakeID);
    }

    function isRefererExist(address _referral) internal view returns(bool){
        UserBasic storage referral = userBase[_referral];
        uint i = 0;
        for(i; i < referral.referralCount; i++){
            if(_msgSender() == referral.referrers[i]){
                return true;
            }
        }
        return false;
    }

    function sendreferralReward(uint _depositAmount, address _referral) internal {

        bool isExist = isRefererExist(_referral);
        if(_referral == address(0x0) || isExist) { return; }
        UserBasic storage referral = userBase[_referral];
        require((referral.stakingCount > 0 || _referral == owner()) && _referral != _msgSender(), "Invalid referral");
        referral.referrers.push(_msgSender());

        if (referralRewards.length > referral.referralCount){
            uint referral_reward = _depositAmount * referralRewards[referral.referralCount] / 1e3;
            referral.referalRewardAmount += referral_reward;
            safeTransfer(USDT, _referral, referral_reward);

            emit AdminFeeReward(_msgSender(), _referral, referral_reward);
        }
        referral.referralCount++;
    }

    function sendAdminFee(uint16[3] memory _feeAmount, uint _depositAmount, bool isDeposit) internal returns(uint) {
        uint feeSpend;
        for (uint i = 0; i < 3; i++){
            uint fee = _depositAmount * _feeAmount[i] / 1e3;
            if( isDeposit) {
                safeTransferFrom(USDT, _msgSender(), Admin[i], fee);
            } else {
                safeTransfer(USDT, Admin[i], fee);
            }

            emit AdminFeeReward(_msgSender(),Admin[i], fee);

            feeSpend += fee;
        }   
        return feeSpend;
    }

    function claim(uint256 _stakeID) public whenNotPaused nonReentrant {

        UserBasic storage user__ = userBase[_msgSender()];
        UserDetails storage user = userInfo[_msgSender()][_stakeID];
        require(user.stakeTime > 0,"invalid stakeID");
        uint rewardAmount = pendingReward(_msgSender(), _stakeID);
        user.lastClaimTime = uint128(block.timestamp)  ;
        if (block.timestamp >= user.rewardEndTime) { user.lastClaimTime = user.rewardEndTime; }

        user.claimAmount += rewardAmount;
        user__.totalClaimAmount += rewardAmount;

        if(rewardAmount > 0){
            uint fee = sendAdminFee(claimFee, rewardAmount, false);
            safeTransfer(USDT, _msgSender(), (rewardAmount - fee));
        }

        emit Claim(_msgSender(), rewardAmount, block.timestamp, _stakeID);
    }

    function pendingReward( address _user, uint _stakeID) public view returns(uint256 reward) {
        UserDetails storage user = userInfo[_user][_stakeID];
        require(user.withdrawTime == 0,"user already withdraw");
        uint stakeTime = 0;

        stakeTime = block.timestamp - user.lastClaimTime;
        if (block.timestamp >= user.rewardEndTime) { stakeTime = user.rewardEndTime - user.lastClaimTime; }
        
        uint amount = user.stakeAmount * APY_percentage * 1e16 / (365 * 86400 * 1e3 );
        reward = (stakeTime  * amount) / 1e16;
    }

    function withdraw(uint _stakeID) external whenNotPaused  {
        UserDetails storage user = userInfo[_msgSender()][_stakeID];
        require(user.stakeTime > 0,"invalid stakeID");
        require(user.withdrawTime == 0,"user already withdraw");
        require(user.rewardEndTime <= block.timestamp,"withdraw time not reached");
        claim(_stakeID);

        uint fee = sendAdminFee(withdrawFee, user.stakeAmount, false);
        user.withdrawTime = uint128(block.timestamp);
        safeTransfer(USDT, _msgSender(), user.stakeAmount - fee);  

        emit Withdraw(_msgSender(), user.stakeAmount - fee , _stakeID, block.timestamp);
    }

    function viewUserReferrers(address _account) external view returns(address[] memory referrers) {
        return userBase[_account].referrers;
    }

    function setDepositSlotValue(uint16 _depositSlot) external onlyOwner{
        depositSlot = _depositSlot;
    }

    function updateUSDT( address _newToken) external onlyOwner { 
        require(_newToken != address(0x0),"invalid token address");
        USDT = IERC20(_newToken);
    }

    function updatereferralReward(uint16[] memory _newRewards) external onlyOwner {
        referralRewards = _newRewards;
    }

    function recover(address _token, address _to, uint _amount) external onlyOwner {
        safeTransfer(IERC20(_token), _to, _amount);
    }

    function setDepositFee(uint16[3] memory _depositFee) external onlyOwner {
        depositFee = _depositFee;
    }

    function setWithdrawFee(uint16[3] memory _withdrawFee) external onlyOwner {
        withdrawFee = _withdrawFee;
    }

    function setClaimFee(uint16[3] memory _claimFee) external onlyOwner {
        claimFee = _claimFee;
    }

    function setReinverseFee(uint16[3] memory _reinverseFee) external onlyOwner {
        reinverseFee = _reinverseFee;
    }

    function setAPYPercentage(uint16 _new_APY) external onlyOwner {
        APY_percentage = _new_APY;
    }
    
    function setAdmin(address[3] memory _newAdmin) external onlyOwner {
        Admin = _newAdmin;
    }

    function setPlanDays(uint16[3] memory _planDays) external onlyOwner {
        planDays = _planDays;
    }

}
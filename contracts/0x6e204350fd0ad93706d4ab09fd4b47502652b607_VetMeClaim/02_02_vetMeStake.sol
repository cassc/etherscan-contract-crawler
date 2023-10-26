// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.19;


interface IERC20 {

    function decimals() external pure returns (uint8);
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        // solhint-disable-next-line max-line-length
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

library HelperLib {

    function notAddressZero(address addr) internal pure {
        require(addr != address(0), "address_zero");
    }

    function getPercent(uint256 val, uint256 percentage)
        internal
        pure
        returns (uint256)
    {
        return (val * percentage) / 100;
    }

    function getFractionPercent(uint256 amount, uint256 fraction)
        internal
        pure
        returns (uint256)
    {
        return (amount * fraction) / 10_000;
    }

}

abstract contract Ownable is Context {
    uint256 public constant delay = 172800; // delay for admin change
    address private admin;
    address public pendingAdmin; // pending admin variable
    uint256 public changeAdminDelay; // admin change delay variable

    event ChangeAdmin(address sender, address newOwner);
    event RejectPendingAdmin(address sender, address newOwner);
    event AcceptPendingAdmin(address sender, address newOwner);

    function onlyOwner() internal view {
        require(_msgSender() == admin, "Ownable: caller is not the owner");
    }

    constructor() {
        admin = _msgSender();
    }

    function _setOwner(address _owner) internal {
        HelperLib.notAddressZero(_owner);
        admin = _owner;
    }

    function changeAdmin(address _admin) external {
        onlyOwner();
        HelperLib.notAddressZero(_admin);
        pendingAdmin = _admin;
        changeAdminDelay = block.timestamp + delay;
        emit ChangeAdmin(_msgSender(), pendingAdmin);
    }

    function rejectPendingAdmin() external {
        onlyOwner();
        if (pendingAdmin != address(0)) {
            pendingAdmin = address(0);
            changeAdminDelay = 0;
        }
        emit RejectPendingAdmin(_msgSender(), pendingAdmin);
    }

    function owner() public view returns (address) {
        return admin;
    }


    function acceptPendingAdmin() external {
        onlyOwner();
        if (changeAdminDelay > 0 && pendingAdmin != address(0)) {
            require(
                block.timestamp > changeAdminDelay,
                "Ownable: owner apply too early"
            );
            admin = pendingAdmin;
            changeAdminDelay = 0;
            pendingAdmin = address(0);
        }
        emit AcceptPendingAdmin(_msgSender(), admin);
    }
}


contract VetMeStaking is Ownable{ 
    IERC20 public immutable stakingToken;
    IERC20 public immutable rewardsToken;

    uint256 public constant w_delay = 172_800; // delay for withdraw for 48 hours
    uint public duration;
    uint public finishAt;
    uint public totalReward;
    uint public totalForStake;
    mapping(address => uint) public withdraw_pending;
    mapping(address => bool) public rewarded;

    uint public totalSupply;
    mapping(address => uint) public balanceOf;

    event WithdrawRequst(address sender, uint amount);
    event WithdrawRequstCancel(address sender);
    event Withdraw(address sender, uint amount);
    event Staked(address sender, uint amount);
    event Claimed(address sender, uint amount);


    constructor(address _stakingToken,address _rewardsToken,uint _totalForStake){
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardsToken);
        totalForStake = _totalForStake;
    }

    function setRewardsDuration(uint _duration) external {
        onlyOwner();
        require(finishAt > block.timestamp || finishAt == 0,"Reward duration has finished");
        duration +=_duration;
        finishAt = block.timestamp + _duration;
    }

    function notifyRewardAmount(uint _amount) external payable {
        onlyOwner();
         require(_amount > 0, "Amount must be greater than zero");
        rewardsToken.transferFrom(msg.sender, address(this), _amount);
        totalReward += _amount;
    }

    function stake(uint _amount) external {
        require(_amount > 0, "Amount = 0");
        require(duration > 0, "Staking not started");
        require(block.timestamp < finishAt, "Staking period has ended");
        stakingToken.transferFrom(msg.sender, address(this),_amount);
        balanceOf[msg.sender]+= _amount;
        totalSupply += _amount;
        rewarded[msg.sender] = false;

        emit Staked(_msgSender(), _amount);
    }


     function requestWithdraw() external   {  
            require(balanceOf[_msgSender()] > 0,"You have no stake"); 
            withdraw_pending[_msgSender()] = block.timestamp + w_delay;
            emit WithdrawRequst(_msgSender(),  block.timestamp + w_delay);
    }

     function cancelWithdrawRequest() external   {  
            withdraw_pending[_msgSender()] = 0;
            emit WithdrawRequstCancel(_msgSender());
    }

     function withdraw() external{  
           require(balanceOf[_msgSender()] > 0,"You have no stake"); 
           require(withdraw_pending[_msgSender()] > 0,"You have no pending withdraw");
           require(block.timestamp >= withdraw_pending[_msgSender()],"Withdraw pending.");
           uint amount = balanceOf[(_msgSender())];
           balanceOf[(_msgSender())] = 0;
           totalSupply -= amount;
           stakingToken.transfer((_msgSender()),amount);
           withdraw_pending[_msgSender()] = 0;
           emit Withdraw(_msgSender(),amount);
    }

        
    function claimReward() external{
        require(balanceOf[_msgSender()] > 0,"You have no stake"); 
        require(finishAt <= block.timestamp, "Staking period is not over");
        require(!rewarded[msg.sender], "Reward has been claimed");
        
        uint reward =  ((balanceOf[_msgSender()] / totalForStake) * 100) * (totalReward / 100);
        uint balance = balanceOf[_msgSender()];

        rewarded[msg.sender] = true;
        balanceOf[_msgSender()]= 0;
        rewardsToken.transfer(msg.sender, reward);
        stakingToken.transfer(msg.sender, balance);
        totalReward -= reward;
        emit Claimed(_msgSender(),reward);
    }

    function redeemReward() external{
        require(totalReward > 0,"No reward in the contract"); 
         onlyOwner();
         rewardsToken.transfer(msg.sender,totalReward);
         totalReward = 0;
         finishAt=0;
         duration=0;
    }

    function _min(uint x,uint y) private pure returns (uint){
        return x <=y ? x : y;
    }
}
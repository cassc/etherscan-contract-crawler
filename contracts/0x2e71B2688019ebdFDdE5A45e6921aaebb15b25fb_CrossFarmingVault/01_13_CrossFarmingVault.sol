// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "sgn-v2-contracts/contracts/message/interfaces/IMessageBus.sol";
import "./interfaces/IMessage.sol";
import "./libraries/DataTypes.sol";

/// @title A vault contract deployed on EVM chain, users can stake LP token from EVM liquidity pool
/// to participate MasterchefV2 farm pools(BSC chain), get native CAKE reward.
contract CrossFarmingVault is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amount; // user deposit original LP token amount.
        uint256 lastActionTime;
    }

    struct PoolInfo {
        IERC20 lpToken;
        uint256 mcv2PoolId; // pool id in Pancakeswap MastercherV2 farms.
        uint256 totalAmount; // total staked LP token amount.
    }

    // Info of each pool.
    PoolInfo[] public poolInfo;

    // cross farming sender contract's messagebus contract.
    address public messageBus;
    // cross farming sender contract deployed on other EVM chain(not bsc chain)
    // which send cross-chain msg to celer messagebus deployed on EVM chain.
    address public immutable CROSS_FARMING_SENDER;
    // cross farming receiver contract deployed on BSC chain
    // which receive cross-chain msg from celer messagebus deployed on BSC chain.
    address public immutable CROSS_FARMING_RECEIVER;
    // the operator for fallbackwithdraw/deposit operation.
    address public operator;
    // BSC chain ID
    uint64 public immutable BSC_CHAIN_ID;

    // whether LP tokend added to pool
    mapping(IERC20 => bool) public exists;
    // deposit records (account => (pid => (nonce => amount))
    /// @notice this is just for 'deposit' function, make sure operator fallbackDeposit amount
    /// exactly match original deposit amount, in withdraw related function should not consider this.
    mapping(address => mapping(uint256 => mapping(uint64 => uint256))) public deposits;
    // MCV2 pool 1:1 vault pool
    mapping(uint256 => uint256) public poolMapping;
    // white list masterchefv2 pool id. function 'add' mcv2 pool id should be in the list.
    mapping(uint256 => bool) public whitelistPool;
    // (pid => (account => UserInfo))
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    /// @notice used nonce (user => (pid => (nonce => bool)))
    mapping(address => mapping(uint256 => mapping(uint64 => bool))) public usedNonce;

    event Pause();
    event Unpause();
    event AddedWhiteListPool(uint256 pid);
    event AddedPool(address indexed lpToken, uint256 mockPoolId);
    event OperatorUpdated(address indexed newOperator, address indexed oldOperator);
    event Deposit(address indexed sender, uint256 pid, uint256 amount, uint64 nonce);
    event Withdraw(address indexed sender, uint256 pid, uint256 amount, uint64 nonce);
    event EmergencyWithdraw(address indexed sender, uint256 pid, uint256 amount, uint64 nonce);
    event AckWithdraw(address indexed sender, uint256 pid, uint256 amount, uint64 nonce);
    event FallbackDeposit(address indexed sender, uint256 pid, uint256 amount, uint64 nonce);
    event FallbackWithdraw(address indexed sender, uint256 pid, uint256 amount, uint64 nonce);
    event AckEmergencyWithdraw(address indexed sender, uint256 pid, uint256 amount, uint64 nonce);

    /**
     * @param _operator: a priviledged user for fallback operation.
     * @param _sender: cross farming sender contract on EVM chain
     * @param _receiver: cross farming receiver contract on BSC
     * @param _chainId: BSC chain ID
     */
    constructor(
        address _operator,
        address _sender,
        address _receiver,
        uint64 _chainId
    ) {
        operator = _operator;
        CROSS_FARMING_SENDER = _sender;
        CROSS_FARMING_RECEIVER = _receiver;
        BSC_CHAIN_ID = _chainId;

        // set messageBus
        messageBus = IMessage(CROSS_FARMING_SENDER).messageBus();

        // dummpy pool, poolInfo index increase from 1.
        poolInfo.push(PoolInfo({lpToken: IERC20(address(0)), mcv2PoolId: 0, totalAmount: 0}));
    }

    modifier onlySender() {
        require(msg.sender == CROSS_FARMING_SENDER, "not cross farming sender");
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "not fallback operator");
        _;
    }

    modifier onlyNotUsedNonce(
        address _user,
        uint256 _pid,
        uint64 _nonce
    ) {
        require(!usedNonce[_user][_pid][_nonce], "used nonce");
        _;
    }

    modifier notContract() {
        require(!_isContract(msg.sender), "contract not allowed");
        require(msg.sender == tx.origin, "proxy contract not allowed");
        _;
    }

    /**
     * @notice Add available MasterchefV2 farm pool id for cross-farming.
     * @param _mcv2Pid MasterchefV2 pool id array.
     */
    function addWhiteListPool(uint256 _mcv2Pid) public onlyOwner {
        require(!whitelistPool[_mcv2Pid], "Added mcv2 pool id");
        whitelistPool[_mcv2Pid] = true;

        emit AddedWhiteListPool(_mcv2Pid);
    }

    /**
     * @notice Add lp token and pool id corresponding to masterchefv2 farm pool.
     * @dev same token can't be added repeatedly
     * @param _lpToken lp token address.
     * @param _mcv2PoolId pool id in masterchefv2 farm pool, must be in whitelist pools.
     */
    function add(IERC20 _lpToken, uint256 _mcv2PoolId) public onlyOwner {
        require(!exists[_lpToken], "Existed token");
        require(whitelistPool[_mcv2PoolId], "Not whitelist pool");
        require(poolMapping[_mcv2PoolId] == 0, "MCV2 pool already matched");
        require(_lpToken.balanceOf(address(this)) >= 0, "Not ERC20 token");

        // add poolInfo
        poolInfo.push(PoolInfo({lpToken: _lpToken, mcv2PoolId: _mcv2PoolId, totalAmount: 0}));

        // update mappping
        exists[_lpToken] = true;
        poolMapping[_mcv2PoolId] = poolInfo.length - 1;

        emit AddedPool(address(_lpToken), _mcv2PoolId);
    }

    /**
     * @notice deposit funds into current vault.
     * @dev only possible when contract not paused.
     * @param _pid lp token pool id in vault contract.
     * @param _amount deposit token amount.
     */
    function deposit(uint256 _pid, uint256 _amount) external payable nonReentrant whenNotPaused notContract {
        require(_amount > 0, "Nothing to deposit");

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        uint256 before = pool.lpToken.balanceOf(address(this));
        pool.lpToken.safeTransferFrom(msg.sender, address(this), _amount);
        _amount = pool.lpToken.balanceOf(address(this)) - before;

        uint64 nonce = IMessage(CROSS_FARMING_SENDER).nonces(msg.sender, pool.mcv2PoolId);
        // encode message
        bytes memory message = encodeMessage(
            msg.sender,
            pool.mcv2PoolId,
            _amount,
            DataTypes.MessageTypes.Deposit,
            nonce
        );

        // send message
        (bool success, ) = CROSS_FARMING_SENDER.call{value: msg.value}(
            abi.encodeWithSignature("sendFarmMessage(bytes)", message)
        );

        require(success, "send deposit farm message failed");

        // update poolInfo
        pool.totalAmount = pool.totalAmount + _amount;
        // update userInfo
        user.amount = user.amount + _amount;
        user.lastActionTime = block.timestamp;
        // save deposit record
        deposits[msg.sender][_pid][nonce] = _amount;

        // deposit don't need to mark nonce used

        emit Deposit(msg.sender, _pid, _amount, nonce);
    }

    /**
     * @notice withdraw funds from vault.
     * @dev just send 'withdraw' message to MasterchefV2 pool on BSC chain. don't transfer LP token to user,
     * after withdraw on Masterchef pool success and send ack message back, 'ackWithdraw' will finally transfer token back.
     * @notice only possible when contract not paused.
     * @param _pid lp token pool id in vault contract.
     * @param _amount withdraw token amount.
     */
    function withdraw(uint256 _pid, uint256 _amount) external payable nonReentrant notContract whenNotPaused {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(user.amount >= _amount && _amount > 0, "withdraw: Insufficient amount");

        // encode farming message
        uint64 nonce = IMessage(CROSS_FARMING_SENDER).nonces(msg.sender, pool.mcv2PoolId);

        bytes memory message = encodeMessage(
            msg.sender,
            pool.mcv2PoolId,
            _amount,
            DataTypes.MessageTypes.Withdraw,
            nonce
        );

        // send message
        (bool success, ) = CROSS_FARMING_SENDER.call{value: msg.value}(
            abi.encodeWithSignature("sendFarmMessage(bytes)", message)
        );

        require(success, "send withdraw farm message failed");

        // don't do any state change, will do it at ackWithdraw

        emit Withdraw(msg.sender, _pid, _amount, nonce);
    }

    /**
     * @notice withdraw funds from vault.
     * @dev just send 'emergencyWithdraw' message to MasterchefV2 pool on BSC chain. don't transfer LP token to user,
     * after emergencyWithdraw on Masterchef pool success and send ack message back, 'ackEmergencyWithdraw' will finally transfer token back.
     * @notice only be called when contract not paused, emergencyWithdraw only mean withdraw from Masterchef don't care about CAKE reward.
     * @param _pid lp token pool id in vault contract.
     */
    function emergencyWithdraw(uint256 _pid) external payable nonReentrant notContract whenNotPaused {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        uint256 amount = user.amount;
        require(amount > 0, "No fund left");

        // encode farming message
        uint64 nonce = IMessage(CROSS_FARMING_SENDER).nonces(msg.sender, pool.mcv2PoolId);

        bytes memory message = encodeMessage(
            msg.sender,
            pool.mcv2PoolId,
            amount,
            DataTypes.MessageTypes.EmergencyWithdraw,
            nonce
        );

        // send farming message
        (bool success, ) = CROSS_FARMING_SENDER.call{value: msg.value}(
            abi.encodeWithSignature("sendFarmMessage(bytes)", message)
        );

        require(success, "send emergencyWithdraw farm message failed");

        // don't do any state change, will do it at ackEmergencyWithdraw

        emit EmergencyWithdraw(msg.sender, _pid, amount, nonce);
    }

    /**
     * @notice only called by cross-chain sender contract. withdraw token in specific pool.
     * @param _user user address.
     * @param _mcv2pid lp token pool id in mcv2 farm pool.
     * @param _amount withdraw token amount.
     * @param _nonce withdraw tx nonce from BSC chain.
     */
    function ackWithdraw(
        address _user,
        uint256 _mcv2pid,
        uint256 _amount,
        uint64 _nonce
    ) external nonReentrant onlySender {
        uint256 pid = poolMapping[_mcv2pid];
        require(!usedNonce[_user][pid][_nonce], "used nonce");

        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][_user];

        // check by ack amount
        require(user.amount >= _amount && _amount > 0, "ackWithdraw: Insufficient amount");

        // update poolInfo
        pool.totalAmount = pool.totalAmount - _amount;
        // update userInfo
        user.amount -= _amount;
        user.lastActionTime = block.timestamp;

        // mark nonce used
        usedNonce[_user][pid][_nonce] = true;

        // transfer LP token
        IERC20(pool.lpToken).safeTransfer(_user, _amount);

        emit AckWithdraw(_user, pid, _amount, _nonce);
    }

    /**
     * @notice only called by cross-chain sender contract. withdraw all staked token in specific pool.
     * @param _user user address.
     * @param _mcv2pid lp token pool id in mcv2 farm pool.
     * @param _nonce withdraw tx nonce from BSC chain.
     */
    function ackEmergencyWithdraw(
        address _user,
        uint256 _mcv2pid,
        uint64 _nonce
    ) external nonReentrant onlySender {
        uint256 pid = poolMapping[_mcv2pid];
        require(!usedNonce[_user][pid][_nonce], "used nonce");

        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][_user];

        uint256 withdrawAmount = user.amount;

        // totalAmount > withdrawAmount
        pool.totalAmount -= withdrawAmount;
        // update userInfo
        user.amount = 0;
        user.lastActionTime = block.timestamp;
        // mark nonce used
        usedNonce[_user][pid][_nonce] = true;

        // transfer token
        IERC20(pool.lpToken).safeTransfer(_user, withdrawAmount);

        emit AckEmergencyWithdraw(_user, pid, withdrawAmount, _nonce);
    }

    /**
     * @dev called by operator when user deposit success on source chain(EVM chain) but failed on dest chain(BSC chain).
     * please make sure 'fallbackDeposit' called on BSC chain first.
     * @param _user user address.
     * @param _pid pool id in current vault, not mcv2 pid.
     * @param _amount fallbackDeposit withdraw token amount.
     * @param _nonce failed nonce.
     */
    function fallbackDeposit(
        address _user,
        uint256 _pid,
        uint256 _amount,
        uint64 _nonce
    ) external onlyOperator onlyNotUsedNonce(_user, _pid, _nonce) {
        // double check
        require(deposits[_user][_pid][_nonce] == _amount, "withdraw amount not match staking record");

        _fallback(_user, _pid, _amount, _nonce);

        emit FallbackDeposit(_user, _pid, _amount, _nonce);
    }

    /**
     * @notice only called by operator when below scenarios happened:
     * case 1: if withdraw/emergencywithdraw success on source chain(EVM) and withdraw on proxy contract success
     * on EVM chain, but failed to send Ack msg back to EVM chain, only call this function.
     *
     * case 2: if withdraw/emergencywithdraw success on source chain(EVM), but failed to withdraw on proxy contract(maybe msg
     * failed to deliver to BSC chain or other issues), please make sure call 'fallbackWithdraw' on receiver contract on BSC chain first,
     * then call this function
     *
     * @param _user user address.
     * @param _pid pool id in current vault, not mcv2 pool id.
     * @param _amount fallbackwithdraw token amount.
     * @param _nonce failed nonce.
     */
    function fallbackWithdraw(
        address _user,
        uint256 _pid,
        uint256 _amount,
        uint64 _nonce
    ) external onlyOperator onlyNotUsedNonce(_user, _pid, _nonce) {
        _fallback(_user, _pid, _amount, _nonce);

        emit FallbackWithdraw(_user, _pid, _amount, _nonce);
    }

    function _fallback(
        address _user,
        uint256 _pid,
        uint256 _amount,
        uint64 _nonce
    ) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        // check fallback amount
        require(user.amount >= _amount && _amount > 0, "fallback: Insufficient amount");

        // update poolInfo
        pool.totalAmount = pool.totalAmount - _amount;
        // update userInfo
        user.amount -= _amount;
        user.lastActionTime = block.timestamp;

        // mark nonce used
        usedNonce[_user][_pid][_nonce] = true;

        // transfer LP token back
        IERC20(pool.lpToken).safeTransfer(_user, _amount);
    }

    // set fallbackwithdraw operator
    function setOperator(address _operator) external onlyOwner {
        require(_operator != address(0), "Operator can't be zero address");
        address temp = operator;
        operator = _operator;

        emit OperatorUpdated(operator, temp);
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    /**
     * @notice utility interface for FE to calc routing message fee charged by celer.
     * @param _message encoded cross-farm  message
     */
    function calcFee(bytes calldata _message) external view returns (uint256) {
        return IMessageBus(messageBus).calcFee(_message);
    }

    /**
     * @notice utility interface for FE to encode cross-farming message.
     * @param _account cross-farm user account.
     * @param _pid MasterchefV2 farm pool id.
     * @param _amount the input token amount.
     * @param _msgType farm message type.
     * @param _nonce user nonce.
     */
    function encodeMessage(
        address _account,
        uint256 _pid,
        uint256 _amount,
        DataTypes.MessageTypes _msgType,
        uint64 _nonce
    ) public view returns (bytes memory) {
        return
            abi.encode(
                DataTypes.CrossFarmRequest({
                    receiver: CROSS_FARMING_RECEIVER,
                    dstChainId: BSC_CHAIN_ID,
                    nonce: _nonce,
                    account: _account,
                    amount: _amount,
                    pid: _pid,
                    msgType: _msgType
                })
            );
    }

    /**
     * @notice Triggers stopped state
     * @dev Only possible when contract not paused.
     */
    function pause() external onlyOwner {
        _pause();
        emit Pause();
    }

    /**
     * @notice Returns to normal state
     * @dev Only possible when contract is paused.
     */
    function unpause() external onlyOwner {
        _unpause();
        emit Unpause();
    }

    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
}
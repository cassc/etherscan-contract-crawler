//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import '../interface/IPuppetOfDispatcher.sol';
import '../interface/IReceiver.sol';

contract WithdrawalAccount is Context, ReentrancyGuard, IPuppetOfDispatcher,IReceiver, Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    event Withdrawal(address user, uint256 amount);
    event SetOperator(address indexed user, bool allow );
    event Sweep(address token, address recipient, uint256 amount);

    address public token;
    address public dispatcher;
    mapping(address => bool) public operators;
    uint256 constant public MAX_WITHDRAWAL = 2* 10 ** 5 * 10 ** 18;

    address public platformAddress;
    uint256 public platformFeeRate;
    address public ptrPoolAddress;
    uint256 public ptrFeeRate;

    modifier onlyOperator() {
        require(operators[_msgSender()], "WithdrawalAccount: sender is not operator");
        _;
    }

    modifier onlyDispatcher() {
        require(_msgSender() == dispatcher, "WithdrawalAccount:sender is not dispatcher");
        _;
    }
    constructor(address _token, address _dispatcher) {
        token = _token;
        dispatcher = _dispatcher;
        operators[msg.sender] = true;
        operators[dispatcher] = true;
    }

    function setPlatformAddress(address user) external onlyOwner{
        require(user != address(0), "user: ZERO_ADDRESS");
        platformAddress = user;
    }

    function setPtrPoolAddress(address ptrAddress) external onlyOwner{
        require(ptrAddress != address(0), "ptrAddress: ZERO_ADDRESS");
        ptrPoolAddress = ptrAddress;
    }

    function setPlatformFeeRate(uint256 _feeRate) external onlyOwner{
        require(_feeRate > 0, "_feeRate: not > 0");
        require(_feeRate < 50, "_feeRate: not > 0");
        platformFeeRate = _feeRate;
    }

    function setPtrFeeRate(uint256 _feeRate) external onlyOwner{
        require(_feeRate > 0, "_feeRate: not > 0");
        require(_feeRate < 50, "_feeRate: not > 0");
        ptrFeeRate = _feeRate;
    }

    function withdrawal(address user, uint256 amount) external  onlyOperator nonReentrant{
        require(user != address(0), "WithdrawalAccount: user is zero address");
        require(amount != 0, "WithdrawalAccount: amount is zero");
        require(amount <= MAX_WITHDRAWAL, "WithdrawalAccount: Withdrawal amount is too large");
        uint256 transferRate = 100-platformFeeRate-ptrFeeRate;
        require(transferRate > 0, "transferRate: not > 0");
        IERC20(token).safeTransfer(platformAddress, amount.mul(platformFeeRate).div(100));
        IERC20(token).safeTransfer(ptrPoolAddress, amount.mul(ptrFeeRate).div(100));
        IERC20(token).safeTransfer(user, amount.mul(transferRate).div(100));
        emit Withdrawal(user, amount);
    }

    function setOperator(address user, bool allow) external override onlyDispatcher{
        require(user != address(0), "WithdrawalAccount: ZERO_ADDRESS");
        operators[user] = allow;
        emit SetOperator(user, allow);
    }

    function setDispatcher(address _dispatcher) external override onlyDispatcher{
        require(_dispatcher != address(0), "WithdrawalAccount: ZERO_ADDRESS");
        dispatcher = _dispatcher;
    }

    function sweep(address stoken, address recipient) external onlyOperator{
        uint256 balance = IERC20(stoken).balanceOf(address(this));
        if(balance > 0) {
            IERC20(stoken).safeTransfer(recipient, balance);
            emit Sweep(stoken, recipient, balance);
        }
    }

    function harvest() external override onlyDispatcher  {
        uint256 balanceOf = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(dispatcher, balanceOf);
    }

    function withdrawToDispatcher(uint256 leaveAmount) external override  onlyDispatcher  {
        require(leaveAmount > 0, "WithdrawalAccount: leaveAmount is zero");
        IERC20(token).safeTransfer(dispatcher, leaveAmount);
    }

    function totalAmount() external override view returns(uint256) {

        return IERC20(token).balanceOf(address(this));
    }
}
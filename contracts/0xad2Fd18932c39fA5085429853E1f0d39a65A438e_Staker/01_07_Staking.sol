pragma solidity ^0.6.12;

import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Staker is Ownable {
    using SafeMath for uint256;
    using Address for address;
    
    IERC20 _token; 
    mapping (address => uint256) _balances;
    mapping (address => uint256) _unlockTime;
    mapping (address => bool) _isIDO;
    bool halted;

    event Stake(address indexed account, uint256 timestamp, uint256 value);
    event Unstake(address indexed account, uint256 timestamp, uint256 value);
    event Lock(address indexed account, uint256 timestamp, uint256 unlockTime, address locker);

    constructor() public {
        _token = IERC20(0x3d6F0DEa3AC3C607B3998e6Ce14b6350721752d9);
    }

    function stakedBalance(address account) external view returns (uint256) {
        return _balances[account];
    }

    function unlockTime(address account) external view returns (uint256) {
        return _unlockTime[account];
    }

    function isIDO(address account) external view returns (bool) {
        return _isIDO[account];
    }

    function stake(uint256 value) external notHalted {
        require(value > 0, "Staker: stake value should be greater than 0");
        _token.transferFrom(_msgSender(), address(this), value);

        _balances[_msgSender()] = _balances[_msgSender()].add(value);
        emit Stake(_msgSender(),now,value);
    }

    function unstake(uint256 value) external lockable {
        require(_balances[_msgSender()] >= value, 'Staker: insufficient staked balance');

        _balances[_msgSender()] = _balances[_msgSender()].sub(value,"Staker: insufficient staked balance");
        _token.transfer(_msgSender(), value);
        emit Unstake(_msgSender(),now,value);
    }

    function lock(address user, uint256 unlockTime) external onlyIDO {
        require(unlockTime > now, "Staker: unlock is in the past");
        if (_unlockTime[user] < unlockTime) {
            _unlockTime[user] = unlockTime;
            emit Lock(user,now,unlockTime,_msgSender());
        }
    }

    function halt(bool status) external onlyOwner {
        halted = status;
    }

    function addIDO(address account) external onlyOwner {
        require(account != address(0), "Staker: cannot be zero address");
        _isIDO[account] = true;
    }

    modifier onlyIDO() {
        require(_isIDO[_msgSender()],"Staker: only IDOs can lock");
        _;
    }

    modifier lockable() {
        require(_unlockTime[_msgSender()] <= now, "Staker: account is locked");
        _;
    }

    modifier notHalted() {
        require(!halted, "Staker: Deposits are paused");
        _;
    }
}
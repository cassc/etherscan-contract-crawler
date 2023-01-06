// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";



contract TagPoolStakingT3 is AccessControl ,ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bytes32 public constant PAUSE_ROLE = keccak256("PAUSE_ROLE");

    IERC20 public immutable TagCoin;

    IERC20 public immutable PoolToken;

    mapping(address => uint256) public balanceOf;

    mapping ( address => uint256 ) public depositBlock;

    uint256 public totalSupply;

    uint256 public totalRewards;

    uint256 private constant MULTIPLIER = 1e18;

    uint256 private rewardIndex;

    mapping(address => uint256) private rewardIndexOf;

    mapping(address => uint256) private earned;

    mapping ( address => bool ) private PoolStaking;

    uint256 private fees;

    address private PoolClaim;

    uint256 private cooldown;

    event StakeEvent( address indexed _user , uint256 _amt);

    event UnStakeEvent ( address indexed _user , uint256 _amt , uint256 _reward );

    modifier isValidFees() {
        require(msg.value > fees, "TagPoolStakingT2: Invalid Fees provided");
        _;
    }

    modifier isStaking() {
        require(PoolStaking[msg.sender] == true, "TagPoolStakingT2: Only PoolStaking can call this function");
        _;
    }

    constructor (
        address _TagCoin,
        address _PoolToken,
        address _DFA
    ) public {
        _setupRole(DEFAULT_ADMIN_ROLE, _DFA);

        PoolToken = IERC20(_PoolToken);
        TagCoin = IERC20(_TagCoin);
    }


    //TagCoin Deposit
    function TDeposit(uint256 _amount) public virtual isStaking {
        updateRewardIndex(_amount);
        totalRewards += _amount;
    }

    function Fund(uint256 _amount) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        updateRewardIndex(_amount);
        TagCoin.transferFrom(msg.sender , address(this) , _amount);
        totalRewards += _amount;
    }

    function updateRewardIndex(uint reward) internal {
        rewardIndex += (reward * MULTIPLIER) / totalSupply;
    }
    //TagCoin Deposit


    // Internal Functions
    function _calculateRewards(address account) internal view returns (uint256) {
        uint shares = balanceOf[account];
        return (shares * (rewardIndex - rewardIndexOf[account])) / MULTIPLIER;
    }

    function _updateRewards(address account) internal {
        earned[account] += _calculateRewards(account);
        rewardIndexOf[account] = rewardIndex;
    }
    // Internal Functions

    // Setters Function
    function setFees( uint256 _fees ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        fees = _fees;
    }

    function setPoolClaim( address _poolClaim ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        PoolClaim = _poolClaim;
    }

    function setCooldown( uint256 _cooldown ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        cooldown = _cooldown;
    }

    function setPoolStaking( address _addr ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        PoolStaking[_addr] = true;
    }

    function unsetPoolStaking( address _addr ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        PoolStaking[_addr] = false;
    }

    // Setters Function

    // View Functions
    function fetchRewards( address _account ) external view returns( uint256 ){
        return _calculateRewards(_account);
    }

    function fetchFees() external view returns( uint256 ){
        return fees;
    }

    function fetchPoolClaim() external view returns( address ){
        return PoolClaim;
    }

    function fetchCooldown() external view returns( uint256 ){
        return cooldown;
    }

    function fetchIsPoolStaking( address _addr ) external view returns( bool ){
        return PoolStaking[_addr];
    }
    // View Functions


    // Core Functions
    function stake(uint amount) external nonReentrant {
        _updateRewards(msg.sender);

        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        depositBlock[msg.sender] = block.number;

        PoolToken.transferFrom(msg.sender, address(this), amount);
        emit StakeEvent( msg.sender , amount );
    }

    function unstake(uint amount) external payable  nonReentrant {
        require((block.number - depositBlock[msg.sender]) >= cooldown  , "TagPoolStakingT3 : unstake cant be done before cooldown");
        require(msg.value >= fees  , "TagPoolStakingT3 : Not enough fees");
        uint256 diff = msg.value - fees;
        payable(msg.sender).transfer(diff);
        payable(PoolClaim).transfer(fees);

        _updateRewards(msg.sender);

        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;

        uint reward = earned[msg.sender];
        if (reward > 0) {
            earned[msg.sender] = 0;
            TagCoin.transfer(msg.sender, reward);
        }

        PoolToken.transfer(msg.sender, amount);
        emit UnStakeEvent( msg.sender , amount, reward);
    }

    // Core Functions


}
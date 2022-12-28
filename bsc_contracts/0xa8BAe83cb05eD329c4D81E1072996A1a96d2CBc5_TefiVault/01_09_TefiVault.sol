//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TefiVault is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint amount;
        uint share;
        uint depositedAt;
        uint claimedAt;
        address referral;
    }

    address public strategy;
    IERC20 public immutable asset;

    uint public totalSupply;
    uint public totalShare;
    uint public underlying;
    uint public profits;
    uint public rebalanceRate = 20;

    bool locked;
    uint public constant DUST = 0.01 ether;

    mapping(address => UserInfo) public users;

    modifier onlyStrategy {
        require (msg.sender == strategy, "!permission");
        _;
    }

    modifier clearDustShare {
        _;
        UserInfo storage user = users[msg.sender];
        if (user.share < DUST) {
            totalSupply -= user.amount;
            totalShare -= user.share;
            delete users[msg.sender];
        }
    }

    constructor(address _strategy, address _asset) {
        strategy = _strategy;
        asset = IERC20(_asset);
    }

    function balance() public view returns (uint) {
        return asset.balanceOf(address(this)) + underlying;
    }

    function available() public view returns (uint) {
        return asset.balanceOf(address(this));
    }

    function balanceOf(address _user) public view returns (uint) {
        return users[_user].share * balance() / totalShare;
    }

    function principalOf(address _user) public view returns (uint) {
        UserInfo storage user = users[_user];
        uint curBal = user.share * balance() / totalShare;
        return curBal > user.amount ? user.amount : curBal;
    }

    function earned(address _user) public view returns (uint) {
        UserInfo storage user = users[_user];
        uint bal = balanceOf(_user);
        return user.amount < bal ? (bal - user.amount) : 0;
    }

    function totalEarned() external view returns (uint) {
        uint totalBal = balance();
        return totalBal > totalSupply ? (totalBal - totalSupply) : 0;
    }

    function deposit(uint _amount) external whenNotPaused nonReentrant {
        require (_amount > 0, "!amount");

        uint share;
        uint poolBal = balance();
        if (totalShare == 0) {
            share = _amount;
        } else {
            share = (_amount * totalShare) / poolBal;
        }

        asset.transferFrom(msg.sender, address(this), _amount);

        UserInfo storage user = users[msg.sender];
        user.share += share;
        user.amount += _amount;
        totalShare += share;
        totalSupply += _amount;

        _rebalance();
    }

    function withdraw(uint _amount) external nonReentrant clearDustShare {
        UserInfo storage user = users[msg.sender];
        uint principal = principalOf(msg.sender);
        require (principal >= _amount, "exceeded amount");
        require (_amount <= available(), "exceeded withdrawable amount");
        
        uint share = _min((_amount * totalShare / balance()), user.share);

        user.share -= share;
        totalShare -= share;
        user.amount -= _amount;
        totalSupply -= _amount;
        
        asset.safeTransfer(msg.sender, _amount);
    }

    function withdrawAll() external nonReentrant clearDustShare {
        UserInfo storage user = users[msg.sender];
        uint _earned = earned(msg.sender);
        
        uint _amount = user.share * balance() / totalShare;
        require (_amount <= available(), "exceeded withdrawable amount");

        totalShare -= user.share;
        totalSupply -= user.amount;
        profits -= _min(profits, _earned);
        delete users[msg.sender];
        
        asset.safeTransfer(msg.sender, _amount);
    }

    function claim() external nonReentrant clearDustShare {
        uint _earned = earned(msg.sender);
        require (_earned > 0, "!earned");

        UserInfo storage user = users[msg.sender];
        uint share = _min((_earned * totalShare / balance()), user.share);

        user.share -= share;
        totalShare -= share;
        profits -= _min(profits, _earned);
        
        asset.safeTransfer(msg.sender, _earned);
    }

    function compound() external nonReentrant {
        uint _earned = earned(msg.sender);
        require (_earned > 0, "!earned");

        UserInfo storage user = users[msg.sender];
        uint share = _earned * totalShare / balance();

        user.share += share;
        totalShare += share;
        user.amount += _earned;
        totalSupply += _earned;
        profits -= _min(profits, _earned);

        _rebalance();
    }

    function rebalance() external nonReentrant {
        _rebalance();
    }
    
    function _rebalance() internal {
        uint invest = investable();
        if (invest == 0) return;
        asset.safeTransfer(strategy, invest);
        underlying += invest;
    }

    function investable() public view returns (uint) {
        uint curBal = available();
        uint poolBal = curBal + underlying - profits;
        uint keepBal = rebalanceRate * poolBal / 100;
        
        if (curBal <= keepBal) return 0;

        return curBal - keepBal;
    }

    function refillable() external view returns (uint) {
        uint curBal = available();
        uint poolBal = curBal + underlying - profits;
        uint keepBal = rebalanceRate * poolBal / 100;
        
        if (curBal >= keepBal) return 0;

        return keepBal - curBal;
    }

    function _min(uint x, uint y) internal pure returns (uint) {
        return x > y ? y : x;
    }

    function reportLose(uint _lose) external onlyStrategy {
        require (_lose <= totalSupply / 2, "wrong lose report");
        // totalSupply -= _lose;
        underlying -= _lose;
    }

    function refill(uint _amount) external onlyStrategy {
        asset.safeTransferFrom(msg.sender, address(this), _amount);
        underlying -= _amount;
    }

    function payout(uint _amount) external {
        asset.safeTransferFrom(msg.sender, address(this), _amount);
        profits += _amount;
    }

    function setRebalanceRate(uint _rate) external onlyOwner {
        require (_rate <= 50, "!rate");
        rebalanceRate = _rate;
    }

    function updateStrategy(address _strategy) external onlyOwner {
        require (underlying > 0, "existing underlying amount");
        strategy = _strategy;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
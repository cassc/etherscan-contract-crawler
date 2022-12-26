// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/IZaynVault.sol";

contract ZaynReferrer is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint public delaySeconds;
    uint256 public minAmountForBonus;
    address public rewardToken;
    address public revShareToken;
    uint256 public rewardAmountUser;
    uint256 public rewardAmountReferrer;

    IERC20 vault;

    struct UserInfo {
        uint lastDepositTime;
        uint256 amount;
        address referrer;
        bool claimed;
        bool refClaim;
        bool withdrawn;
    }

    mapping(address => UserInfo) public userInfo;
    mapping(address => uint256) public refAmount;
    mapping(address => uint256) public refPayments;
    uint256 public totalRefAmount;
    uint256 public feeShareAmount;
    uint256 public zaynPaid;

    address public strategy;

    bool public depositEnabled;

    
    constructor(
        address _rewardToken,
        address _revShareToken,
        uint _delaySeconds,
        uint256 _minAmountForBonus,
        uint256 _rewardAmountUser,
        uint256 _rewardAmountReferrer,
        IERC20 _zaynVault,
        address _strategy

    ) public {
        rewardToken = _rewardToken;
        revShareToken = _revShareToken;
        delaySeconds = _delaySeconds;

        minAmountForBonus = _minAmountForBonus;
        rewardAmountUser = _rewardAmountUser;
        rewardAmountReferrer = _rewardAmountReferrer;
        vault = _zaynVault;
        strategy = _strategy;

        depositEnabled = true;
    }

    function deposit(uint256 amount, address referrer) public {
        require(depositEnabled, "Deposits are not enabled");
        require(msg.sender != referrer, "User and referrer must be different");
        require(msg.sender != address(0), "User cannot be 0 address");
        require(referrer != address(0), "Referrer cannot be 0 address");

        vault.transferFrom(msg.sender, address(this), amount);
        
        UserInfo storage user = userInfo[msg.sender];
        user.lastDepositTime = block.timestamp;
        user.amount += amount;
        user.withdrawn = false;
        user.referrer = referrer;
        refAmount[referrer] += amount;
        totalRefAmount += amount;
    }

    function withdraw(uint256 amount) public {
        require(msg.sender != address(0), "User cannot be 0 address");
        UserInfo storage user = userInfo[msg.sender];
        
        require(user.amount >= amount, "User does not have enough funds locked");
        
        user.amount -= amount;
        user.withdrawn = true;
        refAmount[user.referrer] -= amount;
        totalRefAmount -= amount;
        
        vault.transfer(msg.sender, amount);
    }

    function recordFeeShare(uint256 amount) public {
        require(msg.sender == strategy, "Only strategy can record fee share");
        feeShareAmount += amount;
    }

    function claimBonusUser() external {
        UserInfo storage user = userInfo[msg.sender];
        require(block.timestamp >= user.lastDepositTime.add(delaySeconds), "Time hasn't passed for user");
        require(user.amount >= minAmountForBonus, "User does not have enough funds to be eligble");
        require(!user.claimed, "Already claimed");
        require(!user.withdrawn, "User has withdrawn funds");

        user.claimed = true;
        IERC20(rewardToken).transfer(msg.sender, rewardAmountUser);
    }

    function claimBonusReferrer(address userAddr) external {
        UserInfo storage user = userInfo[userAddr];
        require(block.timestamp >= user.lastDepositTime.add(delaySeconds), "Time hasn't passed for user");
        if(!user.claimed) {
            require(user.amount >= minAmountForBonus, "User does not have enough funds to be eligble");
        }
        require(!user.refClaim, "Already claimed");

        user.refClaim = true;
        IERC20(rewardToken).transfer(user.referrer, rewardAmountReferrer);
    }

    function claimRevShareReferrer(address referrer) external returns (uint256 amount) {
       amount = getReferrerEarning(referrer).sub(refPayments[referrer]);
       refPayments[referrer] += amount;
       IERC20(revShareToken).transfer(referrer, amount);
    }

    function getReferrerEarning(address referrer) view public returns (uint256 amount){
        amount = feeShareAmount.mul(refAmount[referrer]).div(vault.totalSupply());
    }

    function getZaynEarning() view public returns (uint256 referrerAmount, uint256 zaynAmount){
        referrerAmount = feeShareAmount.mul(totalRefAmount).div(vault.totalSupply());
        zaynAmount = feeShareAmount.sub(referrerAmount);
    }
    // ========== ADMIN =================================


    function setDelaySeconds(uint _seconds) external onlyOwner {
        delaySeconds = _seconds;
    }

    function setMinAmountForBonus(uint256 _amount) external onlyOwner {
        minAmountForBonus = _amount;
    }

    function setRewardToken(address _rewardToken) external onlyOwner {
        require(_rewardToken != address(0), "Reward token cannot be zero address");
        rewardToken = _rewardToken;
    }

    function setRevShareToken(address _revShareToken) external onlyOwner {
        require(_revShareToken != address(0), "Rev Share token cannot be zero address");
        revShareToken = _revShareToken;
    }

    function setRewardAmountUser(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Reward ammount cannot be zero");
        rewardAmountUser = _amount;
    }

    function setRewardAmountRef(uint256 _amount) external onlyOwner {
        rewardAmountReferrer = _amount;
    }

    function rescueTokens(address _token) external onlyOwner {
        require(_token != address(vault), "Cannot rescue vault tokens");
        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(msg.sender, amount);
    }

    function zaynCollectFees() external onlyOwner returns (uint256 amount){
        ( , uint256 zaynAmount ) = getZaynEarning();
        amount = zaynAmount.sub(zaynPaid);
        zaynPaid += amount;
        IERC20(revShareToken).transfer(msg.sender, amount);
    }

    function toggleDeposit(bool _toggle) external onlyOwner {
        depositEnabled = _toggle;
    }

}
//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

interface IERC20{
    function decimals() external view returns (uint8);
}

contract IDO is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMathUpgradeable for uint256;
    IERC20Upgradeable public usdt;
    IERC20Upgradeable public son;

    bool public canBuy;
    bool public canClaim;
    uint256 public sonPrice;
    uint256 public buyUsdtLimit;

    uint256 public sonBuyLimit;
    uint256 public sonAlreadyBuyLimit;
    uint256 public usdtReward;

    mapping (address => uint256) public uBuyLimit;
    mapping (address => uint256) public uInviteUsdtReward;

    mapping (address => uint256) public uIDOSonReward;
    mapping (address => uint256) public uAlreadySonReward;
    mapping (address => uint256) public uReleaseNumBySec;
    mapping (address => uint256) public uLastGetRewardTime;

    mapping (address => uint256) public uInviteAllUsdtReward;


    /// @dev Require that the caller must be an EOA account.
    modifier onlyEOA() {
        require(msg.sender == tx.origin, "not eoa");
        _;
    }

    modifier onlyCanBuy() {
        require(canBuy, "not can buy");
        _;
    }

    modifier onlyCanClaim() {
        require(canClaim, "not can claim");
        _;
    }

    function initialize(
        address _son,
        address _usdt
    )
    public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        son = IERC20Upgradeable(_son);
        usdt = IERC20Upgradeable(_usdt);

        canBuy = true;
        canClaim = false;
        sonPrice = 18000;
        buyUsdtLimit = 10000000000;
        sonBuyLimit = 7500000000000000000000000;
    }

    function buySon(uint256 amount, address inviter) external onlyEOA onlyCanBuy nonReentrant {
        require(amount >= 100000000, "Exchange quantity is too small");
        require(inviter != address(0), "err inviter");

        uBuyLimit[msg.sender] = uBuyLimit[msg.sender].add(amount);
        require(uBuyLimit[msg.sender] <= buyUsdtLimit, "Purchase limit exceeded");

        usdt.transferFrom(msg.sender, address(this), amount);
        uint256 sonAmount = amount.mul(1e18).div(sonPrice);
        sonAlreadyBuyLimit = sonAlreadyBuyLimit.add(sonAmount);

        require(sonAmount > 0, "Exchange quantity is too small");
        require(sonAlreadyBuyLimit <= sonBuyLimit, "Oversubscribed");

        uIDOSonReward[msg.sender] = uIDOSonReward[msg.sender].add(sonAmount);
        recommend(amount, inviter);

        usdt.transfer(address(0x802a0cD805877f3fa19Cd7DD70E1f1Ca572Fd610), amount.mul(95).div(100));
    }

    function pendingSon(address account) public view returns(uint256){
        if(uLastGetRewardTime[account] == 0){
            return uIDOSonReward[account].mul(5).div(100);
        }
        uint256 maxReward = uIDOSonReward[account].sub(uAlreadySonReward[account]);
        if (maxReward == 0){
            return 0;
        }

        uint256 pendingReward = block.timestamp.sub(uLastGetRewardTime[account]).mul(uReleaseNumBySec[account]);

        return pendingReward <= maxReward ? pendingReward : maxReward;
    }

    function claimIDOSon() external onlyEOA onlyCanClaim nonReentrant {
        uint256 reward = pendingSon(msg.sender);
        if (reward > 0){
            son.transfer(msg.sender, reward);
            uAlreadySonReward[msg.sender] = uAlreadySonReward[msg.sender].add(reward);
        }
        if (uLastGetRewardTime[msg.sender] == 0 && reward > 0){
            uReleaseNumBySec[msg.sender] = uIDOSonReward[msg.sender].mul(95).div(100).div(15552000);
        }

        uLastGetRewardTime[msg.sender] = block.timestamp;
    }

    function claimInviteUsdt() external onlyEOA nonReentrant {
        usdt.transfer(msg.sender, uInviteUsdtReward[msg.sender]);
        usdtReward = usdtReward.sub(uInviteUsdtReward[msg.sender]);
        uInviteUsdtReward[msg.sender] = 0;
    }

    function recommend(uint256 usdtAmount, address inviter) internal{
        uint256 usdt1Amount = usdtAmount.mul(5).div(100);
        usdtReward = usdtReward.add(usdt1Amount);
        uInviteUsdtReward[inviter] = uInviteUsdtReward[inviter].add(usdt1Amount);
        uInviteAllUsdtReward[inviter] = uInviteAllUsdtReward[inviter].add(usdt1Amount);
    }

    //--------------------------------------------------- Parameter configuration ---------------------------------------------------------------
    function setStatus(bool _canBuy, bool _canClaim) public onlyOwner {
        canBuy = _canBuy;
        canClaim = _canClaim;
        emit LogSetStatus(canBuy, canClaim);
    }

    /// @dev Change the white list exchange quota
    function setSonPrice(uint256 _sonPrice) public onlyOwner {
        sonPrice = _sonPrice;
        emit LogSetSonPrice(sonPrice);
    }

    function setBuyUsdtLimit(uint256 _buyUsdtLimit) public onlyOwner {
        buyUsdtLimit = _buyUsdtLimit;
        emit LogSetBuyUsdtLimit(buyUsdtLimit);
    }

    event LogSetStatus(bool, bool);
    event LogSetSonPrice(uint256);
    event LogSetBuyUsdtLimit(uint256);
}